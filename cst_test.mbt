// Test syntax kinds for S-expression
fn root() -> SyntaxKind { SyntaxKind::new(10) }
fn list() -> SyntaxKind { SyntaxKind::new(11) }
fn atom() -> SyntaxKind { SyntaxKind::new(12) }
fn lparen() -> SyntaxKind { SyntaxKind::new(13) }
fn rparen() -> SyntaxKind { SyntaxKind::new(14) }
fn whitespace() -> SyntaxKind { SyntaxKind::new(15) }

///|
test "SyntaxKind basic operations" {
  let kind = SyntaxKind::new(42)
  assert_eq(kind.raw(), 42)
  assert_eq(SyntaxKind::eof().raw(), 0)
  assert_eq(SyntaxKind::syntax_error().raw(), 2)
}

///|
test "TextSize arithmetic" {
  let a = TextSize::from_int(10)
  let b = TextSize::from_int(5)
  assert_eq((a + b).to_int(), 15)
  assert_eq((a - b).to_int(), 5)
  assert_eq(TextSize::zero().to_int(), 0)
}

///|
test "TextRange operations" {
  let range = TextRange::at(TextSize::from_int(5), TextSize::from_int(10))
  assert_eq(range.start().to_int(), 5)
  assert_eq(range.end().to_int(), 15)
  assert_eq(range.len().to_int(), 10)
  assert_eq(range.is_empty(), false)
  assert_eq(range.contains(TextSize::from_int(7)), true)
  assert_eq(range.contains(TextSize::from_int(20)), false)
}

///|
test "GreenToken creation" {
  let token = GreenToken::new(atom(), "hello")
  assert_eq(token.kind(), atom())
  assert_eq(token.text(), "hello")
  assert_eq(token.text_len().to_int(), 5)
}

///|
test "GreenNode creation" {
  let token1 = GreenToken::new(atom(), "foo")
  let token2 = GreenToken::new(atom(), "bar")
  let children = @array.from_array(
    [
      GreenChild::Token(rel_offset=TextSize::zero(), token=token1),
      GreenChild::Token(rel_offset=TextSize::from_int(3), token=token2),
    ],
  )
  let node = GreenNode::new(list(), children)
  assert_eq(node.kind(), list())
  assert_eq(node.text_len().to_int(), 6)
  assert_eq(node.children_count(), 2)
}

///|
test "GreenNodeBuilder simple tree" {
  let builder = GreenNodeBuilder::new()
  builder.start_node(root())
  builder.token(atom(), "hello")
  builder.finish_node()
  let green = builder.finish()
  assert_eq(green.kind(), root())
  assert_eq(green.text_len().to_int(), 5)
  assert_eq(green.children_count(), 1)
}

///|
test "GreenNodeBuilder nested tree" {
  // Build: (add 1 2)
  let builder = GreenNodeBuilder::new()
  builder.start_node(root())
  builder.start_node(list())
  builder.token(lparen(), "(")
  builder.token(atom(), "add")
  builder.token(whitespace(), " ")
  builder.token(atom(), "1")
  builder.token(whitespace(), " ")
  builder.token(atom(), "2")
  builder.token(rparen(), ")")
  builder.finish_node()
  builder.finish_node()
  let green = builder.finish()
  assert_eq(green.kind(), root())
  assert_eq(green.text_len().to_int(), 9) // "(add 1 2)"
  assert_eq(green.children_count(), 1)
  // Check inner list() node
  match green.child(0) {
    Some(GreenChild::Node(node~, ..)) => {
      assert_eq(node.kind(), list())
      assert_eq(node.children_count(), 7)
    }
    _ => abort("Expected node")
  }
}

///|
test "NodeCache token interning" {
  let cache = NodeCache::new()
  let token1 = cache.token(atom(), "foo")
  let token2 = cache.token(atom(), "foo")
  let token3 = cache.token(atom(), "bar")
  // Same kind and text should return same token
  assert_eq(token1, token2)
  // Different text should return different token
  assert_true(token1 != token3)
}

