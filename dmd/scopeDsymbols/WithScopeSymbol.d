module dmd.scopeDsymbols.WithScopeSymbol;

import dmd.Global;
import dmd.ScopeDsymbol;
import dmd.statements.WithStatement;
import dmd.Identifier;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class WithScopeSymbol : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    WithStatement withstate;

    this(WithStatement withstate)
	{
		this.withstate = withstate;
	}
	

    override WithScopeSymbol isWithScopeSymbol() { return this; }
}
