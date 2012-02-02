module dmd.statements.DoStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class DoStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement body_;
    Expression condition;

    this(Loc loc, Statement b, Expression c)
	{
		super(loc);
		body_ = b;
		condition = c;
	}
	
    override Statement syntaxCopy()
	{
		DoStatement s = new DoStatement(loc, body_ ? body_.syntaxCopy() : null, condition.syntaxCopy());
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





    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    buf.put("do");
		buf.put('\n');
		if (body_)
			body_.toCBuffer(buf, hgs);
		buf.put("while (");
		condition.toCBuffer(buf, hgs);
		buf.put(')');
	}


}
