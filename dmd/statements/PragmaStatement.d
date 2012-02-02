module dmd.statements.PragmaStatement;

import dmd.Global;
import dmd.Statement;
import dmd.expressions.StringExp;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Identifier;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Parameter;
import std.array;
import dmd.Token;

import dmd.DDMDExtensions;

class PragmaStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;
	Expression[] args;		// array of Expression's
	Statement body_;

	this(Loc loc, Identifier ident, Expression[] args, Statement body_)
	{
		super(loc);
		this.ident = ident;
		this.args = args;
		this.body_ = body_;
	}
	
	override Statement syntaxCopy()
	{
		Statement b = null;
		if (body_)
		b = body_.syntaxCopy();
		PragmaStatement s = new PragmaStatement(loc,
			ident, Expression.arraySyntaxCopy(args), b);
		return s;

	}
	
	
	
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("pragma (");
		buf.put(ident.toChars());
		if (args && args.length)
		{
			buf.put(", ");
			argsToCBuffer(buf, args, hgs);
		}
		buf.put(')');
		if (body_)
		{
			buf.put('\n');
			buf.put('{');
			buf.put('\n');
	
			body_.toCBuffer(buf, hgs);
	
			buf.put('}');
			buf.put('\n');
		}
		else
		{
			buf.put(';');
			buf.put('\n');
		}

	}
	
}
