module dmd.expressions.IntegerExp;

import dmd.Global;
import std.format;
import std.ascii;
import std.conv;

import dmd.Expression;
import dmd.types.TypeEnum;
import dmd.types.TypeTypedef;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;


import std.stdio;

import std.array;
import dmd.DDMDExtensions;

class IntegerExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	ulong value;

	this(Loc loc, ulong value, Type type)
	{
		super(loc, TOKint64, IntegerExp.sizeof);
		
		//printf("IntegerExp(value = %lld, type = '%s')\n", value, type ? type.toChars() : "");
		if (type && !type.isscalar())
		{
			//printf("%s, loc = %d\n", toChars(), loc.linnum);
			error("integral constant must be scalar type, not %s", type.toChars());
			type = Type.terror;
		}
		this.type = type;
		this.value = value;
	}

	this(ulong value)
	{
		super(Loc(0), TOKint64, IntegerExp.sizeof);
		this.type = Type.tint32;
		this.value = value;
	}

	//override bool equals(Object o) { assert (false,"zd cut"); }



	override string toChars()
	{
static if (true) {
		return Expression.toChars();
} else {
		static char buffer[value.sizeof * 3 + 1];
		int len = sprintf(buffer.ptr, "%jd", value);
		return buffer[0..len].idup;
}
	}



	override ulong toInteger()
	{
		Type t;

		t = type;
		while (t)
		{
			switch (t.ty)
			{
				case Tbit:
				case Tbool:	value = (value != 0);		break;
				case Tint8:	value = cast(byte)  value;	break;
				case Tchar:
				case Tuns8:	value = cast(ubyte) value;	break;
				case Tint16:	value = cast(short) value;	break;
				case Twchar:
				case Tuns16:	value = cast(ushort)value;	break;
				case Tint32:	value = cast(int)   value;	break;
				case Tdchar:
				case Tuns32:	value = cast(uint)  value;	break;
				case Tint64:	value = cast(long)  value;	break;
				case Tuns64:	value = cast(ulong) value;	break;
				case Tpointer:
						if (PTRSIZE == 4)
							value = cast(uint) value;
						else if (PTRSIZE == 8)
							value = cast(ulong) value;
						else
							assert(0);
						break;

				case Tenum:
				{
					TypeEnum te = cast(TypeEnum)t;
					t = te.sym.memtype;
					continue;
				}

				case Ttypedef:
				{
					TypeTypedef tt = cast(TypeTypedef)t;
					t = tt.sym.basetype;
					continue;
				}

				default:
					/* This can happen if errors, such as
					 * the type is painted on like in fromConstInitializer().
					 */
					if (!global.errors)
					{
						writef("%s %p\n", type.toChars(), type);
						assert(0);
					}
					break;

			}
			break;
		}
		return value;
	}


	override real toImaginary()
	{
		assert(false);
	}


	override int isConst()
	{
		return 1;
	}

	override bool isBool(bool result)
	{
        int r = toInteger() != 0;
        return cast(bool)(result ? r : !r);
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		long v = toInteger();

		if (type)
		{	
			Type t = type;

		  L1:
			switch (t.ty)
			{
				case Tenum:
				{   
					TypeEnum te = cast(TypeEnum)t;
					formattedWrite(buf,"cast(%s)", te.sym.toChars());
					t = te.sym.memtype;
					goto L1;
				}

				case Ttypedef:
				{	
					TypeTypedef tt = cast(TypeTypedef)t;
					formattedWrite(buf,"cast(%s)", tt.sym.toChars());
					t = tt.sym.basetype;
					goto L1;
				}

				case Twchar:	// BUG: need to cast(wchar)
				case Tdchar:	// BUG: need to cast(dchar)
					if (cast(ulong)v > 0xFF)
					{
						 formattedWrite(buf,"'\\U%08x'", v);
						 break;
					}
				case Tchar:
					if (v == '\'')
						buf.put("'\\''");
					else if (isPrintable( to!dchar(v) ) && v != '\\')
						formattedWrite(buf,"'%s'", cast(char)v);	/// !
					else
						formattedWrite(buf,"'\\x%02x'", cast(int)v);
					break;

				case Tint8:
					buf.put("cast(byte)");
					goto L2;

				case Tint16:
					buf.put("cast(short)");
					goto L2;

				case Tint32:
				L2:
					formattedWrite(buf,"%d", cast(int)v);
					break;

				case Tuns8:
					buf.put("cast(ubyte)");
					goto L3;

				case Tuns16:
					buf.put("cast(ushort)");
					goto L3;

				case Tuns32:
				L3:
					formattedWrite(buf,"%du", cast(uint)v);
					break;

				case Tint64:
					//buf.printf("%jdL", v);
					formattedWrite(buf,"%sL", v);
					break;

				case Tuns64:
				L4:
					//buf.printf("%juLU", v);
					formattedWrite(buf,"%sLU", v);
					break;

				case Tbit:
				case Tbool:
					buf.put(v ? "true" : "false");
					break;

				case Tpointer:
					buf.put("cast(");
					buf.put(t.toChars());
					buf.put(')');
					if (PTRSIZE == 4)
						goto L3;
					else if (PTRSIZE == 8)
						goto L4;
					else
						assert(0);

				default:
					/* This can happen if errors, such as
					 * the type is painted on like in fromConstInitializer().
					 */
					if (!global.errors)
					{
						debug {
							writef("%s\n", t.toChars());
						}
						assert(0);
					}
					break;
			}
		}
		else if (v & 0x8000000000000000L)
			formattedWrite(buf,"0x%jx", v);
		else
			formattedWrite(buf,"%jd", v);
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
	    if (cast(long)value < 0)
		formattedWrite(buf,"N%d", -value);
	    else
		formattedWrite(buf,"%d", value);
	}



}

