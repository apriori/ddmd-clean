module dmd.Scope;
// also defines enum CSX and enum SCOPE

import dmd.global;
import dmd.type;
import std.array;
import dmd.Module;
import dmd.scopeDsymbol;
import dmd.funcDeclaration;
import dmd.dsymbol;
import dmd.statement;
import dmd.identifier;
import dmd.docComment;


alias int SCOPE;
enum
{
	SCOPEctor = 1,	// constructor type
	SCOPEstaticif = 2,	// inside static if
	SCOPEfree = 4,	// is on free list
}

alias int CSX;
enum
{
    CSXthis_ctor = 1,   // called this()
    CSXsuper_ctor = 2,   // called super()
    CSXthis	 = 4,   // referenced this
    CSXsuper = 8,   // referenced super
    CSXlabel	= 0x10,   // seen a label
    CSXreturn	= 0x20,   // seen a return statement
    CSXany_ctor	= 0x40,   // either this() or super() was called
}

class Scope
{
    Scope enclosing;		// enclosing Scope

    Module module_;		// Root module
    ScopeDsymbol scopesym;	// current symbol
    ScopeDsymbol sd;		// if in static if, and declaring new symbols,
				// sd gets the addMember()
    FuncDeclaration func;	// function we are in
    Dsymbol parent;		// parent to use
    LabelStatement slabel;	// enclosing labelled statement
    SwitchStatement sw;	// enclosing switch statement
    TryFinallyStatement tf;	// enclosing try finally statement
    TemplateInstance tinst;    // enclosing template instance
    Statement sbreak;		// enclosing statement that supports "break"
    Statement scontinue;	// enclosing statement that supports "continue"
    ForeachStatement fes;	// if nested function for ForeachStatement, this is it
    uint offset;		// next offset to use in aggregate
    int inunion;		// we're processing members of a union
    int incontract;		// we're inside contract code
    int nofree;			// set if shouldn't free it
    int noctor;			// set if constructor calls aren't allowed
    int intypeof;		// in typeof(exp)
    int parameterSpecialization; // if in template parameter specialization
    int noaccesscheck;		// don't do access checks
    int mustsemantic;		// cannot defer semantic()

    uint callSuper;		// primitive flow analysis for constructors

    uint structalign;	// alignment for struct members
    LINK linkage = LINKd;		// linkage for external functions

    PROT protection = PROTpublic;	// protection for class members
    int explicitProtection;	// set if in an explicit protection attribute

    StorageClass stc;		// storage class

    SCOPE flags;

    AnonymousAggregateDeclaration anonAgg;	// for temporary analysis

    DocComment lastdc;		// documentation comment for last symbol at this scope
    uint lastoffset;	// offset in docbuf of where to insert next dec
    Appender!(char[]) docbuf;		// buffer for documentation output

///    static void *operator new(size_t sz);
    static Scope createGlobal(Module module_)
	{
		Scope sc = new Scope();
		sc.module_ = module_;
		sc.scopesym = new ScopeDsymbol();

		// Add top level package as member of this global scope
		Dsymbol m = module_;
		while (m.parent !is null)
			m = m.parent;

		m.addMember(null, sc.scopesym, true);
		m.parent = null;			// got changed by addMember()

		// Create the module scope underneath the global scope
	   sc = sc.push(module_);
		sc.parent = module_;
		return sc;
	}

    this()
	{
		// Create root scope

		//printf("Scope.Scope() %p\n", this);
		this.structalign = global.structalign;
	}
	
    this(Module module_)
	{
		assert(false);
	}
	
