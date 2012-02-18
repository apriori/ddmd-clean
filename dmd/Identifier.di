// D import file generated from './dmd/Identifier.d'
module dmd.Identifier;
import dmd.BasicUtils;
import dmd.Token;
import std.array;
import std.conv;
import std.format;
Identifier[string] stringtable;
void initKeywords();
mixin(import("Id.txt"));
class Identifier
{
    TOK value;
    string string_;
    this(string string_, TOK value)
{
this.string_ = string_;
this.value = value;
}
    static void initKeywords();

    override bool opEquals(Object o);

    hash_t hashCode()
{
assert(false);
}
    void print()
{
assert(false);
}
    string toChars()
{
return string_;
}
    version (_DH)
{
    string toHChars()
{
assert(false);
}
}
    string toHChars2();
    DYNCAST dyncast()
{
return DYNCAST_IDENTIFIER;
}
    static Identifier idPool(string s)
{
Identifier sv = stringtable.get(s,null);
if (sv is null)
sv = new Identifier(s,TOKidentifier);
return sv;
}

    static Identifier uniqueId(string s)
{
static uint num = 0;
num++;
return uniqueId(s,num);
}

    static Identifier uniqueId(string s, int num)
{
string buffer = s ~ to!(string)(num);
assert(buffer.length + 3 * (int).sizeof + 1 <= 32);
return idPool(buffer);
}

}
