module dmd.scopeDsymbols.UnionDeclaration;

import dmd.Global;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.Identifier;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class UnionDeclaration : StructDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Identifier id)
	{
		super(loc, id);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		UnionDeclaration ud;

		if (s)
			ud = cast(UnionDeclaration)s;
		else
			ud = new UnionDeclaration(loc, ident);
		StructDeclaration.syntaxCopy(ud);
		return ud;
	}

	override string kind()
	{
		return "union";
	}

	override UnionDeclaration isUnionDeclaration() { return this; }
}
