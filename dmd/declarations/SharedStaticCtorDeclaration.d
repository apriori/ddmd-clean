module dmd.declarations.SharedStaticCtorDeclaration;

import dmd.Global;
import dmd.declarations.StaticCtorDeclaration;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.declarations.FuncDeclaration;

import dmd.DDMDExtensions;

class SharedStaticCtorDeclaration : StaticCtorDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
		super(loc, endloc, "_sharedStaticCtor");
	}
	
    Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		SharedStaticCtorDeclaration scd = new SharedStaticCtorDeclaration(loc, endloc);
		return FuncDeclaration.syntaxCopy(scd);
	}
	
    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("shared ");
		StaticCtorDeclaration.toCBuffer(buf, hgs);
	}

    SharedStaticCtorDeclaration isSharedStaticCtorDeclaration() { return this; }
}
