#!/bin/sh

#  Make this file build the lexer into a library!!!!

#rdmd ./dmd/Lexer.d --build-only -lib -H -m32
rdmd ./dmd/genIds

dmd ./dmd/Lexer.d ./dmd/Token.d ./dmd/BasicUtils.d ./dmd/Identifier.d -lib -H -m32 -Hd./dmd -od./dmd -J./dmd -oflibLexer.a
