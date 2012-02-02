module dmd.expressions.DotTypeExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.Token;


import std.array;
import dmd.DDMDExtensions;

class DotTypeExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

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

