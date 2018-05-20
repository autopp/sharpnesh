require 'spec_helper'

describe Sharpnesh::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse(StringIO.new(src), 'input.sh') }
    let(:expected) { n(:root, list: root_list) }

    context 'with simple word' do
      let(:src) { 'foo' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command, assigns: [], body: [n(:name, body: 'foo')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with two word' do
      let(:src) { 'foo bar' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command, assigns: [], body: [n(:name, body: 'foo'), n(:name, body: 'bar')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with two commands' do
      let(:src) { 'foo;bar' }
      let(:root_list) do
        [
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
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with a assign' do
      let(:src) { 'a=x foo' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [n(:assign, name: 'a', value: n(:name, body: 'x'))],
                               body: [n(:name, body: 'foo')])),
            terminal: nil)
        ]
      end

      it do
        pending
        is_expected.to eq(expected)
      end
    end
  end
end
