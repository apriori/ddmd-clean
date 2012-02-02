module dmd.declarations.TupleDeclaration;

import dmd.Global;
import std.format;

import dmd.Declaration;
import dmd.Parameter;
import dmd.types.TypeTuple;
import dmd.Token;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Type;
import dmd.Expression;
import std.array;
import dmd.expressions.DsymbolExp;

import dmd.DDMDExtensions;

class TupleDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

	Object[] objects;
	int isexp;			// 1: expression tuple

	TypeTuple tupletype;	// !=NULL if this is a type tuple

	this(Loc loc, Identifier ident, Object[] objects)
	{
		super(ident);
		this.type = null;
		this.objects = objects;
		this.isexp = 0;
		this.tupletype = null;
	}

	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);
	}

	override string kind()
	{
		return "tuple";
	}

	//override Type getType() { assert(false,"zd cut"); }

	//override bool needThis() { assert(false,"zd cut"); }

	override TupleDeclaration isTupleDeclaration() { return this; }
}
