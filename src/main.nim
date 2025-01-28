import ./renderer
import ../lib/SimpleDocParser/src/parser
# import ../lib/SimpleDocParser/src/debug/printer
import std/cmdline

if paramCount() > 1 or paramCount() == 0:
  echo "Expected a single file path argument, there is either too many or two few!"
else:
  var sdrenderer = DocumentRenderer()
  var sdparser = Parser()
  var path = paramStr(1)
  sdparser.setPath(path)
  # printTokens(sdparser.getTokens())
  sdparser.execute()
  sdrenderer.execute(sdparser.getNodes())
