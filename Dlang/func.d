module func;

import node;
import block;

class funct: branch_node {
    node_t[] func_name;
    node_t[] func_body;

    this(lexer_t l) {
        match!(token_type.func_keyword)(l);
        match!(token_type.Identifier)(l, func_name);
        match!(token_type.LParen)(l);
        // Arguments Not Supported but would go here
        match!(token_type.RParen)(l);

        match!(block_node)(l, func_body);
    }

    override string toString() {
        import std.algorithm;
        auto classname = this.classinfo.name.findSplit(".")[2];
        auto res = "<" ~ classname ~ " name=\"" ~ func_name[0].toString() ~ "\">\n";
        res ~= "<body>\n" ~ func_body[0].toString() ~ "</body>\n";
        res ~= "</" ~ classname ~ ">\n";
        return res;
    }
}