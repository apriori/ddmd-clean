module dmd.statements.ReturnStatement;

import dmd.Global;
import std.format;

import dmd.Statement;
import dmd.statements.GotoStatement;
import dmd.Dsymbol;
import dmd.statements.CompoundStatement;
import dmd.Identifier;
import dmd.expressions.AssignExp;
import dmd.statements.ExpStatement;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.IntegerExp;
import dmd.expressions.ThisExp;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.types.TypeFunction;
import dmd.Token;
import dmd.Type;
import dmd.Expression;
import dmd.expressions.StructLiteralExp;
import dmd.types.TypeStruct;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.InterState;
import dmd.expressions.VarExp;
import dmd.VarDeclaration;




import dmd.DDMDExtensions;

class ReturnStatement : Statement
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
		Expression e = exp ? exp.syntaxCopy() : null;
		return new ReturnStatement(loc, e);
	}
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		formattedWrite(buf,"return ");
		if (exp)
			exp.toCBuffer(buf, hgs);
		buf.put(';');
		buf.put('\n');
	}
	
	
	

	
	
    override ReturnStatement isReturnStatement() { return this; }
}
