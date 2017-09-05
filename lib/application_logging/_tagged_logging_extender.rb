#
# UNUSED & DEPRICATED
#
# Расширение для `ActiveSupport::TaggedLogging`, при помощи которого
# предотвращается конвертация сообщения и тегов в строку и они сохраняются
# в хеше.
# В оригинале происходит это - https://github.com/rails/rails/blob/v5.1.2/activesupport/lib/active_support/tagged_logging.rb#L21
#
# Использовать так:
#   ```
#   logger = ApplicationLogging::TaggedLoggingExtender.new(
#     ActiveSupport::TaggedLogging.new(ApplicationLogging::Logger.new(STDOUT))
#   )
#
#   logger.tagged('BCX') { logger.info 'Stuff' }
#   ```
#
module ApplicationLogging::TaggedLoggingExtender
  module Formatter
    # This method is invoked when a log event occurs.
    def call(severity, timestamp, progname, msg)
      case msg
      when String
        msg = { msg: msg, _tags: current_tags }
      when Hash
        msg[:_tags] = current_tags
      when Array
        msg[1][:_tags] = current_tags
      end

      # Грязный хак, чтобы перепрыгнуть через форматер 
      # ActiveSupport::TaggedLogging и вызвать не super(), а super_super().
      #
      # super(severity, timestamp, progname, msg)
      grand_class = self.singleton_class.superclass
      grand_super = grand_class.instance_method(:call)
      grand_super.bind(self).call(severity, timestamp, progname, msg)
    end
  end

  def self.new(logger)
    ActiveSupport::Deprecation.warn('Using of this module is undesired. Include original ActiveSupport::TaggedLogging in your classes instead.')

    # Ensure we set a default formatter so we aren't extending nil!
    logger.formatter ||= ::ApplicationLogging::Formatter.new
    logger.formatter.extend Formatter
    logger
  end
end
