module dmd.expressions.DivExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;
import dmd.expressions.NegExp;


import dmd.DDMDExtensions;

class DivExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKdiv, DivExp.sizeof, e1, e2);
	}







	override Identifier opId()
	{
		return Id.div;
	}

	override Identifier opId_r()
	{
		return Id.div_r;
	}

}

