module dmd.types.TypeArray;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeNext;
import dmd.FuncDeclaration;
import dmd.Expression;
import dmd.Scope;
import dmd.Identifier;


class TypeArray : TypeNext
{
    this(TY ty, Type next)
	{
		super(ty, next);
	}

}
