module dmd.dsymbols.DebugSymbol;

import dmd.Global;
import std.format;

import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.Module;
import dmd.HdrGenState;

import std.array;

import dmd.DDMDExtensions;

/* DebugSymbol's happen for statements like:
 *	debug = identifier;
 *	debug = integer;
 */
class DebugSymbol : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

    uint level;

    this(Loc loc, Identifier ident)
	{
		super(ident);
		this.loc = loc;
	}

    this(Loc loc, uint level)
	{
		this.level = level;
		this.loc = loc;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		DebugSymbol ds = new DebugSymbol(loc, ident);
		ds.level = level;
		return ds;
	}

    override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
    {  
        assert (false);
    }
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("debug = ");
		if (ident)
			buf.put(ident.toChars());
		else
			formattedWrite(buf,"%u", level);
		buf.put(";");
		buf.put('\n');
	}
	
    override string kind()
	{
		return "debug";
	}
}
