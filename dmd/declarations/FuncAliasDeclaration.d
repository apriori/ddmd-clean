module dmd.declarations.FuncAliasDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class FuncAliasDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    FuncDeclaration funcalias;

    this(FuncDeclaration funcalias)
	{
		super(funcalias.loc, funcalias.endloc, funcalias.ident, funcalias.storage_class, funcalias.type);
		assert(funcalias !is this);
		this.funcalias = funcalias;
	}

    override FuncAliasDeclaration isFuncAliasDeclaration() { return this; }
	
    override string kind()
	{
		return "function alias";
	}
	
}
