module dmd.types.TypeNewArray;

import dmd.HdrGenState;
import dmd.Type;
import std.array;
import dmd.types.TypeNext;

import dmd.DDMDExtensions;

/** T[new]
 */
class TypeNewArray : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

	this(Type next)
	{
		super(Tnarray, next);
		//writef("TypeNewArray\n");
	}

	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		buf.put("[new]");
	}
}
