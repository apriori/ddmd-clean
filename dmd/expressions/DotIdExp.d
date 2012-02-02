module dmd.expressions.DotIdExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.expressions.IntegerExp;
import dmd.Type;
import dmd.expressions.ScopeExp;
import dmd.expressions.StringExp;
import dmd.expressions.PtrExp;
import dmd.types.TypePointer;
import dmd.Dsymbol;
import dmd.dsymbols.EnumMember;
import dmd.VarDeclaration;
import dmd.expressions.ThisExp;
import dmd.expressions.DotVarExp;
import dmd.expressions.VarExp;
import dmd.expressions.CommaExp;
import dmd.declarations.FuncDeclaration;
import dmd.dsymbols.OverloadSet;
import dmd.expressions.OverExp;
import dmd.expressions.TypeExp;
import dmd.declarations.TupleDeclaration;
import dmd.ScopeDsymbol;
import dmd.dsymbols.Import;
import dmd.expressions.TupleExp;
import dmd.expressions.UnaExp;
import dmd.Scope;
import dmd.Token;
import dmd.HdrGenState;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.expressions.DotExp;
import dmd.expressions.IdentifierExp;
import dmd.expressions.CallExp;


import std.array;
import dmd.DDMDExtensions;

class DotIdExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;

	this(Loc loc, Expression e, Identifier ident)
	{
		super(loc, TOKdot, DotIdExp.sizeof, e);
		this.ident = ident;
	}



	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		//printf("DotIdExp.toCBuffer()\n");
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('.');
		buf.put(ident.toChars());
	}

}

