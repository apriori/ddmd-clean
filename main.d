
import dmd.Module;

import dmd.parser, dmd.identifier, dmd.token, std.stdio, std.file;
import dmd.dsymbol;

// Don't worry, there's a method to my madness!!!!
// Don't worry, there's a method to my madness!!!!
// Don't worry, there's a method to my madness!!!!

int main( string[] 
args
)          {

         void next(string s){ write("press Enter..."); stdin.readln(); write(s); }
      auto str1 = "syntactically Wrong{ int Code Buffer; }";   
   auto str2 = "struct Much{ int better; string now; char[] here; } "
               "int feathers = 3; ";
   
      // By the way, comments aren't implemented yet!
         auto m = new Module("test", new Identifier("Testy",TOKidentifier),false,false);
   auto p = new Parser( m, str1, false );
            writeln("Parsing bad code...");
   p.parseModule();
   write(  m.toChars() );
 
            next("\nA little better...\n");
               p.setBuf( str2 );

   p.nextToken(); // There's some inconsistency in the interface
   Dsymbol[] d = p.parseDeclDefs( 0 /+int once+/);
   
               write(  d[0].toChars() );


      // Obviously we're not perfect yet!
   next("Now watch this...\npress Enter!");
      stdin.readln();
         p.setBuf( readText!(char[])("main.d") );
               
               p.parseModule();
   
   write( m.toChars() );
   writeln("Pretty cool, huh?");
   
   return 0;
}
