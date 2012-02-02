module dmd.expressions.FileExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.expressions.StringExp;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;


import std.array;
import dmd.DDMDExtensions;

class FileExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		super(loc, TOKmixin, FileExp.sizeof, e);
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}

