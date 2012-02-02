module dmd.varDeclarations.TypeInfoEnumDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeEnum;
import dmd.scopeDsymbols.EnumDeclaration;
import dmd.varDeclarations.TypeInfoDeclaration;

import std.string : toStringz;

import dmd.DDMDExtensions;

class TypeInfoEnumDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoenum.type;
	}

}

