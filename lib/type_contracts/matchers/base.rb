# frozen_string_literal: true

module TypeContracts
  module Matchers
    class Base
      def match?(value)
        raise NotImplementedError
      end

      def to_s
        raise NotImplementedError
      end
    end
  end
end
