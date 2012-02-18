module dmd.Expression;
// also defines enum WANT,

import dmd.Global;
import dmd.Parameter;
import dmd.UnaExp;
import dmd.BinExp;
import dmd.Identifier;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.Declaration;
import dmd.TemplateParameter;
import dmd.ScopeDsymbol;
import dmd.FuncDeclaration;
import dmd.Statement;
import dmd.Token;
import dmd.types.TypeEnum;
import dmd.types.TypeTypedef;

import std.stdio;
import std.format, std.string;
import std.conv, std.array, std.ascii;

/* Things like:
 *	int.size
 *	foo.size
 *	(foo).size
 *	cast(foo).size
 */
Expression typeDotIdExp(Loc loc, Type type, Identifier ident)
{
	return new DotIdExp(loc, new TypeExp(loc, type), ident);
}

/+/
Expression EXP_CANT_INTERPRET = castToExpression(1);
Expression EXP_CONTINUE_INTERPRET = castToExpression(2);
Expression EXP_BREAK_INTERPRET = castToExpression(3);
Expression EXP_GOTO_INTERPRET = castToExpression(4);
Expression EXP_VOID_INTERPRET = castToExpression(5);
// +/

alias int WANT;
enum 
{
    WANTflags = 1,
    WANTvalue = 2,
    WANTinterpret = 4,
}

Expression castToExpression(int i)
{
	union U
	{
		int i;
		Expression e;
	}
	
	U u;
	u.i = i;
	return u.e;
}

/**************************************************
 * Write expression out to buf, but wrap it
 * in ( ) if its precedence is less than pr.
 */

/+this is in the class, is it needed here?
void expToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs, Expression e, PREC pr)
{
    //if (precedence[e.op] == 0) e.dump(0);
    if ( precedence[e.op] < pr ||
	       /* Despite precedence, we don't allow a<b<c expressions.
	       * They must be parenthesized.
	       */
	       (pr == PREC_rel && precedence[e.op] == pr)
        )
    {
		buf.put('(');
		e.toCBuffer(buf, hgs);
		buf.put(')');
    }
    else
		e.toCBuffer(buf, hgs);
}
+/
/+ Ithink this is unnecessary too
/**************************************************
 * Write out argument list to buf.
 */

void argsToCBuffer(ref Appender!(char[]) buf, Expression[] arguments, ref HdrGenState hgs)
{
    if (arguments)
    {
		foreach (size_t i, Expression arg; arguments)
		{   
			if (arg)
			{	
				if (i)
					buf.put(',');
				expToCBuffer(buf, hgs, arg, PREC_assign);
			}
		}
    }
}
+/


class Expression
{
    Loc loc;			// file location
    TOK op;		// handy to minimize use of dynamic_cast
      
    Type type; // !=null means that semantic() has been run
    int size;			// # of bytes in Expression so we can copy() it

    this(Loc loc, TOK op, int size)
	{
		this.loc = loc;
		//writef("Expression.Expression(op = %d %s) this = %p\n", op, to!(string)(op), this);
		this.op = op;
		this.size = size;
	}

	//bool equals(Object o) { assert (false,"zd cut"); }

	/*********************************
	 * Does *not* do a deep copy.
	 */
    Expression copy()
	{
      return cloneThis(this);
	}
	
    Expression syntaxCopy()
	{
		//printf("Expression::syntaxCopy()\n");
		//dump(0);
		return copy();
	}
    
    /**************************************************
     * Write expression out to buf, but wrap it
     * in ( ) if its precedence is less than pr.
     */

