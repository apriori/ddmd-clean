// D import file generated from './dmd/Lexer.d'
module dmd.Lexer;
import dmd.BasicUtils;
import dmd.Token;
import dmd.Identifier;
import std.stdio;
import std.ascii;
import std.uni;
import std.conv;
import std.encoding;
import std.utf;
import std.array;
class Lexer
{
    Loc loc;
    char[] srcbuf;
    char* p;
    size_t endBuf;
    Token token;
    string modName;
    int doDocComment;
    int anyToken;
    int commentToken;
    static Token* freelist;

    static Appender!(char[]) stringbuffer;

    this(string mod, char[] srcbuf, uint begoffset, int doDocComment, int commentToken);
    void setBuf(ref char[] srcbuf)
{
if (srcbuf[$ - 1] != '\x00' && srcbuf[$ - 1] != 26)
this.srcbuf = srcbuf ~ '\x00';
else
this.srcbuf = srcbuf;
p = this.srcbuf.ptr;
}
    nothrow pure @safe bool isIdChar(char c)
{
return std.ascii.isAlphaNum(c) || c == '_';
}

    TOK nextToken();
    TOK peekNext()
{
return peek(&token).value;
}
    TOK peekNext2()
{
Token* t = peek(&token);
return peek(t).value;
}
    void scan(Token* t);
    Token* peek(Token* ct);
    Token* newToken();
    Token* peekPastParen(Token* tk);
    uint escapeSequence();
    TOK wysiwygStringConstant(Token* t, int tc);
    TOK hexStringConstant(Token* t);
    TOK delimitedStringConstant(Token* t);
    TOK tokenStringConstant(Token* t);
    TOK escapeStringConstant(Token* t, int wide);
    TOK charConstant(Token* t, int wide);
    void stringPostfix(Token* t);
    uint wchar_(uint u)
{
assert(false);
}
    TOK number(Token* t);
    TOK inreal(Token* t);
    template error(T...)
{
void error(string format, T t)
{
error(this.loc,format,t);
}
}
    template error(T...)
{
void error(Loc loc, string format, T t)
{
if (modName && !lexGlobal.gag)
{
string p = loc.toChars();
if (p)
writef("%s: ",p);
writefln(format,t);
if (lexGlobal.errors >= 20)
fatal();
}
lexGlobal.errors++;
}
}
    void pragma_();
    uint decodeUTF();
    void getDocComment(Token* t, uint lineComment)
{
}
    static string combineComments(string c1, string c2)
{
assert(false,"zd cut");
}

    static bool isValidIdentifier(string p)
{
assert(false);
}

}
