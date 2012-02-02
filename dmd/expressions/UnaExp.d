module dmd.expressions.UnaExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.types.TypeClass;
import dmd.types.TypeStruct;
import dmd.Dsymbol;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.expressions.DotIdExp;
import dmd.expressions.ArrayExp;
import dmd.expressions.CallExp;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class UnaExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expression e1;

	this(Loc loc, TOK op, int size, Expression e1)
	{
		super(loc, op, size);
		this.e1 = e1;
	}

	override Expression syntaxCopy()
	{
		UnaExp e = cast(UnaExp)copy();
		e.type = null;
		e.e1 = e.e1.syntaxCopy();

		return e;
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(op));
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

}