    void expToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs, Expression e, PREC pr)
    {
        //if (precedence[e.op] == 0) e.dump(0);
        if (precedence[e.op] < pr ||
                /* Despite precedence, we don't allow a<b<c expressions.
                 * They must be parenthesized.
                 */
                (pr == PREC_rel && precedence[e.op] == pr))
        {
            buf.put('(');
            e.toCBuffer(buf, hgs);
            buf.put(')');
        }
        else
            e.toCBuffer(buf, hgs);
    }

    /**************************************************
     * Write out argument list to buf.
     */

    void argsToCBuffer(ref Appender!(char[]) buf, Expression[] arguments, ref HdrGenState hgs)
    {
        if (arguments)
            foreach (size_t i, Expression arg; arguments)
                if (arg)
                {	
                    if (i) buf.put(',');
                    expToCBuffer(buf, hgs, arg, PREC_assign);
                }
    }

    bool isBool(bool result)
    {
        return false;
    }

	Identifier opId()
	{
		assert(false);
	}

	void rvalue()
	{
   }
    //DYNCAST dyncast() { return DYNCAST.DYNCAST_EXPRESSION; }	// kludge for template.isExpression()

    void print()
	{
		assert(false);
	}
	
    string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;
	
		toCBuffer(buf, hgs);
		return buf.data.idup;
	}
	

    private void indent(int indent)
    {
        foreach (i; 0 .. indent)
            writef(" ");
    }

    private string type_print(Type type)
    {
        return type ? type.toChars() : "null";
    }

    void error(T...)(string format, T t)
    {
        .error(loc, format, t);
    }

    void warning(T...)(string format, T t)
    {
        super.warning(loc, format, t);
    }

	int isConst() { assert(false); }

	real toImaginary() { assert(false); }
	Identifier opId_r() { assert(false); }

        ulong toInteger()
        { assert (false);
        }
    int isBit()
    {
        assert (false);
    }

    static Expression combine(Expression e1, Expression e2)
	{
		if (e1)
		{
			if (e2)
			{
				e1 = new CommaExp(e1.loc, e1, e2);
				e1.type = e2.type;
			}
		}
		else
		{
			e1 = e2;
		}

		return e1;
	}
    
	static Expression[] arraySyntaxCopy(Expression[] exps)
	{
		Expression[] a = null;

		if (exps)
		{
			a.length = exps.length;
         foreach ( i, e; exps )
         {
            if (e) 
                a[i] = e.syntaxCopy();
         }
		}
		return a;
	}

    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(op));
	}
	
    void toMangleBuffer(ref Appender!(char[]) buf)
	{
	}

    Expression checkToBoolean()
   {
       assert(false); 
   }
	/**************************************
	 * Do an implicit cast.
	 * Issue error if it can't be done.
	 */
    //Expression implicitCastTo(Scope sc, Type t) { assert (false,"zd cut"); }
    
	/****************************************
	 * Resolve __LINE__ and __FILE__ to loc.
	 */
	Expression resolveLoc(Loc loc, Scope sc)
	{
	    return this;
	}

}

class ArrayLiteralExp : Expression
{
	Expression[] elements;

	this(Loc loc, Expression[] elements)
	{
		super(loc, TOKarrayliteral, ArrayLiteralExp.sizeof);
		this.elements = elements;
	}

	this(Loc loc, Expression e)
	{
		super(loc, TOKarrayliteral, ArrayLiteralExp.sizeof);
		elements ~= e;
	}

	override Expression syntaxCopy()
	{
		return new ArrayLiteralExp(loc, arraySyntaxCopy(elements));
	}

	override bool isBool(bool result)
	{
		size_t dim = elements ? elements.length : 0;
		return result ? (dim != 0) : (dim == 0);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('[');
		argsToCBuffer(buf, elements, hgs);
		buf.put(']');
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		size_t dim = elements ? elements.length : 0;
		formattedWrite(buf,"A%s", dim);	///
		for (size_t i = 0; i < dim; i++)
		{	
			auto e = elements[i];
			e.toMangleBuffer(buf);
		}
	}

}

class AssocArrayLiteralExp : Expression
{
	Expression[] keys;
	Expression[] values;

	this(Loc loc, Expression[] keys, Expression[] values)
	{

		super(loc, TOKassocarrayliteral, this.sizeof);
		assert(keys.length == values.length);
		this.keys = keys;
		this.values = values;	
	}

