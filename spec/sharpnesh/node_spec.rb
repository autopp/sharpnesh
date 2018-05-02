require 'spec_helper'

describe Sharpnesh::Node do
  describe '#initialize' do
    subject { described_class.new(:foo, x: 42, y: 'bar') }

    it 'has :foo type' do
      expect(subject.type).to eq(:foo)
    end

    it 'respond to optional children key and return the value' do
      expect(subject.x).to eq(42)
      expect(subject.y).to eq('bar')
    end

    it { is_expected.not_to respond_to(:z) }
  end
end
