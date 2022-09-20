package parser

import "core:fmt"
import "lex"

LLVMFuzzerTestOneInput :: proc(data: ^u8, size: int) -> int {
	return 0;

}

main :: proc() {
	l: lex.lexer;
	lex.init(&l, "(4-3+2)! + 5");
	
	exp := expression_factory(&l);
	defer exp->deinit();

	sum := exp->evaluate();

	fmt.println(sum);
}
