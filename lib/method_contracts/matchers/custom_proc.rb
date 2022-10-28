# frozen_string_literal: true

module MethodContracts
  module Matchers
    class CustomProc < Base
      def initialize(proc)
        @proc = proc
      end

      def match?(value)
        @proc.call(value)
      end

      def to_s
        '<custom matcher>'
      end
    end
  end
end
