module dmd.expressions.SymOffExp;

import dmd.Global;
import std.format;

import dmd.Expression;
import dmd.Declaration;
import dmd.Type;
import dmd.InterState;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.expressions.SymbolExp;
import dmd.VarDeclaration;
import dmd.expressions.DelegateExp;
import dmd.expressions.ThisExp;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.IntegerExp;
import dmd.expressions.ErrorExp;
import dmd.Token;
import dmd.Dsymbol;

import std.array;
import dmd.DDMDExtensions;

class SymOffExp : SymbolExp
{
	mixin insertMemberExtension!(typeof(this));

	uint offset;

	this(Loc loc, Declaration var, uint offset, bool hasOverloads = false)
	{
		super(loc, TOKsymoff, SymOffExp.sizeof, var, hasOverloads);
		
		this.offset = offset;
		VarDeclaration v = var.isVarDeclaration();
		if (v && v.needThis())
			error("need 'this' for address of %s", v.toChars());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (offset)
			formattedWrite(buf,"(& %s+%s)", var.toChars(), offset); ///
		else
			formattedWrite(buf,"& %s", var.toChars());
	}
}

