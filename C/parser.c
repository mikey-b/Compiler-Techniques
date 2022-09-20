#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

int ipow(int base, int exp)
{
    int result = 1;
    for (;;)
    {
        if (exp & 1)
            result *= base;
        exp >>= 1;
        if (!exp)
            break;
        base *= base;
    }

    return result;
}

// TypeID's of tokens returned by the lexer
typedef enum {
    EndOfFile = 0,
    Number,
    Variable, 
    LParen,
    RParen,
    PlusSign,
    MinusSign,
    StarSign,
    DivideSign,
    BangSign,
    PowSign,

    LessThan,
    GreaterThan,
    EqualSign,
    NotEqualSign,
    EqualOrGreaterThan,
    EqualOrLessThan,

    TernaryStart,
    TernaryMiddle,

    AssignmentSign,

    Unknown
} token_id;

// A token - returned by the lexer
typedef struct {
    char* start_ptr;
    char* end_ptr;
    token_id type_id;
} token;


/*  --- Lexer Generator/Functor ---
    Running "lexer_functor()" will produce the next available token 
*/

char* current_pos;

token lexer_functor() {
    // Remove leading whitespace
    while(*current_pos == ' ') current_pos += 1;

    token res;

    switch(*current_pos) {
        case 'a'...'z': case 'A'...'Z':
            {
                // Save the starting position
                char* start_pos = current_pos;
                // Continue until we find something that isn't a digit, or end of input.
                while(*current_pos != '\0') {
                    if (!isalpha(*current_pos)) break;
                    current_pos += 1;
                }
                res = (token){start_pos, current_pos, Variable};                
            } break;
        case '0'...'9':
            {
                // Save the starting position
                char* start_pos = current_pos;
                // Continue until we find something that isn't a digit, or end of input.
                while(*current_pos != '\0') {
                    if (!isdigit(*current_pos)) break;
                    current_pos += 1;
                }
                res = (token){start_pos, current_pos, Number};
            } break;
        case '(': 
            {
                res = (token){current_pos, current_pos+1, LParen};
                current_pos += 1;            
            } break;
        case ')': 
            {
                res = (token){current_pos, current_pos+1, RParen};
                current_pos += 1;
            } break;
        case '+':
            {
                res = (token){current_pos, current_pos+1, PlusSign};
                current_pos += 1;
            } break;
        case '*': 
            {
                switch (*(current_pos+1)) {
                    case '*': {
                        res = (token){current_pos, current_pos+2, PowSign};
                        current_pos += 2;
                    } break;
                    default: {
                        res = (token){current_pos, current_pos+1, StarSign};
                        current_pos += 1;
                    }
                }
                
            } break;
        case '-':
            {
                res = (token){current_pos, current_pos+1, MinusSign};
                current_pos += 1;
            } break;
        case '/':
            {   
                res = (token){current_pos, current_pos+1, DivideSign};
                current_pos += 1;
            } break;
        case '!':
            {
                switch (*(current_pos+1)) {
                    case '=': {
                        res = (token){current_pos, current_pos+2, NotEqualSign};
                        current_pos += 2;
                    } break;
                    default: {
                        res = (token){current_pos, current_pos+1, BangSign};
                        current_pos += 1;
                    }
                }

            } break;
        case '>':
            {  
                switch (*(current_pos+1)) {
                    case '=': {
                        res = (token){current_pos, current_pos+2, EqualOrGreaterThan};
                        current_pos += 2;
                    } break;
                    default: {
                        res = (token){current_pos, current_pos+1, GreaterThan};
                        current_pos += 1;
                    }
                }

            } break;
        case '<':
            {  
                switch (*(current_pos+1)) {
                    case '=': {
                        res = (token){current_pos, current_pos+2, EqualOrLessThan};
                        current_pos += 2;
                    } break;
                    default: {
                        res = (token){current_pos, current_pos+1, LessThan};
                        current_pos += 1;
                    }
                }
            } break;
        case '=':
            {  
                switch (*(current_pos+1)) {
                    case '=': {
                        res = (token){current_pos, current_pos+2, EqualSign};
                        current_pos += 2;
                    } break;
                    default: {
                        res = (token){current_pos, current_pos+1, AssignmentSign};
                        current_pos += 1;
                    }
                }
            } break;       
        case '?':
            {
                res = (token){current_pos, current_pos+1, TernaryStart};
                current_pos += 1;
            } break;
        case ':':
            {
                res = (token){current_pos, current_pos+1, TernaryMiddle};
                current_pos += 1;
            } break;
        case '\0':
            {
                res = (token){current_pos, current_pos+1, EndOfFile};
                // We don't increment - You will continuously get EOF.
            } break;
        default:
            {
                res = (token){current_pos, current_pos+1, Unknown};
                current_pos += 1;
                return res;
            };
    }

#ifndef NDEBUG
    printf("token - %.*s\n ", (res.end_ptr - res.start_ptr), res.start_ptr);
#endif

    return res;
};

