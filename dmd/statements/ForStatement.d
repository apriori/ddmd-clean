module dmd.statements.ForStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;
import dmd.ScopeDsymbol;


import dmd.DDMDExtensions;

class ForStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement init;
    Expression condition;
    Expression increment;
    Statement body_;

    this(Loc loc, Statement init, Expression condition, Expression increment, Statement body_)
	{
		super(loc);
		
		this.init = init;
		this.condition = condition;
		this.increment = increment;
		this.body_ = body_;
	}

    override Statement syntaxCopy()
	{
		Statement i = null;
		if (init)
			i = init.syntaxCopy();
		Expression c = null;
		if (condition)
			c = condition.syntaxCopy();
		Expression inc = null;
		if (increment)
			inc = increment.syntaxCopy();
		ForStatement s = new ForStatement(loc, i, c, inc, body_.syntaxCopy());
		return s;
	}
	
	
    override void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
	{
		//printf("ForStatement::scopeCode()\n");
		//print();
		if (init)
			init.scopeCode(sc, sentry, sexception, sfinally);
		else
			Statement.scopeCode(sc, sentry, sexception, sfinally);
	}
	
    override bool hasBreak()
	{
		//printf("ForStatement.hasBreak()\n");
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
	
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("for (");
		if (init)
		{
			hgs.FLinit.init++;
			init.toCBuffer(buf, hgs);
			hgs.FLinit.init--;
		}
		else
			buf.put(';');
		if (condition)
		{   buf.put(' ');
			condition.toCBuffer(buf, hgs);
		}
		buf.put(';');
		if (increment)
		{   
			buf.put(' ');
			increment.toCBuffer(buf, hgs);
		}
		buf.put(')');
		buf.put('\n');
		buf.put('{');
		buf.put('\n');
		body_.toCBuffer(buf, hgs);
		buf.put('}');
		buf.put('\n');
	}
	
	
}
