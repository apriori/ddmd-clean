module dmd.attribDeclarations.StorageClassDeclaration;

import dmd.AttribDeclaration;
import dmd.Token;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;

import dmd.DDMDExtensions;

class StorageClassDeclaration: AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    StorageClass stc;

    this(StorageClass stc, Dsymbol[] decl)
	{
		super(decl);
		
		this.stc = stc;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		StorageClassDeclaration scd;

		assert(!s);
		scd = new StorageClassDeclaration(stc, Dsymbol.arraySyntaxCopy(decl));
		return scd;
	}
	
    override void setScope(Scope sc)
	{
		if (decl)
		{
			StorageClass scstc = sc.stc;

			/* These sets of storage classes are mutually exclusive,
			 * so choose the innermost or most recent one.
			 */
			if (stc & (STCauto | STCscope | STCstatic | STCextern | STCmanifest))
				scstc &= ~(STCauto | STCscope | STCstatic | STCextern | STCmanifest);
			if (stc & (STCauto | STCscope | STCstatic | STCtls | STCmanifest | STCgshared))
				scstc &= ~(STCauto | STCscope | STCstatic | STCtls | STCmanifest | STCgshared);
			if (stc & (STCconst | STCimmutable | STCmanifest))
				scstc &= ~(STCconst | STCimmutable | STCmanifest);
			if (stc & (STCgshared | STCshared | STCtls))
				scstc &= ~(STCgshared | STCshared | STCtls);
			if (stc & (STCsafe | STCtrusted | STCsystem))
				scstc &= ~(STCsafe | STCtrusted | STCsystem);
			scstc |= stc;

			setScopeNewSc(sc, scstc, sc.linkage, sc.protection, sc.explicitProtection, sc.structalign);
		}
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

    static void stcToCBuffer(ref Appender!(char[]) buf, StorageClass stc)
	{
		struct SCstring
		{
			StorageClass stc;
			TOK tok;
		};

		enum SCstring[] table =
		[
			{ STCauto,         TOKauto },
			{ STCscope,        TOKscope },
			{ STCstatic,       TOKstatic },
			{ STCextern,       TOKextern },
			{ STCconst,        TOKconst },
			{ STCfinal,        TOKfinal },
			{ STCabstract,     TOKabstract },
			{ STCsynchronized, TOKsynchronized },
			{ STCdeprecated,   TOKdeprecated },
			{ STCoverride,     TOKoverride },
			{ STClazy,         TOKlazy },
			{ STCalias,        TOKalias },
			{ STCout,          TOKout },
			{ STCin,           TOKin },
			{ STCimmutable,    TOKimmutable },
			{ STCshared,       TOKshared },
			{ STCnothrow,      TOKnothrow },
			{ STCpure,         TOKpure },
			{ STCref,          TOKref },
			{ STCtls,          TOKtls },
			{ STCgshared,      TOKgshared },
			{ STCproperty,     TOKat },
			{ STCsafe,         TOKat },
			{ STCtrusted,      TOKat },
			{ STCdisable,      TOKat },
		];

		for (int i = 0; i < table.length; i++)
		{
			if (stc & table[i].stc)
			{
				TOK tok = table[i].tok;
				if (tok == TOKat)
				{	Identifier id;

					if (stc & STCproperty)
						id = Id.property;
					else if (stc & STCsafe)
						id = Id.safe;
					else if (stc & STCtrusted)
						id = Id.trusted;
					else if (stc & STCdisable)
						id = Id.disable;
					else
						assert(0);
					buf.put(id.toChars());
				}
				else
					buf.put(Token.toChars(tok));
				buf.put(' ');
			}
		}
	}
}