/*  --- Lexer, Lookahead Buffer ---
    1 Token Lookahead supported.
    A custom allocator is really adventagous, and should be added here.
*/

token current;

bool peekFor(token_id lookingFor) {
    return (current.type_id == lookingFor);
}

inline token front() {
    return current;
}

inline void advance() {
    current = lexer_functor();
}

/*  --- PARSER ---
    Index:
        1 - Basic "Class" definitions
            - Expression (Base/Abstract Class)
            - Number Literal 
            - Sub Expression (...body...)
            - Infix Expression <lhs> <op> <rhs>
*/
typedef struct expression {
    //void(*display)(struct expression*, int indent);
    int(*evaluate)(struct expression*);
    void(*destroy)(struct expression*);
} expression;

    // Variable
    typedef struct {
        expression base;
        token var;
    } variable_literal;
/*
    void variable_display(expression* s, int indent) {
        variable_literal* self = (variable_literal*)s;
        printf("%*s<variable>%.*s</variable>", indent, " ", (self->var.end_ptr - self->var.start_ptr), self->var.start_ptr);
    }
*/
    int variable_evaluate(expression* s) {
        variable_literal* self = (variable_literal*)s;
        int len = (self->var.end_ptr - self->var.start_ptr);
        char *tmp = malloc(len + 1);
        memcpy(tmp, self->var.start_ptr, len);
        tmp[len] = '\0';

        int res = 88;
        if (tmp[0] == 'a') res = 42;
        if (tmp[0] == 'b') res = 13;
        free(tmp);
        return res;
    }

    // Number
    typedef struct {
        expression base;
        token number;
    } number_literal;
/*
    void number_display(expression* s, int indent) {
        number_literal* self = (number_literal*)s;
        printf("%*s<number>%.*s</number>", indent, " ", (self->number.end_ptr - self->number.start_ptr), self->number.start_ptr);
    }
*/
    int number_evaluate(expression* s) {
        number_literal* self = (number_literal*)s;
        int len = (self->number.end_ptr - self->number.start_ptr);
        char *tmp = malloc(len + 1);
        memcpy(tmp, self->number.start_ptr, len);
        tmp[len] = '\0';
        int res = atoi(tmp);
        free(tmp);
        return res;
    }

    // ( ...body... )
    typedef struct {
        expression base;
        expression* body;
    } sub_expression;
/*
    void sub_expression_display(expression* s, int indent) {
        sub_expression* self = (sub_expression*)s;
        printf("%*s<sub_expression>\n", indent, " ");
        self->body->display(self->body, indent+1);
        printf("\n%*s</sub_expression>", indent, " ");
    }
*/
    int sub_expression_evaluate(expression* s) {
        sub_expression* self = (sub_expression*)s;
        return self->body->evaluate(self->body);
    }

    // <lhs:expression> <opeartor> <rhs:expression>
    typedef struct {
        expression base;
        expression* lhs;
        token operator;
        expression* rhs;
    } infix_expression;
/*
    void infix_display(expression* s, int indent) {
        infix_expression* self = (infix_expression*)s;
        printf("%*s<infix op=\"%.*s\">\n", indent, " ", (self->operator.end_ptr - self->operator.start_ptr), self->operator.start_ptr);

        printf("%*s<lhs>\n", indent+1, " ");
        self->lhs->display(self->lhs, indent+2);
        printf("\n%*s</lhs>\n", indent+1, " ");
        
        printf("%*s<rhs>\n", indent+1, " ");
        self->rhs->display(self->rhs, indent+2);
        printf("\n%*s</rhs>\n", indent+1, " ");

        printf("%*s</infix>", indent, " ");

    }
*/
    int infix_expression_evaluate(expression* s) {
        infix_expression* self = (infix_expression*)s;

        int lhs_res = self->lhs->evaluate(self->lhs);
        int rhs_res = self->rhs->evaluate(self->rhs);

        switch(self->operator.type_id) {
            case PlusSign: return lhs_res + rhs_res;
            case MinusSign: return lhs_res - rhs_res;
            case StarSign: return lhs_res * rhs_res;
            case DivideSign: return lhs_res / rhs_res;

            case GreaterThan: return (lhs_res > rhs_res);
            case EqualOrGreaterThan: return (lhs_res >= rhs_res);
            case LessThan: return (lhs_res < rhs_res);
            case EqualOrLessThan: return (lhs_res <= rhs_res);
            case EqualSign: return (lhs_res == rhs_res);
            case NotEqualSign: return (lhs_res != rhs_res);

            case PowSign: return ipow(lhs_res, rhs_res);
        }
    }

    // <opeartor> <body:expression>
    typedef struct {
        expression base;
        token operator;
        expression* body;
    } prefix_expression;
