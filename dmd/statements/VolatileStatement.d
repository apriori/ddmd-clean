module dmd.statements.VolatileStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class VolatileStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement statement;

    this(Loc loc, Statement statement)
	{
		super(loc);
		this.statement = statement;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
	
    override Statement[] flatten(Scope sc)
	{
		Statement[] a = statement ? statement.flatten(sc) : null;
		if (a)
		{	
			foreach (ref Statement s; a)
			{   
				s = new VolatileStatement(loc, s);
			}
		}

		return a;
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("volatile");
		if (statement)
		{   
			if (statement.isScopeStatement())
				buf.put('\n');
			else
				buf.put(' ');
			statement.toCBuffer(buf, hgs);
		}
	}



}
