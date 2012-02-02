module dmd.varDeclarations.TypeInfoArrayDeclaration;

import dmd.Global;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.types.TypeDArray;
import dmd.Type;
import dmd.DDMDExtensions;

class TypeInfoArrayDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoarray.type;
	}

}

