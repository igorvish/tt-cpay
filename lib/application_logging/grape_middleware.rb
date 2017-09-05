module ApplicationLogging
  class GrapeMiddleware < Grape::Middleware::Base

    def call(env)
      ActiveSupport::Notifications.instrument "request.grape_middleware" do |payload|
        @app.call(env).tap do |response|
          payload[:env] = env
          payload[:response] = response
        end
      end
    end

  end
end
