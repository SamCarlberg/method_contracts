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
      
      class HashStructureMatcher < MethodContracts::Matchers::Base
        def initialize(key_contract, value_contract)
          @key_matcher = MethodContracts.contract_to_matcher(key_contract)
          @value_matcher = MethodContracts.contract_to_matcher(value_contract)
        end

        def match?(hash)
          return false unless hash.is_a? Hash

          hash.all? do |(key, value)|
            @key_matcher.match?(key) && @value_matcher.match?(value)
          end
        end

        def to_s
          "a hash with keys matching #{@key_matcher} and values matching #{@value_matcher}"
        end
      end
    end
  end
end
