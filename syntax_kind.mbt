///| SyntaxKind - Language-agnostic syntax element identifier
/// Wraps a UInt16 for efficient storage and comparison
pub(all) struct SyntaxKind {
  raw : UInt
} derive(Eq, Hash, Show)

///|
pub fn SyntaxKind::new(raw : UInt) -> SyntaxKind {
  SyntaxKind::{ raw, }
}

///|
pub fn SyntaxKind::raw(self : SyntaxKind) -> UInt {
  self.raw
}

///|
pub impl Compare for SyntaxKind with compare(self : SyntaxKind, other : SyntaxKind) -> Int {
  if self.raw < other.raw {
    -1
  } else if self.raw > other.raw {
    1
  } else {
    0
  }
}

// Common syntax kinds used across languages
///|
pub fn SyntaxKind::eof() -> SyntaxKind {
  SyntaxKind::{ raw: 0 }
}

///|
pub fn SyntaxKind::tombstone() -> SyntaxKind {
  SyntaxKind::{ raw: 1 }
}

///|
pub fn SyntaxKind::syntax_error() -> SyntaxKind {
  SyntaxKind::{ raw: 2 }
}
