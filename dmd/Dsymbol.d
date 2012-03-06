module dmd.dsymbol;

import dmd.global;
import dmd.Scope;
import dmd.Module;
import dmd.scopeDsymbol;
import dmd.identifier;
import dmd.hdrGenState;
import dmd.statement;
import dmd.type;
import dmd.declaration;
import dmd.funcDeclaration;
import dmd.varDeclaration;
import dmd.attribDeclaration;
import dmd.expression;
import dmd.condition;
import dmd.token;

import std.array, std.format;
import std.stdio;
import std.conv;

alias int PROT;
enum
{
    PROTundefined,
    PROTnone,		// no access
    PROTprivate,
    PROTpackage,
    PROTprotected,
    PROTpublic,
    PROTexport,
}

/* State of symbol in winding its way through the passes of the compiler
 */
alias int PASS;
enum
{
    PASSinit,           // initial state
    PASSsemantic,       // semantic() started
    PASSsemanticdone,   // semantic() done
    PASSsemantic2,      // semantic2() run
    PASSsemantic3,      // semantic3() started
    PASSsemantic3done,  // semantic3() done
    PASSobj,            // toObjFile() run
}

alias ulong STC;
alias ulong StorageClass;

enum : ulong
{
    STCundefined    = 0,
    STCstatic	    = 1,
    STCextern	    = 2,
    STCconst	    = 4,
    STCfinal	    = 8,
    STCabstract     = 0x10,
    STCparameter    = 0x20,
    STCfield	    = 0x40,
    STCoverride	    = 0x80,
    STCauto         = 0x100,
    STCsynchronized = 0x200,
    STCdeprecated   = 0x400,
    STCin           = 0x800,		// in parameter
    STCout          = 0x1000,		// out parameter
    STClazy	    = 0x2000,		// lazy parameter
    STCforeach      = 0x4000,		// variable for foreach loop
    STCcomdat       = 0x8000,		// should go into COMDAT record
    STCvariadic     = 0x10000,		// variadic function argument
    STCctorinit     = 0x20000,		// can only be set inside constructor
    STCtemplateparameter = 0x40000,	// template parameter
    STCscope	    = 0x80000,		// template parameter
    STCimmutable    = 0x100000,
    STCref	    = 0x200000,
    STCinit	    = 0x400000,		// has explicit initializer
    STCmanifest	    = 0x800000,		// manifest constant
    STCnodtor	    = 0x1000000,	// don't run destructor
    STCnothrow	    = 0x2000000,	// never throws exceptions
    STCpure	    = 0x4000000,	// pure function
    STCtls	    = 0x8000000,	// thread local
    STCalias	    = 0x10000000,	// alias parameter
    STCshared       = 0x20000000,	// accessible from multiple threads
    STCgshared      = 0x40000000,	// accessible from multiple threads
					// but not typed as "shared"
    STCwild         = 0x80000000,	// for "wild" type constructor
    STC_TYPECTOR    = (STCconst | STCimmutable | STCshared | STCwild),

    // attributes
	STCproperty		= 0x100000000,
	STCsafe			= 0x200000000,
	STCtrusted		= 0x400000000,
	STCsystem		= 0x800000000,
	STCctfe			= 0x1000000000,	// can be used in CTFE, even if it is static
	STCdisable      = 0x2000000000,	// for functions that are not callable
}

class Dsymbol : Dobject
{
    Identifier ident;
    //Identifier c_ident;
    Dsymbol parent;
    //Symbol* csym;		// symbol for code generator
    //Symbol* isym;		// import version of csym
    // I'm gonna try making comments into fully parsed Tokens
    //string comment;	// documentation comment for this Dsymbol
    Loc loc;			// where defined
    Scope scope_;		// !=null means context to use for semantic()

    this()
	{
		// do nothing
	}

    this(Identifier ident)
	{
		this.ident = ident;
	}

   override string toChars()
	{
		return ident ? ident.toChars() : "__anonymous";
	}

