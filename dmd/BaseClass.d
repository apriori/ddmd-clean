module dmd.BaseClass;

import dmd.Global;
import dmd.Type;
import dmd.ScopeDsymbol;
//import dmd.types.TypeFunction;
import dmd.Dsymbol;
import dmd.FuncDeclaration;



class BaseClass 
{
    Type type;				// (before semantic processing)
    PROT protection;		// protection for the base interface

    ClassDeclaration base;
    int offset;				// 'this' pointer offset
    FuncDeclaration[] vtbl;				// for interfaces
					// making up the vtbl[]

    //int baseInterfaces_dim;
    BaseClass[] baseInterfaces;		// if BaseClass is an interface, these
					// are a copy of the InterfaceDeclaration::interfaces

    this()
	{
	}

    this(Type type, PROT protection)
	{
		//printf("BaseClass(this = %p, '%s')\n", this, type->toChars());
		this.type = type;
		this.protection = protection;
	}
}
