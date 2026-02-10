///|
/// SyntaxToken - A token in the red tree with navigation capabilities
pub(all) struct SyntaxToken {
  green : GreenToken
  parent : SyntaxNode
  offset : TextSize
} derive(Eq, Show)

///|
pub fn SyntaxToken::new(
  green : GreenToken,
  parent : SyntaxNode,
  offset : TextSize,
) -> SyntaxToken {
  SyntaxToken::{ green, parent, offset }
}

///|
pub fn SyntaxToken::kind(self : SyntaxToken) -> SyntaxKind {
  self.green.kind()
}

///|
pub fn SyntaxToken::text(self : SyntaxToken) -> String {
  self.green.text()
}

///|
pub fn SyntaxToken::text_range(self : SyntaxToken) -> TextRange {
  TextRange::at(self.offset, self.green.text_len())
}

///|
pub fn SyntaxToken::text_len(self : SyntaxToken) -> TextSize {
  self.green.text_len()
}

///|
pub fn SyntaxToken::parent(self : SyntaxToken) -> SyntaxNode {
  self.parent
}

///|
pub fn SyntaxToken::green(self : SyntaxToken) -> GreenToken {
  self.green
}
