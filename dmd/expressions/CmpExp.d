module dmd.expressions.CmpExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Token;
import dmd.Scope;
import dmd.Type;
import dmd.expressions.ErrorExp;
import dmd.expressions.IntegerExp;
import dmd.expressions.BinExp;



import dmd.DDMDExtensions;

class CmpExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e1, Expression e2)
	{

		super(loc, op, CmpExp.sizeof, e1, e2);
	}




	int isBit()
	{
		assert(false);
	}


	Identifier opId()
	{
		return Id.cmp;
	}

}

