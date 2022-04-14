# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeContracts::Overrides do
  let(:helper_class) do
    class HelperClass
      extend TypeContracts::T
      extend TypeContracts::Overrides

      # attr_writer
      param :value, Object
      attr_writer :single_writer

      param :value, Object
      attr_writer :writer_1, :writer_2, :writer_3

      # attr_accessor
      param :value, Object
      attr_accessor :single_accessor

      param :value, Object
      attr_accessor :accessor_1, :accessor_2, :accessor_3

      # attr_reader
      returns_an Object
      attr_reader :single_reader

      returns_an Object
      attr_reader :reader_1, :reader_2, :reader_3
    end

    HelperClass
  end

  before do
    allow(TypeContracts.config)
      .to receive(:enabled?)
      .and_return(true)
  end

  after do
    Object.send :remove_const, :HelperClass
  end

  it 'generates the correct getter and setter methods when contracts are enabled' do
    allow(TypeContracts.config)
      .to receive(:enabled?)
      .and_return(true)

    instance = helper_class.new

    expect(instance).to respond_to :single_writer=
    expect(instance).to respond_to :writer_1=
    expect(instance).to respond_to :writer_2=
    expect(instance).to respond_to :writer_3=

    expect(instance).to respond_to :single_reader
    expect(instance).to respond_to :reader_1
    expect(instance).to respond_to :reader_2
    expect(instance).to respond_to :reader_3

    expect(instance).to respond_to :single_accessor
    expect(instance).to respond_to :single_accessor=
    expect(instance).to respond_to :accessor_1
    expect(instance).to respond_to :accessor_1=
    expect(instance).to respond_to :accessor_2
    expect(instance).to respond_to :accessor_2=
    expect(instance).to respond_to :accessor_3
    expect(instance).to respond_to :accessor_3=

    p instance.method(:"__original_single_writer=__").source_location
  end

  it 'generates the correct getter and setter methods when contracts are disabled' do
    allow(TypeContracts.config)
      .to receive(:enabled?)
      .and_return(false)

    instance = helper_class.new

    expect(instance).to respond_to :single_writer=
    expect(instance).to respond_to :writer_1=
    expect(instance).to respond_to :writer_2=
    expect(instance).to respond_to :writer_3=

    expect(instance).to respond_to :single_reader
    expect(instance).to respond_to :reader_1
    expect(instance).to respond_to :reader_2
    expect(instance).to respond_to :reader_3

    expect(instance).to respond_to :single_accessor
    expect(instance).to respond_to :single_accessor=
    expect(instance).to respond_to :accessor_1
    expect(instance).to respond_to :accessor_1=
    expect(instance).to respond_to :accessor_2
    expect(instance).to respond_to :accessor_2=
    expect(instance).to respond_to :accessor_3
    expect(instance).to respond_to :accessor_3=

    p instance.method(:single_writer=).source_location
  end
end
