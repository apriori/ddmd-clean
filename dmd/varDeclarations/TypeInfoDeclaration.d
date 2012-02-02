module dmd.varDeclarations.TypeInfoDeclaration;

import dmd.Global;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.Dsymbol;
import dmd.Module;
import dmd.Scope;
import std.array;
   

import dmd.DDMDExtensions;

class TypeInfoDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

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
