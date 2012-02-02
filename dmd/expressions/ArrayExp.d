module dmd.expressions.ArrayExp;

import dmd.Global;
import dmd.Expression;
import dmd.Identifier;
import dmd.expressions.UnaExp;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.Type;
import dmd.expressions.IndexExp;


import std.array;
import dmd.DDMDExtensions;

class ArrayExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expression[] arguments;

	this(Loc loc, Expression e1, Expression[] args)
	{
		super(loc, TOKarray, ArrayExp.sizeof, e1);
		arguments = args;
	}

	override Expression syntaxCopy()
	{
	    return new ArrayExp(loc, e1.syntaxCopy(), arraySyntaxCopy(arguments));
	}




	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put('[');
		argsToCBuffer(buf, arguments, hgs);
		buf.put(']');
	}


	override Identifier opId()
	{
		return Id.index;
	}



}

