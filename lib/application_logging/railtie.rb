require_relative 'subscribers/action_controller'

module ApplicationLogging
  class Railtie < Rails::Railtie

    module IniHelper
      module_function

      def unsubscribe(component, subscriber)
        events = subscriber.public_methods(false).reject{ |method| method.to_s == 'call' }
        events.each do |event|
          # Чтобы отписать сабскрайбер нам нужно знать объект-лисенер, который
          # создавался при вызове `ActiveSupport::Notifications.subscribe`
          # и который является декоратором над сабскрайбером.
          ::ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{component}").each do |listener|
            if listener.instance_variable_get('@delegate') == subscriber
              ::ActiveSupport::Notifications.unsubscribe listener
            end
          end
        end
      end
    end

    # -------------------------------------------------------------------------

    #
    # Инициализируемся до загрузки config/initializers/*
    #
    initializer :application_logging, before: :load_config_initializers do |app|
      # Подключаем рельсовые сабскрайберы, которые будем отписывать.
      # Дело в том что они подписывают сами себя прямо после объявления класса - 
      # то есть при первом включении. И если они еще не были подключены, то мы их 
      # не увидим и не сможем отписать.
      require 'action_controller/log_subscriber'
      require 'action_view/log_subscriber'
      require 'active_job/logging'
      
      # Отписываем рельсовые сабскрайберы
      ::ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
        case subscriber.class.name
        when 'ActionController::LogSubscriber'
          IniHelper.unsubscribe(:action_controller, subscriber)
        when 'ActionView::LogSubscriber' # он просто не нужен
          IniHelper.unsubscribe(:action_view, subscriber)
        when 'ActiveJob::Logging::LogSubscriber'
          IniHelper.unsubscribe(:active_job, subscriber)
        end
      end

      # Подписываем свои сабскрайберы
      ApplicationLogging::Subscribers::ActionController.attach_to(:action_controller)
      ApplicationLogging::Subscribers::GrapeMiddleware.attach_to(:grape_middleware)
      ApplicationLogging::Subscribers::ActiveJob.attach_to(:active_job)
    end

    # config.after_initialize do |app|
    # end

    #
    # Если делать production-решение, то нужно добавить middleware вместо этого 
    # https://github.com/rails/rails/blob/v5.1.3/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
    # Потому что оно перехватывает исключение и начинает его логировать построчно.
    #

  end
end
