///|
/// Demo for expr_lang
fn main {
  // Demo: Format various expressions
  let examples = [
    "let x=1+2", "fn add(a,b){a+b}", "add(1,2)", "1+2*3", "(1+2)*3", "let  result  =  1  +  2",
  ]
  for example in examples {
    println("Input:  \{example}")
    let formatted = @expr_lang.format(example)
    println("Output: \{formatted}")
    println("")
  }
}
