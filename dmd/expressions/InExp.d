module dmd.expressions.InExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;
import dmd.types.TypeAArray;



import dmd.DDMDExtensions;

class InExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKin, InExp.sizeof, e1, e2);
	}


	override int isBit()
	{
		return 0;
	}

	override Identifier opId()
	{
		return Id.opIn;
	}

	override Identifier opId_r()
	{
		return Id.opIn_r;
	}

}

