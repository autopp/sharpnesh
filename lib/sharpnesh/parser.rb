module Sharpnesh
  # Parser provides features of parsing a bash script
  #
  class Parser
    require 'sharpnesh/parser/token_type'
    include TokenType

    require 'sharpnesh/parser/parameter'
    include Parameter

    require 'sharpnesh/parser/arith'
    include Arith

    DEFAULT_RULES = [
      { pattern: /([^$|&;()<> \t\n"']|\\[$|&;()<> \t"'])+/, method: :on_token, opt: TK_STR },
      { pattern: /'([^']|(\\'))*'/, method: :on_token, opt: TK_SQUOTE },
      { pattern: /\$([0-9]|([a-zA-Z_]\w*)|[-*@#?$!])/, method: :on_token, opt: TK_DOLLAR_VAR },
      { pattern: /\${/, method: :on_token, opt: TK_DOLLAR_LBRACE },
      { pattern: /\$\(\(/, method: :on_token, opt: TK_DOLLAR_LPAREN2 },
      { pattern: /\$\(/, method: :on_token, opt: TK_DOLLAR_LPAREN },
      { pattern: /\)\)/, method: :on_token, opt: TK_RPAREN2 },
      { pattern: /\)/, method: :on_token, opt: TK_RPAREN },
      { pattern: /;/, method: :on_token, opt: TK_SEMICOLON }
    ].freeze

    def parse(io, name)
      lexer = Lexer.new(io, name)
      lexer.use_rules(DEFAULT_RULES, allow_blank: true) do
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
        parse_param_expansion(lexer)
      elsif lexer.next(TK_DOLLAR_LPAREN2)
        parse_arith_expansion(lexer)
      elsif lexer.next(TK_DOLLAR_LPAREN)
        parse_command_subst(lexer)
      else
        raise ParseError, "unexpected token: #{lexer.peek}"
      end
    end

    def parse_arith_expansion(lexer)
      body = parse_arith(lexer)
      raise ParseError, 'expect `))`' if !lexer.next(TK_RPAREN2)
      Node.new(:arith_ex, body: body)
    end

    def parse_command_subst(lexer)
      list = parse_list(lexer, TK_RPAREN)
      raise ParseErrorm 'expect `)`' if !lexer.next(TK_RPAREN)
      Node.new(:command_subst, style: '$', list: list)
    end

    def gen_word_rules(sep)
      [
        { pattern: /([^$|&;()<> \t\n"'#{sep}]|\\[$|&;()<> \t"'#{sep}])+/, method: :on_token, opt: TK_STR },
        { pattern: /'([^']|(\\'))*'/, method: :on_token, opt: TK_SQUOTE },
        { pattern: /\$([0-9]|([a-zA-Z_]\w*)|[-*@#?$!])/, method: :on_token, opt: TK_DOLLAR_VAR },
        { pattern: /\${/, method: :on_token, opt: TK_DOLLAR_LBRACE },
        { pattern: /;/, method: :on_token, opt: TK_SEMICOLON }
      ]
    end

    class ParseError < StandardError
    end
  end
end

require 'sharpnesh/parser/lexer'