/*
    void prefix_display(expression* s, int indent) {
        prefix_expression* self = (prefix_expression*)s;
        printf("%*s<prefix op=\"%.*s\">\n", indent, " ", (self->operator.end_ptr - self->operator.start_ptr), self->operator.start_ptr);

        self->body->display(self->body, indent+1);

        printf("\n%*s</prefix>", indent, " ");

    }
*/
    int prefix_expression_evaluate(expression* s) {
        prefix_expression* self = (prefix_expression*)s;

        int body_res = self->body->evaluate(self->body);

        switch(self->operator.type_id) {
            case PlusSign: return 0 + body_res;
            case MinusSign: return 0 - body_res;
        }
    } 

    //  <body:expression> <opeartor>
    typedef struct {
        expression base;
        token operator;
        expression* body;
    } postfix_expression;
/*
    void postfix_display(expression* s, int indent) {
        postfix_expression* self = (postfix_expression*)s;
        printf("%*s<postfix op=\"%.*s\">\n", indent, " ", (self->operator.end_ptr - self->operator.start_ptr), self->operator.start_ptr);

        self->body->display(self->body, indent+1);

        printf("%*s</postfix>", indent, " ");

    }
*/
    int postfix_expression_evaluate(expression* s) {
        postfix_expression* self = (postfix_expression*)s;

        int body_res = self->body->evaluate(self->body);

        switch(self->operator.type_id) {
            case BangSign: {
                int res = 1;
                for(int i = 1; i <= body_res; ++i) res *= i;
                return res;
            }
        }
    }       

    //  <predicate:expression> ? <path1> : <path2>
    typedef struct {
        expression base;
        token operator;
        expression* predicate;
        expression* path1;
        expression* path2;
    } ternary_expression;
/*
    void ternary_display(expression* s, int indent) {
        ternary_expression* self = (ternary_expression*)s;
        printf("%*s<ternary op=\"%.*s\">\n", indent, " ", (self->operator.end_ptr - self->operator.start_ptr), self->operator.start_ptr);

        self->predicate->display(self->predicate, indent+1);

        printf("%*s</ternary>", indent, " ");

    }
*/
    int ternary_expression_evaluate(expression* s) {
        ternary_expression* self = (ternary_expression*)s;

        int predicate_res = self->predicate->evaluate(self->predicate);
        if (predicate_res == 1) {
            int res = self->path1->evaluate(self->path1);
            return res;
        } else {
            int res = self->path2->evaluate(self->path2);
            return res;            
        }
    }  

/*
    These are AST node creation functions.
    create_expression is a Factory Function, You can consider it like an "Abstract Class"
    There is no such thing as an "expression" AST node, but will return the correct instance that is parses
*/

    expression* create_expression(int right_bp);

    void number_destroy(expression* s) {
        free((number_literal*)s);
    }

    expression* create_number_literal() {
        number_literal* result = malloc(sizeof(number_literal));
        //result->base.display = &number_display;
        result->base.evaluate = &number_evaluate;
        result->base.destroy = &number_destroy;

        result->number = front();
        advance();

        return (expression*)result;
    }

    void variable_destroy(expression* s) {
        free((variable_literal*)s);
    }

    expression* create_variable_literal() {
        variable_literal* result = malloc(sizeof(variable_literal));
        //result->base.display = &variable_display;
        result->base.evaluate = &variable_evaluate;
        result->base.destroy = &variable_destroy;

        result->var = front();
        advance();

        return (expression*)result;
    }

    void sub_expression_destroy(expression* s) {
        free((sub_expression*)s);
    }

    expression* create_sub_expression() {
        sub_expression* result = malloc(sizeof(sub_expression));
        result->base.evaluate = &sub_expression_evaluate;
        result->base.destroy = &sub_expression_destroy;

        if (!peekFor(LParen)) {
            // Should do error handling!
            return (expression*)result;
        }
        advance();
        
        result->body = create_expression(0);

        if (!peekFor(RParen)) {
            // Should do error handling!
            return (expression*)result;
        }
        advance();

        return (expression*)result;
    }

    void infix_destroy(expression* s) {
        free((infix_expression*)s);
    }

    expression* create_infix_expression( expression* _lhs, int min_bp ) {
        infix_expression* result = malloc(sizeof(infix_expression));
        //result->base.display = &infix_display;
        result->base.evaluate = &infix_expression_evaluate;
        result->base.destroy = &infix_destroy;

        result->lhs = _lhs;
        result->operator = front();
        advance();
        result->rhs = create_expression(min_bp);    

        return(expression*)result;
    }


    void prefix_destroy(expression* s) {
        free((prefix_expression*)s);
    }

    expression* create_prefix_expression( int min_bp ) {
        prefix_expression* result = malloc(sizeof(prefix_expression));
        //result->base.display = &prefix_display;
        result->base.evaluate = &prefix_expression_evaluate;
        result->base.destroy = &prefix_destroy;
        
        result->operator = front();
        advance();
        result->body = create_expression(min_bp);

        return(expression*)result;
    }

    void postfix_destroy(expression* s) {
        free((postfix_expression*)s);
    }

    expression* create_postfix_expression(expression* _lhs, int min_bp ) {
        prefix_expression* result = malloc(sizeof(prefix_expression));
        //result->base.display = &postfix_display;
        result->base.evaluate = &postfix_expression_evaluate;
        result->base.destroy = &postfix_destroy;
        
        result->body = _lhs;
        result->operator = front();
        advance();

        return(expression*)result;
    }

    void ternary_destroy(expression* s) {
        free((ternary_expression*)s);
    }

    expression* create_ternary_expression(expression* _pred ) {
        ternary_expression* result = malloc(sizeof(ternary_expression));
        //result->base.display = &ternary_display;
        result->base.evaluate = &ternary_expression_evaluate;
        result->base.destroy = &ternary_destroy;
        
        result->predicate = _pred;
        // get ? 
        advance();
        result->path1 = create_expression(0);
        // get :
        advance();
        result->path2 = create_expression(0);

        return(expression*)result;
    }

