module dmd.statements.ConditionalStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Condition;
import dmd.Scope;
import std.array;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class ConditionalStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Condition condition;
    Statement ifbody;
    Statement elsebody;

    this(Loc loc, Condition condition, Statement ifbody, Statement elsebody)
	{
		super(loc);
		this.condition = condition;
		this.ifbody = ifbody;
		this.elsebody = elsebody;
	}
	
    override Statement syntaxCopy()
	{
		Statement e = null;
		if (elsebody)
			e = elsebody.syntaxCopy();
		ConditionalStatement s = new ConditionalStatement(loc, condition.syntaxCopy(), ifbody.syntaxCopy(), e);
		return s;
	}
	
	
    override Statement[] flatten(Scope sc)
	{
		Statement s;

		if (condition.include(sc, null))
			s = ifbody;
		else
			s = elsebody;

		Statement[] a;
		a ~= (s);

		return a;
	}
	
	

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}
