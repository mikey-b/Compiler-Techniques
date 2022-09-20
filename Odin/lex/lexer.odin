package lexer

import "core:testing"

token_type :: enum {
	EOF,
	Identifier,
	Number,
	PlusSign,
	MinusSign,
	LParen,
	RParen,
	BangSign,
	VarKeyword,
	OptionalKeyword,
	ConstructorKeyword,
	Newline,
	BeginKeyword,
	EndKeyword,
}

token :: struct {
	type: token_type,
	text: string
}

lexer :: struct {
	pos: int,
	source: string,
	front: token
}

init :: proc(self: ^lexer, input: string) {
	self.pos = 0;
	self.source = input;
	advance(self);
}

isalpha :: proc(c: u8) -> bool {
	switch c {
		case 'a'..='z', 'A'..='Z': return true;
		case: return false;
	}
}

isdigit :: proc(c: u8) -> bool {
	switch c {
		case '0'..='9': return true;
		case: return false;
	}
}

@(test) 
isalphatest :: proc(t: ^testing.T) {
	testing.expect(t, isalpha('a'));
	testing.expect(t, !isalpha('0'));
}

advance :: proc(self: ^lexer) {
	using self;

	// Consume whitespace
	if pos != len(source) {	
		for source[pos] == ' ' {
			pos+=1;
		}
	}
	
	if pos == len(source) {
		front = token{type = .EOF}
		return
	}

	switch source[pos] {
		case 'A'..='Z', 'a'..='z':
			startpos := pos;
			for pos < len(source) && isalpha(source[pos]) {
				pos+=1;
			}
			t: token_type = .Identifier;
			txt := source[startpos:pos];
			if (txt == "var") {
				t = .VarKeyword;
			} else if (txt == "optional") {
				t = .OptionalKeyword;
			} else if (txt == "constructor") {
				t = .ConstructorKeyword;
			} else if (txt == "begin") {
				t = .BeginKeyword;
			} else if (txt == "end") {
				t = .EndKeyword;
			}
			front = token{text = txt, type = t}
			return
		case '0'..='9':
			startpos := pos;
			for pos < len(source) && isdigit(source[pos]) {
				pos+=1;
			}
			front = token{text = source[startpos:pos], type = .Number}
			return
		case '+':
			front = token{text = source[pos:pos+1], type = .PlusSign}
			pos+=1;
			return
		case '-':
			front = token{text = source[pos:pos+1], type = .MinusSign}
			pos+=1;
			return
		case '(':
			front = token{text = source[pos:pos+1], type = .LParen}
			pos+=1;
			return
		case ')':
			front = token{text = source[pos:pos+1], type = .RParen}
			pos+=1;
			return
		case '!':
			front = token{text = source[pos:pos+1], type = .BangSign}
			pos+=1;
			return
		case '\n':
			front = token{text = source[pos:pos+1], type = .Newline}
			pos+=1;
			return;
	}
}

@(test)
lexertest :: proc(t: ^testing.T) {
	l: lexer;
	init(&l, "    var testing 123  ++");

	testing.expect(t, l.front.type == .VarKeyword);
	advance(&l);
	testing.expect(t, l.front.text == "testing");
	advance(&l);
	testing.expect(t, l.front.text == "123");
	advance(&l);

	testing.expect(t, l.front.text == "+");
	advance(&l);
	testing.expect(t, l.front.text == "+");
	advance(&l);	
	
	testing.expect(t, l.front.type == .EOF);
}
