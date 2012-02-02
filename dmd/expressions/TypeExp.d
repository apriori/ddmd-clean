module dmd.expressions.TypeExp;

import dmd.Global;
import dmd.Expression;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class TypeExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Type type)
	{
		super(loc, TOKtype, TypeExp.sizeof);
		//printf("TypeExp::TypeExp(%s)\n", type->toChars());
		this.type = type;
	}

	override Expression syntaxCopy()
	{
		//printf("TypeExp.syntaxCopy()\n");
		return new TypeExp(loc, type.syntaxCopy());
	}


	override void rvalue()
	{
		error("type %s has no value", toChars());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		type.toCBuffer(buf, null, hgs);
	}


}

