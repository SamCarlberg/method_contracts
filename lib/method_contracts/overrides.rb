# frozen_string_literal: true

module MethodContracts
  module Overrides
    # Need to redefine attr_accessor to not use dynamic method generation with define_method,
    # but use explicit ruby syntax.  Otherwise, method_added can't know about the params list.
    # Also, the method_added callback would only trigger annotations for the first method
    # generated (the getter), so annotations wouldn't apply to the rest.  We're cloning the
    # annotation for each set of methods generated for each property here.
    def attr_accessor(first_property, *other)
      annotation = @__method_contracts__last_annotation
      @__method_contracts__last_annotation = nil
      return super unless self.is_a?(Module) && MethodContracts.config.enabled?

      # No annotations, don't bother redefining stuff.
      return super unless annotation

      property_names = ([first_property] + other).map(&:to_sym)
      property_names.each do |property|
        class_eval <<~RUBY
          def #{property}; @#{property}; end                 # def some_property; @some_property; end
          def #{property}=(value); @#{property} = value; end # def some_property=(value); @some_property = value; end
        RUBY

        if annotation
          getter_copy = __clone_annotation_for_method(annotation, :"#{property}")
          getter_copy[:params] = nil

          setter_copy = __clone_annotation_for_method(annotation, :"#{property}=")
          setter_copy[:return] = nil

          getter_copy[:_redefiner].redefine!(getter_copy)
          setter_copy[:_redefiner].redefine!(setter_copy)
        end
      end
    end

    def attr_writer(first_property, *other)
      # annotations fail when the built-in attr_writer method is called, due it generating methods
      # without parameter names, so just delete the last annotation
      annotation = @__method_contracts__last_annotation
      @__method_contracts__last_annotation = nil

      return super unless self.is_a?(Module) && MethodContracts.config.enabled?

      # No annotations, don't bother redefining stuff.
      return super unless annotation

      property_names = ([first_property] + other).map(&:to_sym)
      property_names.each do |property|
        class_eval <<~RUBY
          def #{property}=(value); @#{property} = value; end # def some_property=(value); @some_property = value; end
        RUBY

        if annotation
          setter_copy = __clone_annotation_for_method(annotation, :"#{property}=")
          setter_copy[:return] = nil
          setter_copy[:_redefiner].redefine!(setter_copy)
        end
      end
    end

    def attr_reader(first_property, *other)
      annotation = @__method_contracts__last_annotation
      @__method_contracts__last_annotation = nil
      return super unless self.is_a?(Module) && MethodContracts.config.enabled?

      # No annotations, don't bother redefining stuff.
      return super unless annotation

      property_names = ([first_property] + other).map(&:to_sym)
      property_names.each do |property|
        class_eval <<~RUBY
          def #{property}; @#{property}; end # def some_property; @some_property; end
        RUBY

        if annotation
          getter_copy = __clone_annotation_for_method(annotation, :"#{property}")
          getter_copy[:params] = nil
          getter_copy[:_redefiner].redefine!(getter_copy)
        end
      end
    end

    def __clone_annotation_for_method(annotation, method_name)
      new_annotation = annotation.clone
      redefiner = ::MethodContracts::Annotations::MethodRedefinition.new(self, method_name, method_type: ::MethodContracts::Annotations::MethodRedefinition::INSTANCE_METHOD)
      new_annotation[:_redefiner] = redefiner

      (@__method_contracts__annotations ||= {})[method_name] = new_annotation
      new_annotation
    end
  end
end
