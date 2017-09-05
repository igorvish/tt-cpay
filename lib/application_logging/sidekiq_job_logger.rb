# From sidekiq changelog:
# 
# 5.0.0
# -----------
# 
# - **BREAKING CHANGE** Job dispatch was refactored for safer integration with
#   Rails 5.  The **Logging** and **RetryJobs** server middleware were removed and
#   functionality integrated directly into Sidekiq::Processor.  These aren't
#   commonly used public APIs so this shouldn't impact most users.
#   ```
#   Sidekiq::Middleware::Server::RetryJobs -> Sidekiq::JobRetry
#   Sidekiq::Middleware::Server::Logging -> Sidekiq::JobLogger
#   ```
# 
# И теперь его можно указать в опциях сайдкика так:
# ```
# Sidekiq.configure_server do |config|
#   config.options[:job_logger] = ApplicationLogging::SidekiqJobLogger
# end
# ```
module ApplicationLogging 
  class SidekiqJobLogger # < Sidekiq::JobLogger

    def call(job, queue)
      ActiveSupport::Notifications.instrument('dispatch.sidekiq_job_logger', job: job, queue: queue) do
        yield
      end
    end

  end
end