	override Expression syntaxCopy()
	{
		return new AssocArrayLiteralExp(loc,
				arraySyntaxCopy(keys), arraySyntaxCopy(values));
	}

	override bool isBool(bool result)
	{
		size_t dim = keys.length;
		return result ? (dim != 0) : (dim == 0);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('[');
		for (size_t i = 0; i < keys.length; i++)
		{	auto key = keys[i];
			auto value = values[i];

			if (i)
				buf.put(',');
			expToCBuffer(buf, hgs, key, PREC_assign);
			buf.put(':');
			expToCBuffer(buf, hgs, value, PREC_assign);
		}
		buf.put(']');
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		size_t dim = keys.length;
		formattedWrite(buf,"A%u", dim);
		for (size_t i = 0; i < dim; i++)
		{	auto key = keys[i];
			auto value = values[i];

			key.toMangleBuffer(buf);
			value.toMangleBuffer(buf);
		}
	}

}
// Declaration of a symbol

class DeclarationExp : Expression
{
	Dsymbol declaration;

	this(Loc loc, Dsymbol declaration)
	{
		super(loc, TOKdeclaration, DeclarationExp.sizeof);
		this.declaration = declaration;
	}

	override Expression syntaxCopy()
	{
		return new DeclarationExp(loc, declaration.syntaxCopy(null));
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		declaration.toCBuffer(buf, hgs);
	}

}

class DefaultInitExp : Expression
{
	TOK subop;

	this(Loc loc, TOK subop, int size)
	{
		super(loc, TOKdefault, size);
		this.subop = subop;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(subop));
	}
}

class LineInitExp : DefaultInitExp
{
	this(Loc loc)
	{
		super(loc, TOKline, this.sizeof);
	}
}

class FileInitExp : DefaultInitExp
{
	this(Loc loc)
	{
		super(loc, TOKfile, this.sizeof);
	}

}

class DollarExp : IdentifierExp
{
	this(Loc loc)
	{
		super(loc, Id.dollar);
	}
}

class DsymbolExp : Expression
{
	Dsymbol s;
	bool hasOverloads;

	this(Loc loc, Dsymbol s, bool hasOverloads = false)
	{
		super(loc, TOKdsymbol, DsymbolExp.sizeof);
		this.s = s;
		this.hasOverloads = hasOverloads;
	}

	override string toChars()
	{
		assert(false);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

}

class FuncExp : Expression
{
	FuncLiteralDeclaration fd;

	this(Loc loc, FuncLiteralDeclaration fd)
	{
		super(loc, TOKfunction, FuncExp.sizeof);
		this.fd = fd;
	}

	override Expression syntaxCopy()
	{
		return new FuncExp(loc, cast(FuncLiteralDeclaration)fd.syntaxCopy(null));
	}

	

	override string toChars()
	{
		return fd.toChars();
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		fd.toCBuffer(buf, hgs);
		//buf.put(fd.toChars());
	}

}

class HaltExp : Expression
{
	this(Loc loc)
	{
		super(loc, TOKhalt, HaltExp.sizeof);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("halt");
	}

}

class IdentifierExp : Expression
{
	Identifier ident;

	Declaration var;

	this(Loc loc, Identifier ident)
	{
		super(loc, TOKidentifier, IdentifierExp.sizeof);
		this.ident = ident;
	}

	this(Loc loc, Declaration var)
	{
		assert(false);
		super(loc, TOK.init, 0);
	}

	override string toChars()
	{
		return ident.toChars();
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (hgs.hdrgen)
			buf.put(ident.toHChars2());
		else
			buf.put(ident.toChars());
	}

}

class IntegerExp : Expression
{
	ulong value;

	this(Loc loc, ulong value, Type type)
	{
		super(loc, TOKint64, IntegerExp.sizeof);
		
		//printf("IntegerExp(value = %lld, type = '%s')\n", value, type ? type.toChars() : "");
		if (type && !type.isscalar())
		{
			//printf("%s, loc = %d\n", toChars(), loc.linnum);
			error("integral constant must be scalar type, not %s", type.toChars());
			type = Type.terror;
		}
		this.type = type;
		this.value = value;
	}

