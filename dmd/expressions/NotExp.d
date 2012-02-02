module dmd.expressions.NotExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Scope;
import dmd.Token;
import dmd.Type;



import dmd.DDMDExtensions;

class NotExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		super(loc, TOKnot, NotExp.sizeof, e);
	}




	override int isBit()
	{
		assert(false);
	}

}
