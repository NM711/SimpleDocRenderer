import lexer
import token
import node
import std/strutils

# TODO: IMPROVE ERROR MESSAGES

# 1. Location of the starting and ending positions of each node
# 2. Messages should be less generic and offer more clues as to what the error should be.

type Parser* = ref object
  lexer: Lexer = Lexer()
  index: int = 0
  tokens: seq[Token]  = @[]
  nodes: seq[Node] = @[] 

# Forward Declarations

proc parseList(self: Parser): Node
proc parseMidElement(self: Parser): Node
proc parseTopContent(self: Parser, body: var seq[Node]): void

# Parser Logic

proc peek(self: Parser, lk: int = 0): Token =
  return self.tokens[self.index + lk]

proc advance(self: Parser): void = 
  if self.peek().id != TokenID.EOF:
    self.index += 1

proc compare(self: Parser, id: TokenID): bool =
  return self.peek().id == id

proc expect(self: Parser, identifiers: seq[TokenID]): void =
  if self.peek().id notin identifiers:
    quit("Unexpected token \"" & $self.peek().id & "\" found, expected one of the following: \"" & $identifiers & "\" instead!", 1)

proc expect(self: Parser, id: TokenID): void =
  if not self.compare(id):
    quit("Unexpected token \"" & $self.peek().id & "\" found, expected \"" & $id & "\" instead!", 1)


proc isHeader(self: Parser): bool =
  return self.compare(TokenID.H1) or self.compare(TokenID.H2) or self.compare(TokenID.H3) or self.compare(TokenID.H4) or self.compare(TokenID.H5) or self.compare(TokenID.H6)

proc isTopElement(self: Parser): bool =
  return self.isHeader() or self.compare(TokenID.PARAGRAPH)

proc isMidElement(self: Parser): bool =
  return self.compare(TokenID.LIST) or self.compare(TokenID.CODE) or self.compare(TokenID.IMAGE)

proc isSubElement(self: Parser): bool =
  return self.compare(TokenID.ITALIC) or self.compare(TokenID.BOLD) or self.compare(TokenID.BOLDITALIC) or self.compare(TokenID.LINK)


# Parses multiple tokens given a constraint

proc parseText(self: Parser, constraint: proc(): bool): Node =
  var node = ValueNode(kind: NodeKind.TEXT)
  while constraint():
    node.value &= self.peek().lexeme
    self.advance()
  return node

# Parses only a single token

proc parseText(self: Parser): Node =
  var node = ValueNode(kind: NodeKind.TEXT, value: self.peek().lexeme)
  self.advance()
  return node

proc parseEmphasis(self: Parser): Node =
  var emphasisKind = case self.peek().id:
    of TokenID.BOLD: NodeKind.BOLD
    of TokenID.ITALIC: NodeKind.ITALIC
    else: NodeKind.BOLD_ITALIC
      
  self.advance()
  var node = EmphasisNode(kind: emphasisKind)
  self.expect(TokenID.LEFT_SQUARE_BRACKET)
  self.advance()
  node.value = self.parseText(proc(): bool = not self.compare(TokenID.RIGHT_SQUARE_BRACKET) and not self.compare(TokenID.EOF))
  self.expect(TokenID.RIGHT_SQUARE_BRACKET)
  self.advance()

  return node

proc parseLinkContent(self: Parser): Node =
  return case self.peek().id:
    of TokenID.ITALIC, TokenID.BOLD, TokenID.BOLDITALIC:
      self.parseEmphasis()
    else:
      self.parseText()

proc parseLink(self: Parser): Node =
  self.advance()
  var node = LinkNode(kind: NodeKind.LINK)
  
  self.expect(TokenID.LEFT_SQUARE_BRACKET)
  self.advance()
  node.content = self.parseLinkContent()
  self.expect(TokenID.COMMA)
  self.advance()
  self.expect(TokenID.STRING_LITERAL)
  node.href = self.peek().lexeme
  self.advance()
  self.expect(TokenID.RIGHT_SQUARE_BRACKET)
  self.advance()

  return node

proc parseSubElement(self: Parser): Node =
  return case self.peek().id:
    of TokenID.ITALIC, TokenID.BOLD, TokenID.BOLDITALIC:
      self.parseEmphasis()
    of TokenID.LINK:
      self.parseLink()
    else:
      quit("Invalid sub element!", 1)

proc parseImage(self: Parser): Node =
  self.advance()

  var node = ImageNode(kind: NodeKind.IMAGE)

  self.expect(TokenID.LEFT_SQUARE_BRACKET)
  self.advance()

  if self.compare(TokenID.LITERAL):
    node.alt = self.peek().lexeme
    self.advance()
    self.expect(TokenID.COMMA)
    self.advance()

  self.expect(TokenID.STRING_LITERAL)
  node.src = self.peek().lexeme
  self.advance()

  self.expect(TokenID.RIGHT_SQUARE_BRACKET)
  self.advance()

  if (self.compare(TokenID.CAPTION)):
    node.caption = BodyNode(kind: NodeKind.TEXT)
    self.advance()
    self.parseTopContent(node.caption.body)
  
  return node

