module dmd.statements.SwitchStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.statements.DefaultStatement;
import dmd.statements.TryFinallyStatement;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.InterState;
import dmd.statements.GotoCaseStatement;
import dmd.statements.CaseStatement;
import dmd.statements.CompoundStatement;
import dmd.statements.SwitchErrorStatement;
import dmd.Type;
import dmd.expressions.HaltExp;
import dmd.statements.ExpStatement;
import dmd.statements.BreakStatement;
import dmd.scopeDsymbols.EnumDeclaration;
import dmd.types.TypeEnum;
import dmd.Dsymbol;
import dmd.dsymbols.EnumMember;
import dmd.types.TypeTypedef;
import dmd.Token;
import dmd.expressions.StringExp;

import dmd.Module;

import dmd.DDMDExtensions;

class SwitchStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression condition;
    Statement body_;
    bool isFinal;

    DefaultStatement sdefault = null;
    TryFinallyStatement tf = null;
    GotoCaseStatement[] gotoCases;		// array of unresolved GotoCaseStatement's
    CaseStatement[] cases;		// array of CaseStatement's
    int hasNoDefault = 0;	// !=0 if no default statement
    int hasVars = 0;		// !=0 if has variable case values

    this(Loc loc, Expression c, Statement b, bool isFinal)
	{
		super(loc);
		
		this.condition = c;
		this.body_ = b;
		this.isFinal = isFinal;
		
	}
	
    override Statement syntaxCopy()
	{
		SwitchStatement s = new SwitchStatement(loc,
			condition.syntaxCopy(), body_.syntaxCopy(), isFinal);
		return s;
	}
	
	
    override bool hasBreak()
	{
		assert(false);
	}
	
	

	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("switch (");
		condition.toCBuffer(buf, hgs);
		buf.put(')');
		buf.put('\n');
		if (body_)
		{
			if (!body_.isScopeStatement())
			{   
				buf.put('{');
				buf.put('\n');
				body_.toCBuffer(buf, hgs);
				buf.put('}');
				buf.put('\n');
			}
			else
			{
				body_.toCBuffer(buf, hgs);
			}
		}
	}

}
