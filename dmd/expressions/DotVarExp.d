module dmd.expressions.DotVarExp;

import dmd.Global;
import dmd.Expression;
import dmd.Declaration;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.declarations.TupleDeclaration;
import dmd.expressions.DsymbolExp;
import dmd.expressions.TupleExp;
import dmd.Type;
import dmd.Dsymbol;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.VarDeclaration;
import dmd.expressions.ErrorExp;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.VarExp;
import dmd.expressions.StructLiteralExp;


import std.array;
import dmd.DDMDExtensions;

class DotVarExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Declaration var;

	bool hasOverloads;

	this(Loc loc, Expression e, Declaration var, bool hasOverloads = false)
	{
		super(loc, TOKdotvar, DotVarExp.sizeof, e);
		//printf("DotVarExp()\n");
		this.var = var;
		this.hasOverloads = hasOverloads;
	}







	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('.');
		buf.put(var.toChars());
	}


}

