module dmd.statements.SwitchErrorStatement;

import dmd.Global;
import dmd.Statement;
import std.array;
import dmd.HdrGenState;


import dmd.DDMDExtensions;

class SwitchErrorStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		super(loc);
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("SwitchErrorStatement.toCBuffer()");
		buf.put('\n');
	}

}

