module dmd.statements.GotoCaseStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.statements.CaseStatement;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class GotoCaseStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;		// NULL, or which case to goto
    CaseStatement cs;		// case statement it resolves to

    this(Loc loc, Expression exp)
	{
		super(loc);
		cs = null;
		this.exp = exp;
	}
	
    override Statement syntaxCopy()
	{
		Expression e = exp ? exp.syntaxCopy() : null;
		GotoCaseStatement s = new GotoCaseStatement(loc, e);
		return s;
	}
	
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("goto case");
		if (exp)
		{   
			buf.put(' ');
			exp.toCBuffer(buf, hgs);
		}
		buf.put(';');
		buf.put('\n');
	}

}
