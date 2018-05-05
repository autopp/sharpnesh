class Sharpnesh::Parser
  # Tokenize input with state
  class Lexer
    def initialize(io, name)
      @source = io.read
      @name = name
      @tokens = []
      @next = 0
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

    def tokenize
      raise NotImplementedError
    end

    Token = Struct.new('Token', :type, :body, :line, :col)
  end
end
