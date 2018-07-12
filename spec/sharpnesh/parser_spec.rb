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

    context 'with array access' do
      let(:src) { '${a[0]} ${a[ 1 ]}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:array_access, body: 'a', subscript: n(:number, value: '0')),
                                 n(:array_access, body: 'a', subscript: n(:number, value: '1'))
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with array expansions' do
      let(:src) { '${foo[*]} ${foo[@]}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:array_ex, array: 'foo', mode: '*'), n(:array_ex, array: 'foo', mode: '@')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with parameter substitutions' do
      let(:src) { '${a:-a} ${a:=\'a\'} ${!a:?${x}} ${!a:+}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:param_subst, ref: false, body: 'a',
                                                 op: ':-', value: n(:str, body: 'a')),
                                 n(:param_subst, ref: false, body: 'a',
                                                 op: ':=', value: n(:sstr, body: 'a')),
                                 n(:param_subst, ref: true, body: 'a',
                                                 op: ':?', value: n(:param_ex, ref: false, body: 'x')),
                                 n(:param_subst, ref: true, body: 'a',
                                                 op: ':+', value: n(:empty))
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with substring expapnsions' do
      let(:src) { '${a:0} ${!a:0:1} ${a: 0 } ${!a: 0 : 1 }' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:substr, ref: false, body: 'a',
                                            offset: n(:number, value: '0'), length: n(:empty)),
                                 n(:substr, ref: true, body: 'a',
                                            offset: n(:number, value: '0'), length: n(:number, value: '1')),
                                 n(:substr, ref: false, body: 'a',
                                            offset: n(:number, value: '0'), length: n(:empty)),
                                 n(:substr, ref: true, body: 'a',
                                            offset: n(:number, value: '0'), length: n(:number, value: '1'))
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with array keys expansions' do
      let(:src) { '${!foo[*]} ${!foo[@]}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:array_keys, array: 'foo', mode: '*'), n(:array_keys, array: 'foo', mode: '@')
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with parameter length expansion' do
      let(:src) { '${#foo} ${#!bar}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:param_len, ref: false, body: 'foo'), n(:param_len, ref: true, body: 'bar')])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with remove pattern' do
      let(:src) { '${a#b} ${a##\'b\'} ${!a%${x}} ${!a%%}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:pattern_rm, ref: false, body: 'a', mode: '#', pattern: n(:str, body: 'b')),
                                 n(:pattern_rm, ref: false, body: 'a', mode: '##', pattern: n(:sstr, body: 'b')),
                                 n(:pattern_rm, ref: true, body: 'a', mode: '%',
                                                pattern: n(:param_ex, ref: false, body: 'x')),
                                 n(:pattern_rm, ref: true, body: 'a', mode: '%%', pattern: n(:empty))
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with pattern substitution' do
      let(:src) { '${a/b/c} ${a/\'b\'/${x}} ${!a/b/}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:pattern_subst, ref: false, body: 'a',
                                                   pattern: n(:str, body: 'b'), replace: n(:str, body: 'c')),
                                 n(:pattern_subst, ref: false, body: 'a',
                                                   pattern: n(:sstr, body: 'b'),
                                                   replace: n(:param_ex, ref: false, body: 'x')),
                                 n(:pattern_subst, ref: true, body: 'a',
                                                   pattern: n(:str, body: 'b'), replace: n(:empty))
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with case modification' do
      let(:src) { '${a^b} ${a^^\'b\'} ${!a,${x}} ${!a,,}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:case_mod, ref: false, body: 'a', mode: '^', pattern: n(:str, body: 'b')),
                                 n(:case_mod, ref: false, body: 'a', mode: '^^', pattern: n(:sstr, body: 'b')),
                                 n(:case_mod, ref: true, body: 'a', mode: ',',
                                              pattern: n(:param_ex, ref: false, body: 'x')),
                                 n(:case_mod, ref: true, body: 'a', mode: ',,', pattern: n(:empty))
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with prefix expansions' do
      let(:src) { '${!foo*} ${!foo@}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:prefix_ex, prefix: 'foo', mode: '*'), n(:prefix_ex, prefix: 'foo', mode: '@')
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with parameter transfomations' do
      let(:src) { '${foo@Q} ${foo@E} ${foo@P} ${!foo@A} ${!foo@a}' }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:param_trans, ref: false, body: 'foo', op: 'Q'),
                                 n(:param_trans, ref: false, body: 'foo', op: 'E'),
                                 n(:param_trans, ref: false, body: 'foo', op: 'P'),
                                 n(:param_trans, ref: true, body: 'foo', op: 'A'),
                                 n(:param_trans, ref: true, body: 'foo', op: 'a')
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with a arithmetic expansion' do
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [n(:arith_ex, body: body)])),
            terminal: nil)
        ]
      end

      context 'with number literal' do
        let(:src) { '$(( 0 ))' }
        let(:body) { n(:number, value: '0') }

        it { is_expected.to eq(expected) }
      end

      context 'with a variable' do
        let(:src) { '$(( x ))' }
        let(:body) { n(:var, name: 'x') }

        it { is_expected.to eq(expected) }
      end

      context 'with a variable starting with $' do
        let(:src) { '$(( $x ))' }
        let(:body) { n(:var, name: '$x') }

        it { is_expected.to eq(expected) }
      end

      context 'with a comma operator' do
        let(:src) { '$((x, y))' }
        let(:body) { n(:binop, op: ',', left: n(:var, name: 'x'), right: n(:var, name: 'y')) }

        it { is_expected.to eq(expected) }
      end
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
