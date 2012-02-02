module dmd.dsymbols.VersionSymbol;

import dmd.Global;
import std.format;

import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Module;
import dmd.conditions.VersionCondition;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;

import std.array;
import dmd.DDMDExtensions;

/* VersionSymbol's happen for statements like:
 *	version = identifier;
 *	version = integer;
 */
class VersionSymbol : Dsymbol
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
		super();

		this.level = level;
		this.loc = loc;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		VersionSymbol ds = new VersionSymbol(loc, ident);
		ds.level = level;
		return ds;
	}

    override bool addMember(Scope sc, ScopeDsymbol s, bool memnum)
	{
		//printf("VersionSymbol::addMember('%s') %s\n", sd->toChars(), toChars());

		// Do not add the member to the symbol table,
		// just make sure subsequent debug declarations work.
		Module m = s.isModule();
		if (ident)
		{
			VersionCondition.checkPredefined(loc, ident.toChars());
			if (!m)
				error("declaration must be at module level");
			else
			{
				if ( ident.toChars in m.versionidsNot )
					error("defined after use");
				m.versionids[ ident.toChars() ] = true;
			}
		}
		else
		{
			if (!m)
				error("level declaration must be at module level");
			else
				m.versionlevel = level;
		}

		return false;
	}


    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("version = ");
		if (ident)
			buf.put(ident.toChars());
		else
			formattedWrite(buf,"%u", level);
		buf.put(";");
		buf.put('\n');
	}

    override string kind()
	{
		return "version";
	}
}
