module dmd.varDeclarations.TypeInfoConstDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;

import dmd.DDMDExtensions;

class TypeInfoConstDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoconst.type;
	}

}

