require 'spec_helper'

describe Sharpnesh::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse(StringIO.new(src), 'input.sh') }

    context 'with simple word' do
      let(:src) { 'foo' }
      let(:expected) do
        n(:list,
          body: n(:pipeline,
                  excl: nil,
                  command: n(:simple_command,
                             assigns: [], body: [n(:name, body: 'foo')])),
          terminal: '', next: nil)
      end

      it { is_expected.to eq(expected) }
    end

    context 'with two word' do
      let(:src) { 'foo bar' }
      let(:expected) do
        n(:list,
          body: n(:pipeline,
                  excl: nil,
                  command: n(:simple_command,
                             assigns: [], body: [n(:name, body: 'foo'), n(:name, body: 'bar')])),
          terminal: '', next: nil)
      end

      it { is_expected.to eq(expected) }
    end
  end
end
