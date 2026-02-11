///| SyntaxKind constants for expr_lang

// Token kinds (1-99)

///|
pub fn eof() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(0)
}

///|
pub fn error_kind() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(1)
}

///|
pub fn whitespace() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(2)
}

///|
pub fn newline() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(3)
}

///|
pub fn name() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(10)
}

///|
pub fn number() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(11)
}

///|
pub fn let_kw() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(20)
}

///|
pub fn fn_kw() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(21)
}

///|
pub fn eq() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(30)
}

///|
pub fn plus() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(31)
}

///|
pub fn minus() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(32)
}

///|
pub fn star() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(33)
}

///|
pub fn slash() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(34)
}

///|
pub fn lparen() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(40)
}

///|
pub fn rparen() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(41)
}

///|
pub fn lbrace() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(42)
}

///|
pub fn rbrace() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(43)
}

///|
pub fn comma() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(44)
}

// Node kinds (100+)

///|
pub fn source_file() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(100)
}

///|
pub fn let_stmt() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(101)
}

///|
pub fn fn_def() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(102)
}

///|
pub fn param_list() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(103)
}

///|
pub fn block() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(104)
}

///|
pub fn binary_expr() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(105)
}

///|
pub fn call_expr() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(106)
}

///|
pub fn arg_list() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(107)
}

///|
pub fn paren_expr() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(108)
}

///|
pub fn expr_stmt() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(109)
}

///|
pub fn name_ref() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(110)
}

///|
pub fn literal() -> @cst.SyntaxKind {
  @cst.SyntaxKind::new(111)
}

///|
/// Check if a SyntaxKind is a token (not a node)
pub fn is_token(kind : @cst.SyntaxKind) -> Bool {
  kind.raw() < 100
}

///|
/// Check if a SyntaxKind is trivia (whitespace/newline)
pub fn is_trivia(kind : @cst.SyntaxKind) -> Bool {
  kind == whitespace() || kind == newline()
}

///|
/// Get the name of a SyntaxKind for debugging
pub fn kind_name(kind : @cst.SyntaxKind) -> String {
  match kind.raw() {
    0 => "eof"
    1 => "error"
    2 => "whitespace"
    3 => "newline"
    10 => "name"
    11 => "number"
    20 => "let_kw"
    21 => "fn_kw"
    30 => "eq"
    31 => "plus"
    32 => "minus"
    33 => "star"
    34 => "slash"
    40 => "lparen"
    41 => "rparen"
    42 => "lbrace"
    43 => "rbrace"
    44 => "comma"
    100 => "source_file"
    101 => "let_stmt"
    102 => "fn_def"
    103 => "param_list"
    104 => "block"
    105 => "binary_expr"
    106 => "call_expr"
    107 => "arg_list"
    108 => "paren_expr"
    109 => "expr_stmt"
    110 => "name_ref"
    111 => "literal"
    _ => "unknown"
  }
}
