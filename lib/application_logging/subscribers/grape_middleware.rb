module ApplicationLogging
  module Subscribers
    class GrapeMiddleware < ::ActiveSupport::LogSubscriber

      def request(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          collect_data(event).merge(
            msg: "Processing by #{event.payload[:env]['api.endpoint'].options[:for]}"
          )
        end
      end

      private

      def collect_data(event)
        {
          event:            event.name,
          duration:         event.duration,
          request_method:   event.payload[:env]['REQUEST_METHOD'],
          request_url:      event.payload[:env]['REQUEST_PATH'],
          response_status:  Rack::Utils::HTTP_STATUS_CODES[event.payload[:response].status],
          caller:           event.payload[:env]['api.endpoint'].source.to_s,
          payload:          {
            headers: event.payload[:env].select{ |k, v| k =~ /\AHTTP_/ }.to_h,
            params: event.payload[:env]['api.endpoint'].params,
          }
        }.merge extract_exception(event)
      end

      def extract_exception(event)
        if event.payload[:exception]
          {
            error_code:         ActionDispatch::ExceptionWrapper.status_code_for_exception(event.payload[:exception_object]),
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
