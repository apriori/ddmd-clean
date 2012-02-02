module dmd.expressions.PostExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Scope;
import dmd.expressions.BinExp;
import dmd.HdrGenState;
import dmd.expressions.IntegerExp;
import dmd.Token;
import dmd.Type;



import std.array;
import dmd.DDMDExtensions;

class PostExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e)
	{
		super(loc, op, PostExp.sizeof, e, new IntegerExp(loc, 1, Type.tint32));
	}



	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put((op == TOKplusplus) ? "++" : "--");
	}

	override Identifier opId()
	{
		return (op == TOKplusplus) ? Id.postinc : Id.postdec;
	}

}

