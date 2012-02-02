module dmd.types.TypeReference;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeNext;
import std.array;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.expressions.NullExp;

import dmd.DDMDExtensions;

class TypeReference : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    this(Type t)
	{
		super( TY.init, null);
		assert(false);
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
	
    override ulong size(Loc loc)
	{
		assert(false);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		assert(false);
	}
	
	
	
	
}
