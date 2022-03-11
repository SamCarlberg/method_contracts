# frozen_string_literal: true

module TypeContracts
  module Annotations
    def annotations(method_name = nil)
      return @__type_contracts__annotations[method_name] if method_name

      @__type_contracts__annotations
    end

    private

    def method_added(m)
      super

      if annotation = @__type_contracts__last_annotation
        @__type_contracts__last_annotation = nil
        (@__type_contracts__annotations ||= {})[m] = annotation

        clazz = self
        method_name = m
        param_contracts = annotation[:params] || [] # default in case no param annotations exist
        return_contract = annotation[:return]

        stubbed_method_name = "__original_#{method_name}__"

        clazz.alias_method stubbed_method_name, method_name

        clazz.define_method(method_name) do |*args, &block|
          param_names = method(stubbed_method_name).parameters.map { |a| a[1] }

          param_contracts.each do |contract|
            param_index = param_names.index(contract.param_name)
            if param_index.nil?
              raise TypeContracts::ParameterDoesNotExistError.new(clazz.name, method_name, contract.param_name)
            end

            contract.check_contract!(clazz, method_name, args[param_index])
          end

          return_value = send(stubbed_method_name, *args, &block)

          return_contract&.check_contract!(clazz, method_name, return_value)

          return_value
        end
      end
    end
  end
end

Object.extend TypeContracts::Annotations
