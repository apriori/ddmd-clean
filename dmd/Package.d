module dmd.Package;

import dmd.Global;
import dmd.ScopeDsymbol;
import dmd.Identifier;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Module;

import dmd.DDMDExtensions;

class Package : ScopeDsymbol
{
   // zd note Package has no members of its own
	mixin insertMemberExtension!(typeof(this));

    this(Identifier ident)
	{
		super(ident);
	}
	
    override string kind()
	{
		assert(false);
	}

    static Dsymbol[string] resolve( 
            Identifier[] packages, 
            Dsymbol pparent, 
            Package ppkg
            )
    {
    assert(false);
    /+
        Dsymbol[string] dst = global.modules;
        Dsymbol parent = null;

        //printf("Package::resolve()\n");
        bool sendPpkg = ( ppkg !is null );

        if (packages)
        {
            foreach (pid; packages)
            {   
                Package p = dst.get( pid, null );
                if (!p)
                {
                    p = new Package(pid);
                    dst[pid] = p;
                    p.parent = parent;
                }
                else
                {
                    assert(p.isPackage());
                    //dot net needs modules and packages with same name
                    version (TARGET_NET) { }
                    else 
                    {
                        if (p.isModule())
                        {   
                            p.error("module and package have the same name");
                            fatal();
                            break;
                        }
                    }
                }
                parent = p;
                dst = p.symtab;
                // this is weird, couldn't find where it was used anyway
                // used a bool place holder, I think it makes sense
                if ( sendPpkg ) 
                {
                    sendPpkg = false;
                    ppkg = p;
                }
            }
            if (pparent)
            {
                pparent = parent;
            }
        }
        return dst;
    +/
    }

    override Package isPackage() { return this; }

}
