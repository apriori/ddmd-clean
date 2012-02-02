module dmd.declarations.PostBlitDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.attribDeclarations.LinkDeclaration;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Type;
import dmd.types.TypeFunction;

import dmd.DDMDExtensions;

class PostBlitDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Loc endloc)
	{
		super(loc, endloc, Id._postblit, STCundefined, null);
	}
	
	this(Loc loc, Loc endloc, Identifier id)
	{
		super(loc, loc, id, STCundefined, null);
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		PostBlitDeclaration dd = new PostBlitDeclaration(loc, endloc, ident);
		return super.syntaxCopy(dd);
	}
	
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("this(this)");
		bodyToCBuffer(buf, hgs);
	}
	
	override void toJsonBuffer(ref Appender!(char[]) buf)
	{
		// intentionally empty
	}

	override bool isVirtual()
	{
		return false;
	}
	
	override bool addPreInvariant()
	{
		return false;
	}
	
	override bool addPostInvariant()
	{
		return (isThis() && vthis && global.params.useInvariants);
	}
	
	override bool overloadInsert(Dsymbol s)
	{
		return false;	   // cannot overload postblits
	}
	
	override void emitComment(Scope sc)
	{
		// intentionally empty
	}

	override PostBlitDeclaration isPostBlitDeclaration() { return this; }
}
