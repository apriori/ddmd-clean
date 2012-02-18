module dmd.AttribDeclaration;

import dmd.Global;
import dmd.Token;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Identifier;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.Declaration;
import dmd.Condition;
import dmd.HdrGenState;

import std.array;

class AttribDeclaration : Dsymbol
{
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

class AlignDeclaration : AttribDeclaration
{
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

class AnonDeclaration : AttribDeclaration
{
	int isunion;
	int sem = 0;			// 1 if successful semantic()

	this(Loc loc, int isunion, Dsymbol[] decl)
	{
		super(decl);
		this.loc = loc;
		this.isunion = isunion;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		AnonDeclaration ad;

		assert(!s);
		ad = new AnonDeclaration(loc, isunion, Dsymbol.arraySyntaxCopy(decl));
		return ad;
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

	override string kind()
	{
		assert(false);
	}
}


class CompileDeclaration : AttribDeclaration
{
    Expression exp;
    ScopeDsymbol sd;
    bool compiled;

	this(Loc loc, Expression exp)
	{

		super(null);
		//printf("CompileDeclaration(loc = %d)\n", loc.linnum);
		this.loc = loc;
		this.exp = exp;
		this.sd = null;
		this.compiled = false;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("CompileDeclaration.syntaxCopy('%s')\n", toChars());
		CompileDeclaration sc = new CompileDeclaration(loc, exp.syntaxCopy());
		return sc;
	}

   override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
   {
       assert (false);
   }


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("mixin(");
		exp.toCBuffer(buf, hgs);
		buf.put(");");
		buf.put('\n');
	}
}

class ConditionalDeclaration : AttribDeclaration
{
    Condition condition;
    Dsymbol[] elsedecl;	// array of Dsymbol's for else block

    this(Condition condition, Dsymbol[] decl, Dsymbol[] elsedecl)
	{
		super(decl);
		//printf("ConditionalDeclaration.ConditionalDeclaration()\n");
		this.condition = condition;
		this.elsedecl = elsedecl;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    ConditionalDeclaration dd;
	
	    assert(!s);
	    dd = new ConditionalDeclaration(condition.syntaxCopy(),
		Dsymbol.arraySyntaxCopy(decl),
		Dsymbol.arraySyntaxCopy(elsedecl));
	    return dd;
	}
	
    override bool oneMember(Dsymbol ps)
	{
		//printf("ConditionalDeclaration.oneMember(), inc = %d\n", condition.inc);
		if (condition.inc)
		{
			auto d = condition.include(null, null) ? decl : elsedecl;
			return Dsymbol.oneMembers(d, ps);
		}
		ps = null;
		return true;
	}
	
    override void emitComment(Scope sc)
	{
	    //printf("ConditionalDeclaration.emitComment(sc = %p)\n", sc);
	    if (condition.inc)
	    {
	    	AttribDeclaration.emitComment(sc);
	    }
	    else if (sc.docbuf.data)
	    {
			/* If generating doc comment, be careful because if we're inside
			 * a template, then include(NULL, NULL) will fail.
			 */
			auto d = decl ? decl : elsedecl;
			foreach(s; d)
			    s.emitComment(sc);
	    }
	}
	
	// Decide if 'then' or 'else' code should be included

    override Dsymbol[] include(Scope sc, ScopeDsymbol sd)
	{
		//printf("ConditionalDeclaration.include()\n");
		assert(condition);
		return condition.include(sc, sd) ? decl : elsedecl;
	}
	
    override void addComment(string comment)
	{
		/* Because addComment is called by the parser, if we called
		 * include() it would define a version before it was used.
		 * But it's no problem to drill down to both decl and elsedecl,
		 * so that's the workaround.
		 */

		if (comment)
		{
			auto d = decl;

			for (int j = 0; j < 2; j++)
			{
				if (d)
				{
					foreach(s; d)
						//printf("ConditionalDeclaration::addComment %s\n", s.toChars());
						s.addComment(comment);
				}
				d = elsedecl;
			}
		}
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    condition.toCBuffer(buf, hgs);
	    if (decl || elsedecl)
	    {
			buf.put('\n');
			buf.put('{');
			buf.put('\n');
			if (decl)
			{
			    foreach (Dsymbol s; decl)
			    {
					buf.put("    ");
					s.toCBuffer(buf, hgs);
			    }
			}
			buf.put('}');
			if (elsedecl)
			{
			    buf.put('\n');
			    buf.put("else");
			    buf.put('\n');
			    buf.put('{');
			    buf.put('\n');
			    foreach (Dsymbol s; elsedecl)
			    {
					buf.put("    ");
					s.toCBuffer(buf, hgs);
			    }
			    buf.put('}');
			}
	    }
	    else
		buf.put(':');
	    buf.put('\n');
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

    override void importAll(Scope sc)
    {
        Dsymbol[] d = include(sc, null);

        //writef("\tConditionalDeclaration::importAll '%s', d = %p\n",toChars(), d);
        if (d)
        {
           foreach (s; d)
               s.importAll(sc);
        }
    }
    
    override void setScope(Scope sc)
    {
		Dsymbol[] d = include(sc, null);
		
		//writef("\tConditionalDeclaration::setScope '%s', d = %p\n",toChars(), d);
		if (d)
		{
			foreach (s; d)
				s.setScope(sc);
		}

    }
}

class LinkDeclaration : AttribDeclaration
{
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

class PragmaDeclaration : AttribDeclaration
{
    Expression[] args;		// array of Expression's

