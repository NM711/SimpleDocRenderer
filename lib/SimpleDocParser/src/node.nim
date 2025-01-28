type NodeKind* = enum
  HEADER,
  PARAGRAPH,
  TEXT,
  LIST,
  LIST_ITEM,
  LIST_TITLE,
  LINK,
  ITALIC,
  BOLD,
  BOLD_ITALIC,
  CODE,
  IMAGE

type ListItemType* = enum
  UNORDERED,
  ORDERED,
  CHECKED

type Node* = ref object of RootObj
  kind*: NodeKind

type ValueNode* = ref object of Node
  value*: string
  
type EmphasisNode* = ref object of Node
  value*: Node

type BodyNode* = ref object of Node
  body*: seq[Node]

type CodeBlockNode* = ref object of Node
  content*: string
  language*: string

type ImageNode* = ref object of Node
  src*: string
  alt*: string
  caption*: BodyNode

type HeaderNode* = ref object of BodyNode
  depth*: int

type LinkNode* = ref object of Node
  content*: Node
  href*: string

type ListItemNode* = ref object of BodyNode
  case itemType*: ListItemType
    of ListItemType.ORDERED:
      number*: int
    of ListItemType.CHECKED:
      isInteractive*: bool
      isChecked*: bool
    else:
      discard

type ListNode* = ref object of Node
  items*: seq[ListItemNode]
