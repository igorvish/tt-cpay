module ApplicationLogging
  module Subscribers
    class SidekiqJobLogger < ::ActiveSupport::LogSubscriber

      def dispatch(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          collect_data(event).merge(
            msg: event.payload[:exception] ? "fail: #{event.duration} ms" : "done: #{event.duration} ms"
          )
        end
      end

      private

      def collect_data(event)
        {
          event:    event.name,
          duration: event.duration,
          payload:  event.payload,
        }.merge(extract_exception(event))
      end

      def extract_exception(event)
        if event.payload[:exception]
          {
            error_message:      event.payload[:exception].join(': '),
            error_backtrace:    event.payload[:exception_object].backtrace,
          }
        else
          {}
        end
      end

    end
  end
end
