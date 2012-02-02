module dmd.expressions.DefaultInitExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class DefaultInitExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

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
