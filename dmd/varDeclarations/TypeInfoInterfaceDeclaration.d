module dmd.varDeclarations.TypeInfoInterfaceDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.varDeclarations.ClassInfoDeclaration;
import dmd.types.TypeClass;
import dmd.varDeclarations.TypeInfoClassDeclaration;


import dmd.DDMDExtensions;

class TypeInfoInterfaceDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfointerface.type;
	}

}

