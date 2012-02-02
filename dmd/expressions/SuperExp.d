module dmd.expressions.SuperExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.declarations.FuncDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Dsymbol;
import dmd.HdrGenState;
import dmd.expressions.ThisExp;
import dmd.Token;
import dmd.Type;

import std.array;
import dmd.DDMDExtensions;

class SuperExp : ThisExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		super(loc);
		op = TOKsuper;
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("super");
	}



}

