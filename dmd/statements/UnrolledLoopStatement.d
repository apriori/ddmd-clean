module dmd.statements.UnrolledLoopStatement;

import dmd.Global;
import dmd.Expression;
import dmd.Statement;
import dmd.InterState;
import std.array;
import dmd.Scope;
import dmd.HdrGenState;


import dmd.DDMDExtensions;

class UnrolledLoopStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	Statement[] statements;

	this(Loc loc, Statement[] s)
	{
		super(loc);
		statements = s;
	}

	override Statement syntaxCopy()
	{
		assert(false);
	}


	override bool hasBreak()
	{
		assert(false);
	}

	override bool hasContinue()
	{
		assert(false);
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

