module dmd.statements.IfStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Parameter;
import dmd.Expression;
import dmd.VarDeclaration;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.ScopeDsymbol;
import dmd.Type;
import dmd.expressions.CondExp;
import dmd.expressions.AndAndExp;
import dmd.expressions.OrOrExp;
import dmd.expressions.AssignExp;
import dmd.expressions.VarExp;

import dmd.DDMDExtensions;

import std.array;

class IfStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Parameter arg;
    Expression condition;
    Statement ifbody;
    Statement elsebody;

    VarDeclaration match;	// for MatchExpression results

    this(Loc loc, Parameter arg, Expression condition, Statement ifbody, Statement elsebody)
	{
		super(loc);
		this.arg = arg;
		this.condition = condition;
		this.ifbody = ifbody;
		this.elsebody = elsebody;
	}
		
    override Statement syntaxCopy()
	{
		Statement i = null;
		if (ifbody)
			i = ifbody.syntaxCopy();

		Statement e = null;
		if (elsebody)
			e = elsebody.syntaxCopy();

		Parameter a = arg ? arg.syntaxCopy() : null;
		IfStatement s = new IfStatement(loc, a, condition.syntaxCopy(), i, e);
		return s;
	}
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("if (");
		if (arg)
		{
			if (arg.type)
				arg.type.toCBuffer(buf, arg.ident, hgs);
			else
			{   
				buf.put("auto ");
				buf.put(arg.ident.toChars());
			}
			buf.put(" = ");
		}
		condition.toCBuffer(buf, hgs);
		buf.put(')');
		buf.put('\n');
		ifbody.toCBuffer(buf, hgs);
		if (elsebody)
		{   
			buf.put("else");
			buf.put('\n');
			elsebody.toCBuffer(buf, hgs);
		}
	}
	
	
    override IfStatement isIfStatement() { return this; }

	
	
}
