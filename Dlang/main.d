import std.stdio;

import lexer;
// - Lexer. Breaks down the input string into tokens(the string start, end, and token type)
import func;
// - Parser. Root node that will construct your tree recursively.

void main() {
    {
        // You will have a top level node, "File", "Module", "Class" or "Unit" - Something that represents 
        // a full file that is read in. This is just an example of parsing a function with RDP, along with a Pratt Parser
        // for operator precedence.        

        auto source_code = "func main() { return (2 ** 3 ** 2 != 512) ? 10 : (20 * 2 == 4 * 10) ? 42 : 69; }";
        auto l = new lang_lexer(source_code);
        auto f = new funct(l);
        writeln(f);
    }

    { /* Pratt Parser */
        // This is a direct test of the expression parsing, which uses operator precedence
        // Also added evaluation of the AST tree expressions, shouldn't really be done her for a serious project.
        import expressions;
        auto source_code = "(1+2 != 3) ? 0 : (20 * 2 == 4 * 10) ? (7*8-3) : 69";
        auto l = new lang_lexer(source_code);
        auto f = expression.factory(l);
        writeln("Evaluating: " ~ source_code);
        writeln(f.evaluate());
    }
    return;
}