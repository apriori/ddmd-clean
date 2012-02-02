module dmd.statements.GotoDefaultStatement;

import dmd.Global;
import dmd.Statement;
import dmd.statements.SwitchStatement;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class GotoDefaultStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    SwitchStatement sw;

    this(Loc loc)
	{
		super(loc);
		sw = null;
	}

    override Statement syntaxCopy()
	{
		GotoDefaultStatement s = new GotoDefaultStatement(loc);
		return s;
	}




    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("goto default;\n");
	}

}
