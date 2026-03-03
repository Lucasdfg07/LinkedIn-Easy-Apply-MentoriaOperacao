# frozen_string_literal: true

require 'selenium-webdriver'

module EasyApply
  module Browser
    module WaitHelpers
      DEFAULT_TIMEOUT = 10
      POLL_INTERVAL = 0.5

      def wait_for_element(driver, by, selector, timeout: DEFAULT_TIMEOUT)
        wait = Selenium::WebDriver::Wait.new(timeout: timeout)
        wait.until { driver.find_element(by, selector) }
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
      end

      def wait_for_elements(driver, by, selector, timeout: DEFAULT_TIMEOUT)
        wait = Selenium::WebDriver::Wait.new(timeout: timeout)
        wait.until do
          elements = driver.find_elements(by, selector)
          elements.any? ? elements : nil
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        []
      end

      def wait_for_clickable(driver, by, selector, timeout: DEFAULT_TIMEOUT)
        wait = Selenium::WebDriver::Wait.new(timeout: timeout)
        wait.until do
          el = driver.find_element(by, selector)
          el.displayed? && el.enabled? ? el : nil
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
      end

      def wait_and_click(driver, by, selector, config:, timeout: DEFAULT_TIMEOUT)
        el = wait_for_clickable(driver, by, selector, timeout: timeout)
        return false unless el

        AntiDetection.action_delay(config)
        el.click
        true
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError
        driver.execute_script('arguments[0].click()', el)
        true
      end

      def scroll_to_element(driver, element)
        driver.execute_script('arguments[0].scrollIntoView({block: "center"})', element)
        sleep(0.5)
      end

      def scroll_page_down(driver)
        driver.execute_script('window.scrollBy(0, window.innerHeight * 0.8)')
        sleep(1)
      end

      def safe_find(driver, by, selector)
        driver.find_element(by, selector)
      rescue Selenium::WebDriver::Error::NoSuchElementError
        nil
      end

      def safe_find_all(driver, by, selector)
        driver.find_elements(by, selector)
      rescue Selenium::WebDriver::Error::NoSuchElementError
        []
      end

      def element_text(driver, by, selector)
        el = safe_find(driver, by, selector)
        el&.text&.strip
      end
    end
  end
end
