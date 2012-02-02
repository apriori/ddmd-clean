module dmd.declarations.DtorDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.types.TypeFunction;
import dmd.Type;
import dmd.HdrGenState;
import std.array;

import dmd.DDMDExtensions;

class DtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Loc endloc)
	{
		super(loc, endloc, Id.dtor, STCundefined, null);
	}

	this(Loc loc, Loc endloc, Identifier id)
	{
		super(loc, endloc, id, STCundefined, null);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		DtorDeclaration dd = new DtorDeclaration(loc, endloc, ident);
		return super.syntaxCopy(dd);
	}
	
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("~this()");
		bodyToCBuffer(buf, hgs);
	}
	
	override void toJsonBuffer(ref Appender!(char[]) buf)
	{
		// intentionally empty
	}
	
	override string kind()
	{
		return "destructor";
	}
	
	override string toChars()
	{
		return "~this";
	}
	
	override bool isVirtual()
	{
		/* This should be FALSE so that dtor's don't get put into the vtbl[],
		 * but doing so will require recompiling everything.
		 */
	version (BREAKABI) {
		return false;
	} else {
		return super.isVirtual();
	}
	}
	
	override bool addPreInvariant()
	{
		return (isThis() && vthis && global.params.useInvariants);
	}
	
	override bool addPostInvariant()
	{
		return false;
	}
	
	override bool overloadInsert(Dsymbol s)
	{
		return false;	   // cannot overload destructors
	}
	
	override void emitComment(Scope sc)
	{
		// intentionally empty
	}

	override DtorDeclaration isDtorDeclaration() { return this; }
}
