module dmd.BasicUtils;

// Loc, warning, error, fatal

import std.format, std.exception, std.stdio;
import std.array;
import std.c.stdlib : exit;

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
      
		if ( filename ) 
         buf.put(filename);

		if (linnum) 
         formattedWrite(buf, "(%s)", linnum);

		return buf.data;
	}

    bool equals(ref const(Loc) loc)
	{
		assert(false);
	}
}

void warning(T...)(string format, T t)
{
	assert(false);
}

void warning(T...)(Loc loc, string format, T t)
{
	if (lexGlobal.params.warnings && !lexGlobal.gag)
    {
		write("warning - ");
		error(loc, format, t);
    }
}

void error(T...)(string format, T t)
{
	writefln(format, t);
    exit(EXIT_FAILURE);
}

void error(T...)(Loc loc, string format, T t)
{
	if (!lexGlobal.gag)
    {
		string p = loc.toChars();

		if (p.length != 0)
			writef("%s: ", p);

		write("Error: ");
		writefln(format, t);

		//halt();
    }
    lexGlobal.errors++;
}

enum
{  
    EXIT_SUCCESS, EXIT_FAILURE,
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
    string sym_ext	= "d";

    string doc_ext	= "html";	// for Ddoc generated files
    string ddoc_ext	= "ddoc";	// for Ddoc macro include files
    string json_ext = "json";
    string map_ext = "map";	// for .map files
    string hdr_ext	= "di";	// for D 'header' import files
    string copyright= "Copyright (c) 1999-2009 by Digital Mars";
    string written	= "written by Walter Bright, ported to D by community"
        ~ ", severely abused by Zach the Mystic ";

    Param params;
    uint errors;	// number of errors reported so far
    uint gag;	// !=0 means gag reporting of errors

    int structalign = 8;
    string version_ = "v0.01";

    char[11+1] date;
    char[8+1] time;
    char[24+1] timestamp;
}

// use std.getopt for most of these
// Put command line switches in here
// Not exactly as "rich", if you will, as the original Param
struct Param
{
    int debuglevel;
    bool[string] debugids;
    bool[string] debugidsNot;

    int versionlevel; //????
    bool[string] versionids;
    bool[string] versionidsNot;
    
    bool warnings;	// enable warnings
    byte Dversion;	// D version number
    bool useDeprecated = false;
    bool useInvariants = false;

}

