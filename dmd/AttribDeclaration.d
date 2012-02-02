module dmd.AttribDeclaration;

import dmd.Global;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.Declaration;
import dmd.HdrGenState;
import dmd.scopeDsymbols.ClassDeclaration;
import std.array;

import dmd.DDMDExtensions;

class AttribDeclaration : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Dsymbol[] decl;	// array of Dsymbol's

    this(Dsymbol[] decl)
	{

		this.decl = decl;
	}
	
    Dsymbol[] include(Scope sc, ScopeDsymbol sd)
	{
		return decl;
	}
	
    override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		bool m = false;
		auto d = include(sc, sd);

		if (d)
		{
            foreach(s; d)
                m |= s.addMember(sc, sd, m | memnum);
		}

		return m;
	}


	Dsymbol toAlias() { assert(false); }

	void importAll(Scope sc) { assert(false); }

    bool isBaseOf(ClassDeclaration cd, int* poffset) { assert(false); }


    void setScope(Scope sc)
    {
    }
    Dsymbol syntaxCopy(Dsymbol s)
    {
        assert(false);
    }
	
    void setScopeNewSc(Scope sc, StorageClass stc, LINK linkage, PROT protection, int explicitProtection, uint structalign)
	{
		if (decl)
		{
			Scope newsc = sc;
			if (stc != sc.stc || linkage != sc.linkage || protection != sc.protection || explicitProtection != sc.explicitProtection || structalign != sc.structalign)
			{
				// create new one for changes
				newsc = sc.clone();				
				newsc.flags &= ~SCOPEfree;
				newsc.stc = stc;
				newsc.linkage = linkage;
				newsc.protection = protection;
				newsc.explicitProtection = explicitProtection;
				newsc.structalign = structalign;
			}
			foreach(Dsymbol s; decl)
				s.setScope(newsc);	// yes, the only difference from semanticNewSc()
			if (newsc != sc)
			{
				sc.offset = newsc.offset;
				newsc.pop();
			}
		}
	}
	
    override void addComment(string comment)
	{
		if (comment !is null)
		{
			auto d = include(null, null);
			if (d)
			{
				foreach(s; d)
				{  
					//printf("AttribDeclaration::addComment %s\n", s.toChars());
					s.addComment(comment);
				}
			}
		}
	}
	
    override void emitComment(Scope sc)
	{
		assert(false);
	}
	
    override string kind()
	{
		assert(false);
	}
	
    override bool oneMember(Dsymbol ps)
	{
		auto d = include(null, null);

		return Dsymbol.oneMembers(d, ps);
	}
	
	
    override void checkCtorConstInit()
	{
		auto d = include(null, null);
		if (d)
		{
			foreach(s; d)
				s.checkCtorConstInit();
		}
	}
	
    override void addLocalClass(ClassDeclaration[] aclasses)
	{
		auto d = include(null, null);
		if (d)
		{
			foreach(s; d)
				s.addLocalClass(aclasses);
		}
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
    
	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }
    	
    override AttribDeclaration isAttribDeclaration() { return this; }

	
}
