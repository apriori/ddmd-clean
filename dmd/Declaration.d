module dmd.Declaration;
// defined in this module: enum STC, enum StorageClass, struct MATCH

import dmd.Global;
import dmd.Dsymbol;
import dmd.ScopeDsymbol;
import dmd.Type;
import dmd.Token;
import dmd.types.TypeTuple;
import dmd.types.TypeTypedef;
import dmd.Identifier;
import dmd.Scope;
import dmd.FuncDeclaration;
import dmd.VarDeclaration;
import dmd.HdrGenState;
import dmd.Initializer;

import std.array;
import std.conv;
import std.stdio : writef;

struct Match
{
    int count;			// number of matches found
    MATCH last;			// match level of lastf
    FuncDeclaration lastf;	// last matching function we found
    FuncDeclaration nextf;	// current matching function
    FuncDeclaration anyf;	// pick a func, any func, to use for error recovery
}

class Declaration : Dsymbol
{
    Type type;
    Type originalType;		// before semantic analysis
    StorageClass storage_class = STCundefined;
    PROT protection = PROTundefined;
    LINK linkage = LINKdefault;
    int inuse;			// used to detect cycles

    this(Identifier id)
	{
		super(id);
	}
	
	
    string kind()
	{
		assert(false);
	}
	
    override uint size(Loc loc)
	{
		assert(false);
	}
	
    void emitComment(Scope sc)
	{
		assert(false);
	}
	
    //override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

    void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}
    Dsymbol syntaxCopy(Dsymbol s)
	{
    assert(false);
   }
    Type getType() { assert(false); }

    bool overloadInsert(Dsymbol s)
    {
        assert(false);
    }
	Dsymbol toAlias() { assert(false); }


    void toJsonBuffer(ref Appender!(char[]) buf)
    {
    }

    bool addPostInvariant()
    {
        assert(false);
    }
    bool addPreInvariant()
    {
        assert(false);
    }
    bool needThis()
    {
        assert(false);
    }
    bool isOverloadable()
	 {
        assert(false);
    }
    bool isImportedSymbol()
	 {
        assert(false);
    }
    string toPrettyChars()
	 {
        assert(false);
    }
    bool isExport()
    {
        assert(false);
    }
    string mangle()
    {
        assert (false);
        //writef("Declaration.mangle(this = %p, '%s', parent = '%s', linkage = %d)\n", this, toChars(), parent ? parent.toChars() : "null", linkage);
    }	
    bool isStatic() { return (storage_class & STCstatic) != 0; }
	
    bool isDelete()
	{
		return false;
	}
	
    bool isDataseg()
	{
		return false;
	}
	
    bool isThreadlocal()
	{
		return false;
	}
	
    bool isCodeseg()
	{
		return false;
	}
	
    bool isCtorinit()     { return (storage_class & STCctorinit) != 0; }
    
	bool isFinal()        { return (storage_class & STCfinal) != 0; }
    
	bool isAbstract()     { return (storage_class & STCabstract)  != 0; }
    
	bool isConst()        { return (storage_class & STCconst) != 0; }
    
	bool isImmutable()    { return (storage_class & STCimmutable) != 0; }
    
	bool isAuto()         { return (storage_class & STCauto) != 0; }
    
	bool isScope()        { return (storage_class & (STCscope | STCauto)) != 0; }
    
	bool isSynchronized() { return (storage_class & STCsynchronized) != 0; }
    
	bool isParameter()    { return (storage_class & STCparameter) != 0; }
    
	bool isDeprecated()   { return (storage_class & STCdeprecated)  != 0; }
    
	bool isOverride()     { return (storage_class & STCoverride) != 0; }

    bool isIn()    { return (storage_class & STCin) != 0; }
    
	bool isOut()   { return (storage_class & STCout) != 0; }
    
	bool isRef()   { return (storage_class & STCref) != 0; }

    PROT prot()
	{
		return protection;
	}

    override Declaration isDeclaration() { return this; }
}

class AliasDeclaration : Declaration
{
	Dsymbol aliassym;
	Dsymbol overnext;		// next in overload list
	int inSemantic;

	this(Loc loc, Identifier ident, Type type)
	{
		super(ident);

		//printf("AliasDeclaration(id = '%s', type = %p)\n", id.toChars(), type);
		//printf("type = '%s'\n", type.toChars());
		this.loc = loc;
		this.type = type;
		this.aliassym = null;
		version (_DH) {
			this.htype = null;
			this.haliassym = null;
		}

		assert(type);
	}

	this(Loc loc, Identifier id, Dsymbol s)
	{
		super(id);

		//printf("AliasDeclaration(id = '%s', s = %p)\n", id->toChars(), s);
		assert(s !is this);	/// huh?
		this.loc = loc;
		this.type = null;
		this.aliassym = s;
		version (_DH) {
			this.htype = null;
			this.haliassym = null;
		}
		assert(s);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("AliasDeclaration::syntaxCopy()\n");
		assert(!s);
		AliasDeclaration sa;
		if (type)
			sa = new AliasDeclaration(loc, ident, type.syntaxCopy());
		else
			sa = new AliasDeclaration(loc, ident, aliassym.syntaxCopy(null));
version (_DH) {
		// Syntax copy for header file
		if (!htype)	    // Don't overwrite original
		{	if (type)	// Make copy for both old and new instances
			{   htype = type.syntaxCopy();
				sa.htype = type.syntaxCopy();
			}
		}
		else			// Make copy of original for new instance
			sa.htype = htype.syntaxCopy();
		if (!haliassym)
		{	if (aliassym)
			{   haliassym = aliassym.syntaxCopy(s);
				sa.haliassym = aliassym.syntaxCopy(s);
			}
		}
		else
			sa.haliassym = haliassym.syntaxCopy(s);
} // version (_DH)
		return sa;
	}


