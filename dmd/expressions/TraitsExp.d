module dmd.expressions.TraitsExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.Lexer;
import dmd.expressions.ArrayLiteralExp;
import dmd.expressions.VarExp;
import dmd.expressions.StringExp;
import dmd.expressions.DotIdExp;
import dmd.expressions.DotVarExp;
import dmd.expressions.IntegerExp;
import dmd.expressions.TupleExp;
import dmd.Type;
import dmd.Dsymbol;
import dmd.expressions.DsymbolExp;
import dmd.ScopeDsymbol;
import dmd.declarations.FuncDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.types.TypeClass;
import dmd.Declaration;


import std.array;
import dmd.DDMDExtensions;

/************************************************
 * Delegate to be passed to overloadApply() that looks
 * for functions matching a trait.
 */

struct Ptrait
{
	Expression e1;
	Expression[] exps;		// collected results
	Identifier ident;		// which trait we're looking for
	
	bool visit(FuncDeclaration f)
	{
		if (ident == Id.getVirtualFunctions && !f.isVirtual())
			return false;

		Expression e;

		if (e1.op == TOKdotvar)
		{   
			DotVarExp dve = cast(DotVarExp)e1;
			e = new DotVarExp(Loc(0), dve.e1, f);
		}
		else
			e = new DsymbolExp(Loc(0), f);
		exps ~= (e);

		return false;
	}
}

class TraitsExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;

	Object[] args;

	this(Loc loc, Identifier ident, Object[] args)
	{
		super(loc, TOKtraits, this.sizeof);
		this.ident = ident;
		this.args = args;
	}

	override Expression syntaxCopy()
	{
		return new TraitsExp(loc, ident, TemplateInstance.arraySyntaxCopy(args));
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("__traits(");
		buf.put(ident.toChars());
		if (args)
		{
			for (int i = 0; i < args.length; i++)
			{
				buf.put(',');
				Object oarg = args[i];
				ObjectToCBuffer(buf, hgs, oarg);
			}
		}
		buf.put(')');
	}
}
