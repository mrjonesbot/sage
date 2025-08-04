module Sage
  class BaseController < Blazer::BaseController
    include Pagy::Backend

    layout "sage/application"
    helper Importmap::ImportmapTagsHelper
    helper Sage::ApplicationHelper
  end
end
