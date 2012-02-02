module dmd.varDeclarations.TypeInfoClassDeclaration;

import dmd.Global;
/// WTF is this for??

import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.varDeclarations.ClassInfoDeclaration;
import dmd.types.TypeClass;

import dmd.DDMDExtensions;

class TypeInfoClassDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoclass.type;
	}

}

