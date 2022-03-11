# frozen_string_literal: true

module TypeContracts
  class Param
    NO_CONTRACT = Object.new.freeze

    module Mixin
      # Defines a contract for a single parameter on the next method that gets defined.
      #
      # @param param_name [Symbol]
      #   the name of the parameter the contract is applied to
      # @param contract
      #   the contract for the parameter.  This could be a specific value (eg '1'),
      #   a class (eg String), an array of possible values or matches (eg [String, Symbol]),
      #   or a matcher that that has a no-arg constructor.  This can also be excluded and
      #   a block provided instead; the block accepts the return value of the method and must
      #   return a boolean value
      def param(param_name, contract = NO_CONTRACT, &block)
        contract = TypeContracts::Param.new(param_name, contract, &block)

        @__type_contracts__last_annotation ||= {}
        @__type_contracts__last_annotation[:params] ||= []
        @__type_contracts__last_annotation[:params] << contract
      end
    end

    attr_reader :param_name, :contract

    def initialize(param_name, contract, &block)
      raise 'Parameter name is required' if param_name.nil? || param_name.empty?
      raise 'Contract and block are mutually exclusive' if block && contract != NO_CONTRACT
      raise 'Either a contract or block is required' if block.nil? && contract == NO_CONTRACT

      @param_name = param_name.to_sym
      @contract = block || contract

      @matcher = TypeContracts.contract_to_matcher(@contract)
    end

    def check_contract!(clazz, method_name, value)
      unless @matcher.match?(value)
        raise TypeContracts::BrokenParamContractError.new(clazz.name, method_name, @param_name, @matcher, value)
      end
    end
  end
end

Module.include TypeContracts::Param::Mixin
