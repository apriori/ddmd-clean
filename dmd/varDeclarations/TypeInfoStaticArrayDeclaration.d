module dmd.varDeclarations.TypeInfoStaticArrayDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.types.TypeSArray;


import dmd.DDMDExtensions;

class TypeInfoStaticArrayDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfostaticarray.type;
	}

}
