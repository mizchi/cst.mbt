///|
/// GreenToken - Immutable token in the green tree
/// Contains syntax kind and the actual text
pub(all) struct GreenToken {
  kind : SyntaxKind
  text : String
} derive(Eq, Hash, Show)

///|
pub fn GreenToken::new(kind : SyntaxKind, text : String) -> GreenToken {
  GreenToken::{ kind, text }
}

///|
pub fn GreenToken::kind(self : GreenToken) -> SyntaxKind {
  self.kind
}

///|
pub fn GreenToken::text(self : GreenToken) -> String {
  self.text
}

///|
pub fn GreenToken::text_len(self : GreenToken) -> TextSize {
  TextSize::from_int(self.text.length())
}
