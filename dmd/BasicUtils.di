// D import file generated from './dmd/BasicUtils.d'
module dmd.BasicUtils;
import std.format;
import std.exception;
import std.stdio;
import std.array;
import std.c.stdlib;
LexGlobal lexGlobal;
struct Loc
{
    string filename;
    uint linnum;
    this(int x)
{
linnum = x;
filename = null;
}
    this(string filename, uint linnum)
{
this.linnum = linnum;
this.filename = filename;
}
    string toChars()
{
auto buf = appender!(string)();
if (filename)
buf.put(filename);
if (linnum)
formattedWrite(buf,"(%s)",linnum);
return buf.data;
}
    bool equals(ref const(Loc) loc)
{
assert(false);
}
}
template warning(T...)
{
void warning(string format, T t)
{
assert(false);
}
}
template warning(T...)
{
void warning(Loc loc, string format, T t)
{
if (lexGlobal.params.warnings && !lexGlobal.gag)
{
write("warning - ");
error(loc,format,t);
}
}
}
template error(T...)
{
void error(string format, T t)
{
writefln(format,t);
exit(EXIT_FAILURE);
}
}
template error(T...)
{
void error(Loc loc, string format, T t)
{
if (!lexGlobal.gag)
{
string p = loc.toChars();
if (p.length != 0)
writef("%s: ",p);
write("Error: ");
writefln(format,t);
}
lexGlobal.errors++;
}
}
enum 
{
EXIT_SUCCESS,
EXIT_FAILURE,
}
void fatal()
{
exit(EXIT_FAILURE);
}
alias int DYNCAST;
enum 
{
DYNCAST_OBJECT,
DYNCAST_EXPRESSION,
DYNCAST_DSYMBOL,
DYNCAST_TYPE,
DYNCAST_IDENTIFIER,
DYNCAST_TUPLE,
}
struct LexGlobal
{
    string sym_ext = "d";
    string doc_ext = "html";
    string ddoc_ext = "ddoc";
    string json_ext = "json";
    string map_ext = "map";
    string hdr_ext = "di";
    string copyright = "Copyright (c) 1999-2009 by Digital Mars";
    string written = "written by Walter Bright, ported to D by community" ~ ", severely abused by Zach the Mystic ";
    Param params;
    uint errors;
    uint gag;
    int structalign = 8;
    string version_ = "v0.01";
    char[11 + 1] date;
    char[8 + 1] time;
    char[24 + 1] timestamp;
}
struct Param
{
    int debuglevel;
    bool[string] debugids;
    bool[string] debugidsNot;
    int versionlevel;
    bool[string] versionids;
    bool[string] versionidsNot;
    bool warnings;
    byte Dversion;
    bool useDeprecated = false;
    bool useInvariants = false;
}
