module dmd.varDeclarations.TypeInfoStructDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.Parameter;
import dmd.types.TypeStruct;
import dmd.types.TypeFunction;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.Identifier;
import dmd.varDeclarations.TypeInfoDeclaration;

import std.string : toStringz;

import dmd.DDMDExtensions;

class TypeInfoStructDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfostruct.type;
	}

}

