module dmd.statements.CaseRangeStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.statements.ExpStatement;
import dmd.expressions.IntegerExp;
import dmd.statements.CaseStatement;
import dmd.statements.CompoundStatement;
import dmd.Statement;
import std.array;
import dmd.statements.SwitchStatement;
import dmd.HdrGenState;
import dmd.Scope;

import dmd.DDMDExtensions;

class CaseRangeStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression first;
    Expression last;
    Statement statement;

    this(Loc loc, Expression first, Expression last, Statement s)
	{

		super(loc);
		this.first = first;
		this.last = last;
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("case ");
		first.toCBuffer(buf, hgs);
		buf.put(": .. case ");
		last.toCBuffer(buf, hgs);
		buf.put('\n');
		statement.toCBuffer(buf, hgs);
	}
}
