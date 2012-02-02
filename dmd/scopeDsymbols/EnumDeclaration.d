module dmd.scopeDsymbols.EnumDeclaration;

import dmd.Global;
import dmd.ScopeDsymbol;
import dmd.expressions.AddExp;
import dmd.Type;
import dmd.expressions.CmpExp;
import dmd.expressions.IntegerExp;
import dmd.expressions.EqualExp;
import dmd.Token;
import dmd.Expression;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Module;
import dmd.types.TypeEnum;
import dmd.dsymbols.EnumMember;
import dmd.Lexer;


import std.stdio : writef;

import dmd.DDMDExtensions;

class EnumDeclaration : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

   /* enum ident : memtype { ... }
     */
    Type type;			// the TypeEnum
    Type memtype;		// type of the members
    
    Expression maxval;
    Expression minval;
    Expression defaultval;	// default initializer
	bool isdeprecated = false;
	bool isdone = false;	// 0: not done
							// 1: semantic() successfully completed
    
    this(Loc loc, Identifier id, Type memtype)
	{
		super(id);
		this.loc = loc;
		type = new TypeEnum(this);
		this.memtype = memtype;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    Type t = null;
	    if (memtype)
		t = memtype.syntaxCopy();

	    EnumDeclaration ed;
	    if (s)
	    {	ed = cast(EnumDeclaration)s;
		ed.memtype = t;
	    }
	    else
		ed = new EnumDeclaration(loc, ident, t);
	    ScopeDsymbol.syntaxCopy(ed);
	    return ed;
	}
	
	
    override bool oneMember(Dsymbol ps)
	{
    		if (isAnonymous())
			return Dsymbol.oneMembers(members, ps);
	    	return Dsymbol.oneMember(ps);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    buf.put("enum ");
	    if (ident)
	    {	buf.put(ident.toChars());
		buf.put(' ');
	    }
	    if (memtype)
	    {
		buf.put(": ");
		memtype.toCBuffer(buf, null, hgs);
	    }
	    if (!members)
	    {
		buf.put(';');
		buf.put('\n');
		return;
	    }
	    buf.put('\n');
	    buf.put('{');
	    buf.put('\n');
	    foreach(Dsymbol s; members)
	    {
		EnumMember em = s.isEnumMember();
		if (!em)
		    continue;
		//buf.put("    ");
		em.toCBuffer(buf, hgs);
		buf.put(',');
		buf.put('\n');
	    }
	    buf.put('}');
	    buf.put('\n');
	}
	
    override Type getType()
	{
		return type;
	}
	
    override string kind()
	{
		return "enum";
	}
	
    override bool isDeprecated()			// is Dsymbol deprecated?
	{
		return isdeprecated;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

    override EnumDeclaration isEnumDeclaration() { return this; }

	
    void toDebug()
	{
		assert(false);
	}
	
    //Symbol* sinit;

};
