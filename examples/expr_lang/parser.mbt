///| Parser for expr_lang

///| Parser state
pub struct Parser {
  tokens : Array[Token]
  mut pos : Int
  builder : @cst.GreenNodeBuilder
}

///|
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  Parser::{ tokens, pos: 0, builder: @cst.GreenNodeBuilder::new() }
}

///| Peek current token
fn Parser::peek(self : Parser) -> Token {
  if self.pos >= self.tokens.length() {
    Token::new(eof(), "")
  } else {
    self.tokens[self.pos]
  }
}

///| Peek token kind
fn Parser::peek_kind(self : Parser) -> @cst.SyntaxKind {
  self.peek().kind()
}

///| Check if at a specific kind
fn Parser::at(self : Parser, kind : @cst.SyntaxKind) -> Bool {
  self.peek_kind() == kind
}

///| Advance and emit current token
fn Parser::bump(self : Parser) -> Unit {
  let tok = self.peek()
  self.builder.token(tok.kind(), tok.text())
  self.pos += 1
}

///| Skip whitespace tokens
fn Parser::skip_trivia(self : Parser) -> Unit {
  while is_trivia(self.peek_kind()) {
    self.bump()
  }
}

///| Expect and consume a specific token kind
fn Parser::expect(self : Parser, kind : @cst.SyntaxKind) -> Unit {
  self.skip_trivia()
  if self.at(kind) {
    self.bump()
  } else {
    // Emit error token
    self.builder.token(error_kind(), "")
  }
}

///| Parse source file
pub fn Parser::parse(self : Parser) -> @cst.GreenNode {
  self.builder.start_node(source_file())
  while not(self.at(eof())) {
    self.skip_trivia()
    if self.at(eof()) {
      break
    }
    self.parse_stmt()
  }
  self.builder.finish_node()
  self.builder.finish()
}

///| Parse a statement
fn Parser::parse_stmt(self : Parser) -> Unit {
  self.skip_trivia()
  match self.peek_kind() {
    k if k == let_kw() => self.parse_let_stmt()
    k if k == fn_kw() => self.parse_fn_def()
    _ => self.parse_expr_stmt()
  }
}

///| Parse let statement: let NAME = expr
fn Parser::parse_let_stmt(self : Parser) -> Unit {
  self.builder.start_node(let_stmt())
  self.bump() // let
  self.skip_trivia()
  self.expect(name()) // NAME
  self.skip_trivia()
  self.expect(eq()) // =
  self.skip_trivia()
  self.parse_expr()
  self.builder.finish_node()
}

///| Parse function definition: fn NAME(params) { expr }
fn Parser::parse_fn_def(self : Parser) -> Unit {
  self.builder.start_node(fn_def())
  self.bump() // fn
  self.skip_trivia()
  self.expect(name()) // NAME
  self.skip_trivia()
  self.expect(lparen()) // (
  self.parse_params()
  self.expect(rparen()) // )
  self.skip_trivia()
  self.parse_block()
  self.builder.finish_node()
}

///| Parse parameter list
fn Parser::parse_params(self : Parser) -> Unit {
  self.builder.start_node(param_list())
  self.skip_trivia()
  if not(self.at(rparen())) {
    self.expect(name()) // first param
    while {
      self.skip_trivia()
      self.at(comma())
    } {
      self.bump() // ,
      self.skip_trivia()
      self.expect(name())
    }
  }
  self.builder.finish_node()
}

///| Parse block: { expr }
fn Parser::parse_block(self : Parser) -> Unit {
  self.builder.start_node(block())
  self.expect(lbrace()) // {
  self.skip_trivia()
  if not(self.at(rbrace())) {
    self.parse_expr()
  }
  self.skip_trivia()
  self.expect(rbrace()) // }
  self.builder.finish_node()
}

///| Parse expression statement
fn Parser::parse_expr_stmt(self : Parser) -> Unit {
  self.builder.start_node(expr_stmt())
  self.parse_expr()
  self.builder.finish_node()
}

///| Parse expression (entry point)
fn Parser::parse_expr(self : Parser) -> Unit {
  self.parse_add_expr()
}

///| Parse additive expression: mul_expr (('+' | '-') mul_expr)*
fn Parser::parse_add_expr(self : Parser) -> Unit {
  let checkpoint = self.builder.checkpoint()
  self.parse_mul_expr()
  while {
    self.skip_trivia()
    self.at(plus()) || self.at(minus())
  } {
    self.builder.start_node_at(checkpoint, binary_expr())
    self.bump() // + or -
    self.skip_trivia()
    self.parse_mul_expr()
    self.builder.finish_node()
  }
}

///| Parse multiplicative expression: call_expr (('*' | '/') call_expr)*
fn Parser::parse_mul_expr(self : Parser) -> Unit {
  let checkpoint = self.builder.checkpoint()
  self.parse_call_expr()
  while {
    self.skip_trivia()
    self.at(star()) || self.at(slash())
  } {
    self.builder.start_node_at(checkpoint, binary_expr())
    self.bump() // * or /
    self.skip_trivia()
    self.parse_call_expr()
    self.builder.finish_node()
  }
}

///| Parse call expression: primary_expr ('(' args? ')')?
fn Parser::parse_call_expr(self : Parser) -> Unit {
  let checkpoint = self.builder.checkpoint()
  self.parse_primary_expr()
  self.skip_trivia()
  if self.at(lparen()) {
    self.builder.start_node_at(checkpoint, call_expr())
    self.bump() // (
    self.parse_args()
    self.expect(rparen()) // )
    self.builder.finish_node()
  }
}

///| Parse argument list
fn Parser::parse_args(self : Parser) -> Unit {
  self.builder.start_node(arg_list())
  self.skip_trivia()
  if not(self.at(rparen())) {
    self.parse_expr() // first arg
    while {
      self.skip_trivia()
      self.at(comma())
    } {
      self.bump() // ,
      self.skip_trivia()
      self.parse_expr()
    }
  }
  self.builder.finish_node()
}

///| Parse primary expression: NAME | NUMBER | '(' expr ')'
fn Parser::parse_primary_expr(self : Parser) -> Unit {
  self.skip_trivia()
  match self.peek_kind() {
    k if k == name() => {
      self.builder.start_node(name_ref())
      self.bump()
      self.builder.finish_node()
    }
    k if k == number() => {
      self.builder.start_node(literal())
      self.bump()
      self.builder.finish_node()
    }
    k if k == lparen() => {
      self.builder.start_node(paren_expr())
      self.bump() // (
      self.skip_trivia()
      self.parse_expr()
      self.skip_trivia()
      self.expect(rparen()) // )
      self.builder.finish_node()
    }
    _ => {
      // Error recovery: emit error token and skip
      self.builder.start_node(literal())
      self.builder.token(error_kind(), self.peek().text())
      if not(self.at(eof())) {
        self.pos += 1
      }
      self.builder.finish_node()
    }
  }
}

///| Parse input string and return CST
pub fn parse(input : String) -> @cst.SyntaxNode {
  let tokens = tokenize(input)
  let parser = Parser::new(tokens)
  let green = parser.parse()
  @cst.SyntaxNode::new_root(green)
}
