module dmd.declarations.InvariantDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.types.TypeFunction;
import dmd.Type;
import dmd.scopeDsymbols.AggregateDeclaration;

import dmd.DDMDExtensions;

class InvariantDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
		super(loc, endloc, Id.classInvariant, STCundefined, null);
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		InvariantDeclaration id = new InvariantDeclaration(loc, endloc);
		FuncDeclaration.syntaxCopy(id);
		return id;
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
		return false;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (hgs.hdrgen)
			return;
		buf.put("invariant");
		bodyToCBuffer(buf, hgs);
	}

	override void toJsonBuffer(ref Appender!(char[]) buf)
	{
	}

	override InvariantDeclaration isInvariantDeclaration() { return this; }
}
