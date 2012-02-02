module dmd.expressions.DollarExp;

import dmd.Identifier;
import dmd.Token;
import dmd.expressions.IdentifierExp;

import dmd.Global;
import dmd.DDMDExtensions;

class DollarExp : IdentifierExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		super(loc, Id.dollar);
	}
}

