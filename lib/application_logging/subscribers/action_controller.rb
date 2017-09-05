module ApplicationLogging
  module Subscribers
    class ActionController < ::ActiveSupport::LogSubscriber

      def process_action(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          collect_data(event).merge(
            msg: "Processing by #{event.payload[:controller]}##{event.payload[:action]} as #{event.payload[:format]}"
          )
        end
      end

      def redirect_to(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          collect_data(event).merge(
            msg: "Redirected to #{event.payload[:location]}"
          )
        end
      end

      private

      def collect_data(event)
        {
          event:            event.name,
          duration:         event.duration,
          request_method:   event.payload[:method],
          request_url:      event.payload[:path],
          response_status:  Rack::Utils::HTTP_STATUS_CODES[event.payload[:status].to_i],
          payload:          event.payload.merge(
                              headers: event.payload[:headers].select{ |k, v| k =~ /\AHTTP_/ }.to_h
                            )
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