	this(ulong value)
	{
		super(Loc(0), TOKint64, IntegerExp.sizeof);
		this.type = Type.tint32;
		this.value = value;
	}

	//override bool equals(Object o) { assert (false,"zd cut"); }

	override string toChars()
	{
		return Expression.toChars();
	}

	override ulong toInteger()
	{
		Type t;

		t = type;
		while (t)
		{
			switch (t.ty)
			{
				case Tbit:
				case Tbool:	value = (value != 0);		break;
				case Tint8:	value = cast(byte)  value;	break;
				case Tchar:
				case Tuns8:	value = cast(ubyte) value;	break;
				case Tint16:	value = cast(short) value;	break;
				case Twchar:
				case Tuns16:	value = cast(ushort)value;	break;
				case Tint32:	value = cast(int)   value;	break;
				case Tdchar:
				case Tuns32:	value = cast(uint)  value;	break;
				case Tint64:	value = cast(long)  value;	break;
				case Tuns64:	value = cast(ulong) value;	break;
				case Tpointer:
						if (PTRSIZE == 4)
							value = cast(uint) value;
						else if (PTRSIZE == 8)
							value = cast(ulong) value;
						else
							assert(0);
						break;

				case Tenum:
				{
					TypeEnum te = cast(TypeEnum)t;
					t = te.sym.memtype;
					continue;
				}

				case Ttypedef:
				{
					TypeTypedef tt = cast(TypeTypedef)t;
					t = tt.sym.basetype;
					continue;
				}

				default:
					/* This can happen if errors, such as
					 * the type is painted on like in fromConstInitializer().
					 */
					if (!global.errors)
					{
						writef("%s %s\n", type.toChars(), type);
						assert(0);
					}
					break;

			}
			break;
		}
		return value;
	}

	override real toImaginary()
	{
		assert(false);
	}

	override int isConst()
	{
		return 1;
	}

	override bool isBool(bool result)
	{
        int r = toInteger() != 0;
        return cast(bool)(result ? r : !r);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		long v = toInteger();

		if (type)
		{	
			Type t = type;

		  L1:
			switch (t.ty)
			{
				case Tenum:
				{   
					TypeEnum te = cast(TypeEnum)t;
					formattedWrite(buf,"cast(%s)", te.sym.toChars());
					t = te.sym.memtype;
					goto L1;
				}

				case Ttypedef:
				{	
					TypeTypedef tt = cast(TypeTypedef)t;
					formattedWrite(buf,"cast(%s)", tt.sym.toChars());
					t = tt.sym.basetype;
					goto L1;
				}

				case Twchar:	// BUG: need to cast(wchar)
				case Tdchar:	// BUG: need to cast(dchar)
					if (cast(ulong)v > 0xFF)
					{
						 formattedWrite(buf,"'\\U%08x'", v);
						 break;
					}
				case Tchar:
					if (v == '\'')
						buf.put("'\\''");
					else if (isPrintable( to!char(v) ) && v != '\\')
						formattedWrite(buf,"'%s'", cast(char)v);	/// !
					else
						formattedWrite(buf,"'\\%*2#x'", cast(int)v);
					break;

				case Tint8:
					buf.put("cast(byte)");
					goto L2;

				case Tint16:
					buf.put("cast(short)");
					goto L2;

				case Tint32:
				L2:
					formattedWrite(buf,"%s", cast(int)v);
					break;

				case Tuns8:
					buf.put("cast(ubyte)");
					goto L3;

				case Tuns16:
					buf.put("cast(ushort)");
					goto L3;

				case Tuns32:
				L3:
					formattedWrite(buf,"%su", cast(uint)v);
					break;

				case Tint64:
					//buf.printf("%jdL", v);
					formattedWrite(buf,"%sL", v);
					break;

				case Tuns64:
				L4:
					//buf.printf("%juLU", v);
					formattedWrite(buf,"%sLU", v);
					break;

				case Tbit:
				case Tbool:
					buf.put(v ? "true" : "false");
					break;

				case Tpointer:
					buf.put("cast(");
					buf.put(t.toChars());
					buf.put(')');
					if (PTRSIZE == 4)
						goto L3;
					else if (PTRSIZE == 8)
						goto L4;
					else
						assert(0);

				default:
					/* This can happen if errors, such as
					 * the type is painted on like in fromConstInitializer().
					 */
					if (!global.errors)
					{
						debug {
							writefln("%s", t.toChars());
						}
						assert(0);
					}
					break;
			}
		}
		else if (v & 0x8000000000000000L)
			formattedWrite(buf,"%#X", v);
		else
			formattedWrite(buf,"%s", v);
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
	    if (cast(long)value < 0)
		formattedWrite(buf,"N%s", -value);
	    else
		formattedWrite(buf,"%s", value);
	}

}

/* Use this expression for error recovery.
 * It should behave as a 'sink' to prevent further cascaded error messages.
 */

class ErrorExp : IntegerExp
{
	this()
	{
		super(Loc(0), 0, Type.terror);
	    op = TOKerror;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("__error");
	}
}

class IsExp : Expression
{
	/* is(targ id tok tspec)
     * is(targ id == tok2)
     */
    Type targ;
    Identifier id;	// can be null
    TOK tok;	// ':' or '=='
    Type tspec;	// can be null
    TOK tok2;	// 'struct', 'union', 'typedef', etc.
    TemplateParameter[] parameters;

