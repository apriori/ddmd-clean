module dmd.expressions.SymbolExp;

import dmd.Global;
import dmd.Expression;
import dmd.Declaration;
import dmd.Token;
import dmd.Type;
import dmd.Identifier;
import dmd.expressions.SymOffExp;
import dmd.declarations.FuncDeclaration;
import dmd.VarDeclaration;

import dmd.DDMDExtensions;

class SymbolExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Declaration var;

	bool hasOverloads;

	this(Loc loc, TOK op, int size, Declaration var, bool hasOverloads)
	{
		super(loc, op, size);
		assert(var);
		this.var = var;
		this.hasOverloads = hasOverloads;
	}

}

