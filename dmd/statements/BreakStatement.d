module dmd.statements.BreakStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Identifier;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;
import dmd.declarations.FuncDeclaration;
import dmd.statements.LabelStatement;
import dmd.statements.ReturnStatement;
import dmd.expressions.IntegerExp;


import dmd.DDMDExtensions;

class BreakStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;

    this(Loc loc, Identifier ident)
	{

		super(loc);
		this.ident = ident;
	}
	
    override Statement syntaxCopy()
	{
		BreakStatement s = new BreakStatement(loc, ident);
		return s;
	}
	

	

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("break");
		if (ident)
		{   
			buf.put(' ');
			buf.put(ident.toChars());
		}
		buf.put(';');
		buf.put('\n');
	}

}
