module dmd.types.TypeArray;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeNext;
import dmd.expressions.CallExp;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.VarExp;
import dmd.Expression;
import dmd.Scope;
import dmd.Identifier;
import dmd.expressions.IntegerExp;

import dmd.DDMDExtensions;

class TypeArray : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    this(TY ty, Type next)
	{
		super(ty, next);
	}

}
