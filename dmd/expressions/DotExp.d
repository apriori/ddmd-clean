module dmd.expressions.DotExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.expressions.ScopeExp;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.expressions.DotTemplateExp;
import dmd.expressions.BinExp;
import dmd.Token;

import dmd.DDMDExtensions;

class DotExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKdotexp, DotExp.sizeof, e1, e2);
	}

}

