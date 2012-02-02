module dmd.statements.GotoStatement;

import dmd.Global;
import dmd.Scope;
import dmd.Statement;
import dmd.Identifier;
import dmd.statements.CompoundStatement;
import dmd.dsymbols.LabelDsymbol;
import dmd.statements.TryFinallyStatement;
import dmd.declarations.FuncDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.InterState;


import dmd.DDMDExtensions;

class GotoStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;
    LabelDsymbol label = null;
    TryFinallyStatement tf = null;

    this(Loc loc, Identifier ident)
	{
		super(loc);
		this.ident = ident;
	}
	
    override Statement syntaxCopy()
	{
		GotoStatement s = new GotoStatement(loc, ident);
		return s;
	}
	

	

	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("goto ");
		buf.put(ident.toChars());
		buf.put(';');
		buf.put('\n');
	}
	
    override GotoStatement isGotoStatement() { return this; }
}