   void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      assert (false,"No toCBuffer() for class Dsymbol" );
   }

   Dobject nextSibling() { return null; }
   Dobject previousSibling() { return null; }

   Dobject descend( int rank )
   {
      // No descent possible for this particular Dsymbol
      writeln("Dsymbol.descend: descent failed, returning null");
      return null;
   }
   
   override Dsymbol isDsymbol() { return this; }
	
   string kind()
	{
		return "Dsymbol";
	}
   
   LabelDsymbol isLabel()
   {
       assert (false);
   }	
  
   void addLocalClass(ClassDeclaration[] aclasses)
	{
   }

	void toDocBuffer(ref Appender!(char[]) buf)
   {
      assert(false);
   }

   void emitComment(Scope sc)
   {
      assert(false);
   }

   bool oneMember(Dsymbol* ps)
   {
      assert (false);
   } 
   string mangle()
   {
      Appender!(char[]) buf;
      string id;

      static if (false) {
         printf("Dsymbol::mangle() '%s'", toChars());
         if (parent)
            printf("  parent = %s %s", parent.kind(), parent.toChars());
         printf("\n");
      }
      id = ident ? ident.toChars() : toChars();
      if (parent)
      {
         string p = parent.mangle();
         if (p[0] == '_' && p[1] == 'D')
            p =  p[2..$];
         buf.put(p);
      }
      import std.format;
      formattedWrite(buf, "%s%s", id.length, id);
      id = buf.data.idup;
      //printf("Dsymbol::mangle() %s = %s\n", toChars(), id);
      return id;
   }

   void checkCtorConstInit()
   {
   }

   // copy only syntax trees 
   Dsymbol syntaxCopy(Dsymbol s) { assert(false); }
   void importAll(Scope sc) { assert(false); }
   Dsymbol toAlias() { assert(false); }
   bool overloadInsert(Dsymbol s) { assert(false); }

   Type getType()			// is this a type?
   {
      return null;
   }

   void setScope(Scope sc)
   {
      //printf("Dsymbol.setScope() %p %s\n", this, toChars());
      if (!sc.nofree)
         sc.setNoFree();		// may need it even after semantic() finishes
      scope_ = sc;
   }

   void addComment(string comment)
   {
   }

   string locToChars() 
   {
      assert(false);
   }

   bool isAnonymous()
   {
      return ident ? 0 : 1;
   }

   void error(T...)(Loc loc, string format, T t)
   {
      if (!global.gag)
      {
         string p = loc.toChars();
         if (p.length == 0)
            p = locToChars();

         if (p.length != 0) {
            writef("%s: ", p);
         }

         write("Error: ");
         writef("%s %s ", kind(), toPrettyChars());

         writefln(format, t);
      }

      global.errors++;

      //fatal();
   }

   void error(T...)(string format, T t)
   {
      //printf("Dsymbol.error()\n");
      if (!global.gag)
      {
         string p = loc.toChars();

         if (p.length != 0) {
            writef("%s: ", p);
         }

         write("Error: ");
         if (isAnonymous()) {
            writef("%s ", kind());
         } else {
            writef("%s %s ", kind(), toPrettyChars());
         }

         writefln(format, t);
      }
      global.errors++;

      //fatal();
   }

   Module getModule()
   {
      assert(false);
   }


   Dsymbol toParent()
   {
      return parent ? parent.pastMixin() : null;
   }

   Dsymbol pastMixin() 
   {
      assert(false);
   }


   /**********************************
    * Use this instead of toParent() when looking for the
    * 'this' pointer of the enclosing function/class.
    */
   Dsymbol toParent2()
   {
      Dsymbol s = parent;
      while (s && s.isTemplateInstance())
         s = s.parent;
      return s;
   }

   TemplateInstance inTemplateInstance()
   {
      for (Dsymbol parent = this.parent; parent; parent = parent.parent)
      {
         TemplateInstance ti = parent.isTemplateInstance();
         if (ti)
            return ti;
      }

      return null;
   }

   /*************************************
    * Do syntax copy of an array of Dsymbol's.
    */
   static Dsymbol[] arraySyntaxCopy(Dsymbol[] a)
   {
      assert(false);
   }


   string toPrettyChars()
   {
      //printf("Dsymbol.toPrettyChars() '%s'\n", toChars());
      if (!parent) {
         return toChars();
      }

      // accumulate them and then print in reverse with dots
      string[] parStr; 
      auto len = this.toChars().length;

      Dsymbol p = this.parent;
      while ( p ) 
      {
         len += p.toChars().length + 1;
         parStr ~= p.toChars;
         p = p.parent;
      }

      string st;
        st.length = len;

        foreach_reverse( s; parStr )
            st ~= s ~ ".";
        return st;
    }

    bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
    {
        assert(false);
    }

    /**************************************
     * Determine if this symbol is only one.
     * Returns:
     *  false, *ps = null: There are 2 or more symbols
     *  true,  *ps = null: There are zero symbols
     *  true,  *ps = symbol: The one and only one symbol
     */
    bool oneMember(Dsymbol ps)
    {
        //printf("Dsymbol::oneMember()\n");
        ps = this;
        return true;
    }

    /*****************************************
     * Same as Dsymbol::oneMember(), but look at an array of Dsymbol[] 
     */
    static bool oneMembers(Dsymbol[] members, Dsymbol ps)
    {
       //printf("Dsymbol::oneMembers() %d\n", members ? members.length : 0);
       Dsymbol s = null;

       if (members)
       {
          foreach(sx; members)
          {   
             //printf("\t[%d] kind %s = %d, s = %p\n", i, sx.kind(), x, *ps);
             if ( !sx.oneMember(ps) )
             {
                //printf("\tfalse 1\n");
                assert(ps is null);
                return false;
             }
             if (ps)
             {
                if (s)          // more than one symbol
                {   
                   ps = null;
                   //printf("\tfalse 2\n");
                   return false;
                }
                s = ps;
             }
          }
       }

       ps = s;        // s is the one symbol, null if none
       //printf("\ttrue\n");
       return true;
    }

    uint size(Loc loc)
    {
       assert(false);
    }

    AggregateDeclaration isThis()	// is a 'this' required to access the member
    {
       return null;
    }

    ClassDeclaration isClassMember()	// are we a member of a class?
    {
       Dsymbol parent = toParent();
       if (parent && parent.isClassDeclaration())
          return cast(ClassDeclaration)parent;
       return null;
    }

    AggregateDeclaration isMember()	// is this symbol a member of an AggregateDeclaration?
    {
       //printf("Dsymbol::isMember() %s\n", toChars());
       Dsymbol parent = toParent();
       //printf("parent is %s %s\n", parent.kind(), parent.toChars());
       return parent ? parent.isAggregateDeclaration() : null;
    }

    // Eliminate need for dynamic_cast
    Package isPackage() { return null; }
    Module isModule() { return null; }
    EnumMember isEnumMember() { return null; }
    TemplateDeclaration isTemplateDeclaration() { return null; }
    TemplateInstance isTemplateInstance() { return null; }
    TemplateMixin isTemplateMixin() { return null; }
    Declaration isDeclaration() { return null; }
    ThisDeclaration isThisDeclaration() { return null; }
    TupleDeclaration isTupleDeclaration() { return null; }
    TypedefDeclaration isTypedefDeclaration() { return null; }
    AliasDeclaration isAliasDeclaration() { return null; }
    AggregateDeclaration isAggregateDeclaration() { return null; }
    FuncDeclaration isFuncDeclaration() { return null; }
    FuncAliasDeclaration isFuncAliasDeclaration() { return null; }
    FuncLiteralDeclaration isFuncLiteralDeclaration() { return null; }
    CtorDeclaration isCtorDeclaration() { return null; }
    PostBlitDeclaration isPostBlitDeclaration() { return null; }
    DtorDeclaration isDtorDeclaration() { return null; }
    StaticCtorDeclaration isStaticCtorDeclaration() { return null; }
    StaticDtorDeclaration isStaticDtorDeclaration() { return null; }
    SharedStaticCtorDeclaration isSharedStaticCtorDeclaration() { return null; }
    SharedStaticDtorDeclaration isSharedStaticDtorDeclaration() { return null; }
    InvariantDeclaration isInvariantDeclaration() { return null; }
    UnitTestDeclaration isUnitTestDeclaration() { return null; }
    NewDeclaration isNewDeclaration() { return null; }
    VarDeclaration isVarDeclaration() { return null; }
    ClassDeclaration isClassDeclaration() { return null; }
    StructDeclaration isStructDeclaration() { return null; }
    UnionDeclaration isUnionDeclaration() { return null; }
    InterfaceDeclaration isInterfaceDeclaration() { return null; }
    ScopeDsymbol isScopeDsymbol() { return null; }
    WithScopeSymbol isWithScopeSymbol() { return null; }
    ArrayScopeSymbol isArrayScopeSymbol() { return null; }
    Import isImport() { return null; }
    EnumDeclaration isEnumDeclaration() { return null; }
    SymbolDeclaration isSymbolDeclaration() { return null; }
    AttribDeclaration isAttribDeclaration() { return null; }
    OverloadSet isOverloadSet() { return null; }
}

