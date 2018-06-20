module Sharpnesh
  # Parser provides features of parsing a bash script
  #
  class Parser
    require 'sharpnesh/parser/token_type'
    include TokenType

    DEFAULT_RULES = [
      { pattern: /([^$|&;()<> \t\n"']|\\[$|&;()<> \t"'])+/, method: :on_token, opt: TK_STR },
      { pattern: /'([^']|(\\'))*'/, method: :on_token, opt: TK_SQUOTE },
      { pattern: /\$([0-9]|([a-zA-Z_]\w*)|[-*@#?$!])/, method: :on_token, opt: TK_DOLLAR_VAR },
      { pattern: /\${/, method: :on_token, opt: TK_DOLLAR_LBRACE },
      { pattern: /;/, method: :on_token, opt: TK_SEMICOLON }
    ].freeze

    EXPANSION_RULES = [
      { pattern: /([0-9]|([a-zA-Z_]\w*)|[-*@#?$!])/, method: :on_token, opt: TK_VAR },
      { pattern: /\[@\]/, method: :on_token, opt: TK_BRACKET_AT },
      { pattern: /\[\*\]/, method: :on_token, opt: TK_BRACKET_ASTALISK },
      { pattern: /}/, method: :on_token, opt: TK_RBRACE }
    ].freeze

    def parse(io, name)
      lexer = Lexer.new(io, name)
      lexer.use_rules(DEFAULT_RULES) do
        Node.new(:root, list: parse_list(lexer, TK_EOS))
      end
    end

    def parse_list(lexer, terminal)
      list = []
      list << parse_pipelines(lexer) while !lexer.peek(terminal)
      list
    end

    def parse_pipelines(lexer)
      pipeline = parse_pipeline(lexer)
      terminal = (terminal_token = lexer.next(TK_SEMICOLON, TK_NEWLINE, TK_AND)) ? terminal_token.body : nil
      Node.new(:pipelines, body: pipeline, terminal: terminal)
    end

    def parse_pipeline(lexer)
      not_op = lexer.next(TK_NOT)
      command = parse_command(lexer)
      while (pipe = lexer.next(TK_PIPE, TK_PIPE_AND))
        command = Node.new(:pipe, pipe: pipe, lhs: command, rhs: parse_command(lexer))
      end
      Node.new(:pipeline, excl: not_op, command: command)
    end

    def parse_command(lexer)
      parse_simple_command(lexer)
    end

    CONTROL_OPERATORS = [
      TK_LOR, TK_AND, TK_LAND, TK_SEMICOLON,
      TK_SEMICOLON2, TK_SEMICOLON_AND, TK_SEMICOLON2_AND,
      TK_LPAREN, TK_RPAREN,
      TK_PIPE, TK_PIPE_AND,
      TK_NEWLINE, TK_EOS
    ].freeze
    def parse_simple_command(lexer)
      # parse assignments
      assigns = []
      while (assign = lexer.accept(/[a-zA-Z0-9][a-zA-Z0-9_]*=/, TK_ASSIGN_HEAD))
        head = lexer.peek
        value = head.blank.empty? && !CONTROL_OPERATORS.include?(head.type) ? parse_word(lexer) : nil
        assigns << Node.new(:assign, name: assign.body[0...-1], value: value)
      end

      # parse command body
      body = [parse_word(lexer)]
      body << parse_word(lexer) while !lexer.peek(*CONTROL_OPERATORS)

      Node.new(:simple_command, assigns: assigns, body: body)
    end

    def parse_word(lexer)
      if (str = lexer.next(TK_STR))
        Node.new(:str, body: str.body)
      elsif (sstr = lexer.next(TK_SQUOTE))
        Node.new(:sstr, body: sstr.body[1...-1])
      elsif (dollar_var = lexer.next(TK_DOLLAR_VAR))
        Node.new(:simple_param_ex, body: dollar_var.body[1..-1])
      elsif lexer.next(TK_DOLLAR_LBRACE)
        parse_expansion(lexer)
      else
        raise ParseError, "unexpected token: #{lexer.peek}"
      end
    end

    def parse_expansion(lexer)
      lexer.use_rules(EXPANSION_RULES) do
        # check ref `!`
        ref = !!lexer.accept(/!/, TK_NOT, allow_blank: false)
        if !(param = lexer.next(TK_VAR, allow_blank: false))
          raise ParseError, 'expect parameter'
        end

        node = if (array_ex = lexer.next(TK_BRACKET_AT, TK_BRACKET_ASTALISK, allow_blank: false))
          # array expansion
          type = ref ? :array_keys : :array_ex
          Node.new(type, array: param.body, mode: array_ex.body[1])
        elsif (prefix_match_mode = lexer.accept(/[@*]/, nil, allow_blank: false))
          raise ParseError, 'prefix matching requires `!`' if !ref
          Node.new(:prefix_ex, prefix: param.body, mode: prefix_match_mode.body)
        else
          # normal expansion
          Node.new(:param_ex, ref: ref, body: param.body)
        end
        raise ParseError, 'expect `}`' if !lexer.next(TK_RBRACE, allow_blank: false)
        node
      end
    end

    class ParseError < StandardError
    end
  end
end

require 'sharpnesh/parser/lexer'
