type TokenID* = enum 
  COMMA,
  PERIOD,
  ASTERISK,
  DASH,
  LEFT_SQUARE_BRACKET,
  RIGHT_SQUARE_BRACKET,  
  STRING_LITERAL,
  NUMBER_LITERAL,
  CODE_BLOCK_LITERAL,
  LITERAL,
  NEWLINE,  
  PARAGRAPH,
  BOLD,
  BOLDITALIC,
  ITALIC,
  LINK,
  LIST,
  IMAGE,
  CAPTION,
  CODE,
  INTERACTIVE,
  H1,
  H2,
  H3,
  H4,
  H5,
  H6,
  EOF
    
type Position* = object
  line*: uint
  column*: uint

type Location* = object
  starting*: Position
  ending*: Position

type Token* = object
  id*: TokenID
  lexeme*: string
  position*: Position
