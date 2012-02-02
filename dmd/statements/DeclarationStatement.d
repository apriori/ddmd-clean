module dmd.statements.DeclarationStatement;

import dmd.Global;
import dmd.statements.ExpStatement;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Statement;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.expressions.DeclarationExp;
import dmd.Token;
import dmd.VarDeclaration;

import dmd.DDMDExtensions;

class DeclarationStatement : ExpStatement
{
	mixin insertMemberExtension!(typeof(this));
	
    // Doing declarations as an expression, rather than a statement,
    // makes inlining functions much easier.

    this(Loc loc, Dsymbol declaration)
	{
		super(loc, new DeclarationExp(loc, declaration));
	}
	
    this(Loc loc, Expression exp)
	{
		super(loc, exp);
	}
	
    override Statement syntaxCopy()
	{
		DeclarationStatement ds = new DeclarationStatement(loc, exp.syntaxCopy());
		return ds;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		exp.toCBuffer(buf, hgs);
	}
	

    override DeclarationStatement isDeclarationStatement() { return this; }
}
