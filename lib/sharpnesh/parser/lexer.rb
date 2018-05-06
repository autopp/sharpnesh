class Sharpnesh::Parser
  # Tokenize input with state
  class Lexer
    def initialize(io, name)
      @source = io.read
      @name = name
      @tokens = []
      @next = 0
      @pos = 0
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

    private

    RULES = [
      [/^[a-zA-Z_][a-zA-Z_0-9]*/, :name]
    ].freeze

    def tokenize
      RULES.each do |pattern, type|
        pattern.match(source, pos) do |md|
          body = md[0]
          token = Token.new(type, body, @line, @col)
          @col += body.size
          @pos += body.size
          @next += 1
          @tokens << token
          break token
        end
      end

      raise ParseError, 'cannot recognize charactor'
    end

    Token = Struct.new(
      'Token', :type, :body, :break,
      :start_line, :start_col, :end_line, :end_col
    )
  end
end
