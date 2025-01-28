import token except Location
import std/tables
import std/strutils

type LexerState = enum
  START,
  EXIT,
  EXPECTED_REPEAT,
  ESCAPE,
  CODE_BLOCK_OPEN,
  CODE_BLOCK_CLOSE,
  STRING,
  SPECIAL,
  ELEMENT,
  ALPHABET,
  DIGIT,
  WS

let keywords*: Table[string, TokenID] = {
  "@h1": TokenID.H1,
  "@h2": TokenID.H2,
  "@h3": TokenID.H3,
  "@h4": TokenID.H4,
  "@h5": TokenID.H5,
  "@h6": TokenID.H6,
  "@paragraph": TokenID.PARAGRAPH,
  "@link":  TokenID.LINK,
  "@code": TokenID.CODE,
  "@list": TokenID.LIST,
  "@img": TokenID.IMAGE,
  "@caption": TokenID.CAPTION,
  "@interactive": TokenID.INTERACTIVE,
  "@italic": TokenID.ITALIC,
  "@bold": TokenID.BOLD,
  "@bolditalic": TokenID.BOLDITALIC,
  "@i": TokenID.ITALIC,
  "@b": TokenID.BOLD,
  "@bi": TokenID.BOLDITALIC,
}.toTable()

# let attributtedElements: seq[string] = @["@bold", "@bolditalic", "@italic", "@i", "@b", "@bi", "@link", "@img", "@code"]

type Lexer* = ref object
  index: int = 0
  tokens: seq[Token] = @[]
  constructedLexeme: string = ""
  file: string = ""
  currentPosition: Position = Position(line: 1, column: 1)

proc peek(self: Lexer): char =
  return self.file[self.index]

proc updatePosition(self: Lexer): void =
  self.currentPosition.column += 1
  if (self.peek() == '\n'):
    self.currentPosition.line += 1
    self.currentPosition.column = 1

proc advance(self: Lexer): void =
  self.updatePosition()
  if self.peek() != '\0':
    self.index += 1

proc appendAdvance(self: Lexer): void =
  self.constructedLexeme &= self.peek()
  self.advance()

proc pushToken(self: Lexer, id: TokenID, state: var LexerState): void =
  self.tokens.add(Token(id: id, lexeme: self.constructedLexeme, position: self.currentPosition))
  self.constructedLexeme = ""
  state = LexerState.START

proc pushToken(self: Lexer, id: TokenID): void =
  self.tokens.add(Token(id: id, lexeme: self.constructedLexeme, position: self.currentPosition))
  self.constructedLexeme = ""

proc getInitialState(self: Lexer): LexerState =
  return case self.peek():
    of '\0':
      LexerState.EXIT
    of ' ', '\n', '\t':
      LexerState.WS
    of '"':
      LexerState.STRING
    # State for tokens that must view the next character in line to decide what they are
    of '<', '\\':
      LexerState.EXPECTED_REPEAT
    of '@':
      LexerState.ELEMENT
    of 'a' .. 'z', 'A' .. 'Z':
      LexerState.ALPHABET
    of '0' .. '9':
      LexerState.DIGIT
    of '[', ']', ',', '.', '*', '-':
      LexerState.SPECIAL
    else:
      LexerState.ALPHABET

proc consumeRepeated(self: Lexer, current: char, state: var LexerState, outcomeState: LexerState, failureState: LexerState = LexerState.START): void =
  if self.peek() == current:
    self.advance()
    state = outcomeState
  else:
    state = failureState

proc setPath*(self: Lexer, path: string): void =
  try:
    self.file = readFile(path) & ' ' & '\0'
  except IOError:
    quit(getCurrentExceptionMsg(), 1)

proc getTokens*(self: Lexer): seq[Token] =
  return self.tokens

proc clear*(self: Lexer): void =
  self.index = 0
  self.file = ""
  self.constructedLexeme = ""
  self.currentPosition = Position(line: 1, column: 1)
  self.tokens = @[]

