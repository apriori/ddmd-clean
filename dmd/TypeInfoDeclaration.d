module dmd.TypeInfoDeclaration;

import dmd.Global;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.Dsymbol;
import dmd.Module;
import dmd.Scope;
import std.array;

class TypeInfoDeclaration : VarDeclaration
{
	Type tinfo;

	this(Type tinfo, int internal)
	{
		super(Loc(0), global.typeinfo.type, tinfo.getTypeInfoIdent(internal), null);
		this.tinfo = tinfo;
		storage_class = STCstatic | STCgshared;
		protection = PROTpublic;
		linkage = LINKc;
	}

	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);		  // should never be produced by syntax
		return null;
	}
	
   override void emitComment(Scope sc)
	{
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }
}

class TypeInfoAssociativeArrayDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoassociativearray.type;
	}

}

class TypeInfoClassDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoclass.type;
	}
}

class TypeInfoConstDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoconst.type;
	}

}


class TypeInfoArrayDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoarray.type;
	}

}

class TypeInfoDelegateDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfodelegate.type;
	}

}

class TypeInfoEnumDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoenum.type;
	}

}

class TypeInfoFunctionDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
        type = global.typeinfofunction.type;
	}

}

class TypeInfoInterfaceDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfointerface.type;
	}

}

class TypeInfoInvariantDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfoinvariant.type;
	}

}

class TypeInfoPointerDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfopointer.type;
	}

}

class TypeInfoSharedDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
		type = global.typeinfoshared.type;
	}

}
class TypeInfoStaticArrayDeclaration : TypeInfoDeclaration
{
    this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfostaticarray.type;
	}

}
class TypeInfoStructDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfostruct.type;
	}

}

class TypeInfoTupleDeclaration : TypeInfoDeclaration
{
    this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfotypelist.type;
	}

}
class TypeInfoTypedefDeclaration : TypeInfoDeclaration
{
	this(Type tinfo)
	{
		super(tinfo, 0);
	    type = global.typeinfotypedef.type;
	}

}

class TypeInfoWildDeclaration : TypeInfoDeclaration
{
    this(Type tinfo)
    {
        super(tinfo, 0);
        type = global.typeinfowild.type;
    }

}
