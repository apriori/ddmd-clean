module dmd.attribDeclarations.ProtDeclaration;

import dmd.AttribDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class ProtDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    PROT protection;

    this(PROT p, Dsymbol[] decl)
	{
		super(decl);

		protection = p;
		//printf("decl = %p\n", decl);
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		ProtDeclaration pd;

		assert(!s);
		pd = new ProtDeclaration(protection, Dsymbol.arraySyntaxCopy(decl));
		return pd;
	}

	override void importAll(Scope sc)
	{
		Scope newsc = sc;
		if (sc.protection != protection || sc.explicitProtection != 1)
		{
			// create new one for changes
			newsc = sc.clone();
			newsc.flags &= ~SCOPEfree;
			newsc.protection = protection;
			newsc.explicitProtection = 1;
		}

		foreach (Dsymbol s; decl)
			s.importAll(newsc);

		if (newsc !is sc)
			newsc.pop();
	}

    override void setScope(Scope sc)
	{
		if (decl)
		{
			setScopeNewSc(sc, sc.stc, sc.linkage, protection, 1, sc.structalign);
		}
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

    static void protectionToCBuffer(ref Appender!(char[]) buf, PROT protection)
	{
		assert(false);
	}
}
