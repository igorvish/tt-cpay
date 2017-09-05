class HomeController < ApplicationController

  def index
    Rails.logger.info('Hello World from HomeController#index')
    SampleJob.perform_later('some', 'args')
    render plain: 'Hello World'
  end

end
