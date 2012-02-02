module dmd.varDeclarations.ThisDeclaration;

import dmd.Global;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.Type;
import dmd.Identifier;

import dmd.DDMDExtensions;

// For the "this" parameter to member functions

class ThisDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Type t)
	{
		super(loc, t, Id.This, null);
		noauto = true;
	}
	
    override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);
	}
	
    override ThisDeclaration isThisDeclaration() { return this; }
}
