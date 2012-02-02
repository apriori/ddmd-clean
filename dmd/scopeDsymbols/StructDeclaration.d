module dmd.scopeDsymbols.StructDeclaration;

import dmd.Global;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.DeclarationExp;
import dmd.initializers.VoidInitializer;
import dmd.Initializer;
import dmd.initializers.ExpInitializer;
import dmd.Token;
import dmd.Statement;
import dmd.expressions.VarExp;
import dmd.statements.CompoundStatement;
import dmd.expressions.AssignExp;
import dmd.expressions.DotVarExp;
import dmd.expressions.AddrExp;
import dmd.expressions.CastExp;
import dmd.declarations.PostBlitDeclaration;
import dmd.Lexer;
import dmd.statements.ExpStatement;
import dmd.expressions.DotIdExp;
import dmd.types.TypeSArray;
import dmd.expressions.ThisExp;
import dmd.varDeclarations.ThisDeclaration;
import dmd.types.TypeFunction;
import dmd.Parameter;
import dmd.Type;
import dmd.Identifier;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.types.TypeStruct;
import dmd.Expression;
import dmd.expressions.IdentifierExp;
import dmd.expressions.PtrExp;
import dmd.expressions.CallExp;
import dmd.statements.ReturnStatement;
import dmd.ScopeDsymbol;
import dmd.Module;
import dmd.VarDeclaration;
import dmd.declarations.InvariantDeclaration;
import dmd.declarations.NewDeclaration;
import dmd.declarations.DeleteDeclaration;
import dmd.expressions.IntegerExp;
import dmd.expressions.EqualExp;
import dmd.expressions.AndAndExp;


import std.stdio;

import dmd.DDMDExtensions;

class StructDeclaration : AggregateDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    bool zeroInit;		// true if initialize with 0 fill

    int hasIdentityAssign;	// !=0 if has identity opAssign
    FuncDeclaration cpctor;	// generated copy-constructor, if any
    FuncDeclaration eq;	// bool opEquals(ref const T), if any

    FuncDeclaration[] postblits;	// Array of postblit functions
    FuncDeclaration postblit;	// aggregate postblit

    this(Loc loc, Identifier id)
	{
		super(loc, id);

		// For forward references
		type = new TypeStruct(this);

	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		StructDeclaration sd;

		if (s)
			sd = cast(StructDeclaration)s;
		else
			sd = new StructDeclaration(loc, ident);
		ScopeDsymbol.syntaxCopy(sd);
		return sd;
	}



    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

    override string mangle()
	{
		//printf("StructDeclaration.mangle() '%s'\n", toChars());
		return Dsymbol.mangle();
	}

    override string kind()
	{
		assert(false);
	}

version(DMDV1)
    Expression cloneMembers()
	{
		assert(false);
	}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}





    override StructDeclaration isStructDeclaration() { return this; }
}
