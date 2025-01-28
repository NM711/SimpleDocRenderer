import ../src/parser
import ../src/debug/printer

var sdparser = Parser()

sdparser.setPath("./test.sd")
printTokens(sdparser.getTokens())
sdparser.execute()

printNodes(sdparser.getNodes())
