module dmd.statements.CompileStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Expression;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Token;
import dmd.ParseStatementFlags;
import dmd.Parser;
import dmd.statements.CompoundStatement;
import dmd.expressions.StringExp;

import dmd.DDMDExtensions;

class CompileStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	Expression exp;

	this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}

	override Statement syntaxCopy()
	{
		Expression e = exp.syntaxCopy();
		CompileStatement es = new CompileStatement(loc, e);
		return es;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("mixin(");
		exp.toCBuffer(buf, hgs);
		buf.put(");");
		if (!hgs.FLinit.init)
			buf.put('\n');
	}


}
