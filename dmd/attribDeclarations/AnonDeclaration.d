module dmd.attribDeclarations.AnonDeclaration;

import dmd.Global;
import std.array;
import dmd.Scope;
import dmd.AttribDeclaration;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.scopeDsymbols.AnonymousAggregateDeclaration;
import dmd.Module;
import dmd.VarDeclaration;

import dmd.DDMDExtensions;

class AnonDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

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

