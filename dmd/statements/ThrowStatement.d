module dmd.statements.ThrowStatement;

import dmd.Global;
import std.format;

import dmd.Statement;
import dmd.Expression;
import dmd.HdrGenState;
import dmd.Scope;
import std.array;
import dmd.Expression;
import dmd.declarations.FuncDeclaration;


import dmd.DDMDExtensions;

class ThrowStatement : Statement
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
		ThrowStatement s = new ThrowStatement(loc, exp.syntaxCopy());
		return s;
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		formattedWrite(buf,"throw ");
		exp.toCBuffer(buf, hgs);
		buf.put(';');
		buf.put('\n');
	}
	

}
