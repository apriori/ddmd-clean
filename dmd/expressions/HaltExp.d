module dmd.expressions.HaltExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.Type;
import dmd.HdrGenState;
import dmd.Token;


import std.array;
import dmd.DDMDExtensions;

class HaltExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		super(loc, TOKhalt, HaltExp.sizeof);
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("halt");
	}


}

