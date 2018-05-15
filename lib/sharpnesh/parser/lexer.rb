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
      token = peek
      return if !expected.empty? && !expected.include?(token.type)
      @next += 1
      token
    end

    # return next token (not steped)
    #
    # @return [Token]
    def peek
      if @next < @tokens.size
        @tokens[@next]
      else
        tokenize
      end
    end

    def back
      raise 'cannot back empty lexer' if @next.zero?
      @next -= 1
    end

    private

    RULES = [
      { pattern: /[a-zA-Z_]\w*/, method: :on_token, opt: TK_NAME },
      { pattern: /[ \t]+/, method: :on_token, opt: TK_BLANK }
    ].freeze

    def tokenize
      blank = ''

      return Token.new(TK_EOS, blank, nil, @line, @col) if @scanner.eos?

      RULES.each do |pattern:, method:, opt:|
        matched = @scanner.scan(pattern)
        return send(method, matched, blank, opt) if matched
      end

      raise ParseError, 'cannot recognize charactor'
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
