# frozen_string_literal: true

module MethodContracts
  module Matchers
    module Structure
      module Mixin
        # Shorthand for MethodContracts::Matchers::Structure::ArrayStructureMatcher.new(element_contract)
        def ArrayOf(element_contract)
          ArrayStructureMatcher.new(element_contract)
        end

        # Shorthand for MethodContracts::Matchers::Structure::HashStructureMatcher.new(key_contract, value_contract)
        def HashOf(key_contract, value_contract)
          HashStructureMatcher.new(key_contract, value_contract)
        end
      end
    end
  end
end

Module.include MethodContracts::Matchers::Structure::Mixin
