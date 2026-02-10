///|
/// Tests for expr_lang

// Lexer tests
test "lexer: tokenize simple expression" {
  let tokens = tokenize("1 + 2")
  assert_eq(tokens.length(), 6) // 1 ws + ws 2 eof
  assert_eq(tokens[0].kind(), number())
  assert_eq(tokens[0].text(), "1")
  assert_eq(tokens[1].kind(), whitespace())
  assert_eq(tokens[2].kind(), plus())
  assert_eq(tokens[3].kind(), whitespace())
  assert_eq(tokens[4].kind(), number())
  assert_eq(tokens[4].text(), "2")
  assert_eq(tokens[5].kind(), eof())
}

///|
test "lexer: tokenize let statement" {
  let tokens = tokenize("let x = 1")
  assert_eq(tokens[0].kind(), let_kw())
  assert_eq(tokens[0].text(), "let")
  assert_eq(tokens[2].kind(), name())
  assert_eq(tokens[2].text(), "x")
  assert_eq(tokens[4].kind(), eq())
}

///|
test "lexer: tokenize function definition" {
  let tokens = tokenize("fn add(a, b) { a + b }")
  assert_eq(tokens[0].kind(), fn_kw())
  assert_eq(tokens[2].kind(), name())
  assert_eq(tokens[2].text(), "add")
  assert_eq(tokens[3].kind(), lparen())
}

///|
test "lexer: tokenize operators" {
  let tokens = tokenize("+-*/")
  assert_eq(tokens[0].kind(), plus())
  assert_eq(tokens[1].kind(), minus())
  assert_eq(tokens[2].kind(), star())
  assert_eq(tokens[3].kind(), slash())
}

// Parser tests

///|
test "parser: parse simple expression" {
  let cst = parse("1 + 2")
  assert_eq(cst.kind(), source_file())
  let children = cst.child_nodes()
  assert_eq(children.length(), 1) // one expr_stmt
  assert_eq(children[0].kind(), expr_stmt())
}

///|
test "parser: parse let statement" {
  let cst = parse("let x = 1 + 2")
  assert_eq(cst.kind(), source_file())
  let children = cst.child_nodes()
  assert_eq(children.length(), 1)
  assert_eq(children[0].kind(), let_stmt())
}

///|
test "parser: parse function definition" {
  let cst = parse("fn add(a, b) { a + b }")
  assert_eq(cst.kind(), source_file())
  let children = cst.child_nodes()
  assert_eq(children.length(), 1)
  assert_eq(children[0].kind(), fn_def())
}

///|
test "parser: parse binary expression precedence" {
  // 1 + 2 * 3 should parse as 1 + (2 * 3)
  let cst = parse("1 + 2 * 3")
  assert_eq(cst.kind(), source_file())
}

///|
test "parser: parse parenthesized expression" {
  let cst = parse("(1 + 2) * 3")
  assert_eq(cst.kind(), source_file())
}

///|
test "parser: parse function call" {
  let cst = parse("add(1, 2)")
  assert_eq(cst.kind(), source_file())
  let children = cst.child_nodes()
  assert_eq(children.length(), 1)
  // expr_stmt contains call_expr
  let expr_stmt_node = children[0]
  assert_eq(expr_stmt_node.kind(), expr_stmt())
}

// Formatter tests

///|
test "formatter: add spaces around binary operators" {
  assert_eq(format("1+2"), "1 + 2")
  assert_eq(format("1-2"), "1 - 2")
  assert_eq(format("1*2"), "1 * 2")
  assert_eq(format("1/2"), "1 / 2")
}

///|
test "formatter: normalize multiple spaces" {
  assert_eq(format("1  +  2"), "1 + 2")
}

///|
test "formatter: format let statement" {
  assert_eq(format("let x=1+2"), "let x = 1 + 2")
  assert_eq(format("let  x  =  1"), "let x = 1")
}

///|
test "formatter: format function call with comma spacing" {
  assert_eq(format("add(a,b,c)"), "add(a, b, c)")
  assert_eq(format("add(a , b , c)"), "add(a, b, c)")
}

///|
test "formatter: remove extra spaces in parentheses" {
  assert_eq(format("( 1 + 2 )"), "(1 + 2)")
}

///|
test "formatter: format function definition with block" {
  let input = "fn add(a,b){a+b}"
  let output = format(input)
  // Should have proper spacing and newlines
  assert_true(output.contains("fn add(a, b)"))
  assert_true(output.contains("a + b"))
}

///|
test "formatter: preserve structure after formatting" {
  let input = "let x=1+2"
  let formatted = format(input)
  assert_eq(formatted, "let x = 1 + 2")
  // Re-format should be idempotent
  let reformatted = format(formatted)
  assert_eq(formatted, reformatted)
}

///|
test "formatter: complex expression" {
  let input = "1+2*3"
  let output = format(input)
  assert_eq(output, "1 + 2 * 3")
}

///|
test "formatter: parenthesized expression" {
  let input = "(1+2)*3"
  let output = format(input)
  assert_eq(output, "(1 + 2) * 3")
}
