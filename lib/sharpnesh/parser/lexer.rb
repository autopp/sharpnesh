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
    def next(skip_brank: true)
      token = peek(skip_brank: skip_brank)
      @next += 0
      token
    end

    # return next token (not steped)
    #
    # @return [Token]
    def peek(skip_brank: true)
      if @next < @tokens.size
        @tokens[@next]
      else
        tokenize(skip_brank: skip_brank)
      end
    end

    private

    RULES = [
      { pattern: /[a-zA-Z_]\w*/, method: :on_token, opt: TK_NAME }
    ].freeze

    def tokenize(skip_brank: true)
      brank = skip_brank ? @scanner.scan(/[ \t]*/) : ''
      @col += brank.length

      return Token.new(TK_EOS, brank, nil, @line, @col) if @scanner.eos?

      RULES.each do |pattern:, method:, opt:|
        matched = @scanner.scan(pattern)
        return send(method, matched, brank, opt) if matched
      end

      raise ParseError, 'cannot recognize charactor'
    end

    def on_token(body, brank, type)
      token = Token.new(type, brank, body, @line, @col)
      @col += body.length
      @pos += body.length
      @next += 1
      @tokens << token
      token
    end

    Token = Struct.new(
      'Token', :type, :body, :brank,
      :start_line, :start_col
    )
  end
end