class AliasThis : Dsymbol
{
   // alias Identifier this;
   Identifier ident;

   this(Loc loc, Identifier ident)
   {
      super(null);		// it's anonymous (no identifier)
      this.loc = loc;
      this.ident = ident;
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      /* Since there is no semantic information stored here,
       * we don't need to copy it.
       */
      return this;
   }


   override string kind()
   {
      assert(false);
   }

   AliasThis isAliasThis() { return this; }
}

/* DebugSymbol's happen for statements like:
 *	debug = identifier;
 *	debug = integer;
 */
class DebugSymbol : Dsymbol
{
   uint level;

   this(Loc loc, Identifier ident)
   {
      super(ident);
      this.loc = loc;
   }

   this(Loc loc, uint level)
   {
      this.level = level;
      this.loc = loc;
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      DebugSymbol ds = new DebugSymbol(loc, ident);
      ds.level = level;
      return ds;
   }

   override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
   {  
      assert (false);
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("debug = ");
      if (ident)
         buf.put(ident.toChars());
      else
         formattedWrite(buf,"%s", level);
      buf.put(";");
      buf.put(hgs.nL);
   }

   override string kind()
   {
      return "debug";
   }
}

class EnumMember : Dsymbol
{
   Expression value;
   Type type;

	this(Loc loc, Identifier id, Expression value, Type type)
	{
		super(id);

		this.value = value;
		this.type = type;
		this.loc = loc;
	}

