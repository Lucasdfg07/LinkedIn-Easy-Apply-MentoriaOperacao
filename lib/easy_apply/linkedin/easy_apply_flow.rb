# frozen_string_literal: true

module EasyApply
  module LinkedIn
    class EasyApplyFlow
      include Browser::WaitHelpers

      MAX_STEPS = 8

      def initialize(driver, config, profile)
        @driver = driver
        @config = config
        @profile = profile
      end

      def apply!(job)
        Log.info("Starting Easy Apply for: #{job[:title]} at #{job[:company]}")

        unless click_easy_apply_button
          Log.warn('Could not find Easy Apply button')
          return { success: false, reason: 'no_easy_apply_button' }
        end

        unless wait_for_modal
          Log.warn('Easy Apply modal did not open')
          return { success: false, reason: 'modal_not_opened' }
        end

        step = 0
        loop do
          step += 1
          if step > MAX_STEPS
            Log.warn("Max steps (#{MAX_STEPS}) reached, aborting")
            dismiss_modal
            return { success: false, reason: 'max_steps_exceeded' }
          end

          AntiDetection.action_delay(@config)
          fill_visible_fields

          if submit_button_visible?
            return do_submit(job)
          elsif review_button_visible?
            click_review
          elsif next_button_visible?
            click_next
          else
            Log.warn("No navigation button found at step #{step}")
            dismiss_modal
            return { success: false, reason: 'navigation_stuck' }
          end

          AntiDetection.action_delay(@config)
        end
      end

      private

      def click_easy_apply_button
        btn = wait_for_clickable(@driver, :css, Selectors::EASY_APPLY_BUTTON, timeout: 5)
        return false unless btn

        text = btn.text.downcase
        return false unless text.include?('easy apply') || text.include?('candidatura simplificada')

        btn.click
        true
      end

      def wait_for_modal
        wait_for_element(@driver, :css, Selectors::EASY_APPLY_MODAL, timeout: 10)
      end

      def fill_visible_fields
        fill_text_inputs
        fill_selects
        fill_textareas
        fill_checkboxes
      end

      def fill_text_inputs
        inputs = safe_find_all(@driver, :css, "#{Selectors::EASY_APPLY_MODAL} #{Selectors::FORM_INPUT}")
        inputs.each { |input| fill_input(input) }
      end

      def fill_input(input)
        return if input.attribute('value').to_s.strip.length > 0
        return unless input.displayed?

        label_text = find_label_for(input)
        value = resolve_value(label_text, input)

        return unless value

        input.clear
        AntiDetection.human_type(input, value.to_s,
                                 min_ms: @config.dig('delays', 'typing_delay_min_ms') || 50,
                                 max_ms: @config.dig('delays', 'typing_delay_max_ms') || 200)
        Log.debug("Filled input '#{label_text}' with '#{value}'")
      rescue StandardError => e
        Log.debug("Could not fill input: #{e.message}")
      end

      def fill_selects
        selects = safe_find_all(@driver, :css, "#{Selectors::EASY_APPLY_MODAL} #{Selectors::FORM_SELECT}")
        selects.each do |select|
          next unless select.displayed?

          label_text = find_label_for(select)
          value = resolve_value(label_text, select)

          if value
            select_option_by_text(select, value)
          else
            select_first_non_empty(select)
          end
        rescue StandardError => e
          Log.debug("Could not fill select: #{e.message}")
        end
      end

      def fill_textareas
        textareas = safe_find_all(@driver, :css, "#{Selectors::EASY_APPLY_MODAL} #{Selectors::FORM_TEXTAREA}")
        textareas.each do |ta|
          next unless ta.displayed?
          next if ta.attribute('value').to_s.strip.length > 0

          label_text = find_label_for(ta)
          value = resolve_value(label_text, ta)
          next unless value

          ta.clear
          AntiDetection.human_type(ta, value.to_s,
                                   min_ms: @config.dig('delays', 'typing_delay_min_ms') || 50,
                                   max_ms: @config.dig('delays', 'typing_delay_max_ms') || 200)
        rescue StandardError => e
          Log.debug("Could not fill textarea: #{e.message}")
        end
      end

      def fill_checkboxes
        checkboxes = safe_find_all(@driver, :css, "#{Selectors::EASY_APPLY_MODAL} #{Selectors::FORM_CHECKBOX}")
        checkboxes.each do |cb|
          next unless cb.displayed?
          next if cb.selected?

          label_text = find_label_for(cb)
          if label_text&.downcase&.match?(/follow|terms|agree|acknowledge/)
            cb.click
            Log.debug("Checked: #{label_text}")
          end
        rescue StandardError => e
          Log.debug("Could not click checkbox: #{e.message}")
        end
      end

      def find_label_for(element)
        id = element.attribute('id')
        if id && !id.empty?
          label = safe_find(@driver, :css, "label[for='#{id}']")
          return label.text.strip if label
        end

        parent = element.find_element(:xpath, './ancestor::div[contains(@class, "grouping") or contains(@class, "section")]')
        label = begin
          parent.find_element(:css, 'label, legend, span.t-14')
        rescue Selenium::WebDriver::Error::NoSuchElementError
          nil
        end
        label&.text&.strip || ''
      rescue StandardError
        ''
      end

      def resolve_value(label_text, _element)
        return nil if label_text.nil? || label_text.empty?

        label_lower = label_text.downcase

        # Direct profile field mappings
        direct = direct_mappings.find { |pattern, _| label_lower.match?(pattern) }
        return direct[1] if direct

        # Check easy_apply_answers
        @profile.easy_apply_answers.each do |key, val|
          return val if label_lower.include?(key.downcase)
        end

        Log.warn("Unknown field: '#{label_text}' - skipping")
        nil
      end

      def direct_mappings
        [
          [/first\s*name|nome/i, @profile.first_name],
          [/last\s*name|sobrenome/i, @profile.last_name],
          [/email/i, @profile.email],
          [/phone|telefone|mobile|celular/i, @profile.phone],
          [/city|cidade/i, @profile.city],
          [/current\s*title|cargo\s*atual|headline/i, @profile.current_title],
        ]
      end

      def select_option_by_text(select_el, text)
        options = select_el.find_elements(:tag_name, 'option')
        match = options.find { |o| o.text.strip.downcase.include?(text.to_s.downcase) }
        match ||= options.find { |o| o.text.strip.downcase == 'yes' } if text.to_s.downcase == 'yes'

        if match
          match.click
          Log.debug("Selected option: '#{match.text.strip}'")
        end
      end

      def select_first_non_empty(select_el)
        options = select_el.find_elements(:tag_name, 'option')
        non_empty = options.reject { |o| o.text.strip.empty? || o.attribute('value').to_s.strip.empty? }
        non_empty.first&.click if non_empty.any? && !select_el.find_elements(:css, 'option[selected]').any?
      end

      def submit_button_visible?
        btn = safe_find(@driver, :css, Selectors::MODAL_SUBMIT)
        btn&.displayed? && btn&.enabled?
      end

      def review_button_visible?
        btn = safe_find(@driver, :css, Selectors::MODAL_REVIEW)
        btn&.displayed? && btn&.enabled?
      end

      def next_button_visible?
        btn = safe_find(@driver, :css, Selectors::MODAL_NEXT)
        btn&.displayed? && btn&.enabled?
      end

      def click_next
        wait_and_click(@driver, :css, Selectors::MODAL_NEXT, config: @config)
      end

      def click_review
        wait_and_click(@driver, :css, Selectors::MODAL_REVIEW, config: @config)
      end

      def do_submit(job)
        btn = wait_for_clickable(@driver, :css, Selectors::MODAL_SUBMIT, timeout: 5)
        unless btn
          dismiss_modal
          return { success: false, reason: 'submit_button_not_found' }
        end

        btn.click
        AntiDetection.action_delay(@config)

        if verify_success
          Log.info("Application submitted: #{job[:title]} at #{job[:company]}")
          dismiss_post_apply
          { success: true, reason: 'submitted' }
        else
          Log.warn("Could not confirm submission for: #{job[:title]}")
          dismiss_modal
          { success: false, reason: 'submission_unconfirmed' }
        end
      end

      def verify_success
        success = safe_find(@driver, :css, Selectors::APPLICATION_SENT)
        return true if success

        sleep(2)
        safe_find(@driver, :css, Selectors::APPLICATION_SENT) != nil
      end

      def dismiss_post_apply
        close = safe_find(@driver, :css, Selectors::MODAL_CLOSE)
        close&.click
      rescue StandardError
        nil
      end

      def dismiss_modal
        close = safe_find(@driver, :css, Selectors::MODAL_CLOSE)
        if close&.displayed?
          close.click
          sleep(1)
          discard = safe_find(@driver, :css, Selectors::MODAL_DISCARD)
          discard&.click if discard&.displayed?
        end
      rescue StandardError
        nil
      end
    end
  end
end
