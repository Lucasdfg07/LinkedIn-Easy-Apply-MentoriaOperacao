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

      def initialize(driver, config)
        @driver = driver
        @config = config
      end

      def search
        url = build_search_url
        Log.info("Searching jobs: #{url}")

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

      private

      def build_search_url
        params = { 'keywords' => @config.dig('search', 'keywords') }

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

      def extract_job_cards
        wait_for_elements(@driver, :css, Selectors::JOB_LIST_ITEMS, timeout: 15)
        items = safe_find_all(@driver, :css, Selectors::JOB_LIST_ITEMS)

        items.filter_map do |item|
          extract_card_data(item)
        rescue StandardError => e
          Log.debug("Error extracting job card: #{e.message}")
          nil
        end
      end

      def extract_card_data(item)
        link = item.find_element(:css, 'a')
        href = link&.attribute('href')
        return nil unless href

        job_id = extract_job_id(href)
        return nil unless job_id

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

        {
          id: job_id,
          title: title_el&.text&.strip,
          company: company_el&.text&.strip,
          url: href
        }
      end

      def extract_job_id(url)
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
