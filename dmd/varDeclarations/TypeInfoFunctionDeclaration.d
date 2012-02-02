module dmd.varDeclarations.TypeInfoFunctionDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.types.TypeFunction;


import dmd.DDMDExtensions;

class TypeInfoFunctionDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
        type = global.typeinfofunction.type;
	}

}

