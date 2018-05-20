require 'spec_helper'

describe Sharpnesh::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse(StringIO.new(src), 'input.sh') }

    context 'with simple word' do
      let(:src) { 'foo' }
      let(:expected) do
        n(:root,
          list: [
            n(:pipelines,
              body: n(:pipeline,
                      excl: nil,
                      command: n(:simple_command, assigns: [], body: [n(:name, body: 'foo')])),
              terminal: nil)
          ])
      end

      it { is_expected.to eq(expected) }
    end

    context 'with two word' do
      let(:src) { 'foo bar' }
      let(:expected) do
        n(:root,
          list: [
            n(:pipelines,
              body: n(:pipeline,
                      excl: nil,
                      command: n(:simple_command, assigns: [], body: [n(:name, body: 'foo'), n(:name, body: 'bar')])),
              terminal: nil)
          ])
      end

      it { is_expected.to eq(expected) }
    end

    context 'with two commands' do
      let(:src) { 'foo;bar' }
      let(:expected) do
        n(:root,
          list: [
            n(:pipelines,
              body: n(:pipeline,
                      excl: nil,
                      command: n(:simple_command, assigns: [], body: [n(:name, body: 'foo')])),
              terminal: ';'),
            n(:pipelines,
              body: n(:pipeline,
                      excl: nil,
                      command: n(:simple_command, assigns: [], body: [n(:name, body: 'bar')])),
              terminal: nil)
          ])
      end

      it do
        pending
        is_expected.to eq(expected)
      end
    end
  end
end
