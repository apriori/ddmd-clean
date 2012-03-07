module dmd.unaExp;

import dmd.global;
import dmd.expression;
import dmd.identifier;
import dmd.funcDeclaration;
import dmd.binExp;
import dmd.unaExp;
//import dmd.types.TypeClass;
//import dmd.types.TypeStruct;
import dmd.dsymbol;
import dmd.scopeDsymbol;
import dmd.type;
import dmd.Scope;
import dmd.hdrGenState;
import dmd.token;
import dmd.declaration;
import dmd.varDeclaration;

import std.array;

class UnaExp : Expression
{
	Expression e1;

	this(Loc loc, TOK op, int size, Expression e1)
	{
		super(loc, op, size);
		this.e1 = e1;
	}

	override Expression syntaxCopy()
	{
		UnaExp e = cast(UnaExp)copy();
		e.type = null;
		e.e1 = e.e1.syntaxCopy();

		return e;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(op));
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}
}

class AddrExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKaddress, AddrExp.sizeof, e);
	}
}

class ArrayExp : UnaExp
{
	Expression[] arguments;

	this(Loc loc, Expression e1, Expression[] args)
	{
		super(loc, TOKarray, ArrayExp.sizeof, e1);
		arguments = args;
	}

	override Expression syntaxCopy()
	{
	    return new ArrayExp(loc, e1.syntaxCopy(), arraySyntaxCopy(arguments));
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put("[");
		argsToCBuffer(buf, arguments, hgs);
		buf.put("]");
	}

	override Identifier opId()
	{
		return Id.index;
	}
}

class ArrayLengthExp : UnaExp
{
	this(Loc loc, Expression e1)
	{
		super(loc, TOKarraylength, ArrayLengthExp.sizeof, e1);
	}

	static Expression rewriteOpAssign(BinExp exp)
   {
        assert (false);
   } 

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put(".length");
	}
}

class AssertExp : UnaExp
{
	Expression msg;

	this(Loc loc, Expression e, Expression msg = null)
	{

		super(loc, TOKassert, AssertExp.sizeof, e);
		this.msg = msg;
	}

	override Expression syntaxCopy()
	{
		AssertExp ae = new AssertExp(loc, e1.syntaxCopy(),
				       msg ? msg.syntaxCopy() : null);
		return ae;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("assert(");
		expToCBuffer(buf, hgs, e1, PREC_assign);
		if (msg)
		{
			buf.put(", ");
			expToCBuffer(buf, hgs, msg, PREC_assign);
		}
		buf.put(")");
	}
}

class BoolExp : UnaExp
{
	this(Loc loc, Expression e, Type t)
	{

		super(loc, TOKtobool, BoolExp.sizeof, e);
		//type = t;
	}

	override bool isBit()
	{
		return true;
	}
}

class CallExp : UnaExp
{
	Expression[] arguments;

	this(Loc loc, Expression e, Expression[] exps)
	{
		super(loc, TOKcall, CallExp.sizeof, e);
		this.arguments = exps;
	}

	this(Loc loc, Expression e)
	{

		super(loc, TOKcall, CallExp.sizeof, e);
	}

	this(Loc loc, Expression e, Expression earg1)
	{

		super(loc, TOKcall, CallExp.sizeof, e);
		
		Expression[] arguments;
		if (earg1)
		{	
			arguments.reserve(1);
			arguments[0] = earg1;
		}
		this.arguments = arguments;
	}

	this(Loc loc, Expression e, Expression earg1, Expression earg2)
	{

		super(loc, TOKcall, CallExp.sizeof, e);
		
		Expression[] arguments;
		arguments.reserve(2);
		arguments[0] = earg1;
		arguments[1] = earg2;

		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new CallExp(loc, e1.syntaxCopy(), arraySyntaxCopy(arguments));
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		int i;
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put('(');
		argsToCBuffer(buf, arguments, hgs);
		buf.put(')');
	}
}

class CastExp : UnaExp
{
	// Possible to cast to one type while painting to another type
	Type to;				// type to cast to
	MOD mod;				// MODxxxxx

	this(Loc loc, Expression e, Type t)
	{

		super(loc, TOKcast, CastExp.sizeof, e);
		to = t;
		this.mod = cast(MOD)~0;
	}

	this(Loc loc, Expression e, MOD mod)
	{

		super(loc, TOKcast, CastExp.sizeof, e);
		to = null;
		this.mod = mod;
	}

	override Expression syntaxCopy()
	{
		return to ? new CastExp(loc, e1.syntaxCopy(), to.syntaxCopy())
	      : new CastExp(loc, e1.syntaxCopy(), mod);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("cast(");
		if (to)
			to.toCBuffer(buf, null, hgs);
		else
		{
			MODtoBuffer(buf, mod);
		}
		buf.put(')');
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

	
	static int X(int fty, int tty) {
		return ((fty) * TMAX + (tty));
	}

	override Identifier opId()
	{
		return Id.cast_;
	}
}

class ComExp : UnaExp
{
	this(Loc loc, Expression e)
	{

		super(loc, TOKtilde, ComExp.sizeof, e);
	}

