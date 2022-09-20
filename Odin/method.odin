package parser

import "lex"
import "core:testing"
import "core:fmt"

method :: struct {
	deinit: proc(^method),
	print: proc(^method),
}

method_signature :: struct {
	deinit: proc(^method_signature),
	print: proc(^method_signature),
}

unary_method_init :: proc(l: ^lex.lexer) -> ^method_signature {
	unary_method :: struct {
		using base: method_signature,
		name: string,
	}
	
	result := new(unary_method);
	result.deinit = proc(s: ^method_signature) {
		self := cast(^unary_method)s;
		free(self);
	}
	result.print = proc(s: ^method_signature) {
		self := cast(^unary_method)s;
		fmt.println(self);
	}
	
	assert(l.front.type == .Identifier);
	result.name = l.front.text;
	lex.advance(l);
	
	return result;
}

code_block :: struct {
	deinit: proc(^code_block),
}

code_block_init :: proc(l: ^lex.lexer) -> ^code_block {
	result := new(code_block);
	result.deinit = proc(self: ^code_block) {
		free(self);
	}
	
	assert(l.front.type == .BeginKeyword);
	lex.advance(l);
	
	assert(l.front.type == .Newline);
	lex.advance(l);
	
	
	
	assert(l.front.type == .EndKeyword);
	lex.advance(l);
	
	assert(l.front.type == .Newline);
	lex.advance(l);
	
	return result;
}

constructor_init :: proc(l: ^lex.lexer) -> ^method {
	constructor_method :: struct {
		using base: method,
		signature: ^method_signature,
		body: ^code_block,
	}

	result := new(constructor_method);
	result.deinit = proc(s: ^method) {
		using self := cast(^constructor_method)s;
		
		signature->deinit();
		body->deinit();
		
		free(self);
	}
	result.print = proc(s: ^method) {
		using self := cast(^constructor_method)s;
		fmt.println(self);
		signature->print();
	}
	
	assert(l.front.type == .ConstructorKeyword);
	lex.advance(l);
	
	result.signature = unary_method_init(l);
	
	assert(l.front.type == .Newline);
	lex.advance(l);
	
	result.body = code_block_init(l);
	
	return result;
}

@(test)
constructor_test :: proc(t: ^testing.T) {
	l: lex.lexer;
	lex.init(&l, "constructor t\nbegin\nend\n");
	
	t := constructor_init(&l);
	t->print();
	
	assert(l.front.type == .EOF);
}
