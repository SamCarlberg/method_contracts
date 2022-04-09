# frozen_string_literal: true

module TypeContracts
  module Annotations
    def annotations(method_name = nil)
      return @__type_contracts__annotations[method_name] if method_name

      @__type_contracts__annotations
    end

    class MethodRedefinition
      NOT_PROVIDED = Object.new.freeze

      INSTANCE_METHOD = :instance_method
      SINGLETON_METHOD = :singleton_method

      attr_reader :clazz, :method_name, :method_type

      def initialize(clazz, method_name, method_type:)
        @clazz = clazz
        @method_name = method_name
        @method_type = method_type

        method = case method_type
                 when INSTANCE_METHOD
                   clazz.instance_method(method_name)
                 when SINGLETON_METHOD
                   clazz.method(method_name)
                 end
        @params = method.parameters.map(&:reverse).to_h
        @params_array = @params.to_a

        @variadic  = @params.find { |name, option| option == :rest }&.first
        @kwariatic = @params.find { |name, option| option == :keyrest }&.first

        @num_params = @params.size - (@kwariatic ? 1 : 0)
      end

      def redefine!(annotation)
        annotation[:_redefined] = false

        # Only redefine the method if the library is enabled
        return unless TypeContracts.config.enabled?

        param_contracts = annotation[:params] || [] # default in case no param annotations exist
        return_contract = annotation[:return]

        stubbed_method_name = "__original_#{method_name}__"

        case method_type
        when INSTANCE_METHOD
          definer_method_name = :define_method
          clazz.alias_method stubbed_method_name, method_name
        when SINGLETON_METHOD
          clazz.singleton_class.alias_method stubbed_method_name, method_name
          definer_method_name = :define_singleton_method
        end

        clazz.send(definer_method_name, method_name) do |*args, **kwargs, &block|
          redefiner = annotation[:_redefiner]
          recombined = redefiner.recombine(*args, **kwargs)

          if recombined.values.none? { |v| v == TypeContracts::Annotations::MethodRedefinition::NOT_PROVIDED }
            # Skip validation if any param is not provided;
            # we'll get an error later when the argument list size mismatches
            param_contracts.each do |contract|
              unless recombined.key?(contract.param_name)
                raise TypeContracts::ParameterDoesNotExistError.new(
                  redefiner.clazz.name,
                  redefiner.method_name,
                  contract.param_name
                )
              end

              contract.check_contract!(redefiner.clazz, redefiner.method_name, recombined[contract.param_name])
            end
          end

          return_value = send(stubbed_method_name, *args, **kwargs, &block)

          return_contract&.check_contract!(redefiner.clazz, redefiner.method_name, return_value)

          return_value
        end

        annotation[:_redefined] = true
      end

      # Recombines a splatted args array and kwargs hash into a single hash
      # where the keys are the parameter names on the original method
      def recombine(*args, **kwargs)
        hash = build_return_hash

        move_named_param_from_kwargs(args, kwargs)

        num_args = args.size
        num_varargs = num_args - @num_params + 1 # irrelevant if there isn't an actual variadic param
        num_varargs_processed = 0

        next_param_index = 0

        num_args.times do |index|
          arg = args[index]
          param = @params_array[next_param_index]
          name, type = *param

          if type == :rest
            # varargs
            hash[name] = [] if hash[name] == NOT_PROVIDED

            if num_varargs_processed < num_varargs
              hash[name] << arg
              num_varargs_processed += 1
            end

            next_param_index += 1 if num_varargs_processed >= num_varargs
          else
            hash[name] = arg
            next_param_index += 1
          end
        end

        if @variadic
          # Really only used if no variadic params are passed
          hash[@variadic] ||= args
        end

        if @kwariatic
          hash[@kwariatic] = kwargs
        end

        hash
      end

      private

      # Builds a hash of return values.
      # Values will be nil and keys will appear in the same order as the parameters on the method.
      # returns_a HashOf(Symbol, nil)
      def build_return_hash
        @params
          .reject { |name, option| option == :keyrest }
          .to_h { |name, option| [name.to_sym, NOT_PROVIDED] }
      end

      # Removes values for named params from `kwargs` and appends them to `args`.
      def move_named_param_from_kwargs(args, kwargs)
        kwarg_removal_index = -1
        kwargs.each_with_index do |(name, value), index|
          if @params[name] == :key && index == kwarg_removal_index + 1
            args << value
            kwarg_removal_index += 1
          else
            break
          end
        end

        delete_count = -1
        kwargs.delete_if do
          (delete_count += 1) <= kwarg_removal_index
        end
      end
    end

    private

    def method_added(m)
      super

      if annotation = @__type_contracts__last_annotation
        @__type_contracts__last_annotation = nil
        (@__type_contracts__annotations ||= {})[m] = annotation

        redefiner = MethodRedefinition.new(self, m, method_type: MethodRedefinition::INSTANCE_METHOD)
        annotation[:_redefiner] = redefiner
        redefiner.redefine!(annotation)
      end
    end

    def singleton_method_added(m)
      super

      if annotation = @__type_contracts__last_annotation
        @__type_contracts__last_annotation = nil
        (@__type_contracts__annotations ||= {})[m] = annotation

        redefiner = MethodRedefinition.new(self, m, method_type: MethodRedefinition::SINGLETON_METHOD)
        annotation[:_redefiner] = redefiner
        redefiner.redefine!(annotation)
      end
    end
  end
end
