module dmd.expressions.BoolExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.Token;


import dmd.DDMDExtensions;

class BoolExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e, Type t)
	{

		super(loc, TOKtobool, BoolExp.sizeof, e);
		type = t;
	}




	override int isBit()
	{
		return true;
	}

}

