module dmd.Declaration;
// defined in this module: enum STC, enum StorageClass, struct MATCH

import dmd.Global;
import dmd.Dsymbol;
import dmd.Type;
import dmd.declarations.TypedefDeclaration;
import dmd.Identifier;
import dmd.Scope;
import dmd.declarations.FuncDeclaration;
import dmd.VarDeclaration;

import std.array;

import dmd.DDMDExtensions;

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
	mixin insertMemberExtension!(typeof(this));
	
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
