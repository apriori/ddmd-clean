module dmd.expressions.LineInitExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.expressions.DefaultInitExp;
import dmd.expressions.IntegerExp;
import dmd.Token;
import dmd.Type;

import dmd.DDMDExtensions;

class LineInitExp : DefaultInitExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		super(loc, TOKline, this.sizeof);
	}


}
