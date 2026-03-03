# frozen_string_literal: true

require 'logger'
require 'json'
require 'fileutils'

module EasyApply
  module Log
    def self.setup(log_dir: 'log')
      FileUtils.mkdir_p(log_dir)

      file_logger = ::Logger.new(
        File.join(log_dir, 'easy_apply.log'),
        'daily',
        formatter: method(:json_formatter)
      )

      console_logger = ::Logger.new($stdout, formatter: method(:console_formatter))

      @logger = MultiLogger.new(file_logger, console_logger)
    end

    def self.logger
      @logger || setup
    end

    def self.info(msg, **ctx)    = logger.info(format_msg(msg, ctx))
    def self.warn(msg, **ctx)    = logger.warn(format_msg(msg, ctx))
    def self.error(msg, **ctx)   = logger.error(format_msg(msg, ctx))
    def self.debug(msg, **ctx)   = logger.debug(format_msg(msg, ctx))

    def self.format_msg(msg, ctx)
      ctx.empty? ? msg : "#{msg} #{ctx.map { |k, v| "#{k}=#{v}" }.join(' ')}"
    end

    def self.json_formatter(severity, time, _progname, msg)
      JSON.generate(
        timestamp: time.iso8601,
        level: severity,
        message: msg
      ) + "\n"
    end

    def self.console_formatter(severity, time, _progname, msg)
      color = case severity
              when 'INFO'  then "\e[32m"
              when 'WARN'  then "\e[33m"
              when 'ERROR' then "\e[31m"
              else "\e[37m"
              end
      "#{color}[#{time.strftime('%H:%M:%S')}] #{severity}\e[0m #{msg}\n"
    end

    class MultiLogger
      def initialize(*loggers)
        @loggers = loggers
      end

      %i[info warn error debug].each do |level|
        define_method(level) do |msg|
          @loggers.each { |l| l.send(level, msg) }
        end
      end
    end
  end
end
