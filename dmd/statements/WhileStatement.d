module dmd.statements.WhileStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;
import dmd.statements.ForStatement;

import dmd.DDMDExtensions;

class WhileStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression condition;
    Statement body_;

    this(Loc loc, Expression c, Statement b)
	{
		super(loc);
		condition = c;
		body_ = b;
	}
	
    override Statement syntaxCopy()
	{
		WhileStatement s = new WhileStatement(loc, condition.syntaxCopy(), body_ ? body_.syntaxCopy() : null);
		return s;
	}
	
	
    override bool hasBreak()
	{
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
	
	
    override bool comeFrom()
	{
		assert(false);
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

	
}
