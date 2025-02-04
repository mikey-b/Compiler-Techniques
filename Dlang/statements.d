module statements;
import node;
import expressions;

class return_statement: branch_node {
    node_t[] e_body;
 public:
    this(lexer_t l) {
        match!(token_type.return_keyword)(l);
        match!(expression)(l, e_body);
        match!(token_type.semicolon)(l);
    }

    override string toString() {
        import std.conv: to;
        auto res = "<return>\n";
        res ~= to!string((cast(expression)e_body[0]).evaluate()) ~ "\n";
        res ~= "</return>\n";
        return res;
    }    
}