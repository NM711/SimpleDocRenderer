# SimpleDoc

Simple doc is a small markup language I created after having a hard time parsing Markdown.

It aims to be simple to write and read, as well as simple enough for developers to write implementations for.

The entire grammar is meant to be parasable with an LL(k) parser, so a simple recursive descent should do.
Additionally I will make sure a BNF grammar is included with this repository.

### Headers

```
  @h1 Header
  
  @h2 Header
  
  @h3 Header
  
  @h4 Header
  
  @h5 Header
  
  @h6 Header
```

### Paragraphs

```
  @paragraph Content Here
```

### Emphasis

```
  @italic [Emphasis]
  @bold [Emphasis]
  @italicbold [Emphasis]
```

**OR** using the shorthand labels

```
  @i [Emphasis]
  @b [Emphasis]
  @bi [Emphasis] 
```

### Link


Links follow the following structure:

```
  @link [<TEXT>, "<URL>"]
```
#### **Example**
```
  @link [@bold[Hello World], "http://example.com"]
```
### Image

Images follow the following structures:

```
  @img [<ALT>, "<SRC>"]
```

```
  @img ["<SRC>"]
```

Images may also have a sub caption element such as 

```
  @img [<ALT>, "<SRC>"]
    @caption <CONTENT>
```


#### **Example**

```
  @img [Mountains, "http://example.com"]
    @caption Great mountains somewhere on @bolditalic[Earth].
```

### Code Blocks

Code blocks can follow the following structures:

```
  @code ["<LANGUAGE>"] << <CONTENT> >>
```

**OR**

```
  @code << <CONTENT> >>  
```

#### **Example**

```
  @code ["javascript"]

  <<
    function main() {
      console.log("Hello World!")
    }
  >>
```

### Lists



Lists follow the following structure:

```
  @list 
    <LIST_TYPE> <ITEM>
```

Lists are also nestable.
```
  @list 
    <LIST_TYPE> @list
      <LIST_TYPE> <ITEM>
```

#### Unordered Lists

```
  @list 
    * Item1
    * Item2
    * Item3 
```

#### Ordered Lists

```
  @list 
    1. Item1
    2. Item2
    3. Item3 
```

#### Check Lists

\\* In a checklist bracket means that the item is checked

```
  @list 
    - [] Item1
    - [] Item2
    - [*] Item3 
```

By default checked lists are disabled for interaction, but if a list item has the ***@interactive*** tag, 
it means a user will be able to interact with it when its compiled to HTML.

```
  @list 
    - [] Item1
    - [] Item2
    - @interactive[*] Item3 
```

##### **Nested Lists Example**

```
    @list 
    * @item
      1. SubItem1
      2. SubItem2
      3. SubItem3
    * Item2
    * Item3 
```

## Escaping Special Characters

Special characters can be escaped with a ***\\\\*** prefix


### **Example**

```
  \\@italic[Escaped]
```

## Example Document

```
@h1 Test File

@paragraph
  This is a generic test file to validate the functionality of the markup language parser.

@h2 Section 1: Overview

@paragraph
  This section provides an example paragraph with inline styles and escaped characters.

  @bold[This is bold text.]

  Escaping special syntax: \\@link[@bold[example] "https://example.com"]

  Brackets in normal context: [Sample Text]

@h2 Section 2: Lists

@h3 Unordered List
  @list
    * First item
    * Second item
    * Third item

@h3 Ordered List
  @list
    1. Step one
    2. Step two
    3. Step three

@h2 Section 3: Code Examples

@code <<Generic Code Block>>

@code ["javascript"]

<<
  function example() {
    console.log("Hello, world!");
  }
>>  
```
# TODO:

1. Improved error messages
