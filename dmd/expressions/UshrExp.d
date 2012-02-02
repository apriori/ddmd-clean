module dmd.expressions.UshrExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;


import dmd.DDMDExtensions;

class UshrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKushr, UshrExp.sizeof, e1, e2);
	}





	override Identifier opId()
	{
		return Id.ushr;
	}

	override Identifier opId_r()
	{
		return Id.ushr_r;
	}

}
