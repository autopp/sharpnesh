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
    def next(*expected, allow_blank: @allow_blank)
      return if !(token = peek(*expected, allow_blank: allow_blank))
      @next += 1
      block_given? ? yield(token) : token
    end

    # return next token (not steped)
    #
    # @return [Token]
    def peek(*expected, allow_blank: @allow_blank)
      token = tokenize(allow_blank: allow_blank)
      return if !token || !expected.empty? && !expected.include?(token.type) || !allow_blank && !token.blank.empty?
      block_given? ? yield(token) : token
    end

    def accept(pattern, type, allow_blank: @allow_blank)
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

    def skip_blank
      return if @tokens.size > @next
      @scanner.scan(/[ \t]*/)
      nil
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

    def use_rules(rules, allow_blank: @allow_blank)
      reset_buffer
      before_allow_blank = @allow_blank
      @allow_blank = allow_blank
      @rules_stack.push(rules)
      begin
        yield
      ensure
        @allow_blank = before_allow_blank
        @rules_stack.pop
      end
    end

    private

    def tokenize(allow_blank:)
      return @tokens[@next] if @next < @tokens.size
      blank = allow_blank ? @scanner.scan(/[ \t]*/) : ''
      @col += blank.length
      return Token.new(TK_EOS, blank, nil, @line, @col) if @scanner.eos?

      @rules_stack.last.each do |pattern:, method:, opt:|
        matched = @scanner.scan(pattern)
        return send(method, matched, blank, opt) if matched
      end

      nil
    end

    def on_token(body, blank, type)
      token = Token.new(type, body, blank, @line, @col)
      @col += body.length
      @tokens << token
      token
    end

    def on_newline(body, blank, type)
      token = Token.new(type, body, blank, @line, @col)
      @col = 0
      @line += 1
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
