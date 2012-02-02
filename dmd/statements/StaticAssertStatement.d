module dmd.statements.StaticAssertStatement;

import dmd.Global;
import dmd.Statement;
import dmd.dsymbols.StaticAssert;
import std.array;
import dmd.HdrGenState;
import dmd.Scope;

import dmd.DDMDExtensions;

class StaticAssertStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    StaticAssert sa;

    this(StaticAssert sa)
	{
		super(sa.loc);
		this.sa = sa;
	}
	
    override Statement syntaxCopy()
	{
		StaticAssertStatement s = new StaticAssertStatement(cast(StaticAssert)sa.syntaxCopy(null));
		return s;
	}
	

    
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}
