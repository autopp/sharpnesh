module Sharpnesh
  class Parser
    # Arith provides methods for parsing arithmetic expression
    #
    module Arith # rubocop:disable Metrics/ModuleLength
      include Sharpnesh::Parser::TokenType

      ARITH_RULES = [
        { pattern: /\d+/, method: :on_token, opt: TK_NUMBER },
        { pattern: /\$?[a-zA-Z_][a-zA-Z_0-9]*/, method: :on_token, opt: TK_VAR },
        { pattern: /,/, method: :on_token, opt: TK_COMMA },
        { pattern: /[=]{2}/, method: :on_token, opt: TK_EQL },
        { pattern: %r{([-+*/%^&|]|<<|>>)?\=}, method: :on_token, opt: TK_ASSIGN },
        { pattern: /[?]/, method: :on_token, opt: TK_QUESTION },
        { pattern: /:/, method: :on_token, opt: TK_COLON },
        { pattern: /[|]{2}/, method: :on_token, opt: TK_LOR },
        { pattern: /[&]{2}/, method: :on_token, opt: TK_LAND },
        { pattern: /[|]/, method: :on_token, opt: TK_BOR },
        { pattern: /\^/, method: :on_token, opt: TK_BXOR },
        { pattern: /&/, method: :on_token, opt: TK_BAND },
        { pattern: /!=/, method: :on_token, opt: TK_NEQ },
        { pattern: /<</, method: :on_token, opt: TK_LSHIFT },
        { pattern: />>/, method: :on_token, opt: TK_RSHIFT },
        { pattern: /<=/, method: :on_token, opt: TK_LEQ },
        { pattern: /</, method: :on_token, opt: TK_LTN },
        { pattern: />=/, method: :on_token, opt: TK_GEQ },
        { pattern: />/, method: :on_token, opt: TK_GTN },
        { pattern: /[*]{2}/, method: :on_token, opt: TK_EXP },
        { pattern: /[+]{2}/, method: :on_token, opt: TK_INC },
        { pattern: /\+/, method: :on_token, opt: TK_ADD },
        { pattern: /-/, method: :on_token, opt: TK_SUB },
        { pattern: /\*/, method: :on_token, opt: TK_MUL },
        { pattern: %r{/}, method: :on_token, opt: TK_DIV },
        { pattern: /%/, method: :on_token, opt: TK_MOD },
        { pattern: /!/, method: :on_token, opt: TK_NOT },
        { pattern: /~/, method: :on_token, opt: TK_BNOT }
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
        [TK_LOR],
        [TK_LAND],
        [TK_BOR],
        [TK_BXOR],
        [TK_BAND],
        [TK_EQL, TK_NEQ],
        [TK_LTN, TK_LEQ, TK_GTN, TK_GEQ],
        [TK_LSHIFT, TK_RSHIFT],
        [TK_ADD, TK_SUB],
        [TK_MUL, TK_DIV, TK_MOD]
      ].freeze
      def parse_binary_op_expr(lexer, index)
        tokens = BINOP_INFOS[index]
        next_index = index + 1
        operand_proc = if next_index < BINOP_INFOS.size
          proc { parse_binary_op_expr(lexer, next_index) }
        else
          proc { parse_exp_expr(lexer) }
        end

        expr = operand_proc.call
        while (op = lexer.next(*tokens))
          expr = Node.new(:binop, op: op.body, left: expr, right: parse_binary_op_expr(lexer, index))
        end
        expr
      end

      def parse_exp_expr(lexer)
        expr = parse_unary_op_expr(lexer)
        if lexer.next(TK_EXP)
          Node.new(:binop, op: '**', left: expr, right: parse_exp_expr(lexer))
        else
          expr
        end
      end

      def parse_unary_op_expr(lexer)
        if (op = lexer.next(TK_NOT, TK_BNOT, TK_SUB, TK_ADD, TK_INC))
          Node.new(:unop, op: op.body, operand: parse_unary_op_expr(lexer))
        else
          parse_primary_expr(lexer)
        end
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
