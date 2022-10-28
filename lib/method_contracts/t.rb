# frozen_string_literal: true

module MethodContracts
  # An intermediary module that, when extended, will add all methods pertaining to type contracts
  # to the class or module doing the extending.
  #
  # @example
  #   module MyModule
  #     extend MethodContracts::T
  #   end
  module T
    include MethodContracts::Annotations
    include MethodContracts::Overrides
    include MethodContracts::Param::Mixin
    include MethodContracts::Return::Mixin
  end
end
