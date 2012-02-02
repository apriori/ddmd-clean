module dmd.expressions.TupleExp;

import dmd.Global;
import dmd.Expression;
import dmd.declarations.TupleDeclaration;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.expressions.TypeExp;
import dmd.types.TypeTuple;
import dmd.Token;
import dmd.Dsymbol;
import dmd.expressions.DsymbolExp;

import std.array;
import dmd.DDMDExtensions;

/****************************************
 * Expand tuples.
 */
/+
+/
class TupleExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expression[] exps;

	this(Loc loc, Expression[] exps)
	{
		super(loc, TOKtuple, TupleExp.sizeof);
		
		this.exps = exps;
		this.type = null;
	}

	this(Loc loc, TupleDeclaration tup)
	{
		super(loc, TOKtuple, TupleExp.sizeof);
		type = null;

		exps.reserve(tup.objects.length);
		foreach (o; tup.objects)
		{   
			if (auto e = cast(Expression)o)
			{
				e = e.syntaxCopy();
				exps ~= (e);
			}
			else if (auto s = cast(Dsymbol)o)
			{
				auto e = new DsymbolExp(loc, s);
				exps ~= (e);
			}
			else if (auto t = cast(Type)o)
			{
				auto e = new TypeExp(loc, t);
				exps ~= (e);
			}
			else
			{
				error("%s is not an expression", o.toString());
			}
		}
	}

	override Expression syntaxCopy()
	{
		return new TupleExp(loc, arraySyntaxCopy(exps));
	}

	//override bool equals(Object o) { assert (false,"zd cut"); }


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("tuple(");
		//TODO cancel argsToCBuffer(buf, exps, hgs);
		buf.put(')');
	}
}

