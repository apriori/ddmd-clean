module dmd.expressions.IdentifierExp;

import dmd.Global;
import dmd.Expression;
import dmd.Declaration;
import dmd.types.TypePointer;
import dmd.declarations.FuncDeclaration;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.VarDeclaration;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.expressions.TemplateExp;
import dmd.expressions.DsymbolExp;
import dmd.Identifier;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.scopeDsymbols.WithScopeSymbol;
import dmd.expressions.VarExp;
import dmd.expressions.DotIdExp;
import dmd.Type;
import dmd.HdrGenState;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class IdentifierExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;

	Declaration var;

	this(Loc loc, Identifier ident)
	{
		super(loc, TOKidentifier, IdentifierExp.sizeof);
		this.ident = ident;
	}

	this(Loc loc, Declaration var)
	{
		assert(false);
		super(loc, TOK.init, 0);
	}

	override string toChars()
	{
		return ident.toChars();
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (hgs.hdrgen)
			buf.put(ident.toHChars2());
		else
			buf.put(ident.toChars());
	}

}

