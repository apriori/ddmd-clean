module dmd.statements.ForeachRangeStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Token;
import dmd.Parameter;
import dmd.Expression;
import dmd.Statement;
import dmd.VarDeclaration;
import dmd.Scope;
import dmd.initializers.ExpInitializer;
import dmd.Identifier;
import dmd.Lexer;
import dmd.statements.DeclarationStatement;
import dmd.statements.CompoundDeclarationStatement;
import dmd.expressions.DeclarationExp;
import dmd.expressions.PostExp;
import dmd.expressions.VarExp;
import dmd.statements.ForStatement;
import dmd.expressions.IntegerExp;
import dmd.expressions.AddAssignExp;
import dmd.expressions.CmpExp;
import dmd.InterState;
import dmd.expressions.AddExp;
import std.array;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class ForeachRangeStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    TOK op;		// TOKforeach or TOKforeach_reverse
    Parameter arg;		// loop index variable
    Expression lwr;
    Expression upr;
    Statement body_;

    VarDeclaration key = null;

    this(Loc loc, TOK op, Parameter arg, Expression lwr, Expression upr, Statement body_)
	{
		super(loc);
		this.op = op;
		this.arg = arg;
		this.lwr = lwr;
		this.upr = upr;
		this.body_ = body_;
	}
	
    override Statement syntaxCopy()
	{
		ForeachRangeStatement s = new ForeachRangeStatement(loc, op,
			arg.syntaxCopy(),
			lwr.syntaxCopy(),
			upr.syntaxCopy(),
			body_ ? body_.syntaxCopy() : null);

		return s;
	}

	
	override bool hasBreak()
	{
		return true;
	}
	
	override bool hasContinue()
	{
		return true;
	}
	


	
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(op));
		buf.put(" (");

		if (arg.type)
			arg.type.toCBuffer(buf, arg.ident, hgs);
		else
			buf.put(arg.ident.toChars());

		buf.put("; ");
		lwr.toCBuffer(buf, hgs);
		buf.put(" .. ");
		upr.toCBuffer(buf, hgs);
		buf.put(')');
		buf.put('\n');
		buf.put('{');
		buf.put('\n');
		if (body_)
			body_.toCBuffer(buf, hgs);
		buf.put('}');
		buf.put('\n');
	}
	
	
}
