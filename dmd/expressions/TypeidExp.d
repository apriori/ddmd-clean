module dmd.expressions.TypeidExp;

import dmd.Global;
import dmd.Expression;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.expressions.ErrorExp;
import dmd.expressions.DotIdExp;
import dmd.expressions.CommaExp;

import std.array;
import dmd.DDMDExtensions;

class TypeidExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Object obj;

	this(Loc loc, Object o)
	{
		super(loc, TOKtypeid, TypeidExp.sizeof);
		this.obj = o;
	}

	override Expression syntaxCopy()
	{
		return new TypeidExp(loc, objectSyntaxCopy(obj));
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}

