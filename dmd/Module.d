module dmd.Module;

import dmd.Global;
import dmd.Identifier;
import dmd.Package;
import dmd.Type;
import dmd.Parser;
import dmd.Lexer;
//import dmd.declarations.StaticDtorDeclaration;
import dmd.Scope;
import dmd.declarations.SharedStaticCtorDeclaration;
import dmd.declarations.SharedStaticDtorDeclaration;
import dmd.dsymbols.Import;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.ModuleDeclaration;
import dmd.Dsymbol;
import dmd.varDeclarations.ModuleInfoDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.DocComment;
import dmd.HdrGenState;
import dmd.ScopeDsymbol;

import dmd.DDMDExtensions;

import std.stdio;
import std.encoding;
import std.file;

class Module : Package
{
    mixin insertMemberExtension!(typeof(this));

    string arg;	// original argument name
    ModuleDeclaration md; // if !null, the contents of the ModuleDeclaration declaration
    string srcfilename;
    //File srcfile;	// input source file
    //File objfile;	// output .obj file
    //File hdrfile;	// 'header' file
    //File symfile;	// output symbol file
    //File docfile;	// output documentation file
    uint errors;	// if any errors in file
    uint numlines;	// number of lines in source file
    //int isHtml;		// if it is an HTML file
    //int isDocFile;	// if it is a documentation input file, not D source
    //int needmoduleinfo; /// TODO: change to bool
    //version (IN_GCC) { int strictlyneedmoduleinfo; }

    // 0: don't know, 1: does not, 2: does
    int selfimports;	// function... selfImports (capital "I")

    //int insearch;
    //Identifier searchCacheIdent;
    //Dsymbol searchCacheSymbol;	// cached value of search
    //int searchCacheFlags;	// cached flags
    
    //int semanticstarted;	// has semantic() been started?
    //int semanticRun;		// has semantic() been done?
    //int root;			// != 0 if this is a 'root' module,
				// i.e. a module that will be taken all the
				// way to an object file
    //Module importedFrom;	// module from command line we're imported from,
				// i.e. a module that will be taken all the
				// way to an object file

    Dsymbol[] decldefs;		// top level declarations for this Module

    Module[] aimports;		// all imported modules

    ModuleInfoDeclaration vmoduleinfo;

    int debuglevel;	// debug level
    bool[string] debugids;		// debug identifiers
    bool[string] debugidsNot;		// forward referenced debug identifiers

    int versionlevel;	// version level
    bool[string] versionids;		// version identifiers
    bool[string] versionidsNot;	// forward referenced version identifiers

    //Macro macrotable;		// document comment macros
    //Escape escapetable;	// document comment escapes
    //bool safe;			// TRUE if module is marked as 'safe'

    this(string filename, Identifier ident, int doDocComment, int doHdrGen)
    {
        // zd Uhh... I removed some stuff!
        super(ident);
        this.srcfilename = filename;
    }

    // Functionality cut completely. I'm just testing this thing
    // and I'm a very new programmer. It used a lot of code which
    // might look nicer in D anyway.
    // Function is Static!
    static Module load( Loc loc, string filename, Identifier ident)
    {
        Module m;

        
        m = new Module(filename, ident, 0, 0);
        m.loc = loc;


        //m.read(loc);
        //m.srcfilebuffer = readText( m.srcfile );

        m.parse();

        return m;
    }

    void read(Loc loc) { }
    
    void parse()	// syntactic parse
    {
        // Unfortunately I felt too much pressure to know everything too
        // soon. I cut basically everything. 
        // Source file must be in our current directory.
        // And it must be char[]
        // As I said. I cut a lot.
        // I think phobos would do all this stuff better anyway
        
        //printf("Module.parse(srcname = '%s')\n", srcname);
        char[] srcbuf = readText!(char[])( srcfilename );

        auto p = new Parser(this, srcbuf, 0/+docfile+/ );
        p.nextToken();
        members = p.parseModule();
        md = p.md;
        numlines = p.loc.linnum;

        // I process NO SEMANTICS AT ALL
    }

    
    override void toCBuffer(char[] buf, ref HdrGenState hgs)
    {
        // I should actually figure this out...
        // it outputs all of its members as code in sequence...
        assert(false);
    }
    
    // returns !=0 if module imports itself
    // this won't be too hard, but it's in module.c, not Module.d
    int selfImports() { assert(false); }

    // I have no idea who Json is.
    //override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); } 

    override string kind()
    {
        return "module";
    }

    void setDocfile()	// set docfile member
    {
        assert(false);
    }

    override void importAll(Scope prevsc) { assert(false,"zd cut"); }

    // I've said it before, and I'll say it again.
    // Writing software is easy. 
    // Just cut out everything.


    void deleteObjFile() { assert(false,"zd cut"); }

    /************************************
     * Recursively look at every module this module imports,
     * return TRUE if it imports m.
     * Can be used to detect circular imports.
     */
    bool imports(Module m) { assert(false,"zd cut"); }

    override Module isModule() { return this; }
}
