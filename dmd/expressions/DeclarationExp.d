module dmd.expressions.DeclarationExp;

import dmd.Global;
import dmd.Expression;
import dmd.InterState;
import dmd.initializers.ExpInitializer;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.declarations.TupleDeclaration;
import dmd.Dsymbol;
import dmd.AttribDeclaration;
import dmd.VarDeclaration;
import dmd.Token;
import dmd.initializers.VoidInitializer;
import dmd.Type;

import std.array;

import dmd.DDMDExtensions;

// Declaration of a symbol

class DeclarationExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Dsymbol declaration;

	this(Loc loc, Dsymbol declaration)
	{
		super(loc, TOKdeclaration, DeclarationExp.sizeof);
		this.declaration = declaration;
	}

	override Expression syntaxCopy()
	{
		return new DeclarationExp(loc, declaration.syntaxCopy(null));
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		declaration.toCBuffer(buf, hgs);
	}

}

