// Example: Building and navigating a CST for S-expressions
// Input: (let x (+ 1 2))

// Define syntax kinds for S-expressions
fn root_kind() -> @cst.SyntaxKind { @cst.SyntaxKind::new(10) }
fn list_kind() -> @cst.SyntaxKind { @cst.SyntaxKind::new(11) }
fn atom_kind() -> @cst.SyntaxKind { @cst.SyntaxKind::new(12) }
fn lparen_kind() -> @cst.SyntaxKind { @cst.SyntaxKind::new(13) }
fn rparen_kind() -> @cst.SyntaxKind { @cst.SyntaxKind::new(14) }
fn whitespace_kind() -> @cst.SyntaxKind { @cst.SyntaxKind::new(15) }

///|
fn main {
  // Build CST for: (let x (+ 1 2))
  let builder = @cst.GreenNodeBuilder::new()

  builder.start_node(root_kind())
  builder.start_node(list_kind())  // (let x (+ 1 2))
  builder.token(lparen_kind(), "(")
  builder.token(atom_kind(), "let")
  builder.token(whitespace_kind(), " ")
  builder.token(atom_kind(), "x")
  builder.token(whitespace_kind(), " ")

  // Nested list: (+ 1 2)
  builder.start_node(list_kind())
  builder.token(lparen_kind(), "(")
  builder.token(atom_kind(), "+")
  builder.token(whitespace_kind(), " ")
  builder.token(atom_kind(), "1")
  builder.token(whitespace_kind(), " ")
  builder.token(atom_kind(), "2")
  builder.token(rparen_kind(), ")")
  builder.finish_node()

  builder.token(rparen_kind(), ")")
  builder.finish_node()
  builder.finish_node()

  let green = builder.finish()

  // Navigate with red tree
  let root = @cst.SyntaxNode::new_root(green)

  println("CST Structure:")
  println("==============")
  print_tree(root, 0)

  println("")
  println("Text ranges:")
  println("============")
  print_ranges(root, 0)
}

///|
fn print_tree(node : @cst.SyntaxNode, depth : Int) -> Unit {
  let indent = String::make(depth * 2, ' ')
  println("\{indent}Node(kind=\{node.kind().raw()})")

  for child in node.children() {
    match child {
      @cst.SyntaxElement::Node(n) => print_tree(n, depth + 1)
      @cst.SyntaxElement::Token(t) => {
        let token_indent = String::make((depth + 1) * 2, ' ')
        println("\{token_indent}Token(kind=\{t.kind().raw()}, text=\"\{t.text()}\")")
      }
    }
  }
}

///|
fn print_ranges(node : @cst.SyntaxNode, depth : Int) -> Unit {
  let indent = String::make(depth * 2, ' ')
  let range = node.text_range()
  println("\{indent}Node: [\{range.start().to_int()}, \{range.end().to_int()})")

  for child in node.children() {
    match child {
      @cst.SyntaxElement::Node(n) => print_ranges(n, depth + 1)
      @cst.SyntaxElement::Token(t) => {
        let token_indent = String::make((depth + 1) * 2, ' ')
        let r = t.text_range()
        println("\{token_indent}Token \"\{t.text()}\": [\{r.start().to_int()}, \{r.end().to_int()})")
      }
    }
  }
}
