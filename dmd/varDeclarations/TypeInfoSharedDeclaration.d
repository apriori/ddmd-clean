module dmd.varDeclarations.TypeInfoSharedDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;

import dmd.DDMDExtensions;

class TypeInfoSharedDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
		type = global.typeinfoshared.type;
	}

}
