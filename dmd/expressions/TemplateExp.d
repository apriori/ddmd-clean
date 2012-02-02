module dmd.expressions.TemplateExp;

import dmd.Global;
import dmd.Expression;
import dmd.HdrGenState;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class TemplateExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	TemplateDeclaration td;

	this(Loc loc, TemplateDeclaration td)
	{
		super(loc, TOKtemplate, TemplateExp.sizeof);
		//printf("TemplateExp(): %s\n", td.toChars());
		this.td = td;
	}

	override void rvalue()
	{
		error("template %s has no value", toChars());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(td.toChars());
	}
}

