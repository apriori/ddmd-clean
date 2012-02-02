module dmd.expressions.DelegateExp;

import dmd.Global;
import dmd.Expression;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.expressions.UnaExp;
import dmd.types.TypeDelegate;
import dmd.declarations.FuncDeclaration;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;


import std.array;
import dmd.DDMDExtensions;

class DelegateExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

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