///|
test "SyntaxNode navigation" {
  // Build: (let x 42)
  let builder = GreenNodeBuilder::new()
  builder.start_node(root())
  builder.start_node(list())
  builder.token(lparen(), "(")
  builder.token(atom(), "let")
  builder.token(whitespace(), " ")
  builder.token(atom(), "x")
  builder.token(whitespace(), " ")
  builder.token(atom(), "42")
  builder.token(rparen(), ")")
  builder.finish_node()
  builder.finish_node()
  let green = builder.finish()
  // Navigate with red tree
  let root_node = SyntaxNode::new_root(green)
  assert_eq(root_node.kind(), root())
  assert_eq(root_node.text_range().start().to_int(), 0)
  assert_eq(root_node.text_range().end().to_int(), 10)
  // Check children
  let children = root_node.children()
  assert_eq(children.length(), 1)
  // Navigate to list()
  match root_node.first_child() {
    Some(Node(list_node)) => {
      assert_eq(list_node.kind(), list())
      // Check parent navigation
      match list_node.parent() {
        Some(parent) => assert_eq(parent.kind(), root())
        None => abort("Expected parent")
      }
      // Check tokens
      let tokens = list_node.child_tokens()
      assert_eq(tokens.length(), 7)
      assert_eq(tokens[0].text(), "(")
      assert_eq(tokens[1].text(), "let")
      assert_eq(tokens[3].text(), "x")
      assert_eq(tokens[5].text(), "42")
    }
    _ => abort("Expected node")
  }
}

///|
test "SyntaxToken text_range" {
  let builder = GreenNodeBuilder::new()
  builder.start_node(root())
  builder.token(atom(), "foo")
  builder.token(whitespace(), " ")
  builder.token(atom(), "bar")
  builder.finish_node()
  let green = builder.finish()
  let root_node = SyntaxNode::new_root(green)
  let tokens = root_node.child_tokens()
  assert_eq(tokens.length(), 3)
  // foo: [0, 3)
  assert_eq(tokens[0].text_range().start().to_int(), 0)
  assert_eq(tokens[0].text_range().end().to_int(), 3)
  // space: [3, 4)
  assert_eq(tokens[1].text_range().start().to_int(), 3)
  assert_eq(tokens[1].text_range().end().to_int(), 4)
  // bar: [4, 7)
  assert_eq(tokens[2].text_range().start().to_int(), 4)
  assert_eq(tokens[2].text_range().end().to_int(), 7)
}

///|
test "Checkpoint for wrapping" {
  // Build "1 + 2" then wrap "1" into atom() node
  let builder = GreenNodeBuilder::new()
  builder.start_node(root())
  let checkpoint = builder.checkpoint()
  builder.token(atom(), "1")
  // Wrap the "1" token in a node
  builder.start_node_at(checkpoint, list())
  builder.finish_node()
  builder.token(whitespace(), " ")
  builder.token(atom(), "+")
  builder.token(whitespace(), " ")
  builder.token(atom(), "2")
  builder.finish_node()
  let green = builder.finish()
  let root_node = SyntaxNode::new_root(green)
  // First child should be list() containing "1"
  match root_node.first_child() {
    Some(Node(list_node)) => {
      assert_eq(list_node.kind(), list())
      let tokens = list_node.child_tokens()
      assert_eq(tokens.length(), 1)
      assert_eq(tokens[0].text(), "1")
    }
    _ => abort("Expected list() node")
  }
}

///|
test "SyntaxElement utilities" {
  let builder = GreenNodeBuilder::new()
  builder.start_node(root())
  builder.token(atom(), "test")
  builder.finish_node()
  let green = builder.finish()
  let root_node = SyntaxNode::new_root(green)
  match root_node.first_child() {
    Some(el) => {
      assert_eq(el.kind(), atom())
      assert_eq(el.text_len().to_int(), 4)
      match el.as_token() {
        Some(t) => assert_eq(t.text(), "test")
        None => abort("Expected token")
      }
      assert_eq(el.as_node(), None)
    }
    None => abort("Expected child")
  }
}
