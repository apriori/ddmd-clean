module dmd.expressions.OrOrExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Scope;
import dmd.InterState;
import dmd.Token;
import dmd.Expression;
import dmd.expressions.IntegerExp;
import dmd.Type;
import dmd.expressions.CommaExp;
import dmd.expressions.BoolExp;



import dmd.DDMDExtensions;

class OrOrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKoror, OrOrExp.sizeof, e1, e2);
	}
	

    override Expression checkToBoolean()
	{
		e2 = e2.checkToBoolean();
		return this;
	}
	
    override int isBit()
	{
		assert(false);
	}
	
	


}
