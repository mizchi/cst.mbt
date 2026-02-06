///| Lexer for expr_lang

///| Token produced by the lexer
pub struct Token {
  kind : @cst.SyntaxKind
  text : String
} derive(Show, Eq)

///|
pub fn Token::new(kind : @cst.SyntaxKind, text : String) -> Token {
  Token::{ kind, text }
}

///|
pub fn Token::kind(self : Token) -> @cst.SyntaxKind {
  self.kind
}

///|
pub fn Token::text(self : Token) -> String {
  self.text
}

///| Lexer state
pub struct Lexer {
  input : String
  mut pos : Int
} derive(Show)

///|
pub fn Lexer::new(input : String) -> Lexer {
  Lexer::{ input, pos: 0 }
}

///|
fn Lexer::peek(self : Lexer) -> Char? {
  if self.pos >= self.input.length() {
    None
  } else {
    Some(self.input[self.pos].to_int().unsafe_to_char())
  }
}

///|
fn Lexer::advance(self : Lexer) -> Char? {
  match self.peek() {
    Some(c) => {
      self.pos += 1
      Some(c)
    }
    None => None
  }
}

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_alnum(c : Char) -> Bool {
  is_alpha(c) || is_digit(c)
}

///|
fn is_whitespace_char(c : Char) -> Bool {
  c == ' ' || c == '\t'
}

///|
fn Lexer::slice_from(self : Lexer, start : Int) -> String {
  let buf = StringBuilder::new()
  for i = start; i < self.pos; i = i + 1 {
    buf.write_char(self.input[i].to_int().unsafe_to_char())
  }
  buf.to_string()
}

///| Lex a single token
pub fn Lexer::next_token(self : Lexer) -> Token {
  match self.peek() {
    None => Token::new(eof(), "")
    Some(c) => {
      // Whitespace (not newline)
      if is_whitespace_char(c) {
        let start = self.pos
        while {
          match self.peek() {
            Some(ch) => is_whitespace_char(ch)
            None => false
          }
        } {
          let _ = self.advance()
        }
        let text = self.slice_from(start)
        return Token::new(whitespace(), text)
      }
      // Newline
      if c == '\n' {
        let _ = self.advance()
        return Token::new(newline(), "\n")
      }
      // Identifiers and keywords
      if is_alpha(c) {
        let start = self.pos
        while {
          match self.peek() {
            Some(ch) => is_alnum(ch)
            None => false
          }
        } {
          let _ = self.advance()
        }
        let text = self.slice_from(start)
        let kind = match text {
          "let" => let_kw()
          "fn" => fn_kw()
          _ => name()
        }
        return Token::new(kind, text)
      }
      // Numbers
      if is_digit(c) {
        let start = self.pos
        while {
          match self.peek() {
            Some(ch) => is_digit(ch)
            None => false
          }
        } {
          let _ = self.advance()
        }
        let text = self.slice_from(start)
        return Token::new(number(), text)
      }
      // Single character tokens
      let _ = self.advance()
      match c {
        '=' => Token::new(eq(), "=")
        '+' => Token::new(plus(), "+")
        '-' => Token::new(minus(), "-")
        '*' => Token::new(star(), "*")
        '/' => Token::new(slash(), "/")
        '(' => Token::new(lparen(), "(")
        ')' => Token::new(rparen(), ")")
        '{' => Token::new(lbrace(), "{")
        '}' => Token::new(rbrace(), "}")
        ',' => Token::new(comma(), ",")
        _ => Token::new(error_kind(), c.to_string())
      }
    }
  }
}

///| Check if lexer is at end
pub fn Lexer::is_eof(self : Lexer) -> Bool {
  self.pos >= self.input.length()
}

///| Tokenize entire input
pub fn tokenize(input : String) -> Array[Token] {
  let lexer = Lexer::new(input)
  let tokens : Array[Token] = []
  while not(lexer.is_eof()) {
    tokens.push(lexer.next_token())
  }
  tokens.push(Token::new(eof(), ""))
  tokens
}
