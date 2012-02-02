module dmd.expressions.ArrayLiteralExp;

import dmd.Global;
import std.format;

import dmd.Expression;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.expressions.IntegerExp;
import dmd.types.TypeSArray;
import dmd.expressions.StringExp;


import std.array;
import dmd.DDMDExtensions;

class ArrayLiteralExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expression[] elements;

	this(Loc loc, Expression[] elements)
	{
		super(loc, TOKarrayliteral, ArrayLiteralExp.sizeof);
		this.elements = elements;
	}

	this(Loc loc, Expression e)
	{
		super(loc, TOKarrayliteral, ArrayLiteralExp.sizeof);
		elements ~= e;
	}

	override Expression syntaxCopy()
	{
		return new ArrayLiteralExp(loc, arraySyntaxCopy(elements));
	}


	override bool isBool(bool result)
	{
		size_t dim = elements ? elements.length : 0;
		return result ? (dim != 0) : (dim == 0);
	}



	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('[');
		argsToCBuffer(buf, elements, hgs);
		buf.put(']');
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		size_t dim = elements ? elements.length : 0;
		formattedWrite(buf,"A%d", dim);	///
		for (size_t i = 0; i < dim; i++)
		{	
			auto e = elements[i];
			e.toMangleBuffer(buf);
		}
	}









}

