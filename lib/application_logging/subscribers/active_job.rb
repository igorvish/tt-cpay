module ApplicationLogging
  module Subscribers
    # Наследуемся т.к. нам нужны методы:
    # - queue_name
    # - format
    # - scheduled_at
    class ActiveJob < ActiveJob::Logging::LogSubscriber
      def enqueue(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          job = event.payload[:job]
          collect_data(event).merge(
            msg: "Enqueued #{job.class.name} (Job ID: #{job.job_id}) to #{queue_name(event)}"
          )
        end
      end

      def enqueue_at(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          job = event.payload[:job]
          collect_data(event).merge(
            msg: "Enqueued #{job.class.name} (Job ID: #{job.job_id}) to #{queue_name(event)} at #{scheduled_at(event)}"
          )
        end
      end

      def perform_start(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          job = event.payload[:job]
          collect_data(event).merge(
            msg: "Performing #{job.class.name} (Job ID: #{job.job_id}) from #{queue_name(event)}" 
          )
        end
      end

      def perform(event)
        severity = event.payload[:exception] ? ::Logger::ERROR : ::Logger::INFO

        logger.add(severity) do 
          job = event.payload[:job]
          msg = if event.payload[:exception_object]
            "Error performing #{job.class.name} (Job ID: #{job.job_id}) from #{queue_name(event)}"
          else
            "Performed #{job.class.name} (Job ID: #{job.job_id}) from #{queue_name(event)}"
          end
          collect_data(event).merge(
            msg: msg 
          )
        end
      end

      private

      def collect_data(event)
        {
          event:      event.name,
          payload:    { 
            job_id:     event.payload[:job].job_id,
            name:       event.payload[:job].class.name,
            queue:      queue_name(event),
            args:       args_info(event.payload[:job]),
            priority:   event.payload[:job].priority,
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

      # private
      #   def queue_name(event)
      #     event.payload[:adapter].class.name.demodulize.remove("Adapter") + "(#{event.payload[:job].queue_name})"
      #   end

        def args_info(job)
          if job.arguments.any?
            job.arguments.map { |arg| format(arg) }
          else
            []
          end
        end

      #   def format(arg)
      #     case arg
      #     when Hash
      #       arg.transform_values { |value| format(value) }
      #     when Array
      #       arg.map { |value| format(value) }
      #     when GlobalID::Identification
      #       arg.to_global_id rescue arg
      #     else
      #       arg
      #     end
      #   end

      #   def scheduled_at(event)
      #     Time.at(event.payload[:job].scheduled_at).utc
      #   end

      #   def logger
      #     ActiveJob::Base.logger
      #   end
    end
  end
end
