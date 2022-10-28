# frozen_string_literal: true

module MethodContracts
  module Matchers
    class RegularExpression < Base
      def initialize(regexp)
        @regexp = regexp
      end

      def match?(string)
        (string.is_a?(String) || string.is_a?(Symbol)) && @regexp.match?(string)
      end

      def to_s
        @regexp.inspect
      end
    end
  end
end
