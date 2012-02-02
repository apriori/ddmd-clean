module dmd.statements.PeelStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Scope;

import dmd.DDMDExtensions;

class PeelStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	Statement s;

	this(Statement s)
	{
		assert(false);
		super(Loc(0));
	}

}

