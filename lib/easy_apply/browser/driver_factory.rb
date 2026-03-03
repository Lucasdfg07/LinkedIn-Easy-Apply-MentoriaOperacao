# frozen_string_literal: true

require 'selenium-webdriver'

module EasyApply
  module Browser
    class DriverFactory
      ANTI_DETECTION_FLAGS = [
        '--disable-blink-features=AutomationControlled',
        '--disable-infobars',
        '--disable-extensions',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-popup-blocking'
      ].freeze

      CDP_SCRIPTS = [
        "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})",
        "Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en', 'pt-BR']})",
        "Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]})"
      ].freeze

      def self.create(config)
        new(config).build
      end

      def initialize(config)
        @config = config
      end

      def build
        options = Selenium::WebDriver::Chrome::Options.new
        configure_flags(options)
        configure_window_size(options)
        configure_headless(options) if @config.dig('browser', 'headless')

        driver = Selenium::WebDriver.for(:chrome, options: options)
        inject_anti_detection(driver)

        Log.info('Browser driver created', headless: @config.dig('browser', 'headless'))
        driver
      end

      private

      def configure_flags(options)
        ANTI_DETECTION_FLAGS.each { |flag| options.add_argument(flag) }
        options.add_argument('--disable-dev-shm-usage')
        options.add_argument('--lang=en-US')
      end

      def configure_window_size(options)
        width, height = AntiDetection.random_window_size(@config)
        options.add_argument("--window-size=#{width},#{height}")
        Log.debug("Window size: #{width}x#{height}")
      end

      def configure_headless(options)
        options.add_argument('--headless=new')
      end

      def inject_anti_detection(driver)
        CDP_SCRIPTS.each do |script|
          driver.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: script)
        end
      rescue StandardError => e
        Log.warn("CDP injection failed (non-critical): #{e.message}")
      end
    end
  end
end
