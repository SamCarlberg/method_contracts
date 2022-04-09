# frozen_string_literal: true

module TypeContracts
  # An intermediary module that, when extended, will add all methods pertaining to type contracts
  # to the class or module doing the extending.
  #
  # @example
  #   module MyModule
  #     extend TypeContracts::T
  #   end
  module T
    include TypeContracts::Annotations
    include TypeContracts::Param::Mixin
    include TypeContracts::Return::Mixin
  end
end
