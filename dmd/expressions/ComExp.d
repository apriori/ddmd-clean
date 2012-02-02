module dmd.expressions.ComExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Scope;
import dmd.Token;



import dmd.DDMDExtensions;

class ComExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{

		super(loc, TOKtilde, ComExp.sizeof, e);
	}






	override Identifier opId()
	{
		return Id.com;
	}

}

