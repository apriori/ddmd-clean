module dmd.declarations.FuncDeclaration;

import dmd.Global;
import dmd.Declaration;
import dmd.expressions.DotIdExp;
import dmd.expressions.AddrExp;
import dmd.statements.TryFinallyStatement;
import dmd.statements.TryCatchStatement;
import dmd.declarations.SharedStaticDtorDeclaration;
import dmd.Catch;
import dmd.statements.DeclarationStatement;
import dmd.declarations.StaticDtorDeclaration;
import dmd.statements.PeelStatement;
import dmd.statements.SynchronizedStatement;
import dmd.Token;
import dmd.expressions.SymOffExp;
import dmd.expressions.AssignExp;
import dmd.initializers.ExpInitializer;
import dmd.attribDeclarations.StorageClassDeclaration;
import dmd.expressions.StringExp;
import dmd.expressions.DsymbolExp;
import dmd.expressions.HaltExp;
import dmd.expressions.CommaExp;
import dmd.statements.ReturnStatement;
import dmd.expressions.IntegerExp;
import dmd.statements.ExpStatement;
import dmd.statements.CompoundStatement;
import dmd.statements.LabelStatement;
import dmd.expressions.ThisExp;
import dmd.expressions.SuperExp;
import dmd.expressions.IdentifierExp;
import dmd.expressions.AssertExp;
import dmd.expressions.CallExp;
import dmd.expressions.VarExp;
import dmd.declarations.TupleDeclaration;
import dmd.varDeclarations.ThisDeclaration;
import dmd.types.TypeTuple;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.ScopeDsymbol;
import dmd.declarations.AliasDeclaration;
import dmd.Lexer;
import dmd.declarations.CtorDeclaration;
import dmd.declarations.DtorDeclaration;
import dmd.declarations.InvariantDeclaration;
import dmd.expressions.PtrExp;
import dmd.expressions.DeclarationExp;
import dmd.Parameter;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.scopeDsymbols.InterfaceDeclaration;
import dmd.Statement;
import dmd.Identifier;
import dmd.VarDeclaration;
import dmd.dsymbols.LabelDsymbol;
import dmd.statements.ForeachStatement;
import dmd.Type;
import dmd.types.TypeFunction;
import dmd.Expression;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.InterState;
import dmd.BaseClass;
import dmd.Module;

import dmd.DDMDExtensions;

import std.string;

class FuncDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));
	
    Type[] fthrows;			// Array of Type's of exceptions (not used)
    Statement frequire;
    Statement fensure;
    Statement fbody;

    FuncDeclaration[] foverrides;	// functions this function overrides
    FuncDeclaration fdrequire;		// function that does the in contract
    FuncDeclaration fdensure;		// function that does the out contract

    Identifier outId;			// identifier for out statement
    VarDeclaration vresult;		// variable corresponding to outId
    LabelDsymbol returnLabel;		// where the return goes

    Dsymbol[string] localsymtab;		// used to prevent symbols in different
					// scopes from having the same name
    VarDeclaration vthis;		// 'this' parameter (member and nested)
    VarDeclaration v_arguments;	// '_arguments' parameter
    Dsymbol[] parameters;		// Array of VarDeclaration's for parameters
    LabelDsymbol[string] labtab;		// statement label symbol table
    Declaration overnext;		// next in overload list
    Loc endloc;					// location of closing curly bracket
    int vtblIndex;				// for member functions, index into vtbl[]
    int naked;					// !=0 if naked
    int inlineAsm;				// !=0 if has inline assembler
    int inlineNest;				// !=0 if nested inline
    int cantInterpret;			// !=0 if cannot interpret function
    PASS semanticRun;
								// this function's frame ptr
    ForeachStatement fes;		// if foreach body, this is the foreach
    int introducing;			// !=0 if 'introducing' function
    Type tintro;			// if !=null, then this is the type
					// of the 'introducing' function
					// this one is overriding
    int inferRetType;			// !=0 if return type is to be inferred

    // Things that should really go into Scope
    int hasReturnExp;			// 1 if there's a return exp; statement
					// 2 if there's a throw statement
					// 4 if there's an assert(0)
					// 8 if there's inline asm

    // Support for NRVO (named return value optimization)
    bool nrvo_can = true;			// !=0 means we can do it
    VarDeclaration nrvo_var;		// variable to replace with shidden
    //Symbol* shidden;			// hidden pointer passed to function

    //BUILTIN builtin;		// set if this is a known, builtin
					// function we can evaluate at compile
					// time

    //int tookAddressOf;			// set if someone took the address of
					// this function
    Dsymbol[] closureVars;		// local variables in this function
					// which are referenced by nested
					// functions
    
    this(Loc loc, Loc endloc, Identifier id, StorageClass storage_class, Type type)
	{
		super(id);

		this.storage_class = storage_class;
		this.type = type;
		this.loc = loc;
		this.endloc = endloc;
		vtblIndex = -1;
		semanticRun = PASSinit;
		/* The type given for "infer the return type" is a TypeFunction with
		 * null for the return type.
		 */
		inferRetType = (type && type.nextOf() is null);
		nrvo_can = 1;
		//builtin = BUILTINunknown;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		FuncDeclaration f;

		if (s)
			f = cast(FuncDeclaration)s;
		else
			f = new FuncDeclaration(loc, endloc, ident, storage_class, type.syntaxCopy());

		f.outId = outId;
		f.frequire = frequire ? frequire.syntaxCopy() : null;
		f.fensure  = fensure  ? fensure.syntaxCopy()  : null;
		f.fbody    = fbody    ? fbody.syntaxCopy()    : null;
		assert(!fthrows); // deprecated

		return f;
	}

	// Do the semantic analysis on the external interface to the function.

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
//		writef("FuncDeclaration.toCBuffer() '%s'\n", toChars());

		StorageClassDeclaration.stcToCBuffer(buf, storage_class);
		type.toCBuffer(buf, ident, hgs);
		bodyToCBuffer(buf, hgs);
	}

	void bodyToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (fbody )
		{
			buf.put('\n');

			// in{}
			if (frequire)
			{
				buf.put("in");
				buf.put('\n');
				frequire.toCBuffer(buf, hgs);
			}

			// out{}
			if (fensure)
			{
				buf.put("out");
				if (outId)
				{
					buf.put('(');
					buf.put(outId.toChars());
					buf.put(')');
				}
				buf.put('\n');
				fensure.toCBuffer(buf, hgs);
			}

			if (frequire || fensure)
			{
				buf.put("body");
				buf.put('\n');
			}

			buf.put('{');
			buf.put('\n');
			fbody.toCBuffer(buf, hgs);
			buf.put('}');
			buf.put('\n');
		}
		else
		{   buf.put(';');
			buf.put('\n');
		}
	}

	/********************************
	 * Labels are in a separate scope, one per function.
	 */
    LabelDsymbol searchLabel(Identifier ident)
	{
		LabelDsymbol s;

		s = labtab.get(ident.toChars(),null);
		if (!s)
		{
			s = new LabelDsymbol(ident);
			labtab[ident.toChars()] = s;
		}

		return s;
	}

	/****************************************
	 * If non-static member function that has a 'this' pointer,
	 * return the aggregate it is a member of.
	 * Otherwise, return null.
	 */
    override AggregateDeclaration isThis()
	{
		AggregateDeclaration ad = null;

		if ((storage_class & STCstatic) == 0)
		{
			ad = isMember2();
		}
		return ad;
	}

    AggregateDeclaration isMember2()
	{
		AggregateDeclaration ad = null;

		for (Dsymbol s = this; s; s = s.parent)
		{
			ad = s.isMember();
			if (ad)
			{ 
					break;
			}
			if (!s.parent || (!s.parent.isTemplateInstance()))
			{   
					break;
			}
		}
		
		return ad;
	}

    void appendExp(Expression e)
	{
		assert(false);
	}

    void appendState(Statement s)
	{
		assert(false);
	}

    override string mangle()
	out (result)
	{
		assert(result.length > 0);
	}
	body
	{
		if (isMain()) {
			return "_Dmain";
		}

		if (isWinMain() || isDllMain() || ident == Id.tls_get_addr)
			return ident.toChars();

		assert(this);

		return Declaration.mangle();
	}

    override string toPrettyChars()
	{
		if (isMain())
			return "D main";
		else
			return Dsymbol.toPrettyChars();
	}

    int isMain()
	{
		return ident is Id.main && linkage != LINKc && !isMember() && !isNested();
	}

    int isWinMain()
	{
		return ident == Id.WinMain && linkage != LINKc && !isMember();
	}

    int isDllMain()
	{
		return ident == Id.DllMain && linkage != LINKc && !isMember();
	}

    override bool isExport()
	{
		return protection == PROTexport;
	}

    override bool isImportedSymbol()
	{
		return (protection == PROTexport) && !fbody;
	}

    override bool isAbstract()
	{
		return (storage_class & STCabstract) != 0;
	}

    override bool isCodeseg()
	{
		return true;		// functions are always in the code segment
	}

    override bool isOverloadable()
	{
		return 1;			// functions can be overloaded
	}

    bool isPure()
	{
		assert(type.ty == Tfunction);
		return (cast(TypeFunction)this.type).ispure;
	}

	int isSafe()
	{
		assert(type.ty == Tfunction);
		return (cast(TypeFunction)this.type).trust == TRUSTsafe;
	}

	int isTrusted()
	{
		assert(type.ty == Tfunction);
		return (cast(TypeFunction)this.type).trust == TRUSTtrusted;
	}

    bool isNested()
	{
		return ((storage_class & STCstatic) == 0) &&
		   (toParent2().isFuncDeclaration() !is null);
	}

    override bool needThis()
	{
		bool needThis = isThis() !is null;

		if (!needThis) {
			if (auto fa = isFuncAliasDeclaration()) {
				needThis = fa.funcalias.needThis();
			}
		}

		return needThis;
	}

    bool isVirtual()
	{
	    Dsymbol p = toParent();
	    return isMember() &&
			!(isStatic() || protection == PROTprivate || protection == PROTpackage) &&
			p.isClassDeclaration() &&
			!(p.isInterfaceDeclaration() && isFinal());
	}

    override bool isFinal()
	{
		ClassDeclaration cd;
		return isMember() && (Declaration.isFinal() || ((cd = toParent().isClassDeclaration()) !is null && cd.storage_class & STCfinal));
	}

    override string kind()
	{
		return "function";
	}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	FuncDeclaration isUnique()
	{
        assert(false);
	}

	/*******************************
	 * Look at all the variables in this function that are referenced
	 * by nested functions, and determine if a closure needs to be
	 * created for them.
	 */

    /****************************************************
	 * Merge into this function the 'in' contracts of all it overrides.
	 * 'in's are OR'd together, i.e. only one of them needs to pass.
	 */


    /*********************************************
     * Return the function's parameter list, and whether
     * it is variadic or not.
     */

    Parameter[] getParameters(ref int pvarargs)
    {
        Parameter[] fparameters;
        int fvarargs;

        if (type)
        {
	        assert(type.ty == Tfunction);
	        auto fdtype = cast(TypeFunction)type;
	        fparameters = fdtype.parameters;
	        fvarargs = fdtype.varargs;
        }
        else // Constructors don't have type's
        {
            CtorDeclaration fctor = isCtorDeclaration();
	        assert(fctor);
	        fparameters = fctor.arguments;
	        fvarargs = fctor.varargs;
        }
        if (pvarargs)
	     pvarargs = fvarargs;
        return fparameters;
    }

    override FuncDeclaration isFuncDeclaration() { return this; }
}

