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

    context 'with two commands splited by newline' do
      let(:src) { "foo\nbar" }
      let(:root_list) do
        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command, assigns: [], body: [n(:str, body: 'foo')])),
            terminal: "\n"),
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

    context 'with parameter transformations' do
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

    context 'with command substitution' do
      let(:src) { '$(foo bar)' }
      let(:root_list) do
        inner_command = n(:simple_command, assigns: [], body: [n(:str, body: 'foo'), n(:str, body: 'bar')])

        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:command_subst,
                                   style: '$', list: [
                                     n(:pipelines, body: n(:pipeline, excl: nil, command: inner_command), terminal: nil)
                                   ])
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with command substitution' do
      let(:src) { '$(foo $(bar))' }
      let(:root_list) do
        more_inner_command = n(:simple_command, assigns: [], body: [n(:str, body: 'bar')])
        inner_command = n(:simple_command, assigns: [], body: [
                            n(:str, body: 'foo'),
                            n(:command_subst,
                              style: '$', list: [
                                n(:pipelines, body: n(:pipeline, excl: nil, command: more_inner_command), terminal: nil)
                              ])
                          ])

        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:command_subst,
                                   style: '$', list: [
                                     n(:pipelines, body: n(:pipeline, excl: nil, command: inner_command), terminal: nil)
                                   ])
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with back quote string' do
      let(:src) { '`foo bar`' }
      let(:root_list) do
        inner_command = n(:simple_command, assigns: [], body: [n(:str, body: 'foo'), n(:str, body: 'bar')])

        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:command_subst,
                                   style: '`', list: [
                                     n(:pipelines, body: n(:pipeline, excl: nil, command: inner_command), terminal: nil)
                                   ])
                               ])),
            terminal: nil)
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'with process substitutions' do
      let(:src) { 'foo <(bar) >(baz)' }
      let(:root_list) do
        in_command = n(:simple_command, assigns: [], body: [n(:str, body: 'bar')])
        out_command = n(:simple_command, assigns: [], body: [n(:str, body: 'baz')])

        [
          n(:pipelines,
            body: n(:pipeline,
                    excl: nil,
                    command: n(:simple_command,
                               assigns: [],
                               body: [
                                 n(:str, body: 'foo'),
                                 n(:process_subst,
                                   style: '<', list: [
                                     n(:pipelines, body: n(:pipeline, excl: nil, command: in_command), terminal: nil)
                                   ]),
                                 n(:process_subst,
                                   style: '>', list: [
                                     n(:pipelines, body: n(:pipeline, excl: nil, command: out_command), terminal: nil)
                                   ])
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
        let(:src) { '$((x, y, z))' }
        let(:body) do
          n(:binop, op: ',',
                    left: n(:binop, op: ',', left: n(:var, name: 'x'), right: n(:var, name: 'y')),
                    right: n(:var, name: 'z'))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with a assignment' do
        let(:src) { '$((x = 0))' }
        let(:body) do
          n(:binop, op: '=', left: n(:var, name: 'x'), right: n(:number, value: '0'))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with multiple assignments' do
        let(:src) { '$((a = b *= c /= d %= e += f -= g <<= h >>= i &= j ^= k |= 0))' }
        let(:body) do
          n(:binop, op: '=', left: n(:var, name: 'a'), right: n(
            :binop, op: '*=', left: n(:var, name: 'b'), right: n(
              :binop, op: '/=', left: n(:var, name: 'c'), right: n(
                :binop, op: '%=', left: n(:var, name: 'd'), right: n(
                  :binop, op: '+=', left: n(:var, name: 'e'), right: n(
                    :binop, op: '-=', left: n(:var, name: 'f'), right: n(
                      :binop, op: '<<=', left: n(:var, name: 'g'), right: n(
                        :binop, op: '>>=', left: n(:var, name: 'h'), right: n(
                          :binop, op: '&=', left: n(:var, name: 'i'), right: n(
                            :binop, op: '^=', left: n(:var, name: 'j'), right: n(
                              :binop, op: '|=', left: n(:var, name: 'k'), right: n(:number, value: '0')
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          ))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with ternary operator' do
        let(:src) { '$((x ? y : z))' }
        let(:body) { n(:terop, cond: n(:var, name: 'x'), then: n(:var, name: 'y'), else: n(:var, name: 'z')) }

        it { is_expected.to eq(expected) }
      end

      context 'with nested ternary operators' do
        let(:src) { '$((a ? b ? c : d, e : f ? g : h))' }
        let(:body) do
          n(:terop, cond: n(:var, name: 'a'),
                    then: n(:binop, op: ',',
                                    left: n(:terop, cond: n(:var, name: 'b'),
                                                    then: n(:var, name: 'c'),
                                                    else: n(:var, name: 'd')),
                                    right: n(:var, name: 'e')),
                    else: n(:terop, cond: n(:var, name: 'f'), then: n(:var, name: 'g'), else: n(:var, name: 'h')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with a logical OR operator' do
        let(:src) { '$((a ? b : c || d))' }
        let(:body) do
          n(:terop, cond: n(:var, name: 'a'),
                    then: n(:var, name: 'b'),
                    else: n(:binop, op: '||', left: n(:var, name: 'c'), right: n(:var, name: 'd')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with a logical OR operator and logical AND operator' do
        let(:src) { '$((a || b && c))' }
        let(:body) do
          n(:binop, op: '||', left: n(:var, name: 'a'),
                    right: n(:binop, op: '&&', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with logical AND operator and bitwise OR operator' do
        let(:src) { '$((a && b | c))' }
        let(:body) do
          n(:binop, op: '&&', left: n(:var, name: 'a'),
                    right: n(:binop, op: '|', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with bitwise OR operator and bitwise XOR operator' do
        let(:src) { '$((a | b ^ c))' }
        let(:body) do
          n(:binop, op: '|', left: n(:var, name: 'a'),
                    right: n(:binop, op: '^', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with bitwise XOR operator and bitwise AND operator' do
        let(:src) { '$((a ^ b & c))' }
        let(:body) do
          n(:binop, op: '^', left: n(:var, name: 'a'),
                    right: n(:binop, op: '&', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with bitwise AND operator and equality operator' do
        let(:src) { '$((a ^ b == c))' }
        let(:body) do
          n(:binop, op: '^', left: n(:var, name: 'a'),
                    right: n(:binop, op: '==', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with bitwise AND operator and inequality operator' do
        let(:src) { '$((a ^ b != c))' }
        let(:body) do
          n(:binop, op: '^', left: n(:var, name: 'a'),
                    right: n(:binop, op: '!=', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with equality operator and less than operator' do
        let(:src) { '$((a == b < c))' }
        let(:body) do
          n(:binop, op: '==', left: n(:var, name: 'a'),
                    right: n(:binop, op: '<', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with equality operator and less than or equality operator' do
        let(:src) { '$((a == b <= c))' }
        let(:body) do
          n(:binop, op: '==', left: n(:var, name: 'a'),
                    right: n(:binop, op: '<=', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with inequality operator and greater than operator' do
        let(:src) { '$((a != b > c))' }
        let(:body) do
          n(:binop, op: '!=', left: n(:var, name: 'a'),
                    right: n(:binop, op: '>', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with inequality operator and greater than or equality operator' do
        let(:src) { '$((a != b >= c))' }
        let(:body) do
          n(:binop, op: '!=', left: n(:var, name: 'a'),
                    right: n(:binop, op: '>=', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with less than operator and left bitwise shift operator' do
        let(:src) { '$((a < b << c))' }
        let(:body) do
          n(:binop, op: '<', left: n(:var, name: 'a'),
                    right: n(:binop, op: '<<', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with greater than operator and right bitwise shift operator' do
        let(:src) { '$((a > b >> c))' }
        let(:body) do
          n(:binop, op: '>', left: n(:var, name: 'a'),
                    right: n(:binop, op: '>>', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with left bitwise operator and addition operator' do
        let(:src) { '$((a << b + c))' }
        let(:body) do
          n(:binop, op: '<<', left: n(:var, name: 'a'),
                    right: n(:binop, op: '+', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with right bitwise operator and subtraction operator' do
        let(:src) { '$((a >> b - c))' }
        let(:body) do
          n(:binop, op: '>>', left: n(:var, name: 'a'),
                    right: n(:binop, op: '-', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with addition operator and multiplication operator' do
        let(:src) { '$((a + b * c))' }
        let(:body) do
          n(:binop, op: '+', left: n(:var, name: 'a'),
                    right: n(:binop, op: '*', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with subtraction operator and division operator' do
        let(:src) { '$((a - b / c))' }
        let(:body) do
          n(:binop, op: '-', left: n(:var, name: 'a'),
                    right: n(:binop, op: '/', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with subtraction operator and modulo operator' do
        let(:src) { '$((a - b % c))' }
        let(:body) do
          n(:binop, op: '-', left: n(:var, name: 'a'),
                    right: n(:binop, op: '%', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with multiplication operator and exponentiation operator' do
        let(:src) { '$((a * b ** c))' }
        let(:body) do
          n(:binop, op: '*', left: n(:var, name: 'a'),
                    right: n(:binop, op: '**', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with exponentiation operators' do
        let(:src) { '$((a ** b ** c))' }
        let(:body) do
          n(:binop, op: '**', left: n(:var, name: 'a'),
                    right: n(:binop, op: '**', left: n(:var, name: 'b'), right: n(:var, name: 'c')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with logical negation operators' do
        let(:src) { '$((!!a))' }
        let(:body) do
          n(:unop, op: '!', operand: n(:unop, op: '!', operand: n(:var, name: 'a')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with logical negation operator and bitwise negation operator' do
        let(:src) { '$((!~a))' }
        let(:body) do
          n(:unop, op: '!', operand: n(:unop, op: '~', operand: n(:var, name: 'a')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with bitwise negation operator and unary minus operator' do
        let(:src) { '$((~-a))' }
        let(:body) do
          n(:unop, op: '~', operand: n(:unop, op: '-', operand: n(:var, name: 'a')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with unary minus operator and unary plus operator' do
        let(:src) { '$((-+a))' }
        let(:body) do
          n(:unop, op: '-', operand: n(:unop, op: '+', operand: n(:var, name: 'a')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with pre-increment operator' do
        let(:src) { '$((++a))' }
        let(:body) { n(:unop, op: '++', operand: n(:var, name: 'a')) }

        it { is_expected.to eq(expected) }
      end

      context 'with pre-decrement operator' do
        let(:src) { '$((--a))' }
        let(:body) { n(:unop, op: '--', operand: n(:var, name: 'a')) }

        it { is_expected.to eq(expected) }
      end

      context 'with pre-increment operator and post-increment operator' do
        let(:src) { '$((++a++))' }
        let(:body) do
          n(:unop, op: '++', operand: n(:postop, op: '++', operand: n(:var, name: 'a')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with pre-decrement operator and post-decrement operator' do
        let(:src) { '$((--a--))' }
        let(:body) do
          n(:unop, op: '--', operand: n(:postop, op: '--', operand: n(:var, name: 'a')))
        end

        it { is_expected.to eq(expected) }
      end

      context 'with parenthesized expression' do
        let(:src) { '$(((a + b) * c))' }
        let(:body) do
          n(:binop, op: '*',
                    left: n(:parentheses, body: n(:binop, op: '+',
                                                          left: n(:var, name: 'a'), right: n(:var, name: 'b'))),
                    right: n(:var, name: 'c'))
        end

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
