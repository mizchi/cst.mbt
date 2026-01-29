///| SyntaxElement - Either a node or a token in the syntax tree
pub(all) enum SyntaxElement {
  Node(SyntaxNode)
  Token(SyntaxToken)
} derive(Eq, Show)

///|
pub fn SyntaxElement::kind(self : SyntaxElement) -> SyntaxKind {
  match self {
    Node(n) => n.kind()
    Token(t) => t.kind()
  }
}

///|
pub fn SyntaxElement::text_range(self : SyntaxElement) -> TextRange {
  match self {
    Node(n) => n.text_range()
    Token(t) => t.text_range()
  }
}

///|
pub fn SyntaxElement::text_len(self : SyntaxElement) -> TextSize {
  match self {
    Node(n) => n.text_len()
    Token(t) => t.text_len()
  }
}

///|
pub fn SyntaxElement::as_node(self : SyntaxElement) -> SyntaxNode? {
  match self {
    Node(n) => Some(n)
    Token(_) => None
  }
}

///|
pub fn SyntaxElement::as_token(self : SyntaxElement) -> SyntaxToken? {
  match self {
    Node(_) => None
    Token(t) => Some(t)
  }
}

///|
pub fn SyntaxElement::parent(self : SyntaxElement) -> SyntaxNode? {
  match self {
    Node(n) => n.parent()
    Token(t) => Some(t.parent())
  }
}
