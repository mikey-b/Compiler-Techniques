module expressions;

import node;

// --- Binding Power Table ---
// -- bp_lookup defines the binding powers of infix and postfix operators. --
// Smaller binding numbers are stronger binding operators.
struct binding_power { int left_power; int right_power; }
binding_power RightAssociative(int p) { return binding_power(p+1, p); }
binding_power LeftAssociative(int p)  { return binding_power(p - 1, p); }

binding_power bp_lookup(token_type type) {
    switch(type) {
        case token_type.PlusSign: return LeftAssociative(100);
        case token_type.MinusSign: return LeftAssociative(100);
        case token_type.StarSign: return LeftAssociative(200);
        case token_type.DivideSign: return LeftAssociative(200);
        case token_type.PowSign: return RightAssociative(99);
        case token_type.TernaryStart: return RightAssociative(1000);

        case token_type.GreaterThan: return LeftAssociative(50);
        case token_type.EqualOrGreaterThan: return LeftAssociative(50);
        case token_type.LessThan: return LeftAssociative(50);
        case token_type.EqualOrLessThan: return LeftAssociative(50);
        case token_type.EqualSign: return LeftAssociative(50);
        case token_type.NotEqualSign: return LeftAssociative(50);

        // Postfix is always Right Associative
        case token_type.BangSign: return RightAssociative(400);
        default: return binding_power(0,0);
    }
}

// -- prefix_bp_lookup defines the binding powers of prefix operators --
int prefix_bp_lookup(token_type type) {
    switch(type) {
        case token_type.PlusSign: return 300;
        case token_type.MinusSign: return 300;
        default: return 0;
    }
}

// --- Main Pratt Parser ---
// loop is coded in the factory function.
abstract class expression: branch_node {

    static expression factory(lexer_t l, int right_bp = 0) {
        expression result;

        // Check to see if this is a prefix or a valid infix left-hand-side.
        if (l.front.type == token_type.Number) {
            result = new number_literal(l);
        } else if (l.front.type == token_type.LParen) {
            result = new sub_expression(l);
        

        // or check for Prefix operator..
        // --- Prefix Operator lookahead ---
        } else if ((l.front.type == token_type.PlusSign) || (l.front.type == token_type.MinusSign)) {
            result = new prefix_expression( l, prefix_bp_lookup(l.front.type) );
        }

        // Postfix and Infix operators have binding powers.
        // If the binding power is stronger, the current expression is pushed down the AST tree
        while( right_bp < bp_lookup(l.front.type).left_power ) {
            
            // --- Postfix lookahead ---
            if (l.front.type == token_type.BangSign) {
                // This is performing an AST rotation, current result is made a child of the new expression node
                result = new postfix_expression(l, result);
            } else if (l.front.type == token_type.TernaryStart) {
                result = new ternary_expression(l, result);

            // --- Infix lookahead ---
            // It must be an infix operator. Anything that isn't an infix
            // or prefix is an error. (only infix and prefix operators have left binding power)
            // an Assert wouldn't hurt though to catch bugs
            } else {
                result = new infix_expression(l, result, bp_lookup(l.front.type).right_power );
            }         
        }

        return result;
    }

    abstract int evaluate();
}



// Below are all the expression subtypes that the factory can return

class number_literal: expression {
    node_t[] value;

    this(lexer_t l) {
        match!(token_type.Number)(l, value);
    }

    override int evaluate() {
        import std.conv: to;
        return to!int(value[0].toString());
    }
}

class sub_expression: expression {
    node_t[] e_body;

    this(lexer_t l) {
        match!(token_type.LParen)(l);
        match!(expression)(l, e_body);
        match!(token_type.RParen)(l);
    }

    override int evaluate() {
        return (cast(expression)e_body[0]).evaluate();
    }
}

class infix_expression: expression {
    node_t[] lhs;
    token operator;
    node_t[] rhs;

    this(lexer_t l, expression _lhs, int min_bp ) {
        lhs ~= _lhs;

        operator = l.front;
        l.advance();

        match!(expression)(l, rhs, min_bp);
    }

    override int evaluate() {
        import std.math.exponential: pow;

        auto lhs_res = (cast(expression)lhs[0]).evaluate();
        auto rhs_res = (cast(expression)rhs[0]).evaluate();

        switch(operator.type) {
            case token_type.PlusSign: return lhs_res + rhs_res;
            case token_type.MinusSign: return lhs_res - rhs_res;
            case token_type.StarSign: return lhs_res * rhs_res;
            case token_type.DivideSign: return lhs_res / rhs_res;

            case token_type.GreaterThan: return (lhs_res > rhs_res);
            case token_type.EqualOrGreaterThan: return (lhs_res >= rhs_res);
            case token_type.LessThan: return (lhs_res < rhs_res);
            case token_type.EqualOrLessThan: return (lhs_res <= rhs_res);
            case token_type.EqualSign: return (lhs_res == rhs_res);
            case token_type.NotEqualSign: return (lhs_res != rhs_res);

            case token_type.PowSign: return pow(lhs_res, rhs_res);
            default: assert(0);
        }
    }
}

class prefix_expression: expression {
    token operator;
    node_t[] e_body;

    this(lexer_t l, int min_bp) {
        operator = l.front;
        l.advance();

        node_t[] tmp;
        match!(expression)(l, e_body, min_bp);
    }

    override int evaluate() {
        int body_res = (cast(expression)e_body[0]).evaluate();

        switch(operator.type) {
            case token_type.PlusSign: return 0 + body_res;
            case token_type.MinusSign: return 0 - body_res;
            default: assert(0);
        }
    }
}

class postfix_expression: expression {
    node_t[] e_body;
    token operator;

    this(lexer_t l, expression _lhs) {
        e_body ~= _lhs;
        operator = l.front;
        l.advance();
    }

    override int evaluate() {
        int body_res = (cast(expression)e_body[0]).evaluate();

        switch(operator.type) {
            case token_type.BangSign:
                int res = 1;
                for(int i = 1; i <= body_res; ++i) res *= i;
                return res;

            default: assert(0);
        }
    }
}

class ternary_expression: expression {
    node_t[] predicate;
    node_t[] true_path;
    node_t[] false_path;

    this(lexer_t l, expression _pred) {
        predicate ~= _pred;
        match!(token_type.TernaryStart)(l);
        match!(expression)(l, true_path, 0);
        match!(token_type.TernaryMiddle)(l);
        match!(expression)(l, false_path, 0);
    }

    override int evaluate() {
        int pred_res = (cast(expression)predicate[0]).evaluate();
        if (pred_res == 1) {
            return (cast(expression)true_path[0]).evaluate();
        } else {
            return (cast(expression)false_path[0]).evaluate();
        }
    }
}

