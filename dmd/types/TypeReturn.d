module dmd.types.TypeReturn;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeQualified;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;


class TypeReturn : TypeQualified
{
    this(Loc loc)
	{
		super(Treturn, loc);
	}
	

	
	
}
