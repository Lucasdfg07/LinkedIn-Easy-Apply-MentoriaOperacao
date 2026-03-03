# frozen_string_literal: true

require 'thor'

module EasyApply
  class CLI < Thor
    desc 'run', 'Start the Easy Apply bot'
    option :dry_run, type: :boolean, default: false, desc: 'Search and score jobs without applying'
    option :config, type: :string, default: 'config/config.yml', desc: 'Path to config file'
    option :profile, type: :string, default: 'config/profile.yml', desc: 'Path to profile file'
    def run_bot
      setup_signal_handler
      loader = load_config
      config = loader.config
      profile = Matching::Profile.new(loader.profile)

      Log.info('Easy Apply Bot starting', dry_run: options[:dry_run])

      seen_store = Persistence::SeenJobsStore.new
      app_log = Persistence::ApplicationLog.new
      extractor = Matching::RequirementExtractor.new
      scorer = Matching::Scorer.new(config)

      if options[:dry_run]
        run_dry(config, profile, seen_store, app_log, extractor, scorer)
      else
        run_live(config, profile, seen_store, app_log, extractor, scorer)
      end
    rescue Interrupt
      Log.info('Bot stopped by user (SIGINT)')
    rescue StandardError => e
      Log.error("Fatal error: #{e.message}")
      Log.error(e.backtrace.first(5).join("\n"))
      exit(1)
    end

    desc 'validate', 'Validate config and profile files'
    option :config, type: :string, default: 'config/config.yml'
    option :profile, type: :string, default: 'config/profile.yml'
    def validate
      loader = ConfigLoader.new(config_path: options[:config], profile_path: options[:profile])
      loader.load!
      errors = loader.validate!

      if errors.empty?
        puts "\e[32m✓ Config and profile are valid!\e[0m"
        puts "  Keywords: #{loader.config.dig('search', 'keywords')}"
        puts "  Location: #{loader.config.dig('search', 'location')}"
        puts "  Threshold: #{loader.config.dig('matching', 'threshold')}"
        puts "  Skills: #{(loader.profile['skills'] || []).size}"
      else
        puts "\e[31m✗ Validation errors:\e[0m"
        errors.each { |e| puts "  - #{e}" }
        exit(1)
      end
    rescue ConfigError => e
      puts "\e[31m✗ #{e.message}\e[0m"
      exit(1)
    end

    desc 'status', 'Show application statistics'
    def status
      app_log = Persistence::ApplicationLog.new
      seen_store = Persistence::SeenJobsStore.new
      stats = app_log.stats

      puts '=== Easy Apply Bot Status ==='
      puts "Jobs seen:        #{seen_store.count}"
      puts "Total decisions:  #{stats[:total]}"
      puts "Applied:          #{stats[:applied]}"
      puts "Skipped:          #{stats[:skipped]}"
      puts "Failed:           #{stats[:failed]}"
      puts "Average score:    #{stats[:avg_score]}"
      puts ''

      recent = app_log.recent(5)
      if recent.any?
        puts '--- Recent Applications ---'
        recent.each do |entry|
          icon = entry['decision'] == 'applied' ? '✓' : '✗'
          puts "  #{icon} #{entry['title']} @ #{entry['company']} (#{entry['score']}) [#{entry['decision']}]"
        end
      end
    end

    # Map 'run' command name (Thor reserves 'run')
    map 'run' => :run_bot

    private

    def setup_signal_handler
      @running = true
      trap('INT') { @running = false }
    end

    def load_config
      loader = ConfigLoader.new(config_path: options[:config], profile_path: options[:profile])
      loader.load!
      loader
    end

    def run_dry(config, profile, seen_store, app_log, extractor, scorer)
      driver = Browser::DriverFactory.create(config)
      session = Browser::Session.new(driver, config)

      begin
        session.login_with_cookie!
        search = LinkedIn::JobSearch.new(driver, config)
        parser = LinkedIn::JobParser.new(driver, config)

        jobs = search.search
        Log.info("Found #{jobs.size} jobs, processing...")

        jobs.each do |job_card|
          break unless @running

          next if seen_store.seen?(job_card[:id])

          job = parser.parse(job_card)
          requirements = extractor.extract(job[:description])
          score = scorer.score(profile, requirements)

          seen_store.mark_seen!(job[:id], title: job[:title], company: job[:company])

          icon = score[:pass] ? '✓' : '✗'
          puts "#{icon} [#{score[:total]}] #{job[:title]} @ #{job[:company]}"
          puts "  Skills: #{score.dig(:breakdown, :skills, :matched)&.join(', ')}"
          puts "  Exp: #{score.dig(:breakdown, :experience, :score)} | Edu: #{score.dig(:breakdown, :education, :score)}"
          puts ''

          app_log.log_decision!(
            job: job, score: score,
            decision: score[:pass] ? 'would_apply' : 'skipped',
            result: 'dry_run'
          )

          AntiDetection.action_delay(config)
        end

        stats = app_log.stats
        puts "\n=== Dry Run Complete ==="
        puts "Jobs processed: #{stats[:total]}"
        puts "Would apply: #{app_log.entries.count { |e| e['decision'] == 'would_apply' }}"
        puts "Skipped: #{stats[:skipped]}"
      ensure
        session.quit
      end
    end

    def run_live(config, profile, seen_store, app_log, extractor, scorer)
      driver = Browser::DriverFactory.create(config)
      session = Browser::Session.new(driver, config)
      max_apps = config.dig('polling', 'max_applications_per_session') || 50
      break_after = config.dig('polling', 'break_after_applications') || 7
      poll_interval = config.dig('polling', 'interval_seconds') || 60
      session_apps = 0

      begin
        session.login_with_cookie!
        search = LinkedIn::JobSearch.new(driver, config)
        parser = LinkedIn::JobParser.new(driver, config)
        applier = LinkedIn::EasyApplyFlow.new(driver, config, profile)

        loop do
          break unless @running
          break if session_apps >= max_apps

          Log.info("Polling cycle starting (applied: #{session_apps}/#{max_apps})")
          jobs = search.search

          jobs.each do |job_card|
            break unless @running
            break if session_apps >= max_apps

            next if seen_store.seen?(job_card[:id])

            job = parser.parse(job_card)
            requirements = extractor.extract(job[:description])
            score = scorer.score(profile, requirements)

            seen_store.mark_seen!(job[:id], title: job[:title], company: job[:company])

            unless score[:pass]
              Log.info("SKIP: #{job[:title]} @ #{job[:company]} (score: #{score[:total]})")
              app_log.log_decision!(job: job, score: score, decision: 'skipped')
              next
            end

            unless job[:has_easy_apply]
              Log.info("NO EASY APPLY: #{job[:title]} @ #{job[:company]}")
              app_log.log_decision!(job: job, score: score, decision: 'skipped', result: 'no_easy_apply')
              next
            end

            Log.info("APPLYING: #{job[:title]} @ #{job[:company]} (score: #{score[:total]})")
            result = applier.apply!(job)

            if result[:success]
              session_apps += 1
              app_log.log_decision!(job: job, score: score, decision: 'applied', result: 'success')

              if (session_apps % break_after).zero?
                Log.info("Taking a break after #{session_apps} applications...")
                AntiDetection.long_break(config)
              else
                AntiDetection.application_break(config)
              end
            else
              app_log.log_decision!(job: job, score: score, decision: 'failed', result: result[:reason])
            end
          end

          break unless @running

          Log.info("Cycle complete. Waiting #{poll_interval}s before next poll...")
          sleep(poll_interval)
        end

        Log.info("Session complete. Total applications: #{session_apps}")
      ensure
        session.quit
      end
    end
  end
end
