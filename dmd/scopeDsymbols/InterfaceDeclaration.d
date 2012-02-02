module dmd.scopeDsymbols.InterfaceDeclaration;

import dmd.Global;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Type;
import dmd.Parameter;
import dmd.types.TypeTuple;
import dmd.types.TypeClass;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.Module;
import dmd.BaseClass;


import dmd.DDMDExtensions;

class InterfaceDeclaration : ClassDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    bool cpp;				// true if this is a C++ interface

    this(Loc loc, Identifier id, BaseClass[] baseclasses)
	{
		super(loc, id, baseclasses);

		if (id is Id.IUnknown)	// IUnknown is the root of all COM interfaces
		{
			com = true;
			cpp = true;		// IUnknown is also a C++ interface
		}
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		InterfaceDeclaration id;

		if (s)
			id = cast(InterfaceDeclaration)s;
		else
			id = new InterfaceDeclaration(loc, ident, null);

		ClassDeclaration.syntaxCopy(id);
		return id;
	}


    override bool isBaseOf(ClassDeclaration cd, int* poffset)
	{
		uint j;

		//printf("%s.InterfaceDeclaration.isBaseOf(cd = '%s')\n", toChars(), cd.toChars());
		assert(!baseClass);
		for (j = 0; j < cd.interfaces_dim; j++)
		{
			BaseClass b = cd.interfaces[j];

			//printf("\tbase %s\n", b.base.toChars());
			if (this == b.base)
			{
				//printf("\tfound at offset %d\n", b.offset);
				if (poffset)
				{
					*poffset = b.offset;
					if (j && cd.isInterfaceDeclaration())
						*poffset = OFFSET_RUNTIME;
				}
				return true;
			}
			if (isBaseOf(b, poffset))
			{
				if (j && poffset && cd.isInterfaceDeclaration())
					*poffset = OFFSET_RUNTIME;
				return true;
			}
		}

		if (cd.baseClass && isBaseOf(cd.baseClass, poffset))
		return true;

		if (poffset)
			*poffset = 0;
		return false;
	}

    bool isBaseOf(BaseClass bc, int* poffset)
	{
	    //printf("%s.InterfaceDeclaration.isBaseOf(bc = '%s')\n", toChars(), bc.base.toChars());
		for (uint j = 0; j < bc.baseInterfaces.length; j++)
		{
			BaseClass b = bc.baseInterfaces[j];

			if (this == b.base)
			{
				if (poffset)
				{
					*poffset = b.offset;
					if (j && bc.base.isInterfaceDeclaration())
						*poffset = OFFSET_RUNTIME;
				}
				return true;
			}
			if (isBaseOf(b, poffset))
			{
				if (j && poffset && bc.base.isInterfaceDeclaration())
					*poffset = OFFSET_RUNTIME;
				return true;
			}
		}
		if (poffset)
			*poffset = 0;
		return false;
	}

    override string kind()
	{
		assert(false);
	}

	/****************************************
	 * Determine if slot 0 of the vtbl[] is reserved for something else.
	 * For class objects, yes, this is where the ClassInfo ptr goes.
	 * For COM interfaces, no.
	 * For non-COM interfaces, yes, this is where the Interface ptr goes.
	 */



	/*************************************
	 * Create the "InterfaceInfo" symbol
	 */

    override InterfaceDeclaration isInterfaceDeclaration() { return this; }
}
