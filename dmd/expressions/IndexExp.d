module dmd.expressions.IndexExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.Scope;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.ScopeDsymbol;
import dmd.scopeDsymbols.ArrayScopeSymbol;
import dmd.types.TypeNext;
import dmd.types.TypeSArray;
import dmd.types.TypeAArray;
import dmd.expressions.UnaExp;
import dmd.expressions.BinExp;
import dmd.HdrGenState;
import dmd.Token;
import dmd.Dsymbol;
import dmd.expressions.TupleExp;
import dmd.types.TypeTuple;
import dmd.Parameter;
import dmd.expressions.TypeExp;
import dmd.expressions.VarExp;
import dmd.initializers.ExpInitializer;




import std.array;
import dmd.DDMDExtensions;

class IndexExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	VarDeclaration lengthVar;
	int modifiable = 0;	// assume it is an rvalue

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKindex, IndexExp.sizeof, e1, e2);
		//printf("IndexExp.IndexExp('%s')\n", toChars());
	}





	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('[');
		expToCBuffer(buf, hgs, e2, PREC_assign);
		buf.put(']');
	}





}

