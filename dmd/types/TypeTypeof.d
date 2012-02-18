module dmd.types.TypeTypeof;

import dmd.Global;
import dmd.types.TypeFunction;
import dmd.types.TypeQualified;
import dmd.Expression;
import dmd.Identifier;
import dmd.Scope;
import dmd.Type;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.Token;


class TypeTypeof : TypeQualified
{
    Expression exp;

    this(Loc loc, Expression exp)
	{
		super(Ttypeof, loc);
		this.exp = exp;
	}
	
	
	

	
}
