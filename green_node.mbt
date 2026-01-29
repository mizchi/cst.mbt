///| GreenChild - Child element in a green node (either node or token)
pub(all) enum GreenChild {
  Node(rel_offset~ : TextSize, node~ : GreenNode)
  Token(rel_offset~ : TextSize, token~ : GreenToken)
} derive(Eq, Show)

///|
pub fn GreenChild::text_len(self : GreenChild) -> TextSize {
  match self {
    Node(node~, ..) => node.text_len()
    Token(token~, ..) => token.text_len()
  }
}

///|
pub fn GreenChild::rel_offset(self : GreenChild) -> TextSize {
  match self {
    Node(rel_offset~, ..) => rel_offset
    Token(rel_offset~, ..) => rel_offset
  }
}

///|
pub fn GreenChild::kind(self : GreenChild) -> SyntaxKind {
  match self {
    Node(node~, ..) => node.kind()
    Token(token~, ..) => token.kind()
  }
}

///| GreenNode - Immutable composite node in the green tree
/// Contains syntax kind, total text length, and children
pub(all) struct GreenNode {
  kind : SyntaxKind
  text_len : TextSize
  children : @array.T[GreenChild]
} derive(Eq, Show)

///|
pub fn GreenNode::new(
  kind : SyntaxKind,
  children : @array.T[GreenChild]
) -> GreenNode {
  let mut text_len = TextSize::zero()
  for child in children {
    text_len = text_len + child.text_len()
  }
  GreenNode::{ kind, text_len, children }
}

///|
pub fn GreenNode::kind(self : GreenNode) -> SyntaxKind {
  self.kind
}

///|
pub fn GreenNode::text_len(self : GreenNode) -> TextSize {
  self.text_len
}

///|
pub fn GreenNode::children(self : GreenNode) -> @array.T[GreenChild] {
  self.children
}

///|
pub fn GreenNode::children_count(self : GreenNode) -> Int {
  self.children.length()
}

///|
pub fn GreenNode::child(self : GreenNode, index : Int) -> GreenChild? {
  if index >= 0 && index < self.children.length() {
    Some(self.children[index])
  } else {
    None
  }
}
