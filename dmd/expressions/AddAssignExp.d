module dmd.expressions.AddAssignExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Parameter;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Token;
import dmd.Type;
import dmd.expressions.AddExp;
import dmd.expressions.CastExp;
import dmd.expressions.AssignExp;
import dmd.expressions.ArrayLengthExp;

import dmd.DDMDExtensions;

class AddAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKaddass, AddAssignExp.sizeof, e1, e2);
	}
	
	
	

}
