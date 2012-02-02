module dmd.declarations.SharedStaticDtorDeclaration;

import dmd.Global;
import dmd.declarations.StaticDtorDeclaration;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.declarations.FuncDeclaration;

import dmd.DDMDExtensions;

class SharedStaticDtorDeclaration : StaticDtorDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
	    super(loc, endloc, "_sharedStaticDtor");
	}
	
    Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		SharedStaticDtorDeclaration sdd = new SharedStaticDtorDeclaration(loc, endloc);
		return FuncDeclaration.syntaxCopy(sdd);
	}
	
    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    if (!hgs.hdrgen)
		{
			buf.put("shared ");
			StaticDtorDeclaration.toCBuffer(buf, hgs);
		}
	}

    SharedStaticDtorDeclaration isSharedStaticDtorDeclaration() { return this; }
}
