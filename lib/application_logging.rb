require_relative 'application_logging/logging'
require_relative 'application_logging/formatting'

module ApplicationLogging

  def self.mix_to(target_logger)
    target_logger.tap do |l|
      l.extend(ActiveSupport::TaggedLogging) unless l.respond_to?(:tagged)
      l.extend(ApplicationLogging::Logging)
    end

    target_logger.formatter ||= Class.new.new
    target_logger.formatter.tap do |f|
      f.extend(ActiveSupport::TaggedLogging::Formatter) unless f.respond_to?(:tagged)
      f.extend(ApplicationLogging::Formatting)
    end

    target_logger
  end

end

require_relative 'application_logging/railtie' if defined?(Rails)
