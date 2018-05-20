class Sharpnesh::Parser
  # Namespace for constants about of token type
  module TokenType
    TK_ASSIGN = :'='
    TK_LPAREN = :'('
    TK_RPAREN = :')'
    TK_LPAREN2 = :'(('
    TK_RPAREN2 = :'))'
    TK_LBRACKET2 = :'[['
    TK_RBRACKET2 = :']]'
    TK_FOR = :for
    TK_IN = :in
    TK_SEMICOLON = :';'
    TK_DO = :do
    TK_DONE = :done
    TK_SELECT = :select
    TK_CASE = :case
    TK_SEMICOLON2 = :';;'
    TK_SEMICOLON_AND = :';&'
    TK_SEMICOLON2_AND = :';;&'
    TK_ESAC = :esac
    TK_IF = :if
    TK_THEN = :then
    TK_ELIF = :elif
    TK_ELSE = :else
    TK_FI = :fi
    TK_WHILE = :while
    TK_UNTIL = :until
    TK_TIME = :time
    TK_OPT_P = :'-p'
    TK_NOT = :'!'
    TK_PIPE = :'|'
    TK_PIPE_AND = :'|&'
    TK_LAND = :'&&'
    TK_LOR = :'||'
    TK_AND = :&
    TK_NEWLINE = :'\n'
    TK_COMMA = :','
    TK_MUL_ASSIGN = :'*='
    TK_DIV_ASSIGN = :'/='
    TK_MOD_ASSIGN = :'%='
    TK_ADD_ASSIGN = :'+='
    TK_SUB_ASSIGN = :'-='
    TK_LSHIFT_ASSIGN = :'<<='
    TK_RSHIFT_ASSIGN = :'>>='
    TK_BAND_ASSIGN = :'&='
    TK_BXOR_ASSIGN = :'^='
    TK_BOR_ASSIGN = :'|='
    TK_QUESTION = :'?'
    TK_COLON = :':'
    TK_BOR = TK_PIPE
    TK_BXOR = :'^'
    TK_BAND = TK_AND
    TK_EQL = :==
    TK_NEQ = :'!='
    TK_LEQ = :<=
    TK_REQ = :>=
    TK_LTN = :<
    TK_RTN = :>
    TK_LSHIFT = :<<
    TK_RSHIFT = :>>
    TK_ADD = :+
    TK_SUB = :-
    TK_MUL = :*
    TK_DIV = :/
    TK_MOD = :%
    TK_EXP = :**
    TK_BNOT = :~
    TK_INC = :'++'
    TK_DEC = :'--'
    TK_COND_UNARY_OP = :cond_unary_op
    TK_COND_BINARY_OP = :cond_binary_op
    TK_STR = :str
    TK_SQUOTE = :"'"
    TK_DQUOTE = :'"'
    TK_DOLLAR_SQUOTE = :"$'"
    TK_DOLLAR_DQUOTE = :'$"'
    TK_DOLLAR_LBRACE = :'${'
    TK_AT = :'@'
    TK_ASTALISK = :TK_MUL
    TK_USE_DEFAULT_VALUE = :':-'
    TK_ASSIGN_DEFAULT_VALUE = :':='
    TK_ERROR_IF_NULL = :':?'
    TK_USE_ALTERNATE_VALUE = :':+'
    TK_BRACKET_AT = :'[@]'
    TK_BRACKET_ASTALISK = :'[*]'
    TK_SHARP = :'#'
    TK_SHARP2 = :'##'
    TK_MOD2 = :'%%'
    TK_SLASH = TK_DIV
    TK_BXOR2 = :'^^'
    TK_COMMA2 = :',,'
    TK_NAME = :name
    TK_DECIAML = :decimal
    TK_DOLLAR_LPAREN = :'$('
    TK_BQUOTE = :`
    TK_DOLLAR_LPAREN2 = :'$(('
    TK_IN_LPAREN = :'<('
    TK_OUT_LPAREN = :'>('
    TK_EOS = :EOS
  end
end