	this(Loc loc, Type targ, Identifier id, TOK tok, Type tspec, TOK tok2, TemplateParameter[] parameters)
	{
		super(loc, TOKis, IsExp.sizeof);
		
		this.targ = targ;
		this.id = id;
		this.tok = tok;
		this.tspec = tspec;
		this.tok2 = tok2;
		this.parameters = parameters;
	}

	override Expression syntaxCopy()
	{
		// This section is identical to that in TemplateDeclaration.syntaxCopy()
		TemplateParameter[] p = null;
		if (parameters)
		{
			p.reserve(parameters.length);
			for (int i = 0; i < p.length; i++)
			{   
				auto tp = parameters[i];
				p[i] = tp.syntaxCopy();
			}
		}

		return new IsExp(loc,
		targ.syntaxCopy(),
		id,
		tok,
		tspec ? tspec.syntaxCopy() : null,
		tok2,
		p);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("is(");
		targ.toCBuffer(buf, id, hgs);
		if (tok2 != TOKreserved)
		{
			formattedWrite(buf," %s %s", Token.toChars(tok), Token.toChars(tok2));
		}
		else if (tspec)
		{
			if (tok == TOKcolon)
				buf.put(" : ");
			else
				buf.put(" == ");
			tspec.toCBuffer(buf, null, hgs);
		}
		if (parameters)
		{	
			// First parameter is already output, so start with second
			for (int i = 1; i < parameters.length; i++)
			{
				buf.put(',');
				auto tp = parameters[i];
				tp.toCBuffer(buf, hgs);
			}
		}
		buf.put(')');
	}
}

class NewAnonClassExp : Expression
{
	/* thisexp.new(newargs) class baseclasses { } (arguments)
     */
    Expression thisexp;	// if !NULL, 'this' for class being allocated
    Expression[] newargs;	// Array of Expression's to call new operator
    ClassDeclaration cd;	// class being instantiated
    Expression[] arguments;	// Array of Expression's to call class constructor

