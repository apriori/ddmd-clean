module dmd.varDeclarations.TypeInfoAssociativeArrayDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeAArray;
import dmd.varDeclarations.TypeInfoDeclaration;

import dmd.DDMDExtensions;

class TypeInfoAssociativeArrayDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoassociativearray.type;
	}

}

