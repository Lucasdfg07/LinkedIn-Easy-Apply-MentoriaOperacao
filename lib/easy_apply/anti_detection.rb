# frozen_string_literal: true

module EasyApply
  module AntiDetection
    module_function

    def random_delay(min, max)
      delay = rand(min.to_f..max.to_f)
      sleep(delay)
      delay
    end

    def human_type(element, text, min_ms: 50, max_ms: 200)
      text.each_char do |char|
        element.send_keys(char)
        sleep(rand(min_ms..max_ms) / 1000.0)
      end
    end

    def random_window_size(config)
      width = rand(config.dig('browser', 'window_width_min')..config.dig('browser', 'window_width_max'))
      height = rand(config.dig('browser', 'window_height_min')..config.dig('browser', 'window_height_max'))
      [width, height]
    end

    def application_break(config)
      min = config.dig('delays', 'between_applications_min')
      max = config.dig('delays', 'between_applications_max')
      random_delay(min, max)
    end

    def long_break(config)
      min = config.dig('polling', 'break_duration_seconds_min')
      max = config.dig('polling', 'break_duration_seconds_max')
      duration = random_delay(min, max)
      Log.info("Taking a break for #{duration.round(0)}s")
      duration
    end

    def action_delay(config)
      min = config.dig('delays', 'between_actions_min')
      max = config.dig('delays', 'between_actions_max')
      random_delay(min, max)
    end
  end
end
