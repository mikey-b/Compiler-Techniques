module block;
import node;
import statements;

class block_node: branch_node {
    node_t[] instructions;
 public:
    this(lexer_t l) {
        match!(token_type.LCurly)(l);
        
        // Match Zero-or-more instructions
        while(true) {
            if (l.front.type == token_type.return_keyword) {
                match!(return_statement)(l, instructions);
            } else {
                break;
            }
        }

        match!(token_type.RCurly)(l);
    }

    override string toString() {
        //import std.algorithm;
        //auto classname = this.classinfo.name.findSplit(".")[2];
        auto res = ""; //"<block>\n" ~ "</block>\n";
        foreach(inst; instructions) {
            res ~= inst.toString();
        }
        //res ~= "</" ~ classname ~ ">\n";
        return res;
    }    
}