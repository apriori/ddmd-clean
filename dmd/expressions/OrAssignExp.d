module dmd.expressions.OrAssignExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Identifier;
import dmd.Token;


import dmd.DDMDExtensions;

class OrAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKorass, OrAssignExp.sizeof, e1, e2);
	}
	
	
	
	

    override Identifier opId()    /* For operator overloading */
	{
		return Id.orass;
	}

}
