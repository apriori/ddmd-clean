module dmd.types.TypeReturn;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeQualified;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;

import dmd.DDMDExtensions;

class TypeReturn : TypeQualified
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc)
	{
		super(Treturn, loc);
	}
	

	
	
}
