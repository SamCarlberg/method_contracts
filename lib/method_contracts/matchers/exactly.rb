# frozen_string_literal: true

module MethodContracts
  module Matchers
    class Exactly < Base
      def initialize(value)
        @value = value
      end

      def match?(value)
        @value == value
      end

      def to_s
        "equal #{@value.inspect}"
      end
    end
  end
end
