module dmd.expressions.CastExp;

import dmd.Global;
import dmd.Expression;
import dmd.types.TypeStruct;
import dmd.expressions.ErrorExp;
import dmd.expressions.TypeExp;
import dmd.expressions.DotIdExp;
import dmd.expressions.CallExp;
import dmd.Identifier;
import dmd.expressions.BinExp;
import dmd.expressions.UnaExp;
import dmd.expressions.VarExp;
import dmd.Token;
import dmd.VarDeclaration;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.scopeDsymbols.ClassDeclaration;

import dmd.Cast;

import std.array;
import dmd.DDMDExtensions;

class CastExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

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

