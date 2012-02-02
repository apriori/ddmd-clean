module dmd.conditions.StaticIfCondition;

import dmd.Global;
import dmd.Expression;
import dmd.ScopeDsymbol;
import std.array;
import dmd.Scope;
import dmd.Condition;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class StaticIfCondition : Condition
{
	mixin insertMemberExtension!(typeof(this));

	Expression exp;

	this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}

	override Condition syntaxCopy()
	{
	    return new StaticIfCondition(loc, exp.syntaxCopy());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}

