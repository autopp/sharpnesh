require 'spec_helper'

describe Sharpnesh::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse(StringIO.new(src), 'input.sh') }

    context 'with simple word' do
      let(:src) { 'foo' }
    end
  end
end
