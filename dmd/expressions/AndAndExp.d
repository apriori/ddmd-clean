module dmd.expressions.AndAndExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.CommaExp;
import dmd.expressions.BoolExp;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.expressions.IntegerExp;
import dmd.Type;


import dmd.DDMDExtensions;

class AndAndExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKandand, AndAndExp.sizeof, e1, e2);
	}


	override Expression checkToBoolean()
	{
		e2 = e2.checkToBoolean();
		return this;
	}

	override int isBit()
	{
		assert(false);
	}




}

