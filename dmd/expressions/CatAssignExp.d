module dmd.expressions.CatAssignExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.expressions.SliceExp;
import dmd.expressions.ErrorExp;
import dmd.Identifier;
import dmd.Token;
import dmd.Type;


import dmd.DDMDExtensions;

class CatAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKcatass, CatAssignExp.sizeof, e1, e2);
	}
	
	

    override Identifier opId()    /* For operator overloading */
	{
		return Id.catass;
	}

}
