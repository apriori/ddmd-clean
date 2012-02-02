module dmd.statements.SynchronizedStatement;

import dmd.Global;
import dmd.Statement;
import dmd.expressions.IntegerExp;
import dmd.types.TypeSArray;
import dmd.statements.CompoundStatement;
import dmd.Scope;
import dmd.Expression;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.types.TypeIdentifier;
import dmd.Type;
import dmd.HdrGenState;
import std.array;
import dmd.expressions.CastExp;
import dmd.statements.TryFinallyStatement;
import dmd.statements.ExpStatement;
import dmd.expressions.CallExp;
import dmd.expressions.DeclarationExp;
import dmd.expressions.VarExp;
import dmd.statements.DeclarationStatement;
import dmd.Statement;
import dmd.VarDeclaration;
import dmd.initializers.ExpInitializer;
import dmd.Lexer;
import dmd.Identifier;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.expressions.DotIdExp;


import dmd.DDMDExtensions;

class SynchronizedStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    Statement body_;

    this(Loc loc, Expression exp, Statement body_)
	{
		super(loc);
		
		this.exp = exp;
		this.body_ = body_;
		//this.esync = null;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override bool hasContinue()
	{
		assert(false);
	}
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

}
