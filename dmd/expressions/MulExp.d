module dmd.expressions.MulExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.expressions.NegExp;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;


import dmd.DDMDExtensions;

class MulExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmul, MulExp.sizeof, e1, e2);
	}







	override Identifier opId()
	{
		return Id.mul;
	}

	override Identifier opId_r()
	{
		return Id.mul_r;
	}

}