    this(Loc loc, Identifier ident, Expression[] args, Dsymbol[] decl)
	{
		super(decl);
		this.loc = loc;
		this.ident = ident;
		this.args = args;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("PragmaDeclaration.syntaxCopy(%s)\n", toChars());
		PragmaDeclaration pd;

		assert(!s);
		pd = new PragmaDeclaration(loc, ident, Expression.arraySyntaxCopy(args), Dsymbol.arraySyntaxCopy(decl));
		return pd;
	}
	
	
	
    override bool oneMember(Dsymbol* ps)
	{
		*ps = null;
		return true;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
	
    override string kind()
	{
		assert(false);
	}
	
}

class ProtDeclaration : AttribDeclaration
{
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

class StaticIfDeclaration : ConditionalDeclaration
{
	ScopeDsymbol sd;
	int addisdone;

	this(Condition condition, Dsymbol[] decl, Dsymbol[] elsedecl)
	{
		super(condition, decl, elsedecl);
		//printf("StaticIfDeclaration::StaticIfDeclaration()\n");
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)
	{
		StaticIfDeclaration dd;

		assert(!s);
		dd = new StaticIfDeclaration(condition.syntaxCopy(),
		Dsymbol.arraySyntaxCopy(decl),
		Dsymbol.arraySyntaxCopy(elsedecl));
		return dd;
	}

	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		//printf("StaticIfDeclaration.addMember() '%s'\n",toChars());
		/* This is deferred until semantic(), so that
		 * expressions in the condition can refer to declarations
		 * in the same scope, such as:
		 *
		 * template Foo(int i)
		 * {
		 *	 const int j = i + 1;
		 *	 static if (j == 3)
		 *		 const int k;
		 * }
		 */
		this.sd = sd;
		bool m = false;

		if (!memnum)
		{	
			m = AttribDeclaration.addMember(sc, sd, memnum);
			addisdone = 1;
		}
		return m;
	}
	
	override void importAll(Scope sc)
	{
		// do not evaluate condition before semantic pass
	}

	override void setScope(Scope sc)
	{
		// do not evaluate condition before semantic pass
	}


	override string kind()
	{
		assert(false);
	}
}

class StorageClassDeclaration: AttribDeclaration
{
    StorageClass stc;

    this(StorageClass stc, Dsymbol[] decl)
	{
		super(decl);
		
		this.stc = stc;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		StorageClassDeclaration scd;

		assert(!s);
		scd = new StorageClassDeclaration(stc, Dsymbol.arraySyntaxCopy(decl));
		return scd;
	}
	
    override void setScope(Scope sc)
	{
		if (decl)
		{
			StorageClass scstc = sc.stc;

			/* These sets of storage classes are mutually exclusive,
			 * so choose the innermost or most recent one.
			 */
			if (stc & (STCauto | STCscope | STCstatic | STCextern | STCmanifest))
				scstc &= ~(STCauto | STCscope | STCstatic | STCextern | STCmanifest);
			if (stc & (STCauto | STCscope | STCstatic | STCtls | STCmanifest | STCgshared))
				scstc &= ~(STCauto | STCscope | STCstatic | STCtls | STCmanifest | STCgshared);
			if (stc & (STCconst | STCimmutable | STCmanifest))
				scstc &= ~(STCconst | STCimmutable | STCmanifest);
			if (stc & (STCgshared | STCshared | STCtls))
				scstc &= ~(STCgshared | STCshared | STCtls);
			if (stc & (STCsafe | STCtrusted | STCsystem))
				scstc &= ~(STCsafe | STCtrusted | STCsystem);
			scstc |= stc;

			setScopeNewSc(sc, scstc, sc.linkage, sc.protection, sc.explicitProtection, sc.structalign);
		}
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

    static void stcToCBuffer(ref Appender!(char[]) buf, StorageClass stc)
	{
		struct SCstring
		{
			StorageClass stc;
			TOK tok;
		};

		enum SCstring[] table =
		[
			{ STCauto,         TOKauto },
			{ STCscope,        TOKscope },
			{ STCstatic,       TOKstatic },
			{ STCextern,       TOKextern },
			{ STCconst,        TOKconst },
			{ STCfinal,        TOKfinal },
			{ STCabstract,     TOKabstract },
			{ STCsynchronized, TOKsynchronized },
			{ STCdeprecated,   TOKdeprecated },
			{ STCoverride,     TOKoverride },
			{ STClazy,         TOKlazy },
			{ STCalias,        TOKalias },
			{ STCout,          TOKout },
			{ STCin,           TOKin },
			{ STCimmutable,    TOKimmutable },
			{ STCshared,       TOKshared },
			{ STCnothrow,      TOKnothrow },
			{ STCpure,         TOKpure },
			{ STCref,          TOKref },
			{ STCtls,          TOKtls },
			{ STCgshared,      TOKgshared },
			{ STCproperty,     TOKat },
			{ STCsafe,         TOKat },
			{ STCtrusted,      TOKat },
			{ STCdisable,      TOKat },
		];

		for (int i = 0; i < table.length; i++)
		{
			if (stc & table[i].stc)
			{
				TOK tok = table[i].tok;
				if (tok == TOKat)
				{	Identifier id;

					if (stc & STCproperty)
						id = Id.property;
					else if (stc & STCsafe)
						id = Id.safe;
					else if (stc & STCtrusted)
						id = Id.trusted;
					else if (stc & STCdisable)
						id = Id.disable;
					else
						assert(0);
					buf.put(id.toChars());
				}
				else
					buf.put(Token.toChars(tok));
				buf.put(' ');
			}
		}
	}
}
