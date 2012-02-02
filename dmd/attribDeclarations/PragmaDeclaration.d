module dmd.attribDeclarations.PragmaDeclaration;

import dmd.Global;
import dmd.AttribDeclaration;
import dmd.Identifier;
import dmd.expressions.StringExp;
import dmd.Token;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.declarations.FuncDeclaration;



import dmd.DDMDExtensions;

class PragmaDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    Expression[] args;		// array of Expression's

    this(Loc loc, Identifier ident, Expression[] args, Dsymbol[] decl)
	{
		super(decl);
		this.loc = loc;
		this.ident = ident;
		this.args = args;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("PragmaDeclaration.syntaxCopy(%s)\n", toChars());
		PragmaDeclaration pd;

		assert(!s);
		pd = new PragmaDeclaration(loc, ident, Expression.arraySyntaxCopy(args), Dsymbol.arraySyntaxCopy(decl));
		return pd;
	}
	
	
	
    override bool oneMember(Dsymbol* ps)
	{
		*ps = null;
		return true;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
	
    override string kind()
	{
		assert(false);
	}
	
}