proc execute*(self: Lexer): void =
  if len(self.file) == 0:
    quit("Cannot parse file becaus no file path was provided!", 1)

  var state: LexerState = LexerState.START

  while self.peek() != '\0':
    case state:
      of LexerState.START:
        state = self.getInitialState()
      
      of LexerState.EXIT:
        echo self.constructedLexeme
        return

      of LexerState.EXPECTED_REPEAT:
        case self.peek():
          of '\\':
            self.advance()
            self.consumeRepeated('\\', state, LexerState.ESCAPE)
          of '<':
            self.advance()
            self.consumeRepeated('<', state, LexerState.CODE_BLOCK_OPEN)
          of '>':
            self.advance()
            self.consumeRepeated('>', state, LexerState.CODE_BLOCK_CLOSE, LexerState.CODE_BLOCK_OPEN)
            if state == LexerState.CODE_BLOCK_OPEN:
              self.constructedLexeme &= ">"
          else:
            discard

      of LexerState.ESCAPE:
        case self.peek():
          of '\0':
            self.pushToken(TokenID.LITERAL, state)
          of ' ':
            self.appendAdvance()
          of '\n':
            self.appendAdvance()
            self.pushToken(TokenID.LITERAL, state)
          else:
            self.appendAdvance()

      of LexerState.ALPHABET:
        case self.peek():
          of '@', '[', ']', ',', '.', '*', '-', '\0':
            self.pushToken(TokenID.LITERAL, state)
          of '\n':
            self.appendAdvance()
            self.pushToken(TokenID.LITERAL, state)
          of '\\':
            state = LexerState.START
          else:
            self.appendAdvance()

      of LexerState.DIGIT:
        case self.peek():
          of '0' .. '9':
            self.appendAdvance()
          else:
            self.pushToken(TokenID.NUMBER_LITERAL, state)
      
      of LexerState.STRING:
        case self.peek():
          of '"':
            if self.constructedLexeme.len() == 0:
              self.appendAdvance()
            else:
              self.constructedLexeme.removePrefix('"')
              self.advance()
              self.pushToken(TokenID.STRING_LITERAL, state)
          of '\0', '\n', '@':
            self.pushToken(TokenID.LITERAL, state)
          else:
            self.appendAdvance()        

      of LexerState.CODE_BLOCK_OPEN:
        case self.peek():
          of '>':
            state = LexerState.EXPECTED_REPEAT
          of '\0':
            self.pushToken(TokenID.LITERAL, state)
          else:
            self.appendAdvance()

      of LexerState.CODE_BLOCK_CLOSE:
        self.pushToken(TokenID.CODE_BLOCK_LITERAL, state)

      of LexerState.SPECIAL:
        var id = case self.peek():
          of '[':
            TokenID.LEFT_SQUARE_BRACKET
          of ']':
            TokenID.RIGHT_SQUARE_BRACKET
          of '-':
            TokenID.DASH
          of '*':
           TokenID.ASTERISK
          of '.':
            TokenID.PERIOD
          of ',':
            TokenID.COMMA
          else:
            state = LexerState.START
            continue


        self.appendAdvance()

        # consume a single whitespace
        if self.peek() == ' ' or self.peek() == '\n':
          self.appendAdvance()

        while self.peek() == ' ':
          self.advance()
          if self.peek() == '\n':
            self.appendAdvance()
        
        self.pushToken(id)


      of LexerState.ELEMENT:
        case self.peek():
          of '@', 'a' .. 'z', 'A' .. 'Z', '0' .. '9':
            self.appendAdvance()
          else:
            if self.constructedLexeme in keywords:  
              self.pushToken(keywords[self.constructedLexeme], state)
            else:
              self.pushToken(TokenID.LITERAL, state)

      of LexerState.WS:
        case self.peek():
          of '\n', ' ', '\t':
            self.advance()
          else:
            state = LexerState.START

  self.constructedLexeme = "EOF"
  self.pushToken(TokenID.EOF, state)
