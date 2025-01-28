import std/strutils
import ../node

type PrinterAST* = ref object
  depth: int

method accept(self: Node, visitor: PrinterAST): void {.base.}
method accept(self: BodyNode, visitor: PrinterAST): void

proc printNode(self: PrinterAST, kind: NodeKind, value: string = ""): void =
  for i in countup(0, self.depth):
    stdout.write("-")
  stdout.write(" ")

  if value.len() > 0:
    stdout.write(kind, " -> ", value)
  else:
    stdout.write(kind)

  stdout.write("\n")

proc visit(self: PrinterAST, node: Node): void =
  self.printNode(node.kind)
  
proc visit(self: PrinterAST, node: ValueNode): void =
  self.printNode(node.kind, node.value.replace("\n", "\\n"))
  
proc visit(self: PrinterAST, node: BodyNode): void =
  self.printNode(node.kind)
  self.depth += 1
  
  for n in node.body:
    n.accept(self)

  self.depth -= 1
    
proc visit(self: PrinterAST, node: ListItemNode): void =
  self.printNode(node.kind, $node.itemType)
  self.depth += 1
  
  for n in node.body:
    n.accept(self)
  
  self.depth -= 1

proc visit(self: PrinterAST, node: ListNode): void =
  self.printNode(node.kind)
  self.depth += 1

  for n in node.items:
    n.accept(self)

  self.depth -= 1
  
proc visit(self: PrinterAST, node: CodeBlockNode): void =
  self.printNode(node.kind, node.language)
  
proc visit(self: PrinterAST, node: EmphasisNode): void =
  self.printNode(node.kind)
  self.depth += 1
  node.value.accept(self)
  self.depth -= 1

proc visit(self: PrinterAST, node: LinkNode): void =
  self.printNode(node.kind, node.href)
  self.depth += 1
  node.content.accept(self)
  self.depth -= 1
  
proc visit(self: PrinterAST, node: ImageNode): void =
  self.printNode(node.kind, node.src)
  self.depth += 1
  node.caption.accept(self)
  self.depth -= 1
  
proc print*(self: PrinterAST, nodes: seq[Node]): void =
  for node in nodes:
    node.accept(self)

method accept(self: Node, visitor: PrinterAST): void {.base.} =
  visitor.visit(self)
  
method accept(self: ValueNode, visitor: PrinterAST): void =
  visitor.visit(self)

method accept(self: BodyNode, visitor: PrinterAST): void =
  visitor.visit(self)

method accept(self: ListItemNode, visitor: PrinterAST): void =
  visitor.visit(self)
  
method accept(self: ListNode, visitor: PrinterAST): void =
  visitor.visit(self)

method accept(self: CodeBlockNode, visitor: PrinterAST): void =
  visitor.visit(self)

method accept(self: LinkNode, visitor: PrinterAST): void =
  visitor.visit(self)

method accept(self: EmphasisNode, visitor: PrinterAST): void =
  visitor.visit(self)
 
method accept(self: ImageNode, visitor: PrinterAST): void =
  visitor.visit(self)
 
