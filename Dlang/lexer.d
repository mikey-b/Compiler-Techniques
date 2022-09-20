module lexer;

import node;
import std.string : toStringz;
import std.ascii: isAlpha, isDigit;
import std.stdio;
import std.conv: to;

// The streaming lexer. There is a "token_type front" inherited from lexer_t.
// Which holds the current lexed token for lookahead purposes.

// Advance() reads in the next token into "front", one at a time.
class lang_lexer: lexer_t {
    char* current_pos;

 public:

    this(ref string source) {
        current_pos = cast(char*) toStringz(source);
        advance();
    }

    override void advance() {
        // Remove Leading Whitespace
        while(*current_pos == ' ') current_pos += 1;

        switch(*current_pos) {
            case 'a': .. case 'z':
                auto start_pos = current_pos;

                while(*current_pos != '\0') {
                    if (!isAlpha(*current_pos)) break;
                    current_pos += 1;
                }
                char[] r = start_pos[0 .. (current_pos - start_pos)];
                
                // Is this identifier a keyword?
                if (r == "func") {
                    front = new token(start_pos, current_pos, token_type.func_keyword);
                } else if (r == "return") {
                    front = new token(start_pos, current_pos, token_type.return_keyword);
                } else {
                    front = new token(start_pos, current_pos, token_type.Identifier);
                }
                return;

            case '0': .. case '9':
                auto start_pos = current_pos;

                while(*current_pos != '\0') {
                    if (!isDigit(*current_pos)) break;
                    current_pos += 1;
                }
                front = new token(start_pos, current_pos, token_type.Number);
                return;

            case ';':
                front = new token(current_pos, current_pos+1, token_type.semicolon);
                current_pos += 1;
                return;

            case '(':
                front = new token(current_pos, current_pos+1, token_type.LParen);
                current_pos += 1;
                return;

            case ')':
                front = new token(current_pos, current_pos+1, token_type.RParen);
                current_pos += 1;
                return;

            case '+':
                front = new token(current_pos, current_pos+1, token_type.PlusSign);
                current_pos += 1;
                return;

            case '*':
                switch(*(current_pos+1)) {
                    case '*':
                        front = new token(current_pos, current_pos+2, token_type.PowSign);
                        current_pos += 2;
                        return;
                    default:
                        front = new token(current_pos, current_pos+1, token_type.StarSign);
                        current_pos += 1;
                        return;
                }

            case '-':
                front = new token(current_pos, current_pos+1, token_type.MinusSign);
                current_pos += 1;
                return;

            case '/':
                front = new token(current_pos, current_pos+1, token_type.DivideSign);
                current_pos += 1;
                return;
            
            case '!':
                switch(*(current_pos+1)) {
                    case '=':
                        front = new token(current_pos, current_pos+2, token_type.NotEqualSign);
                        current_pos += 2;
                        return;
                    default:
                        front = new token(current_pos, current_pos+1, token_type.BangSign);
                        current_pos += 1;
                        return;
                }

            case '>':
                switch(*(current_pos+1)) {
                    case '=':
                        front = new token(current_pos, current_pos+2, token_type.EqualOrGreaterThan);
                        current_pos += 2;
                        return;
                    default:
                        front = new token(current_pos, current_pos+1, token_type.GreaterThan);
                        current_pos += 1;
                        return;
                }

            case '<':
                switch(*(current_pos+1)) {
                    case '=':
                        front = new token(current_pos, current_pos+2, token_type.EqualOrLessThan);
                        current_pos += 2;
                        return;
                    default:
                        front = new token(current_pos, current_pos+1, token_type.LessThan);
                        current_pos += 1;
                        return;
                }
            
            case '=':
                switch(*(current_pos+1)) {
                    case '=':
                        front = new token(current_pos, current_pos+2, token_type.EqualSign);
                        current_pos += 2;
                        return;
                    default:
                        front = new token(current_pos, current_pos+1, token_type.AssignmentSign);
                        current_pos += 1;
                        return;
                }

            case '?':
                front = new token(current_pos, current_pos+1, token_type.TernaryStart);
                current_pos += 1;
                return;

            case ':':
                front = new token(current_pos, current_pos+1, token_type.TernaryMiddle);
                current_pos += 1;
                return;

            case '\0':
                front = new token(current_pos, current_pos+1, token_type.EndOfFile);
                return;

            case '{':
                front = new token(current_pos, current_pos+1, token_type.LCurly);
                current_pos += 1;
                return;
            case '}':
                front = new token(current_pos, current_pos+1, token_type.RCurly);
                current_pos += 1;
                return;

            default: 
                writeln("Unknown token");
                string r = to!string(current_pos);
                writeln(r);
                assert(0);
        }
    }
}
