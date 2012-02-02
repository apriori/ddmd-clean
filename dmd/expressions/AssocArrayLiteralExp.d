module dmd.expressions.AssocArrayLiteralExp;

import dmd.Global;
import std.format;

import dmd.Expression;
import dmd.InterState;
import dmd.Type;
import dmd.types.TypeAArray;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class AssocArrayLiteralExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expression[] keys;
	Expression[] values;

	this(Loc loc, Expression[] keys, Expression[] values)
	{

		super(loc, TOKassocarrayliteral, this.sizeof);
		assert(keys.length == values.length);
		this.keys = keys;
		this.values = values;	
	}

	override Expression syntaxCopy()
	{
		return new AssocArrayLiteralExp(loc,
				arraySyntaxCopy(keys), arraySyntaxCopy(values));
	}


	override bool isBool(bool result)
	{
		size_t dim = keys.length;
		return result ? (dim != 0) : (dim == 0);
	}



	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('[');
		for (size_t i = 0; i < keys.length; i++)
		{	auto key = keys[i];
			auto value = values[i];

			if (i)
				buf.put(',');
			expToCBuffer(buf, hgs, key, PREC_assign);
			buf.put(':');
			expToCBuffer(buf, hgs, value, PREC_assign);
		}
		buf.put(']');
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		size_t dim = keys.length;
		formattedWrite(buf,"A%u", dim);
		for (size_t i = 0; i < dim; i++)
		{	auto key = keys[i];
			auto value = values[i];

			key.toMangleBuffer(buf);
			value.toMangleBuffer(buf);
		}
	}









}
