# Configure Blazer
Rails.application.config.after_initialize do
  if defined?(Blazer)
    Blazer.from_email = "noreply@example.com"
  end
end