proc parseCodeBlock(self: Parser): Node =
  self.advance()

  var node = CodeBlockNode(kind: NodeKind.CODE, language: "none")

  if self.compare(TokenID.LEFT_SQUARE_BRACKET):
    self.advance()
    self.expect(TokenID.STRING_LITERAL)
    node.language = self.peek().lexeme
    self.advance()
    self.expect(TokenID.RIGHT_SQUARE_BRACKET)
    self.advance()
  
  self.expect(TokenID.CODE_BLOCK_LITERAL)
  node.content = self.peek().lexeme
  self.advance()

  return node

proc parseListItem(self: Parser, itemToken: TokenID, body: var seq[Node]): void =
  while not self.compare(itemToken) and not self.isTopElement() and not self.compare(TokenID.EOF):
    var node = if self.isMidElement():
      self.parseMidElement()
    elif self.isSubElement():
      self.parseSubElement()
    else:
      self.parseText(proc(): bool = not self.compare(itemToken) and not self.isTopElement() and not self.isMidElement() and not self.isSubElement() and not self.compare(TokenID.EOF))
    body.add(node)

proc parseCheckList(self: Parser): Node =
  var node = ListNode(kind: NodeKind.LIST)

  while self.compare(TokenID.DASH):
    var listItem = ListItemNode(kind: NodeKind.LIST_ITEM, itemType: ListItemType.CHECKED)
    self.advance()

    if self.compare(TokenID.INTERACTIVE):
      listItem.isInteractive = true
      self.advance()
    
    self.expect(TokenID.LEFT_SQUARE_BRACKET)
    self.advance()

    if self.compare(TokenID.ASTERISK):
      listItem.isChecked = true
      self.advance()

    self.expect(TokenID.RIGHT_SQUARE_BRACKET)
    self.advance()

    self.parseListItem(TokenID.DASH, listItem.body)
    node.items.add(listItem)
  
  return node

proc parseOrderedList(self: Parser): Node =
  var node = ListNode(kind: NodeKind.LIST)

  while self.compare(TokenID.NUMBER_LITERAL):
    var listItem = ListItemNode(kind: NodeKind.LIST_ITEM, itemType: ListItemType.ORDERED, number: self.peek().lexeme.parseInt())
    self.advance()
    self.expect(TokenID.PERIOD)
    self.advance()
    self.parseListItem(TokenID.NUMBER_LITERAL, listItem.body)
    node.items.add(listItem)

  return node

proc parseUnorderedList(self: Parser): Node =
  var node = ListNode(kind: NodeKind.LIST)

  while self.compare(TokenID.ASTERISK):
    var listItem = ListItemNode(kind: NodeKind.LIST_ITEM, itemType: ListItemType.UNORDERED)
    self.advance()

    self.parseListItem(TokenID.ASTERISK, listItem.body)
    node.items.add(listItem)
  return node

proc parseListContent(self: Parser): Node =
  return case self.peek().id:
    of TokenID.NUMBER_LITERAL:
      self.parseOrderedList()
    of TokenID.ASTERISK:
      self.parseUnorderedList()
    of TokenID.DASH:
      self.parseCheckList()
    else:
      quit("Invalid list type...", 1)
  

proc parseList(self: Parser): Node =
  self.advance()
  self.expect(@[TokenID.NUMBER_LITERAL, TokenID.ASTERISK, TokenID.DASH])
  return self.parseListContent()

proc parseMidElement(self: Parser): Node =
  return case self.peek().id:
    of TokenID.LIST:
      self.parseList()
    of TokenID.CODE:
      self.parseCodeBlock()
    of TokenID.IMAGE:
      self.parseImage()
    else:
      quit("Invalid mid element", 1)

proc parseTopContent(self: Parser, body: var seq[Node]): void =
  proc isValidContent(): bool = not self.isTopElement() and not self.isMidElement() and not self.compare(TokenID.EOF)
  
  while isValidContent():
    var node = if self.isSubElement():
      self.parseSubElement()
    else:
      self.parseText(proc(): bool = not self.isTopElement() and not self.isMidElement() and not self.isSubElement() and not self.compare(TokenID.EOF))
  
    body.add(node)
    

proc parseHeader(self: Parser): Node =
  var node = HeaderNode(kind: NodeKind.HEADER, depth: ord(self.peek().id) - ord(TokenID.H1) + 1)
  self.advance()
  self.parseTopContent(node.body)
  return node

proc parseParagraph(self: Parser): Node =
  var node = BodyNode(kind: NodeKind.PARAGRAPH)
  self.advance()
  self.parseTopContent(node.body)
  return node

proc parseTopElement(self: Parser): Node =
  return case self.peek().id:
    of TokenID.H1 .. TokenID.H6:
      self.parseHeader()
    else:
      self.parseParagraph()

proc parseElement(self: Parser): Node =
  return 
    if self.isSubElement():
      self.parseSubElement()
    elif self.isMidElement():
      self.parseMidElement()
    elif self.isTopElement():
      self.parseTopElement()
    else:
      quit("Invalid top element!")

proc parse(self: Parser): Node =
  return self.parseElement()
      
proc clear*(self: Parser): void =
  self.lexer.clear()
  self.index = 0
  self.tokens = @[]
  self.nodes = @[]
 
proc setPath*(self: Parser, path: string): void = 
  self.lexer.setPath(path)
  self.lexer.execute()
  self.tokens = self.lexer.getTokens()

proc getTokens*(self: Parser): seq[Token] =
  return self.tokens

proc getNodes*(self: Parser): seq[Node] =
  return self.nodes

proc execute*(self: Parser): void =
  while self.peek().id != TokenID.EOF:
    self.nodes.add(self.parse())
