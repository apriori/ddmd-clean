module dmd.varDeclarations.ClassInfoDeclaration;

import dmd.Global;
import dmd.VarDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.Identifier;
import std.array;


import dmd.DDMDExtensions;

class ClassInfoDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	ClassDeclaration cd;

	this(ClassDeclaration cd)
	{

		super(Loc(0), global.classinfo.type, cd.ident, null);
		
		this.cd = cd;
		storage_class = STCstatic | STCgshared;
	}
	
	override Dsymbol syntaxCopy(Dsymbol)
	{
		 assert(false);		// should never be produced by syntax
		 return null;
	}
	

	override void emitComment(Scope sc)
	{
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }
	
}
