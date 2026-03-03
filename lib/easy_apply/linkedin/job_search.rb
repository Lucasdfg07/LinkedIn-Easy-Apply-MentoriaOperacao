# frozen_string_literal: true

require 'uri'
require 'cgi'

module EasyApply
  module LinkedIn
    class JobSearch
      include Browser::WaitHelpers

      JOBS_URL = 'https://www.linkedin.com/jobs/search/'
      MAX_PAGES = 10

      # LinkedIn time filter values (f_TPR parameter)
      TIME_FILTERS = {
        24 => 'r86400',     # Last 24 hours
        168 => 'r604800',   # Last week
        720 => 'r2592000'   # Last month
      }.freeze

      # Skills that map to more recognizable search terms for LinkedIn
      SKILL_DISPLAY_NAMES = {
        'ruby_on_rails' => 'Ruby on Rails',
        'rails' => 'Ruby on Rails',
        'ruby' => 'Ruby',
        'nodejs' => 'Node.js',
        'node' => 'Node.js',
        'nextjs' => 'Next.js',
        'next_js' => 'Next.js',
        'vuejs' => 'Vue.js',
        'vue_js' => 'Vue.js',
        'react_js' => 'React',
        'react_native' => 'React Native',
        'golang' => 'Golang',
        'go' => 'Golang',
        'rest_api' => 'REST API',
        'ci_cd' => 'CI/CD',
        'csharp' => 'C#',
        'cpp' => 'C++',
        'machine_learning' => 'Machine Learning',
        'power_bi' => 'Power BI',
        'artificial_intelligence' => 'AI',
        'html5' => 'HTML5',
        'css3' => 'CSS3'
      }.freeze

      def initialize(driver, config, profile: nil)
        @driver = driver
        @config = config
        @profile = profile
      end

      def search
        url = build_search_url
        Log.info("Search query: #{built_query}")
        Log.info("Search URL: #{url}")

        @driver.navigate.to(url)
        AntiDetection.action_delay(@config)

        jobs = []
        page = 1

        loop do
          page_jobs = extract_job_cards
          Log.info("Page #{page}: found #{page_jobs.size} jobs")
          jobs.concat(page_jobs)

          break if page >= MAX_PAGES
          break unless next_page?

          click_next_page
          page += 1
          AntiDetection.action_delay(@config)
        end

        Log.info("Total jobs found: #{jobs.size}")
        jobs
      end

      # Expose the generated query for validate/debug
      def built_query
        build_boolean_query
      end

      private

      def build_search_url
        params = { 'keywords' => build_boolean_query }

        # Easy Apply filter
        params['f_AL'] = 'true' if @config.dig('search', 'easy_apply_only')

        # Time filter — posted in last N hours
        posted_hours = @config.dig('search', 'posted_hours')
        if posted_hours
          tpr = TIME_FILTERS[posted_hours.to_i]
          params['f_TPR'] = tpr if tpr
        end

        # Work type filter (1=onsite, 2=remote, 3=hybrid)
        work_type = @config.dig('search', 'work_type')
        params['f_WT'] = work_type.to_s if work_type

        # Geographic filter
        geo_id = @config.dig('search', 'geo_id')
        params['geoId'] = geo_id.to_s if geo_id

        params['origin'] = 'JOB_SEARCH_PAGE_JOB_FILTER'
        params['refresh'] = 'true'

        "#{JOBS_URL}?#{URI.encode_www_form(params)}"
      end

      def build_boolean_query
        skill = resolve_primary_skill
        return '' unless skill

        query = "\"#{display_name(skill)}\""

        if @config.dig('search', 'include_remote')
          query += ' AND ("remote" OR "remoto")'
        end

        query
      end

      def resolve_primary_skill
        @profile&.primary_skill
      end

      def display_name(skill)
        SKILL_DISPLAY_NAMES[skill] || skill.tr('_', ' ').split.map(&:capitalize).join(' ')
      end

      def extract_job_cards
        # Scroll to load all job cards
        scroll_job_list

        # Try primary selector, then fallback
        items = find_job_items
        Log.debug("Found #{items.size} job list items")

        items.filter_map do |item|
          extract_card_data(item)
        rescue StandardError => e
          Log.debug("Error extracting job card: #{e.message}")
          nil
        end
      end

      def find_job_items
        # Primary: li with data-occludable-job-id (most reliable, 2026)
        items = wait_for_elements(@driver, :css, Selectors::JOB_LIST_ITEMS, timeout: 10)
        return items if items.any?

        # Fallback: scaffold list items
        items = safe_find_all(@driver, :css, Selectors::JOB_LIST_ITEMS_ALT)
        return items if items.any?

        # Last resort: any element with data-job-id
        safe_find_all(@driver, :css, Selectors::JOB_DATA_ID)
      end

      def scroll_job_list
        3.times do
          @driver.execute_script(<<~JS)
            const list = document.querySelector('.scaffold-layout__list');
            if (list) list.scrollTop = list.scrollHeight;
          JS
          sleep(1)
        end
      end

      def extract_card_data(item)
        # Extract job ID from the item or its link
        job_id = item.attribute('data-occludable-job-id')
        job_id ||= extract_job_id_from_element(item)
        return nil unless job_id

        link = begin
          item.find_element(:css, 'a')
        rescue Selenium::WebDriver::Error::NoSuchElementError
          nil
        end
        href = link&.attribute('href')

        title_el = begin
          item.find_element(:css, Selectors::JOB_CARD_TITLE)
        rescue Selenium::WebDriver::Error::NoSuchElementError
          nil
        end

        company_el = begin
          item.find_element(:css, Selectors::JOB_CARD_COMPANY)
        rescue Selenium::WebDriver::Error::NoSuchElementError
          nil
        end

        title = title_el&.text&.strip
        company = company_el&.text&.strip

        # Skip empty cards (not yet loaded/occluded)
        return nil if title.nil? || title.empty?

        {
          id: job_id,
          title: title,
          company: company,
          url: href || "https://www.linkedin.com/jobs/view/#{job_id}/"
        }
      end

      def extract_job_id_from_element(item)
        # Try data-job-id on child elements
        el = begin
          item.find_element(:css, '[data-job-id]')
        rescue Selenium::WebDriver::Error::NoSuchElementError
          nil
        end
        return el.attribute('data-job-id') if el

        # Try extracting from link href
        link = begin
          item.find_element(:css, 'a')
        rescue Selenium::WebDriver::Error::NoSuchElementError
          nil
        end
        return nil unless link

        href = link.attribute('href')
        extract_job_id_from_url(href) if href
      end

      def extract_job_id_from_url(url)
        match = url.match(/currentJobId=(\d+)/) || url.match(/\/view\/(\d+)/)
        match&.[](1)
      end

      def next_page?
        btn = safe_find(@driver, :css, Selectors::PAGINATION_NEXT)
        btn&.enabled? && btn&.displayed?
      end

      def click_next_page
        wait_and_click(@driver, :css, Selectors::PAGINATION_NEXT, config: @config, timeout: 5)
        sleep(2)
      end
    end
  end
end
