module dmd.hdrGenState;

import std.ascii;
import std.stdio;

struct HdrGenState
{
   char[] indentValue = [];
   char[] nLIndentValue = std.ascii.newline.dup;  // This matters less and less
   char[] nL = std.ascii.newline.dup; // shorter is better!! (?)
   int indentLevel = 0;
   char[] tabString = "   ".dup;
   bool suppressIndentValue = false;

   @property char[] pushIndent()
   {
      pushIndentLevel();
      return indent;
   }

   @property char[] nLIndent()
   {
      if ( suppressIndentValue ) 
      {
         suppressIndentValue = false;
         return nL;
      }
      return nLIndentValue;
   }
   // Suppresses indent for one call to indent()
   void suppressIndent()
   {
      this.suppressIndentValue = true;
   }

   @property char[] indent()
   {
      if ( suppressIndentValue ) 
      {
         suppressIndentValue = false;
         return null;
      }
      return indentValue;
   }
   
   @property char[] pushNewLine()
   {
      pushIndentLevel();
      return nL;
   }
   
   @property char[] popIndent()
   {
      popIndentLevel();
      return this.indent;
   }

   // It was easier to just call these from the other functions
   void pushIndentLevel()
   {
      indentLevel++;
      assert(indentLevel < 18, "HgsGenState.IndentLevel exceeded 18!");
      indentValue ~= tabString;
      nLIndentValue ~= tabString;
      //writeln("pushIndent:length= ",indent.length);
   }
   
   void popIndentLevel()
   {
      indentLevel--;
      //writeln("popIndent:length= ",nLIndent.length);
      assert(indentLevel >= 0 , "HgsGenState.IndentLevel dropped below 0!");
      assert(indentValue.length >= tabString.length, "fail 1");
      assert(nLIndentValue.length >= tabString.length, "fail 2");
      indentValue.length -= tabString.length;
      nLIndentValue.length -= tabString.length;
   }

   bool hdrgen;		// 1 if generating header file
   bool ddoc;		// 1 if generating Ddoc file
   bool console;	// 1 if writing to console
   int tpltMember;
   bool inCallExp;
   bool inPtrExp;
   bool inSlcExp;
   bool inDotExp;
   bool inBinExp;
   bool inArrExp;
   bool emitInst;

   version(all)
   {
      // This struct keeps track of "for" loop semicolons
      // avoiding newLines when the semicolon is in the for loop
      // I think I could do just as well with suppressNLIndent
      struct FLinit_
      {
         int init;
         int decl;
      }

      FLinit_ FLinit;
   }
}
