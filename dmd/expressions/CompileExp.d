module dmd.expressions.CompileExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.expressions.StringExp;
import dmd.Type;
import dmd.Parser;


import std.array;
import dmd.DDMDExtensions;

class CompileExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

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
