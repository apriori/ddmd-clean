module dmd.global;

// EVERYBODY needs these
public import dmd.utils;

import dmd.scopeDsymbol;
import dmd.token;
import dmd.Scope;
import dmd.Module;
import dmd.expression;
import dmd.dsymbol;
import dmd.type;
import dmd.hdrGenState;
import dmd.typeInfoDeclaration;
import dmd.templateParameter;
import dmd.identifier;
//import dmd.statement;
//import dmd.types.TypeFunction;

import std.stdio;
import std.array;
import std.format;
import std.c.stdlib : exit;

static this()
{
    dmd.token.initTochars();
    dmd.token.initPrecedence();
    dmd.identifier.initKeywords();
    dmd.identifier.Id.initIdentifiers();
    Type.init();
}
// Test one to make sure
unittest { assert ( precedence[TOKge] == PREC_rel ); }
unittest { assert ( Token.tochars[TOKge] == ">=" ); }

// Warning: this might 
ParserGlobal global;

struct ParserGlobal
{
   // It's possible this will cause duplicate global structure errors
    static LexerGlobal lexerGlobal;
    alias lexerGlobal this; // 

    ClassDeclaration object;
    ClassDeclaration classinfo;

    // Used in FuncDeclaration.genCfunc()
    Dsymbol[string] st;

    // Used in Module
    Module rootModule;
    Module[string] modules;	// symbol table of all modules
    Module[] amodules;		// array of all modules

    //    Where'd the semantic and backend go?
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

alias int MATCH;
enum 
{
    MATCHnomatch,	// no match
    MATCHconvert,	// match with conversions
    MATCHconst,		// match with conversion to const
    MATCHexact		// exact match
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

