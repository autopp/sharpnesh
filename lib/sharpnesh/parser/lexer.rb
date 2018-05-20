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
    end

    # return next token
    #
    # @return [Token]
    def next(*expected)
      return unless (token = peek(*expected))
      @next += 1
      token
    end

    # return next token (not steped)
    #
    # @return [Token]
    def peek(*expected)
      token = if @next < @tokens.size
        @tokens[@next]
      else
        tokenize
      end
      expected.empty? || expected.include?(token.type) ? token : nil
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

    private

    RULES = [
      { pattern: /[a-zA-Z_]\w*/, method: :on_token, opt: TK_NAME },
      { pattern: /;/, method: :on_token, opt: TK_SEMICOLON }
    ].freeze

    def tokenize
      blank = @scanner.scan(/[ \t]*/)
      @col += blank.length
      return Token.new(TK_EOS, blank, nil, @line, @col) if @scanner.eos?

      RULES.each do |pattern:, method:, opt:|
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

    Token = Struct.new(
      'Token', :type, :body, :blank,
      :start_line, :start_col
    )
  end
end
