///| SyntaxData - Internal data for red tree nodes
pub(all) struct SyntaxData {
  green : GreenNode
  parent : SyntaxNode?
  offset : TextSize
} derive(Eq, Show)

///| SyntaxNode - A node in the red tree with navigation capabilities
/// Provides absolute positions and parent references
pub(all) struct SyntaxNode {
  data : SyntaxData
} derive(Eq, Show)

///|
pub fn SyntaxNode::new_root(green : GreenNode) -> SyntaxNode {
  SyntaxNode::{
    data: SyntaxData::{ green, parent: None, offset: TextSize::zero() },
  }
}

///|
fn SyntaxNode::new_child(
  green : GreenNode,
  parent : SyntaxNode,
  offset : TextSize
) -> SyntaxNode {
  SyntaxNode::{
    data: SyntaxData::{ green, parent: Some(parent), offset },
  }
}

///|
pub fn SyntaxNode::kind(self : SyntaxNode) -> SyntaxKind {
  self.data.green.kind()
}

///|
pub fn SyntaxNode::text_range(self : SyntaxNode) -> TextRange {
  TextRange::at(self.data.offset, self.data.green.text_len())
}

///|
pub fn SyntaxNode::text_len(self : SyntaxNode) -> TextSize {
  self.data.green.text_len()
}

///|
pub fn SyntaxNode::parent(self : SyntaxNode) -> SyntaxNode? {
  self.data.parent
}

///|
pub fn SyntaxNode::green(self : SyntaxNode) -> GreenNode {
  self.data.green
}

///| Collect all children (nodes and tokens) as array
pub fn SyntaxNode::children(self : SyntaxNode) -> Array[SyntaxElement] {
  let green_children = self.data.green.children()
  let base_offset = self.data.offset
  let result : Array[SyntaxElement] = []
  for i = 0; i < green_children.length(); i = i + 1 {
    let green_child = green_children[i]
    let child_offset = base_offset + green_child.rel_offset()
    let element = match green_child {
      GreenChild::Node(node~, ..) => {
        let node = SyntaxNode::new_child(node, self, child_offset)
        SyntaxElement::Node(node)
      }
      GreenChild::Token(token~, ..) => {
        let token = SyntaxToken::new(token, self, child_offset)
        SyntaxElement::Token(token)
      }
    }
    result.push(element)
  }
  result
}

///| Collect child nodes only
pub fn SyntaxNode::child_nodes(self : SyntaxNode) -> Array[SyntaxNode] {
  let result : Array[SyntaxNode] = []
  for child in self.children() {
    match child {
      Node(n) => result.push(n)
      Token(_) => ()
    }
  }
  result
}

///| Collect child tokens only
pub fn SyntaxNode::child_tokens(self : SyntaxNode) -> Array[SyntaxToken] {
  let result : Array[SyntaxToken] = []
  for child in self.children() {
    match child {
      Node(_) => ()
      Token(t) => result.push(t)
    }
  }
  result
}

///| Get child at index
pub fn SyntaxNode::child_at(self : SyntaxNode, index : Int) -> SyntaxElement? {
  let green_children = self.data.green.children()
  if index < 0 || index >= green_children.length() {
    return None
  }
  let green_child = green_children[index]
  let child_offset = self.data.offset + green_child.rel_offset()
  match green_child {
    GreenChild::Node(node~, ..) => {
      let node = SyntaxNode::new_child(node, self, child_offset)
      Some(SyntaxElement::Node(node))
    }
    GreenChild::Token(token~, ..) => {
      let token = SyntaxToken::new(token, self, child_offset)
      Some(SyntaxElement::Token(token))
    }
  }
}

///| Get number of children
pub fn SyntaxNode::children_count(self : SyntaxNode) -> Int {
  self.data.green.children_count()
}

///| Get first child
pub fn SyntaxNode::first_child(self : SyntaxNode) -> SyntaxElement? {
  self.child_at(0)
}

///| Get last child
pub fn SyntaxNode::last_child(self : SyntaxNode) -> SyntaxElement? {
  let count = self.children_count()
  if count == 0 {
    None
  } else {
    self.child_at(count - 1)
  }
}

///| Get first child node
pub fn SyntaxNode::first_child_node(self : SyntaxNode) -> SyntaxNode? {
  let nodes = self.child_nodes()
  if nodes.is_empty() {
    None
  } else {
    Some(nodes[0])
  }
}

///| Get first child token
pub fn SyntaxNode::first_child_token(self : SyntaxNode) -> SyntaxToken? {
  let tokens = self.child_tokens()
  if tokens.is_empty() {
    None
  } else {
    Some(tokens[0])
  }
}
