module dmd.expressions.UAddExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.expressions.UnaExp;
import dmd.Scope;
import dmd.Token;

import dmd.DDMDExtensions;

class UAddExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		super(loc, TOKuadd, this.sizeof, e);
	}


	override Identifier opId()
	{
		return Id.uadd;
	}
}
