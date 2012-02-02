module dmd.statements.ContinueStatement;

import dmd.Global;
import dmd.Statement;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.IntegerExp;
import dmd.statements.ReturnStatement;
import dmd.statements.LabelStatement;
import dmd.Identifier;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class ContinueStatement : Statement
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
		ContinueStatement s = new ContinueStatement(loc, ident);
		return s;
	}

	


    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("continue");
		if (ident)
		{   
			buf.put(' ');
			buf.put(ident.toChars());
		}
		buf.put(';');
		buf.put('\n');
	}

}
