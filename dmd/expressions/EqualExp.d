module dmd.expressions.EqualExp;

import dmd.Global;
import dmd.expressions.ErrorExp;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;
import dmd.expressions.AddrExp;
import dmd.expressions.VarExp;
import dmd.expressions.IntegerExp;
import dmd.Token;
import dmd.expressions.NotExp;




import dmd.DDMDExtensions;

class EqualExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e1, Expression e2)
	{
		super(loc, op, EqualExp.sizeof, e1, e2);
		assert(op == TOKequal || op == TOKnotequal);
	}




	override bool isBit()
	{
		return true;
	}


	override Identifier opId()
	{
		return Id.eq;
	}

}

