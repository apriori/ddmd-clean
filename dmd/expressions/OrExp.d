module dmd.expressions.OrExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;



import dmd.DDMDExtensions;

class OrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKor, OrExp.sizeof, e1, e2);
	}









	override Identifier opId()
	{
		return Id.ior;
	}

	override Identifier opId_r()
	{
		return Id.ior_r;
	}

}

