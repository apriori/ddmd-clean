module dmd.expressions.IdentityExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;


import dmd.DDMDExtensions;

class IdentityExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e1, Expression e2)
	{
		super(loc, op, IdentityExp.sizeof, e1, e2);
	}


	override int isBit()
	{
		assert(false);
	}



}

