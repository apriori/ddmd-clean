module dmd.dsymbols.Import;

import dmd.Global;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Module;
import dmd.Package;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.types.TypeIdentifier;
import dmd.declarations.AliasDeclaration;
import dmd.ScopeDsymbol;
import dmd.attribDeclarations.StorageClassDeclaration;
import dmd.attribDeclarations.ProtDeclaration;

import dmd.DDMDExtensions;

import std.stdio;
import std.array;

void escapePath(ref Appender!(char[]) buf, string fname)
{
	foreach (char c; fname)
	{
		switch (c)
		{
			case '(':
			case ')':
			case '\\':
				buf.put('\\');
			default:
				buf.put( c );
				break;
		}
	}
}

class Import : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));
	
	Identifier[] packages;		// array of Identifier's representing packages
	Identifier id;		// module Identifier
	Identifier aliasId;
	int isstatic;		// !=0 if static import

	// Pairs of alias=name to bind into current namespace
	Identifier[] names;
	Identifier[] aliases;

	AliasDeclaration[] aliasdecls;		// AliasDeclarations for names/aliases

	Module mod;
	Package pkg;		// leftmost package/module

	this(Loc loc, Identifier[] packages, Identifier id, Identifier aliasId, int isstatic)
	{
		super(id);
		
		assert(id);
		this.loc = loc;
		this.packages = packages;
		this.id = id;
		this.aliasId = aliasId;
		this.isstatic = isstatic;

		if (aliasId)
			this.ident = aliasId;
		// Kludge to change Import identifier to first package
		else if ( packages )
			this.ident = packages[0];
	}
	
	override Import isImport() { return this; }

	void addAlias(Identifier name, Identifier alias_)
	{
		if (isstatic)
			error("cannot have an import bind list");

		if (!aliasId)
			this.ident = null;	// make it an anonymous import

		names ~= name;
		aliases ~= alias_;
	}

	override string kind()
	{
		return isstatic ? "static import" : "import";
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)	// copy only syntax trees
	{
		assert(false);
	}
	
	void load(Scope sc)
	{
		/+ zd cut TODO include again 
      //writefln("Import::load('%s')", id.toChars());

		// See if existing module
		Dsymbol[string] dst = Package.resolve(packages, null, pkg);

		Dsymbol s = dst.get( id.toChars(), null );
		if (s)
		{
			if (s.isModule())
				mod = cast(Module)s;
			else
				error("package and module have the same name");
		}
		
		if (!mod)
		{
			// Load module
			mod = Module.load(loc, packages, id);
			dst.insert(id, mod);		// id may be different from mod.ident,
							// if so then insert alias
			if (!mod.importedFrom)
				mod.importedFrom = sc ? sc.module_.importedFrom : global.rootModule;
		}

		if (!pkg)
			pkg = mod;

		//writef("-Import::load('%s'), pkg = %p\n", toChars(), pkg);
      +/
	}
	
	override void importAll(Scope sc)
	{
       /+
		 if (!mod)
       {
           load(sc);
           mod.importAll(null);

           if (!isstatic && !aliasId && !names)
           {
               /* Default to private importing
                */
               PROT prot = sc.protection;
               if (!sc.explicitProtection)
                   prot = PROTprivate;
               sc.scopesym.importScope(mod, prot);
           }
       }
       +/
   }



   override Dsymbol toAlias()
   {
		if (aliasId)
			return mod;
		return this;
	}
	
	/*****************************
	 * Add import to sd's symbol table.
	 */
	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
    assert(false);
    /+
		bool result = false;

		if ( names )
			return Dsymbol.addMember(sc, sd, memnum);

		if (aliasId)
			result = Dsymbol.addMember(sc, sd, memnum);

		/* Instead of adding the import to sd's symbol table,
		 * add each of the alias=name pairs
		 */
		foreach ( name; names)
		{
			auto alias_ = aliases[name];

			if (!alias_)
				alias_ = name;

			TypeIdentifier tname = new TypeIdentifier(loc, name);
			AliasDeclaration ad = new AliasDeclaration(loc, alias_, tname);
			result |= ad.addMember(sc, sd, memnum);

			aliasdecls ~= ad;
		}

		return result;
    +/
	}
	
	
	override bool overloadInsert(Dsymbol s)
	{
		// Allow multiple imports of the same name
		return s.isImport() !is null;
	}
	
	override void toCBuffer( ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

}
