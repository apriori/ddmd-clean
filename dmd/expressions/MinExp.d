module dmd.expressions.MinExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.ErrorExp;
import dmd.Identifier;
import dmd.expressions.IntegerExp;
import dmd.expressions.DivExp;
import dmd.Type;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;


import dmd.DDMDExtensions;

class MinExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmin, MinExp.sizeof, e1, e2);
	}






	override Identifier opId()
	{
		return Id.sub;
	}

	override Identifier opId_r()
	{
		return Id.sub_r;
	}

}

