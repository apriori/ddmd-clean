module dmd.dsymbols.StaticAssert;

import dmd.Global;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.HdrGenState;
import std.array;
import dmd.ScopeDsymbol;
import dmd.Scope;
import dmd.Identifier;

import dmd.DDMDExtensions;

class StaticAssert : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

	Expression exp;
	Expression msg;

	this(Loc loc, Expression exp, Expression msg)
	{
		super(Id.empty);

		this.loc = loc;
		this.exp = exp;
		this.msg = msg;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		StaticAssert sa;

		assert(!s);
		sa = new StaticAssert(loc, exp.syntaxCopy(), msg ? msg.syntaxCopy() : null);
		return sa;
	}

	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		return false;		// we didn't add anything
	}




	override bool oneMember(Dsymbol ps)
	{
		//printf("StaticAssert.oneMember())\n");
		ps = null;
		return true;
	}


	override string kind()
	{
		return "static assert";
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(kind());
		buf.put('(');
		exp.toCBuffer(buf, hgs);
		if (msg)
		{
			buf.put(',');
			msg.toCBuffer(buf, hgs);
		}
		buf.put(");");
		buf.put('\n');
	}
}
