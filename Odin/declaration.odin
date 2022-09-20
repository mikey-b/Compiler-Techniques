package parser

import "core:testing"
import "core:fmt"
import "lex"

declaration :: struct {
	deinit: proc(^declaration),
}

factory :: proc(l: ^lex.lexer) -> ^declaration {
	if (l.front.type == .VarKeyword) {
		return var_dec_init(l);
	} else if (l.front.type == .OptionalKeyword) {
		return optional_dec_init(l);
	}
	
	return nil
}

var_dec_init :: proc(l: ^lex.lexer) -> ^declaration {
	var_dec :: struct {
		using base: declaration,
		ident: string,
	}
	
	result := new(var_dec);
	result.deinit = proc(s: ^declaration) {
		self := cast(^var_dec)s;
		free(self);
	}

	assert(l.front.type == .VarKeyword);
	lex.advance(l);
	
	assert(l.front.type == .Identifier);
	result.ident = l.front.text;
	lex.advance(l);
	
	return result;
}

@(test)
var_dec_test :: proc(t: ^testing.T) {
	l: lex.lexer;
	lex.init(&l, "var test");
	
	d := var_dec_init(&l);
	assert(l.front.type == .EOF);
}


optional_dec_init :: proc(l: ^lex.lexer) -> ^declaration {
	opt_dec :: struct {
		using base: declaration,
		ident: string,
	}
	
	result := new(opt_dec);
	result.deinit = proc(s: ^declaration) {
		self := cast(^opt_dec)s;
		free(self);
	}

	assert(l.front.type == .OptionalKeyword);
	lex.advance(l);
	
	assert(l.front.type == .Identifier);
	result.ident = l.front.text;
	lex.advance(l);
	
	return result;
}

@(test)
opt_dec_test :: proc(t: ^testing.T) {
	l: lex.lexer;
	lex.init(&l, "optional test");
	
	d := optional_dec_init(&l);
	assert(l.front.type == .EOF);
}

