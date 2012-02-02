module dmd.expressions.PtrExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.expressions.SymOffExp;
import dmd.expressions.AddrExp;
import dmd.VarDeclaration;
import dmd.expressions.StructLiteralExp;
import dmd.types.TypePointer;
import dmd.types.TypeArray;
import dmd.expressions.ErrorExp;


import std.array;
import dmd.DDMDExtensions;

class PtrExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		super(loc, TOKstar, PtrExp.sizeof, e);
		//    if (e.type)
		//		type = ((TypePointer *)e.type).next;
	}

	this(Loc loc, Expression e, Type t)
	{
		super(loc, TOKstar, PtrExp.sizeof, e);
		type = t;
	}





	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('*');
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}




	override Identifier opId()
	{
		assert(false);
	}
}

