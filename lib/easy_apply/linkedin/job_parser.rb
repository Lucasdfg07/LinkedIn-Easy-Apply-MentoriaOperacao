# frozen_string_literal: true

module EasyApply
  module LinkedIn
    class JobParser
      include Browser::WaitHelpers

      def initialize(driver, config)
        @driver = driver
        @config = config
      end

      def parse(job_card)
        click_job(job_card)
        AntiDetection.action_delay(@config)
        wait_for_element(@driver, :css, Selectors::JOB_DESCRIPTION, timeout: 10)

        {
          id: job_card[:id],
          title: read_title || job_card[:title],
          company: read_company || job_card[:company],
          location: read_location,
          description: read_description,
          criteria: read_criteria,
          has_easy_apply: has_easy_apply?,
          url: job_card[:url]
        }
      end

      private

      def click_job(job_card)
        link = safe_find(@driver, :css, "a[href*='#{job_card[:id]}']")
        if link
          scroll_to_element(@driver, link)
          link.click
        else
          @driver.navigate.to(job_card[:url])
        end
      end

      def read_title
        element_text(@driver, :css, Selectors::JOB_TITLE)
      end

      def read_company
        element_text(@driver, :css, Selectors::JOB_COMPANY)
      end

      def read_location
        element_text(@driver, :css, Selectors::JOB_LOCATION_DETAIL)
      end

      def read_description
        el = safe_find(@driver, :css, Selectors::JOB_DESCRIPTION_TEXT)
        return '' unless el

        # Get full text including hidden content
        @driver.execute_script('arguments[0].style.maxHeight = "none"', el) rescue nil
        el.text.strip
      end

      def read_criteria
        elements = safe_find_all(@driver, :css, Selectors::JOB_CRITERIA)
        elements.map { |el| el.text.strip }.reject(&:empty?)
      end

      def has_easy_apply?
        btn = safe_find(@driver, :css, Selectors::EASY_APPLY_BUTTON)
        return false unless btn

        text = btn.text.downcase
        text.include?('easy apply') || text.include?('candidatura simplificada')
      end
    end
  end
end
