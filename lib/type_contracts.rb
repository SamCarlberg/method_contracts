# frozen_string_literal: true

require_relative 'type_contracts/annotations'
require_relative 'type_contracts/config'
require_relative 'type_contracts/overrides'
require_relative 'type_contracts/param'
require_relative 'type_contracts/return'
require_relative 'type_contracts/t'
require_relative 'type_contracts/version'
require_relative 'type_contracts/matchers/base'
require_relative 'type_contracts/matchers/custom_proc'
require_relative 'type_contracts/matchers/exactly'
require_relative 'type_contracts/matchers/instanceof'
require_relative 'type_contracts/matchers/match_any'
require_relative 'type_contracts/matchers/regular_expression'
require_relative 'type_contracts/matchers/structure'
require_relative 'type_contracts/matchers/structure/array_structure_matcher'
require_relative 'type_contracts/matchers/structure/hash_structure_matcher'

module TypeContracts
  class Error < StandardError; end

  class BrokenParamContractError < Error
    def initialize(class_name, method_name, param_name, matcher, actual_value)
      super("#{class_name}##{method_name}.#{param_name} was #{actual_value.inspect}, which does not match: #{matcher}")
    end
  end

  class BrokenReturnValueContractError < Error
    def initialize(class_name, method_name, matcher, actual_value)
      super("#{class_name}##{method_name} returned #{actual_value.inspect}, which does not match: #{matcher}")
    end
  end

  class ParameterDoesNotExistError < Error
    def initialize(class_name, method_name, param_name)
      super "Parameter #{class_name}##{method_name}.#{param_name} does not exist"
    end
  end

  def self.root
    File.dirname __dir__
  end

  def self.contract_to_matcher(contract)
    if contract.is_a?(Class) && contract < TypeContracts::Matchers::Base
      # Given a matcher class that doesn't take any constructor args
      # Return a new instance of that matcher
      if contract.instance_method(:initialize).arity.zero?
        return contract.new
      else
        raise "Matcher class #{contract.name} constructor takes arguments!"
      end
    end

    case contract
    when TypeContracts::Matchers::Base
      contract # If given a custom matcher object, use it
    when Regexp
      TypeContracts::Matchers::RegularExpression.new(contract)
    when Proc
      TypeContracts::Matchers::CustomProc.new(contract)
    when Array
      TypeContracts::Matchers::MatchAny.new(contract)
    when Module
      TypeContracts::Matchers::Instanceof.new(contract)
    else
      TypeContracts::Matchers::Exactly.new(contract)
    end
  end

  def self.config
    Config.config
  end

  def self.configure(&block)
    Config.configure(&block)
  end

  # Injects the type contracts methods into the given class or module.
  # Has no effect if type contracts are declared to be used globally.
  #
  # @example
  #  class MyClass
  #   TypeContracts.apply!(self)
  #
  #   param :obj, String
  #   returns nil
  #   def pretty_print(obj)
  #     puts obj.inspect
  #   end
  # end
  #
  # MyClass.new.pretty_print(nil) # => BrokenParamContractError
  # MyClass.new.pretty_print('something') # => 'something'
  #
  # @param module_or_class [Module] the module or class to apply type contracts to.
  def self.apply!(module_or_class)
    module_or_class.extend TypeContracts::T
  end
end
