package parser

import "core:strconv"
import "core:math"
import "core:mem"
import "core:testing"
import "core:fmt"

import "lex"
lexer :: lex.lexer;
token_type :: lex.token_type;
token :: lex.token;
init :: lex.init;
advance :: lex.advance;

expression :: struct {
	deinit: proc(^expression),
	evaluate: proc(^expression) -> int,
}

number_literal_init :: proc(l: ^lexer) -> ^expression {

	number_literal :: struct {
		using base: expression,
		value: int,
	}

	assert(l.front.type == .Number);
	result := new(number_literal);
	
	result.deinit = proc(s: ^expression) {
		self := cast(^number_literal)s;
		free(self);
	}
	result.evaluate = proc(s: ^expression) -> int {
		self := cast(^number_literal)s;
		return self.value;
	}
		
	v,e := strconv.parse_int(l.front.text);
	result.value = v;
	advance(l);
	return result;
}

infix_expression_builder :: proc(l: ^lexer, e: ^expression, bp: int) -> ^expression {

	infix_expression :: struct {
		using base: expression,
		lhs: ^expression,
		operator: token,
		rhs: ^expression,
	}

	result := new(infix_expression);

	result.deinit = proc(s: ^expression) {
		using self := cast(^infix_expression)s;
		lhs->deinit();
		rhs->deinit();
		free(self);
	}
	result.evaluate = proc(s: ^expression) -> int {
		using self := cast(^infix_expression)s;
		#partial switch operator.type {
			case .PlusSign: return lhs->evaluate() + rhs->evaluate();
			case .MinusSign: return lhs->evaluate() - rhs->evaluate();
			case: return 0;
		}
	}
	
	result.lhs = e;
	result.operator = l.front;
	advance(l);
	result.rhs = expression_factory(l, bp);
	
	return result;
}

prefix_expression_builder :: proc(l: ^lexer, bp: int) -> ^expression {

	prefix_expression :: struct {
		using base: expression,
		operator: token,
		rhs: ^expression
	}
	
	result := new(prefix_expression);
	result.deinit = proc(s: ^expression) {
		using self := cast(^prefix_expression)s;
		rhs->deinit();
		free(self);
	}
	result.evaluate = proc(s: ^expression) -> int {
		using self := cast(^prefix_expression)s;
		#partial switch self.operator.type {
			case .PlusSign: return 0 + rhs->evaluate();
			case .MinusSign: return 0 - rhs->evaluate();
			case: return 0;
		}
	}
	
	result.operator = l.front;
	advance(l);
	
	result.rhs = expression_factory(l, bp);
	
	return result;
}

postfix_expression_builder :: proc(l: ^lexer, exp: ^expression) -> ^expression {
	postfix_expression :: struct {
		using base: expression,
		lhs: ^expression,
		operator: token
	}
	result := new(postfix_expression);
	result.deinit = proc(s: ^expression) {
		using self := cast(^postfix_expression)s;
		lhs->deinit();
		free(self);
	}
	result.evaluate = proc(s: ^expression) -> int {
		using self := cast(^postfix_expression)s;
		#partial switch operator.type {
			case .BangSign: return math.factorial( lhs->evaluate() );
			case: return 0;
		}
	}
	
	result.lhs = exp;
	
	assert(l.front.type == .BangSign);
	result.operator = l.front;
	advance(l);
	
	return result;
}

sub_expression_builder :: proc(l: ^lexer) -> ^expression {

	sub_expression :: struct {
		using base: expression,
		exp: ^expression
	}
	
	result := new(sub_expression);
	result.deinit = proc(s: ^expression) {
		using self := cast(^sub_expression)s;
		exp->deinit();
		free(self);
	}
	result.evaluate = proc(s: ^expression) -> int {
		using self := cast(^sub_expression)s;
		
		return exp->evaluate();
	}
	
	assert(l.front.type == .LParen);
	advance(l);
	
	result.exp = expression_factory(l);
	
	assert(l.front.type == .RParen);
	advance(l);
	
	return result;
}

binding_power :: struct {
	left_power: int,
	right_power: int
}

RightAssociative :: proc(p: int) -> binding_power {
	return binding_power{ p + 1, p};
}

LeftAssociative :: proc(p: int) -> binding_power {
	return binding_power{p - 1, p};
}

bp_lookup :: proc(type: token_type) -> binding_power {
	#partial switch type { //Why is partial needed here?
		case .PlusSign: return LeftAssociative(100);
		case .MinusSign: return LeftAssociative(100);
		
		case .BangSign: return RightAssociative(400);
		case: return binding_power{0,0};
	}
}

prefix_bp_lookup :: proc(type: token_type) -> int {
	#partial switch type {
        case .PlusSign: return 300;
        case .MinusSign: return 300;
        case: return 0;
    }
}

expression_factory :: proc(l: ^lexer, right_bp: int = 0) -> ^expression {
	result: ^expression;
	
	if (l.front.type == .Number) {
		result = number_literal_init(l);
	} else if (l.front.type == .LParen) {
		result = sub_expression_builder(l);
		
	// Prefix Expressions
	} else if (prefix_bp_lookup(l.front.type) != 0) {
		result = prefix_expression_builder(l, prefix_bp_lookup(l.front.type) );
	}
	
	for right_bp < bp_lookup(l.front.type).left_power {
		if (l.front.type == .BangSign) {
			result = postfix_expression_builder(l, result);
		} else {
			result = infix_expression_builder(l, result, bp_lookup(l.front.type).right_power);
		}
	}
	
	return result;
}

@(test)
testexpr :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	{
		l: lexer;
		init(&l, "(4-3+2)! + 5");
		
		exp := expression_factory(&l);
		defer exp->deinit();
		
		testing.expect(t, l.front.type == .EOF);

		sum := exp->evaluate();
		
		testing.expect(t, sum == 11);

		fmt.println(sum);
	}

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}