	Dsymbol syntaxCopy(Dsymbol s)
	{
		Expression e = null;
		if (value)
			e = value.syntaxCopy();

		Type t = null;
		if (type)
			t = type.syntaxCopy();

		EnumMember em;
		if (s)
		{	em = cast(EnumMember)s;
			em.loc = loc;
			em.value = e;
			em.type = t;
		}
		else
			em = new EnumMember(loc, ident, e, t);
		return em;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (type)
			type.toCBuffer(buf, ident, hgs);
		else
			buf.put(ident.toChars());
		if (value)
		{
			buf.put(" = ");
			value.toCBuffer(buf, hgs);
		}
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

	override string kind()
	{
		return "enum member";
	}

	override void emitComment(Scope sc)
	{
		assert(false);
	}

	override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	override EnumMember isEnumMember() { return this; }
}

class Import : Dsymbol
{
	Identifier[] packages;		// array of Identifier's representing packages
	Identifier id;		// module Identifier
	Identifier aliasId;
	int isstatic;		// !=0 if static import

	// Pairs of alias=name to bind into current namespace
	Identifier[] names;
	Identifier[] aliases;

	AliasDeclaration[] aliasdecls;		// AliasDeclarations for names/aliases

	Module mod;
	Package pkg;		// leftmost package/module

	this(Loc loc, Identifier[] packages, Identifier id, Identifier aliasId, int isstatic)
	{
		super(id);
		
		assert(id);
		this.loc = loc;
		this.packages = packages;
		this.id = id;
		this.aliasId = aliasId;
		this.isstatic = isstatic;

		if (aliasId)
			this.ident = aliasId;
		// Kludge to change Import identifier to first package
		else if ( packages )
         this.ident = packages[0];
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      if (isstatic)
         buf.put("static ");
      buf.put("import ");
      if (aliasId)
      {
         buf.put( aliasId.toChars() );
         buf.put(" = ");
      }
      if (packages)
      {
         foreach (i; packages)
         {   
            buf.put( i.toChars() );
            buf.put(".");
         }
      }
      buf.put(id.toChars());
      // TODO This is not in dmd (import.c), but it should be!
      if (names)
      {
         buf.put(" : ");
         foreach( j, i; names )
         {
            if (  aliases[j] )
            {
               buf.put( aliases[j].toChars() );
               buf.put(" = ");
            }
            buf.put( i.toChars() );
            if (j < names.length - 1)
               buf.put( ", " );
         }
      }
      buf.put(";");
      buf.put(hgs.nL);
   }

   override Import isImport() { return this; }

   void addAlias(Identifier name, Identifier alias_)
   {
      if (isstatic)
         error("cannot have an import bind list");

      if (!aliasId)
         this.ident = null;	// make it an anonymous import

      names ~= name;
      aliases ~= alias_;
   }

   override string kind()
   {
      return isstatic ? "static import" : "import";
   }

   override Dsymbol syntaxCopy(Dsymbol s)	// copy only syntax trees
   {
      assert(false);
   }

   void load(Scope sc)
   {
      /+ zd cut TODO include again 
         //writefln("Import::load('%s')", id.toChars());

         // See if existing module
         Dsymbol[string] dst = Package.resolve(packages, null, pkg);

      Dsymbol s = dst.get( id.toChars(), null );
      if (s)
      {
         if (s.isModule())
            mod = cast(Module)s;
         else
            error("package and module have the same name");
      }

      if (!mod)
      {
         // Load module
         mod = Module.load(loc, packages, id);
         dst.insert(id, mod);		// id may be different from mod.ident,
         // if so then insert alias
         if (!mod.importedFrom)
            mod.importedFrom = sc ? sc.module_.importedFrom : global.rootModule;
      }

      if (!pkg)
         pkg = mod;

      //writef("-Import::load('%s'), pkg = %p\n", toChars(), pkg);
      +/
   }

