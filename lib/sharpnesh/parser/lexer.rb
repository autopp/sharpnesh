require 'strscan'

class Sharpnesh::Parser
  # Tokenize input with state
  class Lexer
    include TokenType

    def initialize(io, name)
      @scanner = StringScanner.new(io.read)
      @name = name
      @tokens = []
      @next = 0
      @line = 1
      @col = 1
      @rules_stack = []
    end

    # return next token
    #
    # @return [Token]
    def next(*expected, allow_blank: true)
      return if !(token = peek(*expected, allow_blank: allow_blank))
      @next += 1
      token
    end

    # return next token (not steped)
    #
    # @return [Token]
    def peek(*expected, allow_blank: true)
      token = if @next < @tokens.size
        @tokens[@next]
      else
        tokenize
      end
      (expected.empty? || expected.include?(token.type)) && (allow_blank || token.blank.empty?) ? token : nil
    end

    def accept(pattern, type, allow_blank: true)
      reset_buffer

      rollback_pos = @scanner.pos
      blank = allow_blank ? @scanner.scan(/[ \t]*/) : ''
      if !(body = @scanner.scan(pattern))
        @scanner.pos = rollback_pos
        return
      end
      @col += body.length + blank.length
      token = Token.new(type, body, blank, @line, @col)
      @tokens << token
      @next += 1
      token
    end

    # back to previous token
    #
    def back
      raise 'cannot back empty lexer' if @next.zero?
      @next -= 1
    end

    # return whether all tokens are consumed
    #
    # @return [Boolean]
    #
    def eos?
      @next > 0 && @tokens[@next - 1].type == TK_EOS
    end

    def use_rules(rules)
      @rules_stack.push(rules)
      begin
        yield
      ensure
        @rules_stack.pop
      end
    end

    private

    DEFAULT_RULES = [
      { pattern: /([^$|&;()<> \t\n"']|\\[$|&;()<> \t"'])+/, method: :on_token, opt: TK_STR },
      { pattern: /'([^']|(\\'))*'/, method: :on_token, opt: TK_SQUOTE },
      { pattern: /;/, method: :on_token, opt: TK_SEMICOLON }
    ].freeze

    def tokenize
      blank = @scanner.scan(/[ \t]*/)
      @col += blank.length
      return Token.new(TK_EOS, blank, nil, @line, @col) if @scanner.eos?

      @rules_stack.last.each do |pattern:, method:, opt:|
        matched = @scanner.scan(pattern)
        return send(method, matched, blank, opt) if matched
      end

      raise ParseError, "cannot recognize charactor `#{@scanner.rest[0]}`"
    end

    def on_token(body, blank, type)
      token = Token.new(type, body, blank, @line, @col)
      @col += body.length
      @tokens << token
      token
    end

    def reset_buffer
      @tokens.pop(@tokens.size - @next).each do |token|
        body = token.body
        @col -= body.size
        @scanner.pos -= body.bytesize
      end
    end

    # Token infomation generated by Lexer
    #
    class Token
      attr_reader :type, :body, :blank, :start_line, :start_col

      def initialize(type, body, blank, start_line, start_col)
        @type = type
        @body = body
        @blank = blank
        @start_line = start_line
        @start_col = start_col
      end

      def to_s
        type.to_s
      end
    end
  end
end
