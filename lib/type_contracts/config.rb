# frozen_string_literal: true

module TypeContracts
  class Config
    def self.config
      @config ||= new
    end

    def self.configure(&block)
      block.call(config)
    end

    # Enables or disables contracts.  This must be set prior to declaring any contracts.
    attr_accessor :enabled

    # Checks if contracts are enabled.  Returns false if not set.
    #
    # @return [Boolean]
    def enabled
      @enabled || false
    end

    alias_method :enabled?, :enabled

    # Includes the contract mixins everywhere.  Note that this may cause unexpected
    # conflicts on classes that define their own `param`, `returns/returns_a/returns_an`,
    # or `annotations` methods!
    #
    # Has no effect if type contracts are not enabled.
    def include_everywhere!
      return unless enabled?

      TypeContracts.apply!(Module)
    end
  end
end
