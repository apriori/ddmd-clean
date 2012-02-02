module dmd.conditions.DVCondition;

import dmd.Global;
import dmd.Condition;
import dmd.Identifier;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.Module;


class DVCondition : Condition
{
    uint level;
    Identifier ident;
    Module mod;

    this(Module mod, uint level, Identifier ident)
	{
		super(Loc(0));
		this.mod = mod;
		this.level = level;
		this.ident = ident;
	}

    override Condition syntaxCopy()
	{
		return this;	// don't need to copy
	}

    bool include(Scope sc, ScopeDsymbol s) { assert(false); }

    
}
