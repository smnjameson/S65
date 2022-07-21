# S65
S65 kick assembler macro toolkit for MEGA65

## Overview

S65 is a Kick Assembler development library for the MEGA65 that provides a simple API into the Raster Rewrite system 
as well as other useful functionality without the need to create the complex backbone of things like layers and software
sprites.

## Prerequisites

#### NodeJS (required)
  The image parsing, document generation and debugger deploy script makses extensive use of NodeJS. You can install it from:
  
  [https://nodejs.org](https://nodejs.org)
 
#### Sublime Text
  All of the syntax files and autocomplete functionality is currently for Sublime Text only. You can use other IDEs but you 
  will lack all the syntax highlighting and autocomplete hints. You can install it from:
  
  [https://www.sublimetext.com/download](https://www.sublimetext.com/download)
  
  Keep the install to default locations to ensure the build scripting functions coprrectly

#### M65 Debugger
  If you want to use the deploy method in the make.bat file to send your program to a real MEGA65 or a NExys board you will
  need the M65Debugger from [here](https://files.mega65.org?id=042e934f-c6e7-480f-8caa-4176be5ee784). The connection script 
  to launch the programs through the debugger is included by default in the S65 package
  
#### OS
  While the library itself can be used on operating systems other than Windows, you will at this time have to make your own
  build file (make.bat) for your OS. Likewise you may run into other issues such as needing to manually install the Sublime Text
  S65 files. (see below)
  

  
  


