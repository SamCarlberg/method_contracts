# frozen_string_literal: true

module TypeContracts
  module Matchers
    module Structure
      module Mixin
        # Shorthand for TypeContracts::Matchers::Structure::ArrayStructureMatcher.new(element_contract)
        def ArrayOf(element_contract)
          ArrayStructureMatcher.new(element_contract)
        end

        # Shorthand for TypeContracts::Matchers::Structure::HashStructureMatcher.new(key_contract, value_contract)
        def HashOf(key_contract, value_contract)
          HashStructureMatcher.new(key_contract, value_contract)
        end
      end
    end
  end
end

Module.include TypeContracts::Matchers::Structure::Mixin
