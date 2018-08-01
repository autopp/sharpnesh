module Sharpnesh
  class Parser
    # Expansion provides methods for parsing expansion
    #
    module Parameter
      include Sharpnesh::Parser::TokenType

      EXPANSION_RULES = [
        { pattern: /([0-9]|([a-zA-Z_]\w*)|[-*@#?$!])/, method: :on_token, opt: TK_VAR },
        { pattern: /\[@\]/, method: :on_token, opt: TK_BRACKET_AT },
        { pattern: /\[\*\]/, method: :on_token, opt: TK_BRACKET_ASTALISK },
        { pattern: /}/, method: :on_token, opt: TK_RBRACE }
      ].freeze

      def parse_expansion(lexer) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/LineLength
        lexer.use_rules(EXPANSION_RULES, allow_blank: false) do # rubocop:disable Metrics/BlockLength
          # check length `#`
          len = !!lexer.accept(/#/, TK_SHARP)

          # check ref `!`
          ref = !!lexer.accept(/!/, TK_NOT)
          if !(param = lexer.next(TK_VAR))
            raise ParseError, 'expect parameter'
          end

          node = if (array_ex = lexer.next(TK_BRACKET_AT, TK_BRACKET_ASTALISK))
            # array expansion
            type = ref ? :array_keys : :array_ex
            Node.new(type, array: param.body, mode: array_ex.body[1])
          elsif (op = lexer.accept(/:[-=?+]/, nil))
            value = if lexer.peek(TK_RBRACE)
              Node.new(:empty)
            else
              lexer.use_rules(gen_word_rules('}'), allow_blank: true) do
                parse_word(lexer)
              end
            end
            Node.new(:param_subst, ref: ref, body: param.body, op: op.body, value: value)
          elsif lexer.accept(/:/, nil)
            offset = parse_arith(lexer)
            length = lexer.accept(/:/, nil, allow_blank: true) ? parse_arith(lexer) : Node.new(:empty)
            lexer.skip_blank
            Node.new(:substr, ref: ref, body: param.body, offset: offset, length: length)
          elsif (mode = lexer.accept(/[#]{1,2}|%{1,2}|\^{1,2}|[,]{1,2}/, nil))
            type = mode.body.start_with?('#', '%') ? :pattern_rm : :case_mod
            pattern = if lexer.peek(TK_RBRACE)
              Node.new(:empty)
            else
              lexer.use_rules(gen_word_rules('}'), allow_blank: true) do
                parse_word(lexer)
              end
            end
            Node.new(type, ref: ref, body: param.body, mode: mode.body, pattern: pattern)
          elsif lexer.accept(%r{/}, nil)
            pattern = lexer.use_rules(gen_word_rules('/'), allow_blank: true) do
              parse_word(lexer)
            end
            raise ParseError, 'expect `/`' if !lexer.accept(%r{/}, nil)
            replace = if lexer.peek(TK_RBRACE)
              Node.new(:empty)
            else
              lexer.use_rules(gen_word_rules('}'), allow_blank: true) do
                parse_word(lexer)
              end
            end
            Node.new(:pattern_subst, ref: ref, body: param.body, pattern: pattern, replace: replace)
          elsif lexer.accept(/[@]/, nil)
            op = lexer.accept(/[QPEAa]/, nil)
            if op
              Node.new(:param_trans, ref: ref, body: param.body, op: op.body)
            else
              raise ParseError, 'prefix matching requires `!`' if !ref
              Node.new(:prefix_ex, prefix: param.body, mode: '@')
            end
          elsif lexer.accept(/[*]/, nil)
            raise ParseError, 'prefix matching requires `!`' if !ref
            Node.new(:prefix_ex, prefix: param.body, mode: '*')
          elsif lexer.accept(/\[/, nil)
            subscript = parse_arith(lexer)
            raise ParseError, 'expect `]`' if !lexer.accept(/\]/, nil, allow_blank: true)
            Node.new(:array_access, body: param.body, subscript: subscript)
          else
            type = len ? :param_len : :param_ex
            # normal expansion or parameter length
            Node.new(type, ref: ref, body: param.body)
          end
          raise ParseError, 'expect `}`' if !lexer.next(TK_RBRACE)
          node
        end
      end
    end
  end
end
