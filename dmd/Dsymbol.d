module dmd.Dsymbol;

import dmd.Global;
import dmd.Scope;
import dmd.Lexer;
import dmd.Module;
import dmd.ScopeDsymbol;
import std.array;
import dmd.Identifier;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.declarations.SharedStaticCtorDeclaration;
import dmd.declarations.SharedStaticDtorDeclaration;
import dmd.HdrGenState;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.dsymbols.LabelDsymbol;
import dmd.Type;
import dmd.Package;
import dmd.dsymbols.EnumMember;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.scopeDsymbols.TemplateMixin;
import dmd.Declaration;
import dmd.varDeclarations.ThisDeclaration;
import dmd.declarations.TupleDeclaration;
import dmd.declarations.TypedefDeclaration;
import dmd.declarations.AliasDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.declarations.FuncAliasDeclaration;
import dmd.declarations.FuncLiteralDeclaration;
import dmd.declarations.CtorDeclaration;
import dmd.declarations.PostBlitDeclaration;
import dmd.declarations.DtorDeclaration;
import dmd.declarations.StaticCtorDeclaration;
import dmd.declarations.StaticDtorDeclaration;
import dmd.declarations.InvariantDeclaration;
import dmd.declarations.UnitTestDeclaration;
import dmd.declarations.NewDeclaration;
import dmd.VarDeclaration;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.scopeDsymbols.UnionDeclaration;
import dmd.scopeDsymbols.InterfaceDeclaration;
import dmd.scopeDsymbols.WithScopeSymbol;
import dmd.scopeDsymbols.ArrayScopeSymbol;
import dmd.dsymbols.Import;
import dmd.scopeDsymbols.EnumDeclaration;
import dmd.declarations.DeleteDeclaration;
import dmd.declarations.SymbolDeclaration;
import dmd.AttribDeclaration;
import dmd.dsymbols.OverloadSet;
import dmd.Expression;
import dmd.Token;
import dmd.expressions.VarExp;
import dmd.expressions.FuncExp;

import dmd.DDMDExtensions;

import std.stdio;

// TODO: remove dependencies on these
Expression isExpression(Object o)
{
    return cast(Expression)o;
}

Dsymbol isDsymbol(Object o)
{
    return cast(Dsymbol)o;
}

Type isType(Object o)
{
    return cast(Type)o;
}

/***********************
 * Try to get arg as a type.
 */

Type getType(Object o)
{
    Type t = isType(o);
    if (!t)
    {   Expression e = isExpression(o);
	if (e)
	    t = e.type;
    }
    return t;
}

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

class Dsymbol
{
	mixin insertMemberExtension!(typeof(this));
	
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

    string toChars()
	{
		return ident ? ident.toChars() : "__anonymous";
	}
	
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
		///buf.printf("%zu%s", id.length, id);
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

    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
         assert (false,"No toCBuffer() for class Dsymbol" );
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
        //printf("Dsymbol::oneMembers() %d\n", members ? members->length : 0);
        Dsymbol s = null;

        if (members)
        {
            foreach(sx; members)
            {   
                //printf("\t[%d] kind %s = %d, s = %p\n", i, sx->kind(), x, *ps);
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

    /*************************************
     * Look for function inlining possibilities.
     */


    void toCBuffer(char[] buf, ref HdrGenState hgs)
    {
        assert(false);
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
version (_DH)
{
    DeleteDeclaration isDeleteDeclaration() { return null; }
}
    SymbolDeclaration isSymbolDeclaration() { return null; }
    AttribDeclaration isAttribDeclaration() { return null; }
    OverloadSet isOverloadSet() { return null; }
version (TARGET_NET)
{
    PragmaScope isPragmaScope() { return null; }
}
}