    this(Scope enclosing)
	{
		//printf("Scope.Scope(enclosing = %p) %p\n", enclosing, this);
		assert(!(enclosing.flags & SCOPEfree));
		this.module_ = enclosing.module_;
		this.func   = enclosing.func;
		this.parent = enclosing.parent;
		this.scopesym = null;
		this.sd = null;
		this.sw = enclosing.sw;
		this.tf = enclosing.tf;
        this.tinst = enclosing.tinst;
		this.tinst = enclosing.tinst;
		this.sbreak = enclosing.sbreak;
		this.scontinue = enclosing.scontinue;
		this.fes = enclosing.fes;
		this.structalign = enclosing.structalign;
		this.enclosing = enclosing;
debug {
		if (enclosing.enclosing)
			assert(!(enclosing.enclosing.flags & SCOPEfree));

		if (this is enclosing.enclosing)	/// huh?
		{
			writef("this = %p, enclosing = %p, enclosing.enclosing = %p\n", this, enclosing, enclosing.enclosing);
		}
		assert(this !is enclosing.enclosing);
}
		this.linkage = enclosing.linkage;
		this.protection = enclosing.protection;
		this.explicitProtection = enclosing.explicitProtection;
		this.stc = enclosing.stc;
		this.inunion = enclosing.inunion;
		this.incontract = enclosing.incontract;
		this.noctor = enclosing.noctor;
		this.noaccesscheck = enclosing.noaccesscheck;
		this.mustsemantic = enclosing.mustsemantic;
		this.intypeof = enclosing.intypeof;
		this.parameterSpecialization = enclosing.parameterSpecialization;
		this.callSuper = enclosing.callSuper;
		this.docbuf = enclosing.docbuf;
		assert(this !is enclosing);	/// huh?
	}
	
	Scope clone()
	{
		return cloneThis(this);
	}

    Scope push()
	{
		//printf("Scope ~= ()\n");
		Scope s = new Scope(this);
		assert(this !is s);	/// huh?
		return s;
	}
	
    Scope push(ScopeDsymbol ss)
	{
		//printf("Scope ~= (%s)\n", ss.toChars());
		Scope s = push();
		s.scopesym = ss;
		return s;
	}
	
    Scope pop()
	{
		//printf("Scope.pop() %p nofree = %d\n", this, nofree);
		Scope enc = enclosing;

		if (enclosing)
			enclosing.callSuper |= callSuper;

		if (!nofree)
		{
			enclosing = global.scope_freelist;
			global.scope_freelist = this;
			flags |= SCOPEfree;
		}

		return enc;
	}
    
    void mergeCallSuper(Loc loc, uint cs)
	{
		// This does a primitive flow analysis to support the restrictions
		// regarding when and how constructors can appear.
		// It merges the results of two paths.
		// The two paths are callSuper and cs; the result is merged into callSuper.

		if (cs != callSuper)
		{	
			int a;
			int b;

			callSuper |= cs & (CSXany_ctor | CSXlabel);
			if (cs & CSXreturn)
			{
				;
			}
			else if (callSuper & CSXreturn)
			{
				callSuper = cs | (callSuper & (CSXany_ctor | CSXlabel));
			}
			else
			{
				a = (cs        & (CSXthis_ctor | CSXsuper_ctor)) != 0;
				b = (callSuper & (CSXthis_ctor | CSXsuper_ctor)) != 0;

				if (a != b)
					error(loc, "one path skips constructor");
				callSuper |= cs;
			}
		}
	}

	
    Dsymbol insert(Dsymbol s)
	{
		for (Scope sc = this; sc; sc = sc.enclosing)
		{
			//printf("\tsc = %p\n", sc);
			if (sc.scopesym)
			{
				//printf("\t\tsc.scopesym = %p\n", sc.scopesym);
				return sc.scopesym.symtabInsert(s);
			}
		}

		assert(false);
	}

    ClassDeclaration getClassScope()
	{
		assert(false);
	}
	
	/********************************************
	 * Search enclosing scopes for ClassDeclaration.
	 */
    AggregateDeclaration getStructClassScope()
	{
		for (Scope sc = this; sc; sc = sc.enclosing)
		{
			AggregateDeclaration ad;
			
			if (sc.scopesym)
			{
				ad = sc.scopesym.isClassDeclaration();
				if (ad)
					return ad;
				else
				{	
					ad = sc.scopesym.isStructDeclaration();
					if (ad)
						return ad;
				}
			}
		}

		return null;
	}
	
    void setNoFree()
	{
		//int i = 0;

		//printf("Scope.setNoFree(this = %p)\n", this);
		for (Scope sc = this; sc; sc = sc.enclosing)
		{
			//printf("\tsc = %p\n", sc);
			sc.nofree = 1;

			assert(!(flags & SCOPEfree));
			//assert(sc != sc.enclosing);
			//assert(!sc.enclosing || sc != sc.enclosing.enclosing);
			//if (++i == 10)
				//assert(0);
		}
	}
}
