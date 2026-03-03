# frozen_string_literal: true

require 'uri'
require 'cgi'

module EasyApply
  module LinkedIn
    class JobSearch
      include Browser::WaitHelpers

      JOBS_URL = 'https://www.linkedin.com/jobs/search/'
      MAX_PAGES = 10

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
        params = {
          'keywords' => @config.dig('search', 'keywords'),
          'location' => @config.dig('search', 'location'),
          'f_AL' => 'true' # Easy Apply filter
        }

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
