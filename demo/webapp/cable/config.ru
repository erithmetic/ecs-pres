require ::File.expand_path('../../config/environment',  __FILE__)
Rails.application.eager_load!

ActionCable.server.config.allowed_request_origins = %w{http://awesomedemo.click}

run ActionCable.server
