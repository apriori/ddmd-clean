module dmd.varDeclarations.ModuleInfoDeclaration;

import dmd.Global;
import dmd.VarDeclaration;
import dmd.Module;
import dmd.Dsymbol;
import std.array;
import dmd.Scope;

import dmd.DDMDExtensions;

class ModuleInfoDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Module mod;

	this(Module mod)
	{
		super(Loc(0), global.moduleinfo.type, mod.ident, null);
	}
	
	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);		  // should never be produced by syntax
		return null;
	}
	

	void emitComment(Scope *sc)
	{
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

	/+ Symbol? what "Symbol"?
   +/
}
