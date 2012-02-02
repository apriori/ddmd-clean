module dmd.expressions.ShrExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;



import dmd.DDMDExtensions;

class ShrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKshr, ShrExp.sizeof, e1, e2);
	}





	override Identifier opId()
	{
		return Id.shr;
	}

	override Identifier opId_r()
	{
		return Id.shr_r;
	}

}

