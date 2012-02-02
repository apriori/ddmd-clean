module dmd.varDeclarations.TypeInfoTupleDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.types.TypeTuple;
import dmd.Parameter;
import dmd.Expression;

import dmd.DDMDExtensions;

class TypeInfoTupleDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfotypelist.type;
	}

}
