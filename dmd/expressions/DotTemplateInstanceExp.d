module dmd.expressions.DotTemplateInstanceExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.Scope;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.HdrGenState;
import dmd.Token;
import dmd.Declaration;
import dmd.types.TypePointer;
import dmd.types.TypeStruct;
import dmd.expressions.ScopeExp;
import dmd.expressions.DotExp;
import dmd.Type;
import dmd.Identifier;
import dmd.expressions.ErrorExp;
import dmd.expressions.DotVarExp;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.Dsymbol;
import dmd.expressions.DotTemplateExp;
import dmd.expressions.DotIdExp;
import dmd.expressions.TemplateExp;
import dmd.expressions.DsymbolExp;


import std.array;
import dmd.DDMDExtensions;

/* Things like:
 *	foo.bar!(args)
 */
class DotTemplateInstanceExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	TemplateInstance ti;

	this(Loc loc, Expression e, Identifier name, Object[] tiargs)
	{
		super(loc, TOKdotti, DotTemplateInstanceExp.sizeof, e);
		//printf("DotTemplateInstanceExp()\n");
		this.ti = new TemplateInstance(loc, name);
		this.ti.tiargs = tiargs;
	}

	override Expression syntaxCopy()
	{
		DotTemplateInstanceExp de = new DotTemplateInstanceExp(loc, e1.syntaxCopy(), ti.name, TemplateInstance.arraySyntaxCopy(ti.tiargs));
		return de;
	}

	

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('.');
		ti.toCBuffer(buf, hgs);
	}

}

