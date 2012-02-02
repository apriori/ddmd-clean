module dmd.expressions.NegExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Scope;
import dmd.Token;



import dmd.DDMDExtensions;

class NegExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		super(loc, TOKneg, NegExp.sizeof, e);
	}






	override Identifier opId()
	{
		return Id.neg;
	}

}

