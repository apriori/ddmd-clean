module dmd.scopeDsymbols.TemplateMixin;

import dmd.Global;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.Type;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.Expression;
import dmd.ScopeDsymbol;

import dmd.DDMDExtensions;

class TemplateMixin : TemplateInstance
{
	mixin insertMemberExtension!(typeof(this));

	Identifier[] idents;
	Type tqual;

	this(Loc loc, Identifier ident, Type tqual, Identifier[] idents, Object[] tiargs)
	{
		super( loc, idents[$] );
		//printf("TemplateMixin(ident = '%s')\n", ident ? ident.toChars() : "");
		this.ident = ident;
		this.tqual = tqual;
		this.idents = idents;
		this.tiargs = tiargs;
		//this.semantictiargsdone = 1;
		//this.havetempdecl = 1;
	}






	override string kind()
	{
		return "mixin";
	}

	override bool oneMember(Dsymbol* ps)
	{
		return Dsymbol.oneMember(ps);
	}


	override string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		TemplateInstance.toCBuffer(buf, hgs);
		string s = buf.data.idup;
		buf.clear();
		return s;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("mixin ");

		for (int i = 0; i < idents.length; i++)
		{   Identifier id = idents[i];

			if (i)
				buf.put('.');
			buf.put(id.toChars());
		}
		buf.put("!(");
		if (tiargs)
		{
			for (int i = 0; i < tiargs.length; i++)
			{   if (i)
				buf.put(',');
				Object oarg = tiargs[i];
				Type t = isType(oarg);
				Expression e = isExpression(oarg);
				Dsymbol s = isDsymbol(oarg);
				if (t)
					t.toCBuffer(buf, null, hgs);
				else if (e)
					e.toCBuffer(buf, hgs);
				else if (s)
				{
					string p = s.ident ? s.ident.toChars() : s.toChars();
					buf.put(p);
				}
				else if (!oarg)
				{
					buf.put("null");
				}
				else
				{
					assert(0);
				}
			}
		}
		buf.put(')');
		if (ident)
		{
			buf.put(' ');
			buf.put(ident.toChars());
		}
		buf.put(';');
		buf.put('\n');
	}


	override TemplateMixin isTemplateMixin() { return this; }
}
