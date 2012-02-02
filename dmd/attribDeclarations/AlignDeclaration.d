module dmd.attribDeclarations.AlignDeclaration;

import dmd.AttribDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class AlignDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    uint salign;

    this(uint sa, Dsymbol[] decl)
	{
		super(decl);
		salign = sa;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(false);
	}
	
    override void setScope(Scope sc)
	{
		//printf("\tAlignDeclaration::setScope '%s'\n",toChars());
		if (decl)
		{
			setScopeNewSc(sc, sc.stc, sc.linkage, sc.protection, sc.explicitProtection, salign);
		}
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}
