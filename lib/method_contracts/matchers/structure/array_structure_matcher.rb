# frozen_string_literal: true

module MethodContracts
  module Matchers
    module Structure
      class ArrayStructureMatcher < MethodContracts::Matchers::Base
        def initialize(element_contract)
          @element_matcher = MethodContracts.contract_to_matcher(element_contract)
        end

        def match?(array)
          return false unless array.is_a? Array

          array.all?(&@element_matcher.method(:match?))
        end

        def to_s
          "an array of elements matching #{@element_matcher}"
        end
      end
    end
  end
end
