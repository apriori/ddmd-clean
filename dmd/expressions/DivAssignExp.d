module dmd.expressions.DivAssignExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Identifier;
import dmd.Token;
import dmd.Type;
import dmd.expressions.CommaExp;
import dmd.expressions.RealExp;
import dmd.expressions.AssignExp;
import dmd.expressions.ArrayLengthExp;


import dmd.DDMDExtensions;

class DivAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKdivass, DivAssignExp.sizeof, e1, e2);
	}
	
	
	
	

    override Identifier opId()    /* For operator overloading */
	{
		return Id.divass;
	}

}
