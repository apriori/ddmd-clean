module dmd.statements.TryFinallyStatement;

import dmd.Global;
import std.format;

import dmd.Statement;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.statements.CompoundStatement;



import dmd.DDMDExtensions;

class TryFinallyStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement body_;
    Statement finalbody;

    this(Loc loc, Statement body_, Statement finalbody)
	{
		super(loc);
		this.body_ = body_;
		this.finalbody = finalbody;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		formattedWrite(buf,"try\n{\n");
		body_.toCBuffer(buf, hgs);
		formattedWrite(buf,"}\nfinally\n{\n");
		finalbody.toCBuffer(buf, hgs);
		buf.put('}');
		buf.put('\n');
	}
	
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override bool hasContinue()
	{
		assert(false);
	}
	
	


	/****************************************
	 * A try-finally statement.
	 * Builds the following:
	 *	_try
	 *	block
	 *	_finally
	 *	finalbody
	 *	_ret
	 */
}