   override void importAll(Scope sc)
   {
      /+
         if (!mod)
         {
           load(sc);
           mod.importAll(null);

           if (!isstatic && !aliasId && !names)
           {
               /* Default to private importing
                */
               PROT prot = sc.protection;
               if (!sc.explicitProtection)
                   prot = PROTprivate;
               sc.scopesym.importScope(mod, prot);
           }
       }
       +/
   }



   override Dsymbol toAlias()
   {
		if (aliasId)
			return mod;
		return this;
	}
	
	/*****************************
	 * Add import to sd's symbol table.
	 */
	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
    assert(false);
    /+
		bool result = false;

		if ( names )
			return Dsymbol.addMember(sc, sd, memnum);

		if (aliasId)
			result = Dsymbol.addMember(sc, sd, memnum);

		/* Instead of adding the import to sd's symbol table,
		 * add each of the alias=name pairs
		 */
		foreach ( name; names)
		{
			auto alias_ = aliases[name];

			if (!alias_)
				alias_ = name;

			TypeIdentifier tname = new TypeIdentifier(loc, name);
			AliasDeclaration ad = new AliasDeclaration(loc, alias_, tname);
			result |= ad.addMember(sc, sd, memnum);

			aliasdecls ~= ad;
		}

		return result;
    +/
	}
	
	override bool overloadInsert(Dsymbol s)
	{
		// Allow multiple imports of the same name
		return s.isImport() !is null;
	}
}

class LabelDsymbol : Dsymbol
{
    LabelStatement statement;

    this(Identifier ident)
	{
		super(ident);
	}
	
    override LabelDsymbol isLabel()
	{
		return this;
	}
}

class OverloadSet : Dsymbol
{
    Dsymbol[] a;

    this()
	{
	}
	
    void push(Dsymbol s)
	{
		a ~= s;
	}
	
    override OverloadSet isOverloadSet() { return this; }

    override string kind()
	{
		return "overloadset";
	}
}

class StaticAssert : Dsymbol
{
	Expression exp;
	Expression msg;

	this(Loc loc, Expression exp, Expression msg)
	{
		super(Id.empty);

		this.loc = loc;
		this.exp = exp;
		this.msg = msg;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		StaticAssert sa;

		assert(!s);
		sa = new StaticAssert(loc, exp.syntaxCopy(), msg ? msg.syntaxCopy() : null);
		return sa;
	}

	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		return false;		// we didn't add anything
	}




	override bool oneMember(Dsymbol ps)
	{
		//printf("StaticAssert.oneMember())\n");
		ps = null;
		return true;
	}


	override string kind()
	{
		return "static assert";
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(kind());
		buf.put('(');
		exp.toCBuffer(buf, hgs);
		if (msg)
		{
			buf.put(',');
			msg.toCBuffer(buf, hgs);
		}
		buf.put(");");
		buf.put(hgs.nL);
	}
}

/* VersionSymbol's happen for statements like:
 *	version = identifier;
 *	version = integer;
 */
class VersionSymbol : Dsymbol
{
    uint level;

    this(Loc loc, Identifier ident)
	{
		super(ident);
		this.loc = loc;
	}

    this(Loc loc, uint level)
	{
		super();

		this.level = level;
		this.loc = loc;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		VersionSymbol ds = new VersionSymbol(loc, ident);
		ds.level = level;
		return ds;
	}

    override bool addMember(Scope sc, ScopeDsymbol s, bool memnum)
	{
		//printf("VersionSymbol::addMember('%s') %s\n", sd.toChars(), toChars());

		// Do not add the member to the symbol table,
		// just make sure subsequent debug declarations work.
		Module m = s.isModule();
		if (ident)
		{
			VersionCondition.checkPredefined(loc, ident.toChars());
			if (!m)
				error("declaration must be at module level");
			else
			{
				if ( ident.toChars in m.versionidsNot )
					error("defined after use");
				m.versionids[ ident.toChars() ] = true;
			}
		}
		else
		{
			if (!m)
				error("level declaration must be at module level");
			else
				m.versionlevel = level;
		}

		return false;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("version = ");
		if (ident)
			buf.put(ident.toChars());
		else
			formattedWrite(buf,"%u", level);
		buf.put(";");
		buf.put(hgs.nL);
	}

    override string kind()
	{
		return "version";
	}
}
