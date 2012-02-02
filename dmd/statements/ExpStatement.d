module dmd.statements.ExpStatement;

import dmd.Global;
import dmd.Statement;
import dmd.expressions.AssertExp;
import dmd.Expression;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.InterState;
import dmd.Token;
import dmd.statements.DeclarationStatement;


import dmd.DDMDExtensions;

class ExpStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;

    this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}
	
	/*
	~this()
	{
		delete exp;
	}
	*/
    override Statement syntaxCopy()
	{
		Expression e = exp ? exp.syntaxCopy() : null;
		ExpStatement es = new ExpStatement(loc, e);
		return es;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (exp)
			exp.toCBuffer(buf, hgs);
		buf.put(';');
		if (!hgs.FLinit.init)
			buf.put('\n');
	}
	


    




}
