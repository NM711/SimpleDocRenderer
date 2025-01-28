from ../token import Token
import ../node
import ./printerAST

proc printTokens*(tokens: seq[Token]) = 
  for token in tokens:
    echo token
   
proc printNodes*(nodes: seq[Node]): void =
  var printer = PrinterAST()
  printer.print(nodes)
