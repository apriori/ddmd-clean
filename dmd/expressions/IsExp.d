module dmd.expressions.IsExp;

import dmd.Global;
import std.format;

import dmd.Expression;
import dmd.Identifier;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.types.TypeEnum;
import dmd.types.TypeClass;
import dmd.TemplateParameter;
import dmd.BaseClass;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.types.TypeStruct;
import dmd.types.TypeTypedef;
import dmd.expressions.IntegerExp;
import dmd.declarations.AliasDeclaration;
import dmd.Dsymbol;
import dmd.types.TypeTuple;
import dmd.types.TypeDelegate;
import dmd.Declaration;
import dmd.types.TypeFunction;
import dmd.types.TypePointer;
import dmd.Parameter;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class IsExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	/* is(targ id tok tspec)
     * is(targ id == tok2)
     */
    Type targ;
    Identifier id;	// can be null
    TOK tok;	// ':' or '=='
    Type tspec;	// can be null
    TOK tok2;	// 'struct', 'union', 'typedef', etc.
    TemplateParameter[] parameters;

	this(Loc loc, Type targ, Identifier id, TOK tok, Type tspec, TOK tok2, TemplateParameter[] parameters)
	{
		super(loc, TOKis, IsExp.sizeof);
		
		this.targ = targ;
		this.id = id;
		this.tok = tok;
		this.tspec = tspec;
		this.tok2 = tok2;
		this.parameters = parameters;
	}

	override Expression syntaxCopy()
	{
		// This section is identical to that in TemplateDeclaration.syntaxCopy()
		TemplateParameter[] p = null;
		if (parameters)
		{
			p.reserve(parameters.length);
			for (int i = 0; i < p.length; i++)
			{   
				auto tp = parameters[i];
				p[i] = tp.syntaxCopy();
			}
		}

		return new IsExp(loc,
		targ.syntaxCopy(),
		id,
		tok,
		tspec ? tspec.syntaxCopy() : null,
		tok2,
		p);
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("is(");
		targ.toCBuffer(buf, id, hgs);
		if (tok2 != TOKreserved)
		{
			formattedWrite(buf," %s %s", Token.toChars(tok), Token.toChars(tok2));
		}
		else if (tspec)
		{
			if (tok == TOKcolon)
				buf.put(" : ");
			else
				buf.put(" == ");
			tspec.toCBuffer(buf, null, hgs);
		}
		if (parameters)
		{	
			// First parameter is already output, so start with second
			for (int i = 1; i < parameters.length; i++)
			{
				buf.put(',');
				auto tp = parameters[i];
				tp.toCBuffer(buf, hgs);
			}
		}
		buf.put(')');
	}
}

