module node;
import std.conv: to;
import std.stdio;

enum token_type {
    EndOfFile = 0,
    Number,
    Identifier,
        func_keyword,
        return_keyword,
    LParen,
    RParen,
    LCurly,
    RCurly,
    PlusSign,
    MinusSign,
    StarSign,
    DivideSign,
    BangSign,
    PowSign,
    semicolon,

    LessThan,
    GreaterThan,
    EqualSign,
    NotEqualSign,
    EqualOrGreaterThan,
    EqualOrLessThan,

    TernaryStart,
    TernaryMiddle,

    AssignmentSign,

    //Unknown
}

abstract class lexer_t {
    token front;

    void advance();
}

abstract class node_t {
}

class token: node_t {
    immutable(char)* start_ptr;
    immutable(char)* end_ptr;
    token_type type;

    this(char* s, char* e, token_type t) {
        start_ptr = cast(immutable(char)*) s;
        end_ptr = cast(immutable(char)*) e;
        type = t;
    }

    override string toString() {
        string r = start_ptr[0..(end_ptr - start_ptr)];
        return r;
    }
}

abstract class branch_node: node_t {
    node_t[] children;

    void match(token_type lookFor)(lexer_t l) {
        if (l.front.type != lookFor) {
            writeln("Expected " ~ to!string(lookFor) ~ " Found " ~ to!string(l.front.type));
            assert(l.front.type == lookFor);
        }
        children ~= l.front;
        l.advance();
    }
    void match(token_type lookFor)(lexer_t l, ref node_t[] storeTo) {
        if (l.front.type != lookFor) {
            writeln("Expected " ~ to!string(lookFor) ~ " Found " ~ to!string(l.front));
            assert(l.front.type == lookFor);
        }
        auto tmp = l.front;
        storeTo ~= tmp;
        children ~= tmp;
        l.advance();
    }

    void match(T: branch_node, S: node_t[])(lexer_t l, ref S storeTo) {
        static if( __traits(isAbstractClass, T )) {
            auto tmp = T.factory(l);
            children ~= tmp;
            storeTo ~= tmp;
        } else {
            auto tmp = new T(l);
            children ~= tmp;
            storeTo ~= tmp;
        }
    }

    void match(T: branch_node, A)(lexer_t l, ref node_t[] storeTo, A v) {
        static if( __traits(isAbstractClass, T )) {
            auto tmp = T.factory(l, v);
            children ~= tmp;
            storeTo ~= tmp;
        } else {
            auto tmp = new T(l, v);
            children ~= tmp;
            storeTo ~= tmp;
        }
    }    
}