typedef struct {
    int left_power;
    int right_power;
} binding_power;

binding_power RightAssociative(int p) {
    return (binding_power){p + 1, p};
}

binding_power LeftAssociative(int p) {
    return (binding_power){p - 1, p};
}

binding_power bp_lookup(token_id type) {
    // Binding Power Table, Associativity can also be handled here by returning a second binding power
    // Larger for Left binding, lower for Right binding. E.g. (10, 11) - Left binding, (10, 9) - Right binding
    switch(type) {
        // --- Infix ---
        case PlusSign: return LeftAssociative(100);
        case MinusSign: return LeftAssociative(100);
        case StarSign: return LeftAssociative(200);
        case DivideSign: return LeftAssociative(200);
        case PowSign: return RightAssociative(99);
        case TernaryStart: return RightAssociative(1000);

        case GreaterThan: return LeftAssociative(50);
        case EqualOrGreaterThan: return LeftAssociative(50);
        case LessThan: return LeftAssociative(50);
        case EqualOrLessThan: return LeftAssociative(50);
        case EqualSign: return LeftAssociative(50);
        case NotEqualSign: return LeftAssociative(50);

        // --- Postfix --- (Always Right Associative)
        case BangSign: return RightAssociative(400);
        default: return (binding_power){0,0};
    }
}

int prefix_bp_lookup(token_id type) {
    switch(type) {
        case PlusSign: return 300;
        case MinusSign: return 300;
        default: return 0;
    }
}

expression* create_expression(int right_bp) {
    expression* result = NULL;

    // Check to see if this is a prefix or a valid infix left-hand-side.
    if (peekFor(Number)) {
        result = create_number_literal();
    } else if (peekFor(Variable)) {
        result = create_variable_literal();
    } else if (peekFor(LParen)) {
        result = create_sub_expression();

    // --- Prefix Operators ---
    } else if (peekFor(PlusSign) || peekFor(MinusSign)) {
        result = create_prefix_expression( prefix_bp_lookup( front().type_id) );
    }
 
    // Check the next token, if its a valid infix token. Plus the LHS we've just parsed down the AST
    // and into the infix AST node.
    while(right_bp < bp_lookup( front().type_id ).left_power ) {

        // --- Postfix ---
        if (peekFor(BangSign)) {
            result = create_postfix_expression(result, bp_lookup( front().type_id).right_power );
        } else if (peekFor(TernaryStart)) {
            result = create_ternary_expression( result );
        // --- Infix ---
        } else {
            result = create_infix_expression(result, bp_lookup( front().type_id ).right_power );
        }
    }

    // Check we didn't mess up
    assert(result != NULL);
    return result;
}

int main(int argc, char *argv[]) {
    // Source code to parse
    char input[] = "(2 ** 3 ** 2 != 512) ? 10 : (20 * 2 == 4 * 10) ? a : b";

    // Set up the lexer input state, prime the lexer with the first token.
    current_pos = input;
    advance();

    // Create the AST for the expression
    expression* ast = create_expression(0);

    // Evaluate the AST into a value
    int res = ast->evaluate(ast);
    puts("a = 42, b = 13, anything else = 88\n");
    printf("Input = %s\n", input);
    printf("Result = %d\n\n", res);

    // Print the AST in XML
    //ast->display(ast,0);

    ast->destroy(ast);

   return 0;
}