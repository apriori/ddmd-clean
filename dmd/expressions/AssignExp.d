module dmd.expressions.AssignExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Parameter;
import dmd.expressions.IndexExp;
import dmd.expressions.CallExp;
import dmd.expressions.CastExp;
import dmd.types.TypeSArray;
import dmd.expressions.StructLiteralExp;
import dmd.expressions.ArrayLengthExp;
import dmd.types.TypeStruct;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.expressions.VarExp;
import dmd.expressions.SliceExp;
import dmd.expressions.CommaExp;
import dmd.expressions.ArrayExp;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.expressions.CondExp;
import dmd.expressions.DotVarExp;
import dmd.types.TypeClass;
import dmd.types.TypeNext;
import dmd.expressions.TupleExp;
import dmd.VarDeclaration;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Declaration;
import dmd.types.TypeFunction;
import dmd.Type;
import dmd.Dsymbol;
import dmd.expressions.DotIdExp;


import dmd.DDMDExtensions;

class AssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	int ismemset = 0;

	this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKassign, AssignExp.sizeof, e1, e2);
	}

	override Expression checkToBoolean()
	{
		assert(false);
	}

	override Identifier opId()
	{
		return Id.assign;
	}
}

