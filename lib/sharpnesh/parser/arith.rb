module Sharpnesh
  class Parser
    # Arith provides methods for parsing arithmetic expression
    #
    module Arith
      include Sharpnesh::Parser::TokenType

      ARITH_RULES = [
        { pattern: /\d+/, method: :on_token, opt: TK_NUMBER },
        { pattern: /\$?[a-zA-Z_][a-zA-Z_0-9]*/, method: :on_token, opt: TK_VAR },
        { pattern: /,/, method: :on_token, opt: TK_COMMA },
        { pattern: %r{([-+*/%^&|]|<<|>>)?\=}, method: :on_token, opt: TK_ASSIGN },
        { pattern: /[?]/, method: :on_token, opt: TK_QUESTION },
        { pattern: /:/, method: :on_token, opt: TK_COLON },
        { pattern: /[|]{2}/, method: :on_token, opt: TK_LOR },
        { pattern: /[&]{2}/, method: :on_token, opt: TK_LAND },
        { pattern: /[|]/, method: :on_token, opt: TK_BOR },
        { pattern: /\^/, method: :on_token, opt: TK_BXOR },
        { pattern: /&/, method: :on_token, opt: TK_BAND }
      ].freeze

      def parse_arith(lexer)
        lexer.use_rules(ARITH_RULES, allow_blank: true) do
          parse_comma_expr(lexer)
        end
      end

      def parse_comma_expr(lexer)
        expr = parse_assign_expr(lexer)
        expr = Node.new(:binop, op: ',', left: expr, right: parse_assign_expr(lexer)) while lexer.next(TK_COMMA)
        expr
      end

      def parse_assign_expr(lexer)
        if (left = lexer.next(TK_VAR))
          if (op = lexer.next(TK_ASSIGN))
            Node.new(:binop, op: op.body, left: Node.new(:var, name: left.body), right: parse_assign_expr(lexer))
          else
            lexer.back
            parse_ternary_op_expr(lexer)
          end
        else
          parse_ternary_op_expr(lexer)
        end
      end

      def parse_ternary_op_expr(lexer)
        cond = parse_binary_op_expr(lexer, 0)
        return cond if !lexer.next(TK_QUESTION)
        then_expr = parse_comma_expr(lexer)
        raise ParseError, 'expected `:`' if !lexer.next(TK_COLON)
        Node.new(:terop, cond: cond, then: then_expr, else: parse_ternary_op_expr(lexer))
      end

      BINOP_INFOS = [
        { op: '||', token: TK_LOR },
        { op: '&&', token: TK_LAND },
        { op: '|', token: TK_BOR },
        { op: '^', token: TK_BXOR },
        { op: '&', token: TK_BAND }
      ].freeze
      def parse_binary_op_expr(lexer, index)
        current = BINOP_INFOS[index]
        op = current[:op]
        token = current[:token]
        next_index = index + 1
        operand_proc = if next_index < BINOP_INFOS.size
          proc { parse_binary_op_expr(lexer, next_index) }
        else
          proc { parse_primary_expr(lexer) }
        end

        expr = operand_proc.call
        expr = Node.new(:binop, op: op, left: expr, right: parse_binary_op_expr(lexer, index)) while lexer.next(token)
        expr
      end

      def parse_primary_expr(lexer)
        if (number = lexer.next(TK_NUMBER))
          Node.new(:number, value: number.body)
        elsif (var = lexer.next(TK_VAR))
          Node.new(:var, name: var.body)
        else
          raise ParseError, 'expect primary expression'
        end
      end
    end
  end
end
