module dmd.initializers.ExpInitializer;

import dmd.Global;
import dmd.Initializer;
import dmd.expressions.DelegateExp;
import dmd.Scope;
import dmd.Type;
import dmd.expressions.SymOffExp;
import dmd.Expression;
import dmd.HdrGenState;
import std.array;
import dmd.Token;
import dmd.expressions.StringExp;
import dmd.types.TypeSArray;


import dmd.DDMDExtensions;

class ExpInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;

    this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}
	
    override Initializer syntaxCopy()
	{
		return new ExpInitializer(loc, exp.syntaxCopy());
	}
	
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		exp.toCBuffer(buf, hgs);
	}


    override ExpInitializer isExpInitializer() { return this; }
}
