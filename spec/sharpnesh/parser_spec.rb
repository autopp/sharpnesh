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
                    command: n(:simple_command, assigns: [], body: [n(:str, body: 'foo')])),
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
                    command: n(:simple_command, assigns: [], body: [n(:str, body: 'foo'), n(:str, body: 'bar')])),
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
                    command: n(:simple_command, assigns: [], body: [n(:str, body: 'foo')])),
            terminal: ';'),
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command, assigns: [], body: [n(:str, body: 'bar')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with a assignment' do
      let(:src) { 'a=x foo' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [n(:assign, name: 'a', value: n(:str, body: 'x'))],
                               body: [n(:str, body: 'foo')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with two assignments' do
      let(:src) { 'a=x b=y foo' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [
                                 n(:assign, name: 'a', value: n(:str, body: 'x')),
                                 n(:assign, name: 'b', value: n(:str, body: 'y'))
                               ],
                               body: [n(:str, body: 'foo')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with a assignment including `=`' do
      let(:src) { 'a=b=x foo' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [n(:assign, name: 'a', value: n(:str, body: 'b=x'))],
                               body: [n(:str, body: 'foo')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with a empty assignment' do
      let(:src) { 'a= foo' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [n(:assign, name: 'a', value: nil)],
                               body: [n(:str, body: 'foo')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with string' do
      let(:src) { 'foo sample-arg.txt' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:str, body: 'foo'), n(:str, body: 'sample-arg.txt')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with positional parameters' do
      let(:src) { '$1 $2' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:simple_param_ex, body: '1'), n(:simple_param_ex, body: '2')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with normal parameter' do
      let(:src) { '$cmd' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:simple_param_ex, body: 'cmd')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with special parameters' do
      let(:src) { '$- $* $@ $# $? $$ $!' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:simple_param_ex, body: '-'), n(:simple_param_ex, body: '*'),
                                 n(:simple_param_ex, body: '@'), n(:simple_param_ex, body: '#'),
                                 n(:simple_param_ex, body: '?'), n(:simple_param_ex, body: '$'),
                                 n(:simple_param_ex, body: '!')
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with variable expansions' do
      let(:src) { '${cmd} ${!arg}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:param_ex, ref: false, body: 'cmd'), n(:param_ex, ref: true, body: 'arg')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with a single quoted string' do
      let(:src) { "foo 'bar baz'" }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:str, body: 'foo'), n(:sstr, body: 'bar baz')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end
  end
end
