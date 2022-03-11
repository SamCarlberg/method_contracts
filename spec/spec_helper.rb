# frozen_string_literal: true

require_relative '../lib/type_contracts'

Dir.glob(File.join(TypeContracts.root, 'lib/**/*.rb')).sort.each { |f| require_relative f }
