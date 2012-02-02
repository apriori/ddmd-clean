module dmd.expressions.PowAssignExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Scope;
import dmd.Identifier;
import dmd.Expression;
import dmd.Token;
import dmd.Dsymbol;
import dmd.expressions.PowExp;
import dmd.expressions.AssignExp;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.initializers.ExpInitializer;
import dmd.expressions.DeclarationExp;
import dmd.expressions.VarExp;
import dmd.expressions.CommaExp;
import dmd.expressions.ErrorExp;

import dmd.DDMDExtensions;

// Only a reduced subset of operations for now.
class PowAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
    {
        super(loc, TOKpowass, PowAssignExp.sizeof, e1, e2);
    }
    
    
    // For operator overloading
    override Identifier opId()
    {
        return Id.powass;
    }
};
