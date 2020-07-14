# frozen_string_literal: true

module Validate
  module Helpers
    module_function

    def camelize(name)
      name.to_s.split('_').collect(&:capitalize).join
    end
  end
end
