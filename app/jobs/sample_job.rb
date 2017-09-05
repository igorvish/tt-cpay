class SampleJob < ApplicationJob

  def perform(*args)
    Rails.logger.info('New document created', entity_id: '...', email: '...')
  end

end
