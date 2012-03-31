module dmd.docComment;
// Nothin in here. Prolly a wasta time. 

import dmd.Scope;
import dmd.dsymbol;

import std.array;

class Section 
{
    char[] name;

    char[] body_;

    int nooutput;

    void write(DocComment dc, Scope sc, Dsymbol s, ref Appender!(char[]) buf)
	{
		assert(false);
	}
}

struct Macro
{
}

struct Escape
{
    char[] strings[256];

    static char[] escapeChar(uint c)
	{
		assert(false);
	}
}

class DocComment
{
    Section[] sections;		// Section*[]

    Section summary;
    Section copyright;
    Section macros;
    Macro** pmacrotable;
    Escape** pescapetable;

    this()
	{
		assert(false);
	}

    static DocComment parse(Scope sc, Dsymbol s, ubyte[] comment)
	{
		assert(false);
	}
	
    static void parseMacros(Escape** pescapetable, Macro** pmacrotable, ubyte* m, uint mlen)
	{
		assert(false);
	}
	
    static void parseEscapes(Escape** pescapetable, ubyte* textstart, uint textlen)
	{
		assert(false);
	}

    void parseSections(ubyte* comment)
	{
		assert(false);
	}
	
    void writeSections(Scope sc, Dsymbol s, ref Appender!(char[]) buf)
	{
		assert(false);
	}
}
