module dmd.expressions.NullExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.Type;
import dmd.types.TypeTypedef;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class NullExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	ubyte committed;

	this(Loc loc, Type type = null)
	{
		super(loc, TOKnull, NullExp.sizeof);
        this.type = type;
	}


	override bool isBool(bool result)
	{
		assert(false);
	}

	override int isConst()
	{
		return 0;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("null");
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		buf.put('n');
	}





}

