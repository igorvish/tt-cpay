# По умолчанию Sidekiq использует стандартный логер Logger.new(STDOUT) и
# определяет форматер с доп. инфой о потоке: 
# * PID `::Process.pid`
# * TID `Thread.current.object_id.to_s(36)`
# * context `Thread.current[:sidekiq_context]`
#
# Здесь мы клонируем логер приложения и добавляем эту информацию к событию 
# при помощи customize_event.

Sidekiq::Logging.logger = Rails.logger.clone

Sidekiq::Logging.logger.formatter.customize_event = lambda do |event|
  event[:payload] = (event[:payload] || {}).merge(
    pid:      ::Process.pid,
    tid:      Thread.current.object_id.to_s(36),
    context:  Thread.current[:sidekiq_context]
  )
  event
end

# Меняем дефолтный job_logger (former Sidekiq::Middleware::Server::Logging)
Sidekiq.configure_server do |config|
  config.options[:job_logger] = ApplicationLogging::SidekiqJobLogger
end
