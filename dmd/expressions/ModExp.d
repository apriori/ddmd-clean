module dmd.expressions.ModExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.expressions.ErrorExp;


import dmd.DDMDExtensions;

class ModExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmod, ModExp.sizeof, e1, e2);
	}






	override Identifier opId()
	{
		return Id.mod;
	}

	override Identifier opId_r()
	{
		return Id.mod_r;
	}

}

