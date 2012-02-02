module dmd.expressions.DotTemplateExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.Token;
import dmd.HdrGenState;
import dmd.scopeDsymbols.TemplateDeclaration;


import std.array;
import dmd.DDMDExtensions;

class DotTemplateExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	TemplateDeclaration td;

	this(Loc loc, Expression e, TemplateDeclaration td)
	{
		super(loc, TOKdottd, this.sizeof, e);
		this.td = td;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    expToCBuffer(buf, hgs, e1, PREC_primary);
	    buf.put('.');
	    buf.put(td.toChars());
	}
}

