module dmd.expressions.ShrAssignExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Identifier;
import dmd.Token;
import dmd.Type;
import dmd.expressions.ArrayLengthExp;
import dmd.expressions.CastExp;



import dmd.DDMDExtensions;

class ShrAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKshrass, ShrAssignExp.sizeof, e1, e2);
	}
	
	

    override Identifier opId()    /* For operator overloading */
	{
		return Id.shrass;
	}

}
