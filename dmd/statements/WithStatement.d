module dmd.statements.WithStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.VarDeclaration;
import dmd.ScopeDsymbol;
import std.array;
import dmd.expressions.TypeExp;
import dmd.Token;
import dmd.Initializer;
import dmd.initializers.ExpInitializer;
import dmd.Identifier;
import dmd.expressions.ScopeExp;
import dmd.scopeDsymbols.WithScopeSymbol;
import dmd.Type;
import dmd.HdrGenState;
import dmd.Scope;

import dmd.DDMDExtensions;

class WithStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    Statement body_;
    VarDeclaration wthis;

    this(Loc loc, Expression exp, Statement body_)
	{
		super(loc);
		this.exp = exp;
		this.body_ = body_;
		wthis = null;
	}
	
    override Statement syntaxCopy()
	{
		WithStatement s = new WithStatement(loc, exp.syntaxCopy(), body_ ? body_.syntaxCopy() : null);
		return s;
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
	
	

}
