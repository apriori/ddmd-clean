module dmd.expressions.VarExp;

import dmd.Global;
import dmd.Expression;
import dmd.Declaration;
import dmd.InterState;
import dmd.Scope;
import dmd.declarations.FuncLiteralDeclaration;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.declarations.FuncDeclaration;
import dmd.HdrGenState;
import dmd.Token;
import dmd.declarations.SymbolDeclaration;
import dmd.expressions.SymbolExp;
import dmd.Type;

import std.array;
import dmd.DDMDExtensions;

//! Variable
class VarExp : SymbolExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Declaration var, bool hasOverloads = false)
	{
		super(loc, TOKvar, VarExp.sizeof, var, hasOverloads);
		
		//printf("VarExp(this = %p, '%s', loc = %s)\n", this, var.toChars(), loc.toChars());
		//if (strcmp(var.ident.toChars(), "func") == 0) halt();
		this.type = var.type;
	}






	override string toChars()
	{
		return var.toChars();
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(var.toChars());
	}

    








}

