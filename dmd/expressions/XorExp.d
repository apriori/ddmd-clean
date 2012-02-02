module dmd.expressions.XorExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;

import dmd.DDMDExtensions;

class XorExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKxor, XorExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.ixor;
	}

	override Identifier opId_r()
	{
		return Id.ixor_r;
	}

}

