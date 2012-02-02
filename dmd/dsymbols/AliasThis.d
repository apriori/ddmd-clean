module dmd.dsymbols.AliasThis;

import dmd.Global;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.scopeDsymbols.AggregateDeclaration;

import std.array;
import dmd.DDMDExtensions;

class AliasThis : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

   // alias Identifier this;
    Identifier ident;

    this(Loc loc, Identifier ident)
	{
		super(null);		// it's anonymous (no identifier)
		this.loc = loc;
		this.ident = ident;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		/* Since there is no semantic information stored here,
		 * we don't need to copy it.
		 */
		return this;
	}
	
	
    override string kind()
	{
		assert(false);
	}
		
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
	
    AliasThis isAliasThis() { return this; }
}
