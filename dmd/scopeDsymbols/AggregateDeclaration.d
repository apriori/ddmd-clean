module dmd.scopeDsymbols.AggregateDeclaration;

import dmd.Global;
import dmd.ScopeDsymbol;
import dmd.Type;
import dmd.Identifier;
import dmd.statements.ExpStatement;
import dmd.expressions.AddrExp;
import dmd.expressions.CastExp;
import dmd.types.TypeSArray;
import dmd.expressions.DotVarExp;
import dmd.types.TypeStruct;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.Declaration;
import dmd.types.TypeClass;
import dmd.Token;
import dmd.expressions.ThisExp;
import dmd.Expression;
import dmd.expressions.DotIdExp;
import dmd.expressions.CallExp;
import dmd.declarations.DtorDeclaration;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.declarations.InvariantDeclaration;
import dmd.declarations.NewDeclaration;
import dmd.declarations.DeleteDeclaration;
import dmd.declarations.CtorDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.scopeDsymbols.ClassDeclaration;
import std.array;
import dmd.BaseClass;

import dmd.DDMDExtensions;

class AggregateDeclaration : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Type type;
    StorageClass storage_class;
    PROT protection = PROTpublic;
    Type handle;		// 'this' type
    uint structsize;	// size of struct
    uint alignsize;		// size of struct for alignment purposes
    uint structalign;	// struct member alignment in effect
    int hasUnions;		// set if aggregate has overlapping fields
    VarDeclaration[] fields;	// VarDeclaration fields
    uint sizeok;		// set when structsize contains valid data
				// 0: no size
				// 1: size is correct
				// 2: cannot determine size; fwd referenced
    bool isdeprecated;		// true if deprecated

    bool isnested;		// true if is nested
    VarDeclaration vthis;	// 'this' parameter if this aggregate is nested

    // Special member functions
    InvariantDeclaration inv;		// invariant
    NewDeclaration aggNew;		// allocator
    DeleteDeclaration aggDelete;	// deallocator

    //CtorDeclaration *ctor;
    Dsymbol ctor;			// CtorDeclaration or TemplateDeclaration
    CtorDeclaration defaultCtor;	// default constructor
    Dsymbol aliasthis;			// forward unresolved lookups to aliasthis

    FuncDeclaration[] dtors;	// Array of destructors
    FuncDeclaration dtor;	// aggregate destructor

    this(Loc loc, Identifier id)
	{
		super(id);
		this.loc = loc;
	}


    override uint size(Loc loc)
	{
		//printf("AggregateDeclaration.size() = %d\n", structsize);
		if (!members)
			error(loc, "unknown size");

		if (sizeok != 1)
		{
			error(loc, "no size yet for forward reference");
			//*(char*)0=0;
		}

		return structsize;
	}

    override Type getType()
	{
		return type;
	}


    override bool isDeprecated()		// is aggregate deprecated?
	{
		return isdeprecated;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	/*******************************
	 * Do access check for member of this class, this class being the
	 * type of the 'this' pointer used to access smember.
	 */

    override PROT prot()
	{
		assert(false);
	}

    override AggregateDeclaration isAggregateDeclaration() { return this; }
}
