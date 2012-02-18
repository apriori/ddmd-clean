module dmd.types.TypeSlice;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeNext;
import dmd.Expression;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.types.TypeTuple;
import dmd.Parameter;
import dmd.ScopeDsymbol;


class TypeSlice : TypeNext
{
    Expression lwr;
    Expression upr;

    this(Type next, Expression lwr, Expression upr)
	{
		super(Tslice, next);
		//printf("TypeSlice[%s .. %s]\n", lwr.toChars(), upr.toChars());
		this.lwr = lwr;
		this.upr = upr;
	}
	
    override Type syntaxCopy()
	{
		Type t = new TypeSlice(next.syntaxCopy(), lwr.syntaxCopy(), upr.syntaxCopy());
		t.mod = mod;
		return t;
	}
	
	
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		assert(false);
	}
}
