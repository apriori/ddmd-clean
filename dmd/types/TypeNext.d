module dmd.types.TypeNext;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeAArray;
import std.array;
import dmd.Scope;

import dmd.DDMDExtensions;

class TypeNext : Type
{
	mixin insertMemberExtension!(typeof(this));

    Type next;

    this(TY ty, Type next)
	{
		super(ty);
		this.next = next;
	}

    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		super.toDecoBuffer(buf, flag);
		assert(next !is this);
		//printf("this = %p, ty = %d, next = %p, ty = %d\n", this, this.ty, next, next.ty);
		next.toDecoBuffer(buf, (flag & 0x100) ? 0 : mod);
	}

    override void checkDeprecated(Loc loc, Scope sc)
	{
		Type.checkDeprecated(loc, sc);
		if (next)	// next can be null if TypeFunction and auto return type
			next.checkDeprecated(loc, sc);
	}
	
    override Type reliesOnTident()
	{
		return next.reliesOnTident();
	}
	
    override int hasWild()
    {
        return mod == MODwild || next.hasWild();
    }

    /***************************************
     * Return MOD bits matching argument type (targ) to wild parameter type (this).
     */

    
    override Type nextOf()
	{
		return next;
	}
	
    override Type makeConst()
	{
		//printf("TypeNext::makeConst() %p, %s\n", this, toChars());
		if (cto)
		{
			assert(cto.mod == MODconst);
			return cto;
		}
		
		TypeNext t = cast(TypeNext)super.makeConst();
		if (ty != Tfunction && ty != Tdelegate &&
			(next.deco || next.ty == Tfunction) &&
			!next.isImmutable() && !next.isConst())
		{
			if (next.isShared())
				t.next = next.sharedConstOf();
			else
				t.next = next.constOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
		//writef("TypeNext::makeConst() returns %p, %s\n", t, t.toChars());
		return t;
	}
	
    override Type makeInvariant()
	{
		//printf("TypeNext::makeInvariant() %s\n", toChars());
		if (ito)
		{	
			assert(ito.isImmutable());
			return ito;
		}
		TypeNext t = cast(TypeNext)Type.makeInvariant();
		if (ty != Tfunction && ty != Tdelegate && (next.deco || next.ty == Tfunction) && !next.isImmutable())
		{	
			t.next = next.invariantOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
		return t;
	}
	
    override Type makeShared()
	{
		//printf("TypeNext::makeShared() %s\n", toChars());
		if (sto)
		{	
			assert(sto.mod == MODshared);
			return sto;
		}    
		TypeNext t = cast(TypeNext)Type.makeShared();
		if (ty != Tfunction && ty != Tdelegate &&
			(next.deco || next.ty == Tfunction) &&
			!next.isImmutable() && !next.isShared())
		{
			if (next.isConst() || next.isWild())
				t.next = next.sharedConstOf();
			else
				t.next = next.sharedOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
		//writef("TypeNext::makeShared() returns %p, %s\n", t, t.toChars());
		return t;
	}
	
	override Type makeSharedConst()
	{
		//printf("TypeNext::makeSharedConst() %s\n", toChars());
		if (scto)
		{
			assert(scto.mod == (MODshared | MODconst));
			return scto;
		}
		TypeNext t = cast(TypeNext) Type.makeSharedConst();
		if (ty != Tfunction && ty != Tdelegate &&
		    (next.deco || next.ty == Tfunction) &&
			!next.isImmutable() && !next.isSharedConst())
		{
			t.next = next.sharedConstOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
//		writef("TypeNext::makeSharedConst() returns %p, %s\n", t, t.toChars());
		return t;
	}
	
    override Type makeWild()
    {
        //printf("TypeNext::makeWild() %s\n", toChars());
        if (wto)
        {
            assert(wto.mod == MODwild);
	        return wto;
        }    
        auto t = cast(TypeNext)Type.makeWild();
        if (ty != Tfunction && ty != Tdelegate &&
	    (next.deco || next.ty == Tfunction) &&
            !next.isImmutable() && !next.isConst() && !next.isWild())
        {
	        if (next.isShared())
	            t.next = next.sharedWildOf();
	        else
	            t.next = next.wildOf();
        }
        if (ty == Taarray)
        {
    	    (cast(TypeAArray)t).impl = null;		// lazily recompute it
        }
        //printf("TypeNext::makeWild() returns %p, %s\n", t, t->toChars());
        return t;
    }

    override Type makeSharedWild()
    {
        //printf("TypeNext::makeSharedWild() %s\n", toChars());
        if (swto)
        {
            assert(swto.isSharedWild());
	        return swto;
        }    
        auto t = cast(TypeNext)Type.makeSharedWild();
        if (ty != Tfunction && ty != Tdelegate &&
	    (next.deco || next.ty == Tfunction) &&
            !next.isImmutable() && !next.isSharedConst())
        {
	        t.next = next.sharedWildOf();
        }
        if (ty == Taarray)
        {
	        (cast(TypeAArray)t).impl = null;		// lazily recompute it
        }
        //printf("TypeNext::makeSharedWild() returns %p, %s\n", t, t->toChars());
        return t;
    }

    override Type makeMutable()
    {
        //printf("TypeNext::makeMutable() %p, %s\n", this, toChars());
        auto t = cast(TypeNext)Type.makeMutable();
        if (ty != Tfunction && ty != Tdelegate &&
	    (next.deco || next.ty == Tfunction) &&
            next.isWild())
        {
	        t.next = next.mutableOf();
        }
        if (ty == Taarray)
        {
	        (cast(TypeAArray)t).impl = null;		// lazily recompute it
        }
        //printf("TypeNext::makeMutable() returns %p, %s\n", t, t->toChars());
        return t;
    }
    
	
	void transitive()
	{
		/* Invoke transitivity of type attributes
		 */
		next = next.addMod(mod);
	}
}
