module dmd.statements.OnScopeStatement;

import dmd.Global;
import dmd.Statement;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.Identifier;
import dmd.initializers.ExpInitializer;
import dmd.Token;
import dmd.expressions.IntegerExp;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.expressions.AssignExp;
import dmd.expressions.VarExp;
import dmd.expressions.NotExp;
import dmd.statements.IfStatement;
import dmd.statements.DeclarationStatement;
import dmd.statements.ExpStatement;
import dmd.Expression;
import dmd.Lexer;

import dmd.DDMDExtensions;

class OnScopeStatement : Statement
{
	 mixin insertMemberExtension!(typeof(this));

    TOK tok;
    Statement statement;

    this(Loc loc, TOK tok, Statement statement)
	{
		super(loc);

		this.tok = tok;
		this.statement = statement;
	}

    override Statement syntaxCopy()
	{
		OnScopeStatement s = new OnScopeStatement(loc,
			tok, statement.syntaxCopy());
		return s;
	}


    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(tok));
		buf.put(' ');
		statement.toCBuffer(buf, hgs);
	}



    override void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
    {
        assert(false);
    }

}
