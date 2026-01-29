///| Formatter for expr_lang

///| Formatting context
priv struct FormatContext {
  builder : @cst.GreenNodeBuilder
  mut indent : Int
  mut needs_space : Bool
  mut at_line_start : Bool
}

///|
fn FormatContext::new() -> FormatContext {
  FormatContext::{
    builder: @cst.GreenNodeBuilder::new(),
    indent: 0,
    needs_space: false,
    at_line_start: true,
  }
}

///|
fn FormatContext::emit_space(self : FormatContext) -> Unit {
  self.builder.token(whitespace(), " ")
  self.needs_space = false
}

///|
fn FormatContext::emit_newline(self : FormatContext) -> Unit {
  self.builder.token(newline(), "\n")
  self.at_line_start = true
  self.needs_space = false
}

///|
fn FormatContext::emit_indent(self : FormatContext) -> Unit {
  if self.at_line_start && self.indent > 0 {
    let spaces = " ".repeat(self.indent * 2)
    self.builder.token(whitespace(), spaces)
  }
  self.at_line_start = false
}

///|
fn FormatContext::emit_token(
  self : FormatContext,
  kind : @cst.SyntaxKind,
  text : String
) -> Unit {
  self.emit_indent()
  self.builder.token(kind, text)
}

///| Format a syntax node
fn format_node(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  let kind = node.kind()
  ctx.builder.start_node(kind)
  match kind {
    k if k == source_file() => format_source_file(node, ctx)
    k if k == let_stmt() => format_let_stmt(node, ctx)
    k if k == fn_def() => format_fn_def(node, ctx)
    k if k == param_list() => format_param_list(node, ctx)
    k if k == block() => format_block(node, ctx)
    k if k == binary_expr() => format_binary_expr(node, ctx)
    k if k == call_expr() => format_call_expr(node, ctx)
    k if k == arg_list() => format_arg_list(node, ctx)
    k if k == paren_expr() => format_paren_expr(node, ctx)
    k if k == expr_stmt() => format_expr_stmt(node, ctx)
    k if k == name_ref() => format_name_ref(node, ctx)
    k if k == literal() => format_literal(node, ctx)
    _ => format_children_default(node, ctx)
  }
  ctx.builder.finish_node()
}

///| Format source file - statements separated by newlines
fn format_source_file(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  let mut first = true
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Node(n) => {
        if not(first) {
          ctx.emit_newline()
        }
        first = false
        format_node(n, ctx)
      }
      @cst.SyntaxElement::Token(_) => ()
    }
  }
}

///| Format let statement: let NAME = expr
fn format_let_stmt(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        if kind == let_kw() {
          ctx.emit_indent()
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else if kind == name() {
          if ctx.needs_space {
            ctx.emit_space()
          }
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else if kind == eq() {
          if ctx.needs_space {
            ctx.emit_space()
          }
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => {
        if ctx.needs_space {
          ctx.emit_space()
        }
        ctx.needs_space = false
        format_node(n, ctx)
      }
    }
  }
}

///| Format function definition: fn NAME(params) { expr }
fn format_fn_def(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        if kind == fn_kw() {
          ctx.emit_indent()
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else if kind == name() {
          if ctx.needs_space {
            ctx.emit_space()
          }
          ctx.emit_token(kind, t.text())
          ctx.needs_space = false
        } else if kind == lparen() {
          ctx.emit_token(kind, t.text())
          ctx.needs_space = false
        } else if kind == rparen() {
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => {
        if n.kind() == block() {
          if ctx.needs_space {
            ctx.emit_space()
          }
        }
        ctx.needs_space = false
        format_node(n, ctx)
      }
    }
  }
}

///| Format parameter list
fn format_param_list(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  let mut first = true
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        if kind == comma() {
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else if kind == name() {
          if not(first) && ctx.needs_space {
            ctx.emit_space()
          }
          first = false
          ctx.emit_token(kind, t.text())
          ctx.needs_space = false
        } else {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => format_node(n, ctx)
    }
  }
}

///| Format block: { expr } or { newline indent expr newline }
fn format_block(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        if kind == lbrace() {
          ctx.emit_token(kind, t.text())
          ctx.emit_newline()
          ctx.indent += 1
        } else if kind == rbrace() {
          ctx.indent -= 1
          ctx.emit_newline()
          ctx.emit_indent()
          ctx.emit_token(kind, t.text())
        } else {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => {
        format_node(n, ctx)
      }
    }
  }
}

///| Format binary expression: expr op expr with spaces around operator
fn format_binary_expr(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        // Operators get spaces
        if kind == plus() || kind == minus() || kind == star() || kind == slash() {
          ctx.emit_space()
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => {
        if ctx.needs_space {
          ctx.emit_space()
        }
        ctx.needs_space = false
        format_node(n, ctx)
      }
    }
  }
}

///| Format call expression: NAME(args)
fn format_call_expr(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        if kind == lparen() || kind == rparen() {
          ctx.emit_token(kind, t.text())
          ctx.needs_space = false
        } else {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => format_node(n, ctx)
    }
  }
}

///| Format argument list
fn format_arg_list(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  let mut first = true
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        if kind == comma() {
          ctx.emit_token(kind, t.text())
          ctx.needs_space = true
        } else {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => {
        if not(first) && ctx.needs_space {
          ctx.emit_space()
        }
        first = false
        ctx.needs_space = false
        format_node(n, ctx)
      }
    }
  }
}

///| Format parenthesized expression: (expr)
fn format_paren_expr(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        ctx.emit_token(kind, t.text())
        ctx.needs_space = false
      }
      @cst.SyntaxElement::Node(n) => format_node(n, ctx)
    }
  }
}

///| Format expression statement
fn format_expr_stmt(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if is_trivia(kind) {
          continue
        }
        ctx.emit_indent()
        ctx.emit_token(kind, t.text())
      }
      @cst.SyntaxElement::Node(n) => format_node(n, ctx)
    }
  }
}

///| Format name reference
fn format_name_ref(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if not(is_trivia(kind)) {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => format_node(n, ctx)
    }
  }
}

///| Format literal
fn format_literal(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if not(is_trivia(kind)) {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => format_node(n, ctx)
    }
  }
}

///| Default formatting - preserve structure but normalize whitespace
fn format_children_default(node : @cst.SyntaxNode, ctx : FormatContext) -> Unit {
  for child in node.children() {
    match child {
      @cst.SyntaxElement::Token(t) => {
        let kind = t.kind()
        if not(is_trivia(kind)) {
          ctx.emit_token(kind, t.text())
        }
      }
      @cst.SyntaxElement::Node(n) => format_node(n, ctx)
    }
  }
}

///| Convert CST to formatted string
fn green_to_string(node : @cst.GreenNode) -> String {
  let buf = StringBuilder::new()
  collect_text(node, buf)
  buf.to_string()
}

///|
fn collect_text(node : @cst.GreenNode, buf : StringBuilder) -> Unit {
  for child in node.children() {
    match child {
      @cst.GreenChild::Token(token~, ..) => buf.write_string(token.text())
      @cst.GreenChild::Node(node~, ..) => collect_text(node, buf)
    }
  }
}

///| Format source code string
pub fn format(input : String) -> String {
  let cst = parse(input)
  let ctx = FormatContext::new()
  format_node(cst, ctx)
  let green = ctx.builder.finish()
  green_to_string(green)
}
