module dmd.statements.ScopeStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.InterState;
import dmd.ScopeDsymbol;
import dmd.statements.CompoundStatement;


import dmd.DDMDExtensions;

class ScopeStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement statement;

    this(Loc loc, Statement s)
	{
		super(loc);
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		Statement s = statement ? statement.syntaxCopy() : null;
		s = new ScopeStatement(loc, s);
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('{');
		buf.put('\n');

		if (statement)
			statement.toCBuffer(buf, hgs);

		buf.put('}');
		buf.put('\n');
	}
	
    override ScopeStatement isScopeStatement() { return this; }
	
	
    override bool hasBreak()
	{
		//printf("ScopeStatement.hasBreak() %s\n", toChars());
		return statement ? statement.hasBreak() : false;
	}
	
    override bool hasContinue()
	{
		return statement ? statement.hasContinue() : false;
	}
	
	
	
	
	

}
