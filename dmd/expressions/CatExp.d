module dmd.expressions.CatExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;
import dmd.expressions.ArrayLiteralExp;
import dmd.expressions.StringExp;
import dmd.expressions.ErrorExp;


import dmd.DDMDExtensions;

class CatExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKcat, CatExp.sizeof, e1, e2);
	}




	override Identifier opId()
	{
		return Id.cat;
	}

	override Identifier opId_r()
	{
		return Id.cat_r;
	}

}

