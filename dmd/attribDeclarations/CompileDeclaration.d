module dmd.attribDeclarations.CompileDeclaration;

import dmd.Global;
import dmd.AttribDeclaration;
import dmd.Token;
import dmd.expressions.StringExp;
import dmd.Parser;
import dmd.Expression;
import dmd.ScopeDsymbol;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.expressions.StringExp;
import dmd.Parser;

import dmd.DDMDExtensions;

// Mixin declarations

class CompileDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    ScopeDsymbol sd;
    bool compiled;

	this(Loc loc, Expression exp)
	{

		super(null);
		//printf("CompileDeclaration(loc = %d)\n", loc.linnum);
		this.loc = loc;
		this.exp = exp;
		this.sd = null;
		this.compiled = false;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("CompileDeclaration.syntaxCopy('%s')\n", toChars());
		CompileDeclaration sc = new CompileDeclaration(loc, exp.syntaxCopy());
		return sc;
	}

   override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
   {
       assert (false);
   }


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("mixin(");
		exp.toCBuffer(buf, hgs);
		buf.put(");");
		buf.put('\n');
	}
}