	this(Loc loc, Expression thisexp, Expression[] newargs, ClassDeclaration cd, Expression[] arguments)
	{
		super(loc, TOKnewanonclass, NewAnonClassExp.sizeof);
		this.thisexp = thisexp;
		this.newargs = newargs;
		this.cd = cd;
		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new NewAnonClassExp(loc, 
			thisexp ? thisexp.syntaxCopy() : null,
			arraySyntaxCopy(newargs),
			cast(ClassDeclaration)cd.syntaxCopy(null),
			arraySyntaxCopy(arguments));
	}
	

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (thisexp)
		{	
			expToCBuffer(buf, hgs, thisexp, PREC_primary);
			buf.put('.');
		}
		buf.put("new");
		if (newargs && newargs.length)
		{
			buf.put('(');
			argsToCBuffer(buf, newargs, hgs);
			buf.put(')');
		}
		buf.put(" class ");
		if (arguments && arguments.length)
		{
			buf.put('(');
			argsToCBuffer(buf, arguments, hgs);
			buf.put(')');
		}
		//buf.put(" { }");
		if (cd)
		{
			cd.toCBuffer(buf, hgs);
		}
	}

}

class NewExp : Expression
{
	/* thisexp.new(newargs) newtype(arguments)
     */
    Expression thisexp;	// if !null, 'this' for class being allocated
    Expression[] newargs;	// Array of Expression's to call new operator
    Type newtype;
    Expression[] arguments;	// Array of Expression's

    CtorDeclaration member;	// constructor function
    NewDeclaration allocator;	// allocator function
    int onstack;		// allocate on stack

	this(Loc loc, Expression thisexp, Expression[] newargs, Type newtype, Expression[] arguments)
	{
		super(loc, TOKnew, NewExp.sizeof);
		this.thisexp = thisexp;
		this.newargs = newargs;
		this.newtype = newtype;
		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new NewExp(loc,
			thisexp ? thisexp.syntaxCopy() : null,
			arraySyntaxCopy(newargs),
			newtype.syntaxCopy(), arraySyntaxCopy(arguments));
	}

	

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		int i;

		if (thisexp)
		{
			expToCBuffer(buf, hgs, thisexp, PREC_primary);
			buf.put('.');
		}
		buf.put("new ");
		if (newargs && newargs.length)
		{
			buf.put('(');
			argsToCBuffer(buf, newargs, hgs);
			buf.put(')');
		}
		newtype.toCBuffer(buf, null, hgs);
		if (arguments && arguments.length)
		{
			buf.put('(');
			argsToCBuffer(buf, arguments, hgs);
			buf.put(')');
		}
	}

}

class NullExp : Expression
{
	ubyte committed;

	this(Loc loc, Type type = null)
	{
		super(loc, TOKnull, NullExp.sizeof);
        this.type = type;
	}

	override bool isBool(bool result)
	{
		assert(false);
	}

	override int isConst()
	{
		return 0;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("null");
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		buf.put('n');
	}

}

class OverExp : Expression
{
	OverloadSet vars;

	this(OverloadSet s)
	{
		super(loc, TOKoverloadset, OverExp.sizeof);
		//printf("OverExp(this = %p, '%s')\n", this, var.toChars());
		vars = s;
		type = Type.tvoid;
	}

}

class RealExp : Expression
{
	real value;

	this(Loc loc, real value, Type type)
	{
		super(loc, TOKfloat64, RealExp.sizeof);
		this.value = value;
		this.type = type;
	}

	//override bool equals(Object o) { assert (false,"zd cut"); }

	override string toChars()
	{
      return format(type.isimaginary() ? "%si" : "%s", value);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		// TODO zd ... Yeah, it's approximate, maybe later
      formattedWrite( buf, "%s", cast(real)(value) );
      //floatToBuffer(buf, type, value);
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
   {
       assert (false);
   }
}

class ScopeExp : Expression
{
	ScopeDsymbol sds;

	this(Loc loc, ScopeDsymbol pkg)
	{
		super(loc, TOKimport, ScopeExp.sizeof);
		//printf("ScopeExp.ScopeExp(pkg = '%s')\n", pkg.toChars());
		//static int count; if (++count == 38) *(char*)0=0;
		this.sds = pkg;
	}

