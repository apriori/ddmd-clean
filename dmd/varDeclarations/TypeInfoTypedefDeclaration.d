module dmd.varDeclarations.TypeInfoTypedefDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.declarations.TypedefDeclaration;
import dmd.types.TypeTypedef;

import std.string;

import dmd.DDMDExtensions;

class TypeInfoTypedefDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfotypedef.type;
	}

}

