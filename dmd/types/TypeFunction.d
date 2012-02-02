module dmd.types.TypeFunction;

import dmd.Global;
import dmd.types.TypeNext;
import dmd.types.TypeSArray;
import dmd.types.TypeArray;
import dmd.templateParameters.TemplateTupleParameter;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.types.TypeStruct;
import dmd.types.TypeIdentifier;
import dmd.TemplateParameter;
import dmd.varDeclarations.TypeInfoFunctionDeclaration;
import dmd.Type;
import dmd.Scope;
import dmd.Identifier;
import dmd.HdrGenState;
import std.array;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.Parameter;
import dmd.Expression;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.types.TypeTuple;
import dmd.scopeDsymbols.TemplateInstance : isTuple;
import std.stdio;

import dmd.DDMDExtensions;

class TypeFunction : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    // .next is the return type

    Parameter[] parameters;	// function parameters
    int varargs;	// 1: T t, ...) style for variable number of arguments
			// 2: T t ...) style for variable number of arguments
    bool isnothrow;	// true: nothrow
    bool ispure;	// true: pure
    bool isproperty;	// can be called without parentheses
    bool isref;		// true: returns a reference
    LINK linkage;	// calling convention
    TRUST trust;	// level of trust
    Expression[] fargs;	// function arguments

    int inuse;

    this(Parameter[] parameters, Type treturn, int varargs, LINK linkage)
	{
		super(Tfunction, treturn);

		//if (!treturn) *(char*)0=0;
	//    assert(treturn);
		assert(0 <= varargs && varargs <= 2);
		this.parameters = parameters;
		this.varargs = varargs;
		this.linkage = linkage;
        this.trust = TRUSTdefault;
	}
	
    override Type syntaxCopy()
	{
		Type treturn = next ? next.syntaxCopy() : null;
		auto params = Parameter.arraySyntaxCopy(parameters);
		TypeFunction t = new TypeFunction(params, treturn, varargs, linkage);
		t.mod = mod;
		t.isnothrow = isnothrow;
		t.ispure = ispure;
		t.isproperty = isproperty;
		t.isref = isref;
        t.trust = trust;
        t.fargs = fargs;

		return t;
	}

	
    //override void toDecoBuffer(ref Appender!(char[]) buf, int flag) { assert(false,"zd cut"); }
	
    override void toCBuffer(ref Appender!(char[]) buf, Identifier ident, ref HdrGenState hgs)
	{
		//printf("TypeFunction.toCBuffer() this = %p\n", this);
		string p = null;

		if (inuse)
		{	
			inuse = 2;		// flag error to caller
			return;
		}
		inuse++;

		/* Use 'storage class' style for attributes
		 */
	    if (mod)
        {
	        MODtoBuffer(buf, mod);
	        buf.put(' ');
        }

		if (ispure)
			buf.put("pure ");
		if (isnothrow)
			buf.put("nothrow ");
		if (isproperty)
			buf.put("@property ");
		if (isref)
			buf.put("ref ");

        switch (trust)
        {
	    case TRUSTtrusted:
	        buf.put("@trusted ");
	        break;

	    case TRUSTsafe:
	        buf.put("@safe ");
	        break;

		default:
        }

		if (next && (!ident || ident.toHChars2() == ident.toChars()))
			next.toCBuffer2(buf, hgs, MODundefined);
		if (hgs.ddoc != 1)
		{
			switch (linkage)
			{
				case LINKd:		p = null;	break;
				case LINKc:		p = " C";	break;
				case LINKwindows:	p = " Windows";	break;
				case LINKpascal:	p = " Pascal";	break;
				case LINKcpp:	p = " C++";	break;
				default:
				assert(0);
			}
		}

		if (!hgs.hdrgen && p)
			buf.put(p);
		if (ident)
		{   
			buf.put(' ');
			buf.put(ident.toHChars2());
		}
		Parameter.argsToCBuffer(buf, hgs, parameters, varargs);
		inuse--;
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypeFunction::toCBuffer2() this = %p, ref = %d\n", this, isref);
		string p;

		if (inuse)
		{
			inuse = 2;		// flag error to caller
			return;
		}

		inuse++;
		if (next)
			next.toCBuffer2(buf, hgs, MODundefined);

		if (hgs.ddoc != 1)
		{
			switch (linkage)
			{
				case LINKd:			p = null;		break;
				case LINKc:			p = "C ";		break;
				case LINKwindows:	p = "Windows ";	break;
				case LINKpascal:	p = "Pascal ";	break;
				case LINKcpp:		p = "C++ ";		break;
				default: assert(0);
			}
		}

		if (!hgs.hdrgen && p)
			buf.put(p);
		buf.put(" function");
		Parameter.argsToCBuffer(buf, hgs, parameters, varargs);

		/* Use postfix style for attributes
		 */
		if (mod != this.mod)
		{
			modToBuffer(buf);
		}

		if (ispure)
			buf.put(" pure");
		if (isnothrow)
			buf.put(" nothrow");
		if (isproperty)
			buf.put(" @property");
		if (isref)
			buf.put(" ref");

        switch (trust)
        {
	    case TRUSTtrusted:
	        buf.put(" @trusted");
	        break;

	    case TRUSTsafe:
	        buf.put(" @safe");
	        break;

		default:
        }
		inuse--;
	}
	
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoFunctionDeclaration(this);
	}
	
    //override Type reliesOnTident() { assert(false,"zd cut"); }

	/***************************
	 * Examine function signature for parameter p and see if
	 * p can 'escape' the scope of the function.
	 */
    //bool parameterEscapes(Parameter p) { assert(false,"zd cut"); }

	/********************************
	 * 'args' are being matched to function 'this'
	 * Determine match level.
	 * Returns:
	 *	MATCHxxxx
	 */
    //MATCH callMatch(Expression ethis, Expression[] args) { assert(false,"zd cut"); }
	
	
	/***************************
	 * Determine return style of function - whether in registers or
	 * through a hidden pointer to the caller's stack.
	 */
	//RET retStyle() { assert(false,"zd cut"); }

}
