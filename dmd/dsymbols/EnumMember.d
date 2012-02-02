module dmd.dsymbols.EnumMember;

import dmd.Global;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Type;
import dmd.Identifier;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;

import dmd.DDMDExtensions;

class EnumMember : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

	Expression value;
	Type type;

	this(Loc loc, Identifier id, Expression value, Type type)
	{
		super(id);

		this.value = value;
		this.type = type;
		this.loc = loc;
	}

	Dsymbol syntaxCopy(Dsymbol s)
	{
		Expression e = null;
		if (value)
			e = value.syntaxCopy();

		Type t = null;
		if (type)
			t = type.syntaxCopy();

		EnumMember em;
		if (s)
		{	em = cast(EnumMember)s;
			em.loc = loc;
			em.value = e;
			em.type = t;
		}
		else
			em = new EnumMember(loc, ident, e, t);
		return em;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (type)
			type.toCBuffer(buf, ident, hgs);
		else
			buf.put(ident.toChars());
		if (value)
		{
			buf.put(" = ");
			value.toCBuffer(buf, hgs);
		}
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

	override string kind()
	{
		return "enum member";
	}

	override void emitComment(Scope sc)
	{
		assert(false);
	}

	override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	override EnumMember isEnumMember() { return this; }
}
