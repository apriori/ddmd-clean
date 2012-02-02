module dmd.dsymbols.OverloadSet;
// This module seems stupid. Find somewhere better for it I think

import dmd.Dsymbol;

import dmd.DDMDExtensions;

class OverloadSet : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Dsymbol[] a;

    this()
	{
	}
	
    void push(Dsymbol s)
	{
		a ~= s;
	}
	
    override OverloadSet isOverloadSet() { return this; }

    override string kind()
	{
		return "overloadset";
	}
}