	override Expression syntaxCopy()
	{
		ScopeExp se = new ScopeExp(loc, cast(ScopeDsymbol)sds.syntaxCopy(null));
		return se;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (sds.isTemplateInstance())
		{
			sds.toCBuffer(buf, hgs);
		}
		else
		{
			buf.put(sds.kind());
			buf.put(" ");
			buf.put(sds.toChars());
		}
	}
}

class StringExp : Expression
{
	string string_;	// char, wchar, or dchar data
    size_t len;		// number of chars, wchars, or dchars
    ubyte sz;	// 1: char, 2: wchar, 4: dchar
    ubyte committed = 0;	// !=0 if type is committed
    char postfix;	// 'c', 'w', 'd'

	this(Loc loc, string s)
	{
		this(loc, s, 0);
	}

	this(Loc loc, string s, char postfix)
	{
		super(loc, TOKstring, StringExp.sizeof);
		
		this.string_ = s;
		this.len = s.length;
		this.sz = 1;
		this.committed = 0;
		this.postfix = postfix;
	}

	override string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		toCBuffer(buf, hgs);
		return buf.data.idup;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('"');
		foreach ( c; string_ )
		{
			switch (c)
			{
            import std.ascii;
            import std.format;
				case '"':
				case '\\':
				if (!hgs.console)
					buf.put('\\');
				default:
				if (c <= 0xFF)
				{  
					if (c <= 0x7F && (isPrintable(c) || hgs.console))
						buf.put(c);
					else
						formattedWrite(buf,"\\x%02x", c);
				}
				else if (c <= 0xFFFF)
					formattedWrite(buf,"\\x%02x\\x%02x", c & 0xFF, c >> 8);
				else
					formattedWrite(buf,"\\x%02x\\x%02x\\x%02x\\x%02x", c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, c >> 24);
				break;
			}
		}
		buf.put('"');
		if (postfix)
			buf.put(postfix);
	}
}

class StructLiteralExp : Expression
{
	StructDeclaration sd;		// which aggregate this is for
	Expression[] elements;	// parallels sd.fields[] with
				// NULL entries for fields to skip

    //Symbol* sym;		// back end symbol to initialize with literal
    size_t soffset;		// offset from start of s
    int fillHoles;		// fill alignment 'holes' with zero

	this(Loc loc, StructDeclaration sd, Expression[] elements)
	{
		super(loc, TOKstructliteral, StructLiteralExp.sizeof);
		this.sd = sd;
		this.elements = elements;
		//this.sym = null; //BACKEND stuff
		this.soffset = 0;
		this.fillHoles = 1;
	}

	override Expression syntaxCopy()
	{
		return new StructLiteralExp(loc, sd, arraySyntaxCopy(elements));
	}

	/**************************************
	 * Gets expression at offset of type.
	 * Returns null if not found.
	 */

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(sd.toChars());
		buf.put('(');
		argsToCBuffer(buf, elements, hgs);
		buf.put(')');
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		size_t dim = elements ? elements.length : 0;
		formattedWrite(buf,"S%u", dim);
		for (size_t i = 0; i < dim; i++)
	    {
			auto e = elements[i];
			if (e)
				e.toMangleBuffer(buf);
			else
				buf.put('v');	// 'v' for void
	    }
	}

}

class SymbolExp : Expression
{
	Declaration var;

	bool hasOverloads;

	this(Loc loc, TOK op, int size, Declaration var, bool hasOverloads)
	{
		super(loc, op, size);
		assert(var);
		this.var = var;
		this.hasOverloads = hasOverloads;
	}

}

class SymOffExp : SymbolExp
{
	uint offset;

	this(Loc loc, Declaration var, uint offset, bool hasOverloads = false)
	{
		super(loc, TOKsymoff, SymOffExp.sizeof, var, hasOverloads);
		
		this.offset = offset;
		VarDeclaration v = var.isVarDeclaration();
		if (v && v.needThis())
			error("need 'this' for address of %s", v.toChars());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (offset)
			formattedWrite(buf,"(& %s+%s)", var.toChars(), offset); ///
		else
			formattedWrite(buf,"& %s", var.toChars());
	}
}
//! Variable
class VarExp : SymbolExp
{
	this(Loc loc, Declaration var, bool hasOverloads = false)
	{
		super(loc, TOKvar, VarExp.sizeof, var, hasOverloads);
		
		//printf("VarExp(this = %p, '%s', loc = %s)\n", this, var.toChars(), loc.toChars());
		//if (strcmp(var.ident.toChars(), "func") == 0) halt();
		this.type = var.type;
	}

