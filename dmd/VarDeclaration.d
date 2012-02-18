module dmd.VarDeclaration;

import dmd.Global;
import dmd.Declaration;
import dmd.UnaExp;
import dmd.BinExp;
import dmd.ScopeDsymbol;
import dmd.AttribDeclaration;
import dmd.types.TypeSArray;
import dmd.types.TypeTypedef;
import dmd.Initializer;
import dmd.types.TypeStruct;
import dmd.types.TypeTuple;
import dmd.Parameter;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Token;
import dmd.Module;
import dmd.FuncDeclaration;
import dmd.Type;
import dmd.Scope;
import dmd.Identifier;
import dmd.HdrGenState;
import std.array;


import std.stdio : writef;
import std.string : toStringz;


class VarDeclaration : Declaration
{
    Initializer init;
    uint offset;
    bool noauto;			// no auto semantics
	FuncDeclaration[] nestedrefs; // referenced by these lexically nested functions
	bool isargptr = false;		// if parameter that _argptr points to
    
    int ctorinit;		// it has been initialized in a ctor
    int onstack;		// 1: it has been allocated on the stack
				// 2: on stack, run destructor anyway
    int canassign;		// it can be assigned to
    Dsymbol aliassym;		// if redone as alias to another symbol
    Expression value;		// when interpreting, this is the value
				// (null if value not determinable)
    VarDeclaration rundtor;	// if !null, rundtor is tested at runtime to see
				// if the destructor should be run. Used to prevent
				// dtor calls on postblitted vars

    this(Loc loc, Type type, Identifier id, Initializer init)
	{
		super(id);
		
debug
{
		if (!type && !init)
		{
			writef("VarDeclaration('%s')\n", id.toChars());
			//*(char*)0=0;
		}
}
		assert(type || init);
		this.type = type;
		this.init = init;
version(_DH)
{
		this.htype = null;
		this.hinit = null;
}
		this.loc = loc;
		
	}

    Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("VarDeclaration.syntaxCopy(%s)\n", toChars());

		VarDeclaration sv;
		if (s)
		{	
			sv = cast(VarDeclaration)s;
		}
		else
		{
			Initializer init = null;
			if (this.init)
			{   
				init = this.init.syntaxCopy();
			}

			sv = new VarDeclaration(loc, type ? type.syntaxCopy() : null, ident, init);
			sv.storage_class = storage_class;
		}

	version (_DH) {
		// Syntax copy for header file
		if (!htype)      // Don't overwrite original
		{
			if (type)    // Make copy for both old and new instances
			{   htype = type.syntaxCopy();
				sv.htype = type.syntaxCopy();
			}
		}
		else            // Make copy of original for new instance
			sv.htype = htype.syntaxCopy();
		if (!hinit)
		{	
			if (init)
			{   
				hinit = init.syntaxCopy();
				sv.hinit = init.syntaxCopy();
			}
		}
		else
			sv.hinit = hinit.syntaxCopy();
	}
		return sv;
	}

    override string kind()
	{
		return "variable";
	}
	
    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		StorageClassDeclaration.stcToCBuffer(buf, storage_class);

		/* If changing, be sure and fix CompoundDeclarationStatement.toCBuffer()
		 * too.
		 */
		if (type)
			type.toCBuffer(buf, ident, hgs);
		else
			buf.put(ident.toChars());
		if (init)
		{	
			buf.put(" = ");
			ExpInitializer ie = init.isExpInitializer();
			if (ie && (ie.exp.op == TOKconstruct || ie.exp.op == TOKblit))
				(cast(AssignExp)ie.exp).e2.toCBuffer(buf, hgs);
			else
				init.toCBuffer(buf, hgs);
		}
		buf.put(';');
		buf.put('\n');
	}
	
version (_DH) {
    Type htype;
    Initializer hinit;
}
    bool needThis()
	{
		//printf("VarDeclaration.needThis(%s, x%x)\n", toChars(), storage_class);
		return (storage_class & STCfield) != 0;
	}
	
    bool isImportedSymbol()
	{
		if (protection == PROTexport && !init && (storage_class & STCstatic || parent.isModule()))
			return true;

		return false;
	}

    override bool isDataseg()
    {
        assert(false);
    }

	
	
    /********************************************
     * Can variable be read and written by CTFE?
     */

    int isCTFE()
    {
        return (storage_class & STCctfe) || !isDataseg();
    }

	

	/******************************************
	 * If a variable has an auto destructor call, return call for it.
	 * Otherwise, return null.
	 */

	/****************************
	 * Get ExpInitializer for a variable, if there is one.
	 */
    ExpInitializer getExpInitializer()
    {
        assert(false);
    }

	/*******************************************
	 * If variable has a constant expression initializer, get it.
	 * Otherwise, return null.
	 */


	/************************************
	 * Check to see if this variable is actually in an enclosing function
	 * rather than the current one.
	 */





    // Eliminate need for dynamic_cast
    override VarDeclaration isVarDeclaration() { return this; }
}

class ClassInfoDeclaration : VarDeclaration
{
	ClassDeclaration cd;

	this(ClassDeclaration cd)
	{

		super(Loc(0), global.classinfo.type, cd.ident, null);
		
		this.cd = cd;
		storage_class = STCstatic | STCgshared;
	}
	
	override Dsymbol syntaxCopy(Dsymbol)
	{
		 assert(false);		// should never be produced by syntax
		 return null;
	}
	

	override void emitComment(Scope sc)
	{
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }
	
}

class ModuleInfoDeclaration : VarDeclaration
{
	Module mod;

	this(Module mod)
	{
		super(Loc(0), global.moduleinfo.type, mod.ident, null);
	}
	
	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);		  // should never be produced by syntax
		return null;
	}
	

	void emitComment(Scope *sc)
	{
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

	/+ Symbol? what "Symbol"?
   +/
}

// For the "this" parameter to member functions
class ThisDeclaration : VarDeclaration
{
    this(Loc loc, Type t)
	{
		super(loc, t, Id.This, null);
		noauto = true;
	}
	
    override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);
	}
	
    override ThisDeclaration isThisDeclaration() { return this; }
}
