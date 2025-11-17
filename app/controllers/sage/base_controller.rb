module Sage
  class BaseController < Blazer::BaseController
    # Support both Pagy 9.x (Backend) and Pagy 43.x (Method)
    if defined?(Pagy::Backend)
      include Pagy::Backend # Pagy 9.x
    elsif defined?(Pagy::Method)
      include Pagy::Method # Pagy 43.x
    else
      raise "Pagy must be loaded before Sage::BaseController"
    end

    layout "sage/application"
    helper Importmap::ImportmapTagsHelper
    helper Ransack::Helpers::FormHelper
    helper Sage::ApplicationHelper
  end
end
