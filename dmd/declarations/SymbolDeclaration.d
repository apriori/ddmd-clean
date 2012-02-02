module dmd.declarations.SymbolDeclaration;

import dmd.Global;
import dmd.Declaration;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.Token;
import dmd.Dsymbol;
import dmd.Identifier;


import std.stdio;

import dmd.DDMDExtensions;

// This is a shell around a back end symbol

class Symbol : Dsymbol
{
    // some class huh?
}

class SymbolDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

    Symbol* sym;
    StructDeclaration dsym;

    this(Loc loc, Symbol* s, StructDeclaration dsym)
	{
		//string name = Sident.ptr[0..len].idup;
		string name = "NoBackendSymbolsInZD";

		super(new Identifier(name, TOKidentifier));
		
		this.loc = loc;
		sym = s;
		this.dsym = dsym;
		storage_class |= STCconst;
	}


    // Eliminate need for dynamic_cast
    override SymbolDeclaration isSymbolDeclaration() { return this; }
}
