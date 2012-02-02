module dmd.declarations.TypedefDeclaration;

import dmd.Global;
import dmd.Declaration;
import dmd.Initializer;
import dmd.Type;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Module;
import dmd.Scope;
import dmd.initializers.ExpInitializer;
import std.array;
import dmd.HdrGenState;
import dmd.types.TypeTypedef;


import dmd.DDMDExtensions;

class TypedefDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

    Type basetype;
    Initializer init;
    int sem = 0;// 0: semantic() has not been run
				// 1: semantic() is in progress
				// 2: semantic() has been run
				// 3: semantic2() has been run

    this(Loc loc, Identifier id, Type basetype, Initializer init)
	{
		super(id);
		
		this.type = new TypeTypedef(this);
		this.basetype = basetype.toBasetype();
		this.init = init;

	version (_DH) {
		this.htype = null;
		this.hbasetype = null;
	}
		this.loc = loc;
		//BACKEND this.sinit = null;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		Type basetype = this.basetype.syntaxCopy();

		Initializer init = null;
		if (this.init)
			init = this.init.syntaxCopy();

		assert(!s);
		TypedefDeclaration st;
		st = new TypedefDeclaration(loc, ident, basetype, init);
version(_DH)
{
		// Syntax copy for header file
		if (!htype)		// Don't overwrite original
		{
			if (type)	// Make copy for both old and new instances
			{
				htype = type.syntaxCopy();
				st.htype = type.syntaxCopy();
			}
		}
		else			// Make copy of original for new instance
			st.htype = htype.syntaxCopy();
		if (!hbasetype)
		{
			if (basetype)
			{
				hbasetype = basetype.syntaxCopy();
				st.hbasetype = basetype.syntaxCopy();
			}
		}
		else
			st.hbasetype = hbasetype.syntaxCopy();
}
		return st;
	}
	
	
	
    override string mangle()
	{
		//printf("TypedefDeclaration::mangle() '%s'\n", toChars());
		return Dsymbol.mangle();
	}
	
    override string kind()
	{
		assert(false);
	}
	
    override Type getType()
	{
		return type;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

version (_DH) {
    Type htype;
    Type hbasetype;
}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	
    void toDebug()
	{
		assert(false);
	}
	

    override TypedefDeclaration isTypedefDeclaration() { return this; }

}