	override string toChars()
	{
		return var.toChars();
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(var.toChars());
	}

    

}

class TemplateExp : Expression
{
	TemplateDeclaration td;

	this(Loc loc, TemplateDeclaration td)
	{
		super(loc, TOKtemplate, TemplateExp.sizeof);
		//printf("TemplateExp(): %s\n", td.toChars());
		this.td = td;
	}

	override void rvalue()
	{
		error("template %s has no value", toChars());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(td.toChars());
	}
}

class ThisExp : Expression
{
	Declaration var;

	this(Loc loc)
	{
		super(loc, TOKthis, ThisExp.sizeof);
		//printf("ThisExp::ThisExp() loc = %d\n", loc.linnum);
	}

	override bool isBool(bool result)
	{
		return result ? true : false;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("this");
	}

}

class SuperExp : ThisExp
{
	this(Loc loc)
	{
		super(loc);
		op = TOKsuper;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("super");
	}

}

class TraitsExp : Expression
{
	Identifier ident;

	Object[] args;

	this(Loc loc, Identifier ident, Object[] args)
	{
		super(loc, TOKtraits, this.sizeof);
		this.ident = ident;
		this.args = args;
	}

	override Expression syntaxCopy()
	{
		return new TraitsExp(loc, ident, TemplateInstance.arraySyntaxCopy(args));
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("__traits(");
		buf.put(ident.toChars());
		if (args)
		{
			for (int i = 0; i < args.length; i++)
			{
				buf.put(',');
				Object oarg = args[i];
				ObjectToCBuffer(buf, hgs, oarg);
			}
		}
		buf.put(')');
	}
}
/****************************************
 * Expand tuples.
 */
/+
+/
class TupleExp : Expression
{
	Expression[] exps;

	this(Loc loc, Expression[] exps)
	{
		super(loc, TOKtuple, TupleExp.sizeof);
		
		this.exps = exps;
		this.type = null;
	}

	this(Loc loc, TupleDeclaration tup)
	{
		super(loc, TOKtuple, TupleExp.sizeof);
		type = null;

		exps.reserve(tup.objects.length);
		foreach (o; tup.objects)
		{   
			if (auto e = cast(Expression)o)
			{
				e = e.syntaxCopy();
				exps ~= (e);
			}
			else if (auto s = cast(Dsymbol)o)
			{
				auto e = new DsymbolExp(loc, s);
				exps ~= (e);
			}
			else if (auto t = cast(Type)o)
			{
				auto e = new TypeExp(loc, t);
				exps ~= (e);
			}
			else
			{
				error("%s is not an expression", o.toString());
			}
		}
	}

	override Expression syntaxCopy()
	{
		return new TupleExp(loc, arraySyntaxCopy(exps));
	}

	//override bool equals(Object o) { assert (false,"zd cut"); }

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("tuple(");
		//TODO cancel argsToCBuffer(buf, exps, hgs);
		buf.put(')');
	}
}

class TypeExp : Expression
{
	this(Loc loc, Type type)
	{
		super(loc, TOKtype, TypeExp.sizeof);
		//printf("TypeExp::TypeExp(%s)\n", type->toChars());
		this.type = type;
	}

	override Expression syntaxCopy()
	{
		//printf("TypeExp.syntaxCopy()\n");
		return new TypeExp(loc, type.syntaxCopy());
	}

	override void rvalue()
	{
		error("type %s has no value", toChars());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		type.toCBuffer(buf, null, hgs);
	}

}

class TypeidExp : Expression
{
	Object obj;

	this(Loc loc, Object o)
	{
		super(loc, TOKtypeid, TypeidExp.sizeof);
		this.obj = o;
	}

	override Expression syntaxCopy()
	{
		return new TypeidExp(loc, objectSyntaxCopy(obj));
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}

