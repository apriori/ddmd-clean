module dmd.scopeDsymbols.AnonymousAggregateDeclaration;

import dmd.Global;
import dmd.scopeDsymbols.AggregateDeclaration;

import dmd.DDMDExtensions;

class AnonymousAggregateDeclaration : AggregateDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this()
    {
		super(Loc(0), null);
    }

    AnonymousAggregateDeclaration isAnonymousAggregateDeclaration() { return this; }
}
