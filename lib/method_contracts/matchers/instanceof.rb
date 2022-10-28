# frozen_string_literal: true

module MethodContracts
  module Matchers
    class Instanceof < Base
      def initialize(mod)
        @module = mod
      end

      def match?(value)
        value.is_a?(@module)
      end

      def to_s
        "be a #{@module.name}"
      end
    end
  end
end
