# frozen_string_literal: true

module MethodContracts
  class Return
    NO_CONTRACT = Object.new.freeze

    module Mixin
      # Defines a contract for a return value for the next method that gets defined.
      # Only one `returns` contract can be defined for any particular method
      #
      # @param contract
      #   the contract for the return value.  This could be a specific value (eg '1'),
      #   a class (eg String), an array of possible values or matches (eg [String, Symbol]),
      #   or a matcher that that has a no-arg constructor.  This can also be excluded and
      #   a block provided instead; the block accepts the return value of the method and must
      #   return a boolean value
      def returns(contract = NO_CONTRACT, &block)
        contract = MethodContracts::Return.new(contract, &block)

        @__method_contracts__last_annotation ||= {}
        raise 'A contract already exists for the return value' if @__method_contracts__last_annotation[:return]

        @__method_contracts__last_annotation[:return] = contract
      end

      def returns_a(value)
        returns(value)
      end

      alias returns_an returns_a
    end

    attr_reader :contract

    def initialize(contract, &block)
      raise 'Contract and block are mutually exclusive' if block && contract != NO_CONTRACT
      raise 'Contract or block is required' if block.nil? && contract == NO_CONTRACT

      @contract = block || contract
      @matcher = MethodContracts.contract_to_matcher(@contract)
    end

    def check_contract!(clazz, method_name, value)
      unless @matcher.match?(value)
        raise MethodContracts::BrokenReturnValueContractError.new(clazz.name, method_name, @matcher, value)
      end
    end
  end
end
