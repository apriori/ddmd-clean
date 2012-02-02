module dmd.varDeclarations.TypeInfoInvariantDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;

import dmd.DDMDExtensions;

class TypeInfoInvariantDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoinvariant.type;
	}

}

