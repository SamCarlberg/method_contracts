# frozen_string_literal: true

module MethodContracts
  module Matchers
    class MatchAny < Base
      def initialize(array)
        @matchers = array.map(&MethodContracts.method(:contract_to_matcher))
      end

      def match?(value)
        @matchers.any? do |e|
          e.match?(value)
        end
      end

      def to_s
        "<any of: #{@matchers.map(&:to_s).join(', ')}>"
      end
    end
  end
end
