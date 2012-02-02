module dmd.statements.TryCatchStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Identifier;
import dmd.Scope;
import dmd.Catch;
import std.array;
import dmd.HdrGenState;


import dmd.DDMDExtensions;

class TryCatchStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement body_;
    Catch[] catches;

    this(Loc loc, Statement body_, Catch[] catches)
	{
		super(loc);
		this.body_ = body_;
		this.catches = catches;
	}
	
    override Statement syntaxCopy()
	{
		Catch[] a;
		a.reserve(catches.length);
		for (int i = 0; i < a.length; i++)
		{   
			Catch c = catches[i];
			c = c.syntaxCopy();
			a[i] = c;
		}
		TryCatchStatement s = new TryCatchStatement(loc, body_.syntaxCopy(), a);
		return s;
	}
	
	
    override bool hasBreak()
	{
		assert(false);
	}
	
	


	/***************************************
	 * Builds the following:
	 *	_try
	 *	block
	 *	jcatch
	 *	handler
	 * A try-catch statement.
	 */
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("try");
		buf.put('\n');
		if (body_)
			body_.toCBuffer(buf, hgs);
		for (size_t i = 0; i < catches.length; i++)
		{
			Catch c = catches[i];
			c.toCBuffer(buf, hgs);
		}
	}
	
    override TryCatchStatement isTryCatchStatement() { return this; }
}
