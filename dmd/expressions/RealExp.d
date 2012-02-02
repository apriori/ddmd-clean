module dmd.expressions.RealExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.Token;
import dmd.Scope;
import dmd.Type;
import dmd.HdrGenState;

import std.stdio;
import std.format;
import std.string;
import std.array;
import std.conv;

import dmd.DDMDExtensions;

class RealExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	real value;

	this(Loc loc, real value, Type type)
	{
		super(loc, TOKfloat64, RealExp.sizeof);
		//printf("RealExp.RealExp(%Lg)\n", value);
		this.value = value;
		this.type = type;
	}

	//override bool equals(Object o) { assert (false,"zd cut"); }



	override string toChars()
	{
		return format(type.isimaginary() ? "%gi" : "%g", value);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		// TODO zd ... Yeah, it's approximate, maybe later
      formattedWrite( buf, "%s", to!string(value) );
      //floatToBuffer(buf, type, value);
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
   {
       assert (false);
   }
}
