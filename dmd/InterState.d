module dmd.InterState;

import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Statement;


class InterState 
{
	this()
	{
	}
	
    InterState caller;		// calling function's InterState
    FuncDeclaration fd;	// function being interpreted
    Dsymbol[] vars;		// variables used in this function
    Statement start;		// if !=NULL, start execution at this statement
    Statement gotoTarget;	// target of EXP_GOTO_INTERPRET result
    Expression localThis;	// value of 'this', or NULL if none
}
