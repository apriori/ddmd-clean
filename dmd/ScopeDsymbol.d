module dmd.ScopeDsymbol;

import dmd.Global;
import dmd.Dsymbol;
import dmd.Declaration;
import dmd.dsymbols.OverloadSet;
import dmd.dsymbols.Import;
import dmd.Identifier;
import dmd.declarations.FuncDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Scope;
import dmd.Type;

import dmd.DDMDExtensions;

import std.stdio : writef;

class ScopeDsymbol : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));
	
    Dsymbol[] members;		// all Dsymbol's in this scope
    Dsymbol[string] symtab;	// members[] sorted into table

    ScopeDsymbol[] imports;		// imported ScopeDsymbol's
    PROT* prots;	// array of PROT, one for each import

    this()
	{
		// do nothing
	}
	
    this(Identifier id)
	{
		super(id);
	}
	
    Dsymbol syntaxCopy(Dsymbol s)
	{
	    //printf("ScopeDsymbol.syntaxCopy('%s')\n", toChars());

	    ScopeDsymbol sd;
	    if (s)
		sd = cast(ScopeDsymbol)s;
	    else
		sd = new ScopeDsymbol(ident);
	    sd.members = arraySyntaxCopy(members);
	    return sd;
	}
	
    bool isOverloadable()
    {
        return bool.init; 
    }
	
    void addLocalClass(ClassDeclaration[] aclasses) { assert(false); }
    bool isBaseOf(ClassDeclaration cd, int* poffset) { assert(false); }


    string mangle()
    {
        assert (false);
    }
    PROT prot()
    {
        assert (false);
    }
    bool isDeprecated()		// is aggregate deprecated?
    {
        assert (false);
    }
    Type getType()
    {
        assert (false);
    }

    int isforwardRef()
	{
		return (members is null);
	}
	
    void defineRef(Dsymbol s)
	{
		ScopeDsymbol ss = s.isScopeDsymbol();
		members = ss.members;
		ss.members = null;
	}

    static void multiplyDefined(Loc loc, Dsymbol s1, Dsymbol s2)
	{
static if (false) {
		printf("ScopeDsymbol::multiplyDefined()\n");
		printf("s1 = %p, '%s' kind = '%s', parent = %s\n", s1, s1.toChars(), s1.kind(), s1.parent ? s1.parent.toChars() : "");
		printf("s2 = %p, '%s' kind = '%s', parent = %s\n", s2, s2.toChars(), s2.kind(), s2.parent ? s2.parent.toChars() : "");
}
		if (loc.filename)
		{
			.error(loc, "%s at %s conflicts with %s at %s",
			s1.toPrettyChars(),
			s1.locToChars(),
			s2.toPrettyChars(),
			s2.locToChars());
		}
		else
		{
			s1.error(loc, "conflicts with %s %s at %s", s2.kind(), s2.toPrettyChars(), s2.locToChars());
		}
	}

    Dsymbol nameCollision(Dsymbol s)
	{
		assert(false);
	}
	
    string kind()
	{
		assert(false);
	}

	/*******************************************
	 * Look for member of the form:
	 *	const(MemberInfo)[] getMembers(string);
	 * Returns NULL if not found
	 */
    FuncDeclaration findGetMembers() { assert(false,"zd cut"); }

    Dsymbol symtabInsert(Dsymbol s)
    {
      if ( s.ident.string_ in symtab ) return null;
      symtab[s.ident.string_] = s;
      return s; 
    }

    void emitMemberComments(Scope sc)
	{
		assert(false);
	}


   // static Dsymbol getNth(Dsymbol[] members, size_t nth, size_t* pn = null) { assert(false); }
    override ScopeDsymbol isScopeDsymbol() { return this; }
}
