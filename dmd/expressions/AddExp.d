module dmd.expressions.AddExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Type;
import dmd.Token;


import dmd.DDMDExtensions;

class AddExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKadd, AddExp.sizeof, e1, e2);
	}







	override Identifier opId()
	{
		return Id.add;
	}

	override Identifier opId_r()
	{
		return Id.add_r;
	}

}

