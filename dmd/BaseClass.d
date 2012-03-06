module dmd.baseClass;

import dmd.global;
import dmd.type;
import dmd.scopeDsymbol;
//import dmd.types.TypeFunction;
import dmd.dsymbol;
import dmd.funcDeclaration;

class BaseClass : Dobject
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
