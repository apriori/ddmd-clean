module dmd.statements.CaseStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.Statement;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.InterState;
import std.array;
import dmd.statements.SwitchStatement;
import dmd.Token;
import dmd.expressions.VarExp;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.expressions.IntegerExp;
import dmd.statements.GotoCaseStatement;


import dmd.DDMDExtensions;

class CaseStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    Statement statement;

    int index = 0;			// which case it is (since we sort this)
    //block* cblock = null;	// back end: label for the block

    this(Loc loc, Expression exp, Statement s)
	{

		super(loc);
		
		this.exp = exp;
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		CaseStatement s = new CaseStatement(loc, exp.syntaxCopy(), statement.syntaxCopy());
		return s;
	}
	
	
    override int opCmp(Object obj)
	{
		// Sort cases so we can do an efficient lookup
		CaseStatement cs2 = cast(CaseStatement)obj;

		return exp.opCmp(cs2.exp);
	}
	
	
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    buf.put("case ");
		exp.toCBuffer(buf, hgs);
		buf.put(':');
		buf.put('\n');
		statement.toCBuffer(buf, hgs);
	}

}
