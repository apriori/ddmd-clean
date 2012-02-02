module dmd.statements.DefaultStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class DefaultStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement statement;
version (IN_GCC) {
    block* cblock = null;	// back end: label for the block
}

    this(Loc loc, Statement s)
	{
		super(loc);
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		DefaultStatement s = new DefaultStatement(loc, statement.syntaxCopy());
		return s;
	}
	
	
	
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("default:\n");
		statement.toCBuffer(buf, hgs);
	}


}
