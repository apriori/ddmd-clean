module dmd.statements.CompoundStatement;

import dmd.Global;
import dmd.Statement;
import dmd.statements.TryCatchStatement;
import dmd.statements.TryFinallyStatement;
import dmd.Catch;
import dmd.statements.ScopeStatement;
import dmd.Identifier;
import dmd.Lexer;
import dmd.statements.ThrowStatement;
import dmd.expressions.IdentifierExp;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.statements.ReturnStatement;
import dmd.Expression;
import dmd.InterState;
import dmd.statements.IfStatement;

import dmd.DDMDExtensions;

class CompoundStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement[] statements;

    this(Loc loc, Statement[] s)
	{
		super(loc);
		statements = s;
	}
	
    this(Loc loc, Statement s1, Statement s2)
	{
		super(loc);
		
		statements.reserve(2);
		statements ~= (s1);
		statements ~= (s2);
	}
	
    override Statement syntaxCopy()
	{
		Statement[] a;
		a.reserve(statements.length);

		foreach (size_t i, Statement s; statements)
		{	
			if (s)
				s = s.syntaxCopy();
			a[i] = s;
		}

		return new CompoundStatement(loc, a);
	}
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		foreach (s; statements)
		{
			if (s)
				s.toCBuffer(buf, hgs);
		}
	}
	
	
	
	
	

    override Statement[] flatten(Scope sc)
	{
		return statements;
	}

    override ReturnStatement isReturnStatement()
	{
		ReturnStatement rs = null;

		foreach(s; statements)
		{	
			if (s)
			{
				rs = s.isReturnStatement();
				if (rs)
					break;
			}
		}
		return rs;
	}



	


    override CompoundStatement isCompoundStatement() { return this; }
}
