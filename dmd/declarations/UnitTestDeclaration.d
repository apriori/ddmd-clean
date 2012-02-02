module dmd.declarations.UnitTestDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Type;
import dmd.Scope;
import dmd.types.TypeFunction;
import dmd.Module;
import dmd.Lexer;
import dmd.Identifier;

import dmd.DDMDExtensions;

/*******************************
 * Generate unique unittest function Id so we can have multiple
 * instances per module.
 */
Identifier unitTestId()
{
    return Identifier.uniqueId("__unittest");
}

class UnitTestDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
		super(loc, endloc, unitTestId(), STCundefined, null);
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		UnitTestDeclaration utd;

		assert(!s);
		utd = new UnitTestDeclaration(loc, endloc);

		return FuncDeclaration.syntaxCopy(utd);
	}


    override AggregateDeclaration isThis()
	{
		return null;
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

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

    override UnitTestDeclaration isUnitTestDeclaration() { return this; }
}
