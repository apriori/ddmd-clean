module dmd.expressions.XorAssignExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Identifier;
import dmd.Token;

import dmd.DDMDExtensions;

class XorAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKxorass, this.sizeof, e1, e2);
	}
	
	
	
	

    override Identifier opId()    /* For operator overloading */
	{
		return Id.xorass;
	}

}
