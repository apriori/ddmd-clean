module dmd.expressions.ScopeExp;

import dmd.Global;
import dmd.Expression;
import dmd.ScopeDsymbol;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.Token;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.expressions.VarExp;
import dmd.expressions.DotVarExp;
import dmd.expressions.DsymbolExp;
import dmd.Type;

import std.array;
import dmd.DDMDExtensions;

class ScopeExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	ScopeDsymbol sds;

	this(Loc loc, ScopeDsymbol pkg)
	{
		super(loc, TOKimport, ScopeExp.sizeof);
		//printf("ScopeExp.ScopeExp(pkg = '%s')\n", pkg.toChars());
		//static int count; if (++count == 38) *(char*)0=0;
		this.sds = pkg;
	}

	override Expression syntaxCopy()
	{
		ScopeExp se = new ScopeExp(loc, cast(ScopeDsymbol)sds.syntaxCopy(null));
		return se;
	}



	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (sds.isTemplateInstance())
		{
			sds.toCBuffer(buf, hgs);
		}
		else
		{
			buf.put(sds.kind());
			buf.put(" ");
			buf.put(sds.toChars());
		}
	}
}

