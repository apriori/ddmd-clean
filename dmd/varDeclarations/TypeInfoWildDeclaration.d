module dmd.varDeclarations.TypeInfoWildDeclaration;

import dmd.Global;
import dmd.Type;
import dmd.varDeclarations.TypeInfoDeclaration;


import dmd.DDMDExtensions;

class TypeInfoWildDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Type tinfo)
    {
        super(tinfo, 0);
        type = global.typeinfowild.type;
    }

}