	override bool overloadInsert(Dsymbol s)
	{
		/* Don't know yet what the aliased symbol is, so assume it can
		 * be overloaded and check later for correctness.
		 */

		//printf("AliasDeclaration.overloadInsert('%s')\n", s.toChars());
		if (overnext is null)
		{
			if (s is this)
				return true;
			overnext = s;
			return true;

		}
		else
		{
			return overnext.overloadInsert(s);
		}
	}

	override string kind()
	{
		return "alias";
	}

	override Type getType()
	{
		return type;
	}

	override Dsymbol toAlias()
	{
		//printf("AliasDeclaration::toAlias('%s', this = %p, aliassym = %p, kind = '%s')\n", toChars(), this, aliassym, aliassym ? aliassym->kind() : "");
		assert(this !is aliassym);
		//static int count; if (++count == 10) *(char*)0=0;
		if (inSemantic)
		{
			error("recursive alias declaration");
			aliassym = new TypedefDeclaration(loc, ident, Type.terror, null);
		}

		Dsymbol s = aliassym ? aliassym.toAlias() : this;
		return s;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("alias ");
///	static if (false) { // && _DH
///		if (hgs.hdrgen)
///		{
///			if (haliassym)
///			{
///				haliassym.toCBuffer(buf, hgs);
///				buf.put(' ');
///				buf.put(ident.toChars());
///			}
///			else
///				htype.toCBuffer(buf, ident, hgs);
///		}
///		else
///	}
		{
		if (aliassym)
		{
			aliassym.toCBuffer(buf, hgs);
			buf.put(' ');
			buf.put(ident.toChars());
		}
		else
			type.toCBuffer(buf, ident, hgs);
		}
		buf.put(';');
		buf.put('\n');
	}

	version (_DH) {
		Type htype;
		Dsymbol haliassym;
	}
	override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	override AliasDeclaration isAliasDeclaration() { return this; }
}

// A shell around a back end symbol, but there's no back end!
class Symbol {} // Some class huh?

class SymbolDeclaration : Declaration
{
    Symbol* sym;
    StructDeclaration dsym;

    this(Loc loc, Symbol* s, StructDeclaration dsym)
	{
		//string name = Sident.ptr[0..len].idup;
		string name = "NoBackendSymbolsInZD";

		super(new Identifier(name, TOKidentifier));
		
		this.loc = loc;
		sym = s;
		this.dsym = dsym;
		storage_class |= STCconst;
	}


    // Eliminate need for dynamic_cast
    override SymbolDeclaration isSymbolDeclaration() { return this; }
}

class TupleDeclaration : Declaration
{
	Object[] objects;
	int isexp;			// 1: expression tuple

	TypeTuple tupletype;	// !=NULL if this is a type tuple

	this(Loc loc, Identifier ident, Object[] objects)
	{
		super(ident);
		this.type = null;
		this.objects = objects;
		this.isexp = 0;
		this.tupletype = null;
	}

	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);
	}

	override string kind()
	{
		return "tuple";
	}

	//override Type getType() { assert(false,"zd cut"); }

	//override bool needThis() { assert(false,"zd cut"); }

	override TupleDeclaration isTupleDeclaration() { return this; }
}

class TypedefDeclaration : Declaration
{
    Type basetype;
    Initializer init;
    int sem = 0;// 0: semantic() has not been run
				// 1: semantic() is in progress
				// 2: semantic() has been run
				// 3: semantic2() has been run

    this(Loc loc, Identifier id, Type basetype, Initializer init)
	{
		super(id);
		
		this.type = new TypeTypedef(this);
		this.basetype = basetype.toBasetype();
		this.init = init;

	version (_DH) {
		this.htype = null;
		this.hbasetype = null;
	}
		this.loc = loc;
		//BACKEND this.sinit = null;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		Type basetype = this.basetype.syntaxCopy();

		Initializer init = null;
		if (this.init)
			init = this.init.syntaxCopy();

		assert(!s);
		TypedefDeclaration st;
		st = new TypedefDeclaration(loc, ident, basetype, init);
version(_DH)
{
		// Syntax copy for header file
		if (!htype)		// Don't overwrite original
		{
			if (type)	// Make copy for both old and new instances
			{
				htype = type.syntaxCopy();
				st.htype = type.syntaxCopy();
			}
		}
		else			// Make copy of original for new instance
			st.htype = htype.syntaxCopy();
		if (!hbasetype)
		{
			if (basetype)
			{
				hbasetype = basetype.syntaxCopy();
				st.hbasetype = basetype.syntaxCopy();
			}
		}
		else
			st.hbasetype = hbasetype.syntaxCopy();
}
		return st;
	}
	
	
	
    override string mangle()
	{
		//printf("TypedefDeclaration::mangle() '%s'\n", toChars());
		return Dsymbol.mangle();
	}
	
    override string kind()
	{
		assert(false);
	}
	
    override Type getType()
	{
		return type;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

version (_DH) {
    Type htype;
    Type hbasetype;
}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	
    void toDebug()
	{
		assert(false);
	}
	

    override TypedefDeclaration isTypedefDeclaration() { return this; }

}
