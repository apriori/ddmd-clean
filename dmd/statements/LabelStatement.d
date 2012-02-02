module dmd.statements.LabelStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Identifier;
import dmd.statements.TryFinallyStatement;
import dmd.Scope;
import dmd.statements.ExpStatement;
import dmd.Expression;
import dmd.InterState;
import dmd.dsymbols.LabelDsymbol;
import dmd.declarations.FuncDeclaration;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class LabelStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;
    Statement statement;
    TryFinallyStatement tf = null;
    //block* lblock = null;		// back end
    int isReturnLabel = 0;

    this(Loc loc, Identifier ident, Statement statement)
	{
		super(loc);
		this.ident = ident;
		this.statement = statement;
	}

    override Statement syntaxCopy()
	{
		LabelStatement s = new LabelStatement(loc, ident, statement.syntaxCopy());
		return s;
	}
	

    override Statement[] flatten(Scope sc)
	{
		Statement[] a = null;

		if (statement)
		{
			a = statement.flatten(sc);
			if (a)
			{
				if (!a.length)
					a ~= (new ExpStatement(loc, null));

				Statement s = a[0];

				s = new LabelStatement(loc, ident, s);
				a[0] = s;
			}
		}

		return a;
	}
	
	
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(ident.toChars());
		buf.put(':');
		buf.put('\n');
		if (statement)
			statement.toCBuffer(buf, hgs);
	}
	
}
