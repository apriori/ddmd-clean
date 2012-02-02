module dmd.varDeclarations.TypeInfoPointerDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.types.TypePointer;

import dmd.DDMDExtensions;

class TypeInfoPointerDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfopointer.type;
	}

}

