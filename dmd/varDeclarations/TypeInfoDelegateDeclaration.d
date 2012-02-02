module dmd.varDeclarations.TypeInfoDelegateDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.types.TypeDelegate;


import dmd.DDMDExtensions;

class TypeInfoDelegateDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfodelegate.type;
	}

}

