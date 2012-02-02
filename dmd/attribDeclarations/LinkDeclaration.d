module dmd.attribDeclarations.LinkDeclaration;

import dmd.Global;
import dmd.AttribDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class LinkDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    LINK linkage;

    this(LINK p, Dsymbol[] decl)
	{
		super(decl);
		//printf("LinkDeclaration(linkage = %d, decl = %p)\n", p, decl);
		linkage = p;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(false);
	}

    override void setScope(Scope sc)
	{
		//printf("LinkDeclaration::setScope(linkage = %d, decl = %p)\n", linkage, decl);
		if (decl)
		{
			setScopeNewSc(sc, sc.stc, linkage, sc.protection, sc.explicitProtection, sc.structalign);
		}
	}
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
	
    override string toChars()
	{
		assert(false);
	}
}
