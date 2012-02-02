module dmd.Global;
/+ Types defined in this module:
    Global, 
    struct Params,
    struct Loc,
    enum LINK, 
    enum DYNCAST, 
    enum MATCH,
+/

// This is nothing like the original 
// I just got too much of a headache trying to figure the 
// original out.

// The goal is to get the parser up and running.
// Therefore I will add stubs to params I find in the parser
// Maybe I'll keep them in the same place, maybe not

import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Token;
import dmd.Scope;
import dmd.Module;
import dmd.Expression;
import dmd.Dsymbol;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.Identifier;
import dmd.types.TypeFunction;

import std.stdio;
import std.array;
import std.format;
import std.c.stdlib : exit;

Global global;

struct Global
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

    char date[11+1];
    char time[8+1];
    char timestamp[24+1];

    ClassDeclaration object;
    ClassDeclaration classinfo;

    // Used in FuncDeclaration.genCfunc()
    Dsymbol[string] st;

    // Used in Module
    Module rootModule;
    Module[string] modules;	// symbol table of all modules
    Module[] amodules;		// array of all modules

    //    Where'd the semantic and backend go? Well?
    // Used in Scope
    Scope scope_freelist;
    
    ClassDeclaration moduleinfo;
	
    Type tvoidptr;		// void*
    Type tstring;		// immutable(char)[]

    
    ClassDeclaration typeinfo;
    ClassDeclaration typeinfoclass;
    ClassDeclaration typeinfointerface;
    ClassDeclaration typeinfostruct;
    ClassDeclaration typeinfotypedef;
    ClassDeclaration typeinfopointer;
    ClassDeclaration typeinfoarray;
    ClassDeclaration typeinfostaticarray;
    ClassDeclaration typeinfoassociativearray;
    ClassDeclaration typeinfoenum;
    ClassDeclaration typeinfofunction;
    ClassDeclaration typeinfodelegate;
    ClassDeclaration typeinfotypelist;
    ClassDeclaration typeinfoconst;
    ClassDeclaration typeinfoinvariant;
    ClassDeclaration typeinfoshared;
    ClassDeclaration typeinfowild;
	
    Type basic[TMAX];

    Dsymbol sdummy;
    Expression edummy;

    void initClasssym() { assert(false,"zd cut"); }
}

struct Loc
{
    string filename;
    uint linnum;

    this(int x)
    {
		linnum = x;
		filename = null;
    }

    this(Module mod, uint linnum)
	{
		this.linnum = linnum;
		this.filename = mod ? mod.srcfilename : null;
	}

    string toChars()
	{
        auto buf = appender!(char[])();

		if (filename !is null) {
			formattedWrite(buf, "%s", filename);
		}

		if (linnum) {
			formattedWrite(buf, "(%d)", linnum);
			buf.put('\0');
		}

		return buf.data.idup;
	}

    bool equals(ref const(Loc) loc)
	{
		assert(false);
	}
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

alias int LINK;
enum
{
    LINKdefault,
    LINKd,
    LINKc,
    LINKcpp,
    LINKwindows,
    LINKpascal,
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

alias int MATCH;
enum 
{
    MATCHnomatch,	// no match
    MATCHconvert,	// match with conversions
    MATCHconst,		// match with conversion to const
    MATCHexact		// exact match
}

void warning(T...)(string format, T t)
{
	assert(false);
}

void warning(T...)(Loc loc, string format, T t)
{
	if (global.params.warnings && !global.gag)
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
	if (!global.gag)
    {
		string p = loc.toChars();

		if (p.length != 0)
			writef("%s: ", p);

		write("Error: ");
		writefln(format, t);

		//halt();
    }
    global.errors++;
}

enum
{  
    EXIT_SUCCESS, EXIT_FAILURE,
}

void fatal()
{
    exit(EXIT_FAILURE);
}

// Seek ini file... I need this but, 
// In D it would use std.file, std.path, std.process, std.stdio
// I'm putting this on pause
/*****************************
 * Read and analyze .ini file.
 * Input:
 *      argv0   program name (argv[0])
 *      inifile .ini file name
 * Returns:
 *      file name of ini file
 */
//void inifile(string argv0, string inifile) { assert(false,"zd cut"); } 

void browse(string url)
{
	assert(false);
}

void usage()
{
	writef("Digital Mars D Compiler %s\n%s %s\n", global.version_, global.copyright, global.written);
    writef(
`Documentation: http://www.digitalmars.com/d/2.0/index.html
Usage:
  ddmd files.d ... { -switch }

  files.d        D source files
  @cmdfile       read arguments from cmdfile
  -c             do not link
  -cov           do code coverage analysis
  -D             generate documentation
  -Dddocdir      write documentation file to docdir directory
  -Dffilename    write documentation file to filename
  -d             allow deprecated features
  -debug         compile in debug code
  -debug=level   compile in debug code <= level
  -debug=ident   compile in debug code identified by ident
  -debuglib=name    set symbolic debug library to name
  -defaultlib=name  set default library to name
  -deps=filename write module dependencies to filename
  -g             add symbolic debug info
  -gc            add symbolic debug info, pretend to be C
  -H             generate 'header' file
  -Hddirectory   write 'header' file to directory
  -Hffilename    write 'header' file to filename
  --help         print help
  -Ipath         where to look for imports
  -ignore        ignore unsupported pragmas
  -inline        do function inlining
  -Jpath         where to look for string imports
  -Llinkerflag   pass linkerflag to link
  -lib           generate library rather than object files
  -man           open web browser on manual page
  -map           generate linker .map file
  -noboundscheck turns off array bounds checking for all functions
  -nofloat       do not emit reference to floating point
  -O             optimize
  -o-            do not write object file
  -odobjdir      write object & library files to directory objdir
  -offilename	 name output file to filename
  -op            do not strip paths from source file
  -profile	 profile runtime performance of generated code
  -quiet         suppress unnecessary messages
  -release	 compile release version
  -run srcfile args...   run resulting program, passing args
  -unittest      compile in unit tests
  -v             verbose
  -version=level compile in version code >= level
  -version=ident compile in version code identified by ident
  -vtls          list all variables going into thread local storage
  -w             enable warnings
  -X             generate JSON file
  -Xffilename    write JSON file to filename
`
);
}

