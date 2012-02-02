module dmd.expressions.ErrorExp;

import dmd.Global;
import dmd.expressions.IntegerExp;
import dmd.Token;
import dmd.HdrGenState;
import dmd.Type;

import std.array;
import dmd.DDMDExtensions;

/* Use this expression for error recovery.
 * It should behave as a 'sink' to prevent further cascaded error messages.
 */

class ErrorExp : IntegerExp
{
	mixin insertMemberExtension!(typeof(this));

	this()
	{
		super(Loc(0), 0, Type.terror);
	    op = TOKerror;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("__error");
	}
}

