module dmd.expressions.SliceExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.Identifier;
import dmd.expressions.IdentifierExp;
import dmd.expressions.ArrayExp;
import dmd.Dsymbol;
import dmd.InterState;
import dmd.ScopeDsymbol;
import dmd.scopeDsymbols.ArrayScopeSymbol;
import dmd.expressions.CallExp;
import dmd.expressions.DotIdExp;
import dmd.types.TypeTuple;
import dmd.expressions.TupleExp;
import dmd.types.TypeStruct;
import dmd.types.TypeClass;
import dmd.Type;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.Scope;
import dmd.VarDeclaration;
import dmd.expressions.ErrorExp;
import dmd.expressions.TypeExp;
import dmd.Parameter;
import dmd.initializers.ExpInitializer;
import dmd.HdrGenState;
import dmd.Token;
import dmd.types.TypeSArray;

import std.array;
import dmd.DDMDExtensions;

class SliceExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expression upr;		// null if implicit 0
    Expression lwr;		// null if implicit [length - 1]

	VarDeclaration lengthVar = null;

	this(Loc loc, Expression e1, Expression lwr, Expression upr)
	{
		super(loc, TOKslice, SliceExp.sizeof, e1);
		this.upr = upr;
		this.lwr = lwr;
	}

	override Expression syntaxCopy()
	{
		Expression lwr = null;
		if (this.lwr)
			lwr = this.lwr.syntaxCopy();

		Expression upr = null;
		if (this.upr)
			upr = this.upr.syntaxCopy();

		return new SliceExp(loc, e1.syntaxCopy(), lwr, upr);
	}




	//override int lue() { assert (false,"zd cut"); }


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put('[');
		if (upr || lwr)
		{
			if (lwr)
				expToCBuffer(buf, hgs, lwr, PREC_assign);
			buf.put("..");
			if (upr)
				expToCBuffer(buf, hgs, upr, PREC_assign);
			else
				buf.put("length");		// BUG: should be array.length
		}
		buf.put(']');
	}










}

