module dmd.Module;

import dmd.global;
import dmd.identifier;
import dmd.type;
import dmd.Scope;
import dmd.varDeclaration;
import dmd.dsymbol;
import dmd.funcDeclaration;
import dmd.docComment;
import dmd.hdrGenState;
import dmd.scopeDsymbol;

import std.stdio;
import std.encoding;
import std.file;
import std.array;
import std.exception;
import std.format;

// a very small class
class ModuleDeclaration : Dobject
{
    Identifier id;
    Identifier[] packages;		// array of Identifier's representing package
    bool safe;

    this(Identifier[] packages, Identifier id, bool safe)
	{
		this.packages = packages;
		this.id = id;
		this.safe = safe;
	}

   override string toChars()
	{
      auto buf = appender!(char[])();
		if (packages)
		{
			foreach (pid; packages)
			{
            buf.put(pid.toChars());
				buf.put('.');
			}
		}
		buf.put(id.toChars());
		return buf.data.idup;
	}
}

// define Package first. Module inherits from Package
class Package : ScopeDsymbol
{
   // zd note Package has no members of its own
   this(Identifier ident)
   {
      super(ident);
   }

   override string kind()
   {
      assert(false);
   }

   static Dsymbol[string] resolve( 
         Identifier[] packages, 
         Dsymbol pparent, 
         Package ppkg
         )
   {
      assert(false);
      /+
         Dsymbol[string] dst = global.modules;
      Dsymbol parent = null;

      //printf("Package::resolve()\n");
      bool sendPpkg = ( ppkg !is null );

      if (packages)
      {
         foreach (pid; packages)
         {   
            Package p = dst.get( pid, null );
            if (!p)
            {
               p = new Package(pid);
               dst[pid] = p;
               p.parent = parent;
            }
            else
            {
               assert(p.isPackage());
               //dot net needs modules and packages with same name
               version (TARGET_NET) { }
               else 
               {
                  if (p.isModule())
                  {   
                     p.error("module and package have the same name");
                     fatal();
                     break;
                  }
               }
            }
            parent = p;
            dst = p.symtab;
            // this is weird, couldn't find where it was used anyway
            // used a bool place holder, I think it makes sense
            if ( sendPpkg ) 
            {
               sendPpkg = false;
               ppkg = p;
            }
         }
         if (pparent)
         {
            pparent = parent;
         }
      }
      return dst;
      +/
   }

   override Package isPackage() { return this; }

}

class Module : Package
{
   string arg;	// original argument name

   // This is the #!first line, if any
   // does not include the initial #!
   string hashBang = null; 

   ModuleDeclaration md; // if !null, the contents of the ModuleDeclaration declaration
   string srcfilename = "defaultModuleName";
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

   //This is NEVER used in dmd... e
   //Dsymbol[] decldefs;		// top level declarations for this Module

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
      super(ident);
      this.srcfilename = filename;
   }

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
      // NOTE
      // Module no longer depends on dmd.parser.
      // Therefore dmd.Module is COMPLETELY independent of any parsing code
      
      // To load a module:
      version(none)
      {
         import dmd.parser;
         char[] sourceBuffer = "Any old module file that you want to parse".dup;
         Module m;
         m = new Module("Whatever", new Identifier("Whatever",TOKidentifier), false/+doDocComment+/, false/+doHdrGen+/);
         auto pete = new Parser( m, sourceBuffer, false /+doDocComment+/);
         pete.parseModule();
         // Now m is parsed and ready to go!
         // To set pete to a new module:
         Module mm;
         pete.setModule ( mm );
      }


      // I've set it up so that all the BOM conversion
      // will happen in the parser itself, although
      // as of March 3, 2012 it's not implemented

      //char[] srcbuf = readText!(char[])( srcfilename );

      //auto p = new Parser(this, srcbuf, 0/+docfile+/ );
      //p.parseModule(); // parser already has this module in reference
      
      //numlines = p.loc.linnum;
   }

   override string toChars()
   {
      auto codeBuf = appender!(char[]);

      HdrGenState hgs; // I'll need a new name for HdrGenState!

      toCBuffer( codeBuf, hgs);

      char[] s = codeBuf.data;
      return assumeUnique(s);
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      if (md)
      {
         buf.put("module ");
         buf.put(md.toChars());
         buf.put(";" ~ hgs.nL);
      }

      foreach ( i; members)
      {    
         i.toCBuffer(buf, hgs);
      }
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
