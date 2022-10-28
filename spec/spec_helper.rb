# frozen_string_literal: true

require_relative '../lib/method_contracts'

Dir.glob(File.join(MethodContracts.root, 'lib/**/*.rb')).sort.each { |f| require_relative f }
