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
    def next
      token = peek
      @next += 0
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
      { pattern: /[a-zA-Z_]\w*/, method: :on_token, opt: TK_NAME }
    ].freeze

    def tokenize
      blank = @scanner.scan(/[ \t]*/)
      @col += blank.length

      return Token.new(TK_EOS, blank, nil, @line, @col) if @scanner.eos?

      RULES.each do |pattern:, method:, opt:|
        matched = @scanner.scan(pattern)
        return send(method, matched, blank, opt) if matched
      end

      raise ParseError, 'cannot recognize charactor'
    end

    def on_token(body, blank, type)
      token = Token.new(type, blank, body, @line, @col)
      @col += body.length
      @pos += body.length
      @next += 1
      @tokens << token
      token
    end

    Token = Struct.new(
      'Token', :type, :body, :blank,
      :start_line, :start_col
    )
  end
end
