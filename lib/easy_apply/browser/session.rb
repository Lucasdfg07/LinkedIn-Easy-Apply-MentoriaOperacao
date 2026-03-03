# frozen_string_literal: true

module EasyApply
  module Browser
    class Session
      include WaitHelpers

      LINKEDIN_URL = 'https://www.linkedin.com'
      FEED_URL = "#{LINKEDIN_URL}/feed"
      LOGIN_URL = "#{LINKEDIN_URL}/login"

      attr_reader :driver

      def initialize(driver, config)
        @driver = driver
        @config = config
      end

      def login_with_cookie!
        li_at = @config.dig('linkedin', 'li_at')
        raise SessionError, 'li_at cookie not configured' if li_at.nil? || li_at.strip.empty?

        Log.info('Injecting li_at cookie...')
        @driver.navigate.to(LINKEDIN_URL)
        AntiDetection.action_delay(@config)

        @driver.manage.add_cookie(
          name: 'li_at',
          value: li_at,
          domain: '.linkedin.com',
          path: '/',
          secure: true
        )

        @driver.navigate.to(FEED_URL)
        AntiDetection.action_delay(@config)

        verify_session!
        Log.info('LinkedIn session established')
      end

      def active?
        @driver.navigate.to(FEED_URL)
        sleep(2)
        !@driver.current_url.include?('/login')
      rescue StandardError
        false
      end

      def quit
        @driver&.quit
        Log.info('Browser session closed')
      rescue StandardError => e
        Log.warn("Error closing browser: #{e.message}")
      end

      private

      def verify_session!
        sleep(3)
        current = @driver.current_url

        if current.include?('/login') || current.include?('/authwall')
          raise SessionError, 'LinkedIn session invalid. Check your li_at cookie.'
        end

        nav = safe_find(@driver, :css, '.global-nav')
        raise SessionError, 'Could not verify LinkedIn session (nav not found)' unless nav

        true
      end
    end
  end
end
