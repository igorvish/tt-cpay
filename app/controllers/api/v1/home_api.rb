module API
  module V1
    class HomeApi < Grape::API

      use ApplicationLogging::GrapeMiddleware

      prefix 'api'
      version 'v1', using: :path
      format :json

      resource :home do
        desc 'Return Hello World greeting.'
        get do
          Rails.logger.info('Hello World from Grape action')
          { data: 'Hello World' }
        end
      end

    end
  end
end
