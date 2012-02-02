module dmd.expressions.StringExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.types.TypeSArray;
import dmd.expressions.CastExp;
import dmd.types.TypeDArray;
import dmd.Type;
import dmd.Token;
import dmd.Module;
import dmd.Scope;
import dmd.expressions.StringExp;
import dmd.HdrGenState;

import dmd.Dsymbol : isExpression;

import std.array;
import dmd.DDMDExtensions;

class StringExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	string string_;	// char, wchar, or dchar data
    size_t len;		// number of chars, wchars, or dchars
    ubyte sz;	// 1: char, 2: wchar, 4: dchar
    ubyte committed = 0;	// !=0 if type is committed
    char postfix;	// 'c', 'w', 'd'

	this(Loc loc, string s)
	{
		this(loc, s, 0);
	}

	this(Loc loc, string s, char postfix)
	{
		super(loc, TOKstring, StringExp.sizeof);
		
		this.string_ = s;
		this.len = s.length;
		this.sz = 1;
		this.committed = 0;
		this.postfix = postfix;
	}

	override string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		toCBuffer(buf, hgs);
		return buf.data.idup;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('"');
		foreach ( c; string_ )
		{
			switch (c)
			{
            import std.ascii;
            import std.format;
				case '"':
				case '\\':
				if (!hgs.console)
					buf.put('\\');
				default:
				if (c <= 0xFF)
				{  
					if (c <= 0x7F && (isPrintable(c) || hgs.console))
						buf.put(c);
					else
						formattedWrite(buf,"\\x%02x", c);
				}
				else if (c <= 0xFFFF)
					formattedWrite(buf,"\\x%02x\\x%02x", c & 0xFF, c >> 8);
				else
					formattedWrite(buf,"\\x%02x\\x%02x\\x%02x\\x%02x", c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, c >> 24);
				break;
			}
		}
		buf.put('"');
		if (postfix)
			buf.put(postfix);
	}
}

