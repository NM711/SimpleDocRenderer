import std/terminal
import std/strutils
import packages/docutils/highlite
import ../lib/SimpleDocParser/src/node

type DocumentRenderer* = ref object

method accept(self: Node, visitor: DocumentRenderer): void {.base.}
method accept(self: BodyNode, visitor: DocumentRenderer): void
method accept(self: ValueNode, visitor: DocumentRenderer): void

proc indent(self:DocumentRenderer): void =
  stdout.write("  ")
      

proc visit(self: DocumentRenderer, node: Node): void =
  stdout.writeLine(node.kind)

proc visit(self: DocumentRenderer, node: ValueNode): void =
  for c in node.value:
    stdout.write(c)
    if c == '\n':
      self.indent()

  stdout.resetAttributes()
        
proc visit(self: DocumentRenderer, node: BodyNode): void =
  self.indent()
  for n in node.body:
    n.accept(self)


  if node.kind == NodeKind.PARAGRAPH:
    stdout.write("\n\n")

proc visit(self: DocumentRenderer, node: EmphasisNode): void =
  case node.kind:
    of NodeKind.ITALIC:
      stdout.setForegroundColor(fgWhite)
      stdout.setStyle({styleUnderscore})
    of NodeKind.BOLD:
      stdout.setForegroundColor(fgBlack)
      stdout.setBackgroundColor(bgWhite, false)
    else:
      stdout.setForegroundColor(fgBlack)
      stdout.setBackgroundColor(bgWhite, false)
      stdout.setStyle({styleUnderscore})
      
  node.value.accept(self)

proc visit(self: DocumentRenderer, node: CodeBlockNode): void =
  stdout.styledWrite(fgYellow, "[")
  stdout.styledWrite(fgGreen, node.language)
  stdout.styledWrite(fgYellow, "]")
  stdout.styledWrite(fgYellow, ">".repeat(((int)terminalWidth() / 2) - (node.language.len() + 2)))

  if node.content[0] != '\n':
    stdout.write("\n")

  var toknizr: GeneralTokenizer
  initGeneralTokenizer(toknizr, node.content)
  var sourceLang: SourceLanguage = getSourceLanguage(node.language)
  
  if sourceLang == SourceLanguage.langNone:
    stdout.styledWrite(fgWhite, node.content)
  else:
    while true:
      getNextToken(toknizr, sourceLang)
      var currentLexeme: string = substr(node.content, toknizr.start, toknizr.length + toknizr.start - 1)
      case toknizr.kind
        of TokenClass.gtKeyword:
          stdout.styledWrite(fgRed, currentLexeme)
        of TokenClass.gtIdentifier:
          stdout.styledWrite(fgGreen, currentLexeme)
        of TokenClass.gtStringLit:
          stdout.styledWrite(fgYellow, currentLexeme)
        of TokenClass.gtDecNumber, TokenClass.gtFloatNumber, TokenClass.gtHexNumber, TokenClass.gtOctNumber, TokenClass.gtBinNumber:
          stdout.styledWrite(fgMagenta, currentLexeme)
        of TokenClass.gtOperator:
          stdout.styledWrite(fgCyan, currentLexeme)
        of TokenClass.gtEof: break
        else:
          stdout.styledWrite(fgWhite, currentLexeme)

  if node.content[node.content.len() - 1] != '\n':
    stdout.write("\n")
  
  stdout.styledWrite(fgYellow, "<".repeat((int)terminalWidth() / 2))
  
  stdout.write("\n\n")

proc visit(self: DocumentRenderer, node: LinkNode): void =
  node.content.accept(self)

  stdout.styledWrite(fgWhite, "[")
  stdout.setStyle({styleUnderscore})
  stdout.styledWrite(fgBlue, node.href)
  stdout.styledWrite(fgWhite, "] ")
  
proc visit(self: DocumentRenderer, node: ImageNode): void =
  stdout.styledWrite(fgWhite, "[")
  stdout.write(fgWhite, node.alt)
  stdout.write(", ")
  stdout.setStyle({styleUnderscore})
  stdout.styledWrite(fgBlue, node.src)
  stdout.styledWrite(fgWhite, "]\n")

  node.caption.accept(self)
  
proc visit(self: DocumentRenderer, node: ListItemNode): void =
  self.indent()
  case node.itemType:
    of ListItemType.ORDERED:
      stdout.styledWrite(fgYellow, $node.number & ". ")
    of ListItemType.UNORDERED:
      stdout.styledWrite(fgGreen, "• ")
    of ListItemType.CHECKED:
      stdout.styledWrite(fgWhite, "[ ")
      if node.isChecked:
        stdout.styledWrite(fgRed, "*")
      stdout.styledWrite(fgWhite, " ]")

  for n in node.body:
    n.accept(self)

  stdout.write("\n")  
proc visit(self: DocumentRenderer, node: ListNode): void =
  for n in node.items:
    n.accept(self) 
    
proc visit(self: DocumentRenderer, node: HeaderNode): void =
  var tags = "#".repeat(node.depth)

  case node.depth:
    of 1:
      stdout.setForegroundColor(fgBlue)
    of 2:
      stdout.setForegroundColor(fgCyan)
    of 3:
      stdout.setForegroundColor(fgMagenta)
    of 4:
      stdout.setForegroundColor(fgYellow)
    of 5:
      stdout.setForegroundColor(fgRed)
    else:
      stdout.setForegroundColor(fgGreen)

  self.indent()
  
  stdout.write(tags & " ")

  for n in node.body:
    n.accept(self)
    
  stdout.resetAttributes() 
  stdout.write("\n") 
   
proc execute*(self: DocumentRenderer, nodes: seq[Node]): void =
  for node in nodes:
    node.accept(self)

method accept(self: Node, visitor: DocumentRenderer): void {.base.} = 
  visitor.visit(self)

method accept(self: ValueNode, visitor: DocumentRenderer): void = 
  visitor.visit(self)

method accept(self: BodyNode, visitor: DocumentRenderer): void = 
  visitor.visit(self)

method accept(self: HeaderNode, visitor: DocumentRenderer): void = 
  visitor.visit(self)
  
method accept(self: EmphasisNode, visitor: DocumentRenderer): void = 
  visitor.visit(self)
  
method accept(self: ListNode, visitor: DocumentRenderer): void =
  visitor.visit(self)
  
method accept(self: ListItemNode, visitor: DocumentRenderer): void =
  visitor.visit(self)
  
method accept(self: CodeBlockNode, visitor: DocumentRenderer): void =
  visitor.visit(self)

method accept(self: LinkNode, visitor: DocumentRenderer): void =
  visitor.visit(self)
  
method accept(self: ImageNode, visitor: DocumentRenderer): void =
  visitor.visit(self)