	override Identifier opId()
	{
		return Id.com;
	}
}

class CompileExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKmixin, this.sizeof, e);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("mixin(");
		expToCBuffer(buf, hgs, e1, PREC_assign);
		buf.put(')');
	}
}
class DelegateExp : UnaExp
{
	FuncDeclaration func;
	bool hasOverloads;

	this(Loc loc, Expression e, FuncDeclaration f, bool hasOverloads = false)
	{
		super(loc, TOKdelegate, DelegateExp.sizeof, e);
		this.func = f;
		this.hasOverloads = hasOverloads;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('&');
		if (!func.isNested())
		{
			expToCBuffer(buf, hgs, e1, PREC_primary);
			buf.put('.');
		}
		buf.put(func.toChars());
	}
}

class DeleteExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKdelete, DeleteExp.sizeof, e);
	}

	override Expression checkToBoolean()
	{
		assert(false);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("delete ");
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}
}

class DotIdExp : UnaExp
{
	Identifier ident;

	this(Loc loc, Expression e, Identifier ident)
	{
		super(loc, TOKdot, DotIdExp.sizeof, e);
		this.ident = ident;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		//printf("DotIdExp.toCBuffer()\n");
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('.');
		buf.put(ident.toChars());
	}
}

class DotTemplateExp : UnaExp
{
	TemplateDeclaration td;

	this(Loc loc, Expression e, TemplateDeclaration td)
	{
		super(loc, TOKdottd, this.sizeof, e);
		this.td = td;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    expToCBuffer(buf, hgs, e1, PREC_primary);
	    buf.put('.');
	    buf.put(td.toChars());
	}
}

class DotTemplateInstanceExp : UnaExp
{
	TemplateInstance ti;

	this(Loc loc, Expression e, Identifier name, Dobject[] tiargs)
	{
		super(loc, TOKdotti, DotTemplateInstanceExp.sizeof, e);
		//printf("DotTemplateInstanceExp()\n");
		this.ti = new TemplateInstance(loc, name);
		this.ti.tiargs = tiargs;
	}

	override Expression syntaxCopy()
	{
		DotTemplateInstanceExp de = new DotTemplateInstanceExp(loc, e1.syntaxCopy(), ti.name, TemplateInstance.arraySyntaxCopy(ti.tiargs));
		return de;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('.');
		ti.toCBuffer(buf, hgs);
	}
}

class DotTypeExp : UnaExp
{
	Dsymbol sym;

	this(Loc loc, Expression e, Dsymbol s)
	{
		super(loc, TOKdottype, DotTypeExp.sizeof, e);
		this.sym = s;
		this.type = s.getType();
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('.');
		buf.put(sym.toChars());
	}
}

class DotVarExp : UnaExp
{
	Declaration var;

	bool hasOverloads;

	this(Loc loc, Expression e, Declaration var, bool hasOverloads = false)
	{
		super(loc, TOKdotvar, DotVarExp.sizeof, e);
		//printf("DotVarExp()\n");
		this.var = var;
		this.hasOverloads = hasOverloads;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('.');
		buf.put(var.toChars());
	}
}

class FileExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKmixin, FileExp.sizeof, e);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}

class NegExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKneg, NegExp.sizeof, e);
	}

	override Identifier opId()
	{
		return Id.neg;
	}
}

class NotExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKnot, NotExp.sizeof, e);
	}

	override bool isBit()
	{
		assert(false);
	}
}

class PtrExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKstar, PtrExp.sizeof, e);
		//    if (e.type)
		//		type = ((TypePointer *)e.type).next;
	}

	this(Loc loc, Expression e, Type t)
	{
		super(loc, TOKstar, PtrExp.sizeof, e);
		//type = t;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('*');
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

	override Identifier opId()
	{
		assert(false);
	}
}

class SliceExp : UnaExp
{
	Expression upr;		// null if implicit 0
    Expression lwr;		// null if implicit [length - 1]

	VarDeclaration lengthVar = null;

	this(Loc loc, Expression e1, Expression lwr, Expression upr)
	{
		super(loc, TOKslice, SliceExp.sizeof, e1);
		this.upr = upr;
		this.lwr = lwr;
	}

	override Expression syntaxCopy()
	{
		Expression lwr = null;
		if (this.lwr)
			lwr = this.lwr.syntaxCopy();

		Expression upr = null;
		if (this.upr)
			upr = this.upr.syntaxCopy();

		return new SliceExp(loc, e1.syntaxCopy(), lwr, upr);
	}

	//override int lue() { assert (false,"zd cut"); }

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put('[');
		if (upr || lwr)
		{
			if (lwr)
				expToCBuffer(buf, hgs, lwr, PREC_assign);
			buf.put("..");
			if (upr)
				expToCBuffer(buf, hgs, upr, PREC_assign);
			else
				buf.put("length");		// BUG: should be array.length
		}
		buf.put(']');
	}
}

class UAddExp : UnaExp
{
	this(Loc loc, Expression e)
	{
		super(loc, TOKuadd, this.sizeof, e);
	}

	override Identifier opId()
	{
		return Id.uadd;
	}
}
