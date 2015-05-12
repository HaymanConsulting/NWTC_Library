!**********************************************************************************************************************************
! LICENSING
! Copyright (C) 2013-2015  National Renewable Energy Laboratory
!
!    This file is part of the NWTC Subroutine Library.
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.
!
!**********************************************************************************************************************************
! File last committed: $Date$
! (File) Revision #: $Rev$
! URL: $HeadURL$
!**********************************************************************************************************************************
MODULE NWTC_IO


   ! This module contains I/O-related variables and routines with non-system-specific logic.
   ! A list of routines follows the data and type definitions.

   USE                             SysSubs
   USE                             NWTC_Library_Types  ! ProgDesc and other types with copy and other routines for those types

   IMPLICIT  NONE

!=======================================================================

   TYPE(ProgDesc), PARAMETER    :: NWTC_Ver = &                               ! The name, version, and date of the NWTC Subroutine Library.
                                    ProgDesc( 'NWTC Subroutine Library', 'v2.06.00b-bjj', '11-May-2015')

   TYPE, PUBLIC                 :: FNlist_Type                                ! This type stores a linked list of file names.
      CHARACTER(1024)                        :: FileName                      ! A file name.
      TYPE(FNlist_Type), POINTER             :: Next => NULL()                ! The pointer to the next file name in the list.
   END TYPE FNlist_Type


      ! Global coupling scheme variables.

   INTEGER(IntKi), PARAMETER     :: ExplicitLoose = 1
   !bjj: will add more of these as we work our way


      ! Global I/O-related variables.

   INTEGER(IntKi), PARAMETER     :: FlgType  = 1                                 ! Switch for telling if a variable is a flag.
   INTEGER(IntKi), PARAMETER     :: NumType  = 2                                 ! Switch for telling if a variable is a number.
   INTEGER(IntKi), PARAMETER     :: StrType  = 3                                 ! Switch for telling if a variable is a string.

   INTEGER(B2Ki), PARAMETER      :: FileFmtID_WithTime    = 1                    ! ID for FAST Output File Format, specifies that the time channel is included in the output file (use if the output can occur at variable times)
   INTEGER(B2Ki), PARAMETER      :: FileFmtID_WithoutTime = 2                    ! ID for FAST Output File Format, specifies that the time channel is not included in the output file (used only with constant time-step output)


   LOGICAL                       :: Beep     = .TRUE.                            ! Flag that specifies whether or not to beep for error messages and program terminations.

   CHARACTER(20)                 :: ProgName = ' '                               ! The name of the calling program. DO NOT USE THIS IN NEW PROGRAMS (Modules)
   CHARACTER(99)                 :: ProgVer  = ' '                               ! The version (including date) of the calling program. DO NOT USE THIS IN NEW PROGRAMS
   CHARACTER(1), PARAMETER       :: Tab      = CHAR( 9 )                         ! The tab character.


      ! Parameters for writing to echo files (in this module only)

   INTEGER(IntKi), PARAMETER :: NWTC_MaxAryLen = 100 ! the maximum length of arrays that can be printed with the array formats below (used to make sure we don't crash when trying to write too many):
   ! >>> Note that the following array formats use 100, the value of NWTC_MaxAryLen above. Please keep the two numbers consistant!
   CHARACTER(*),PARAMETER :: Ec_StrAryFrmt =              "(15X,A,T30,' - ',A,/,2X,100('""',A,'""',:,1X))"   ! Output format for array of string parameters.
   CHARACTER(*),PARAMETER :: Ec_StrFrmt    =              "(15X,A,T30,' - ',A,/,2X, A )"                     ! Output format for string parameters
   CHARACTER(*),PARAMETER :: Ec_ReAryFrmt  =              "(15X,A,T30,' - ',A,/,100(2X,ES11.4e2,:))"         ! Output format for array of real parameters.
   CHARACTER(*),PARAMETER :: Ec_ReFrmt     = "( 2X, ES11.4e2,2X,A,T30,' - ',A )"                             ! Output format for real parameters
   CHARACTER(*),PARAMETER :: Ec_LgAryFrmt  =              "(15X,A,T30,' - ',A,/,100(2X,L11,:))"              ! Output format for array of logical parameters.
   CHARACTER(*),PARAMETER :: Ec_LgFrmt     =      "( 2X, L11,2X,A,T30,' - ',A )"                             ! Output format for logical parameters
   CHARACTER(*),PARAMETER :: Ec_IntAryFrmt =              "(15X,A,T30,' - ',A,/,100(2X,I11,:))"              ! Output format for array of integer parameters.
   CHARACTER(*),PARAMETER :: Ec_IntFrmt    =      "( 2X, I11,2X,A,T30,' - ',A )"                             ! Output format for integer parameters
   CHARACTER(*),PARAMETER :: Ec_Ch11Frmt   =      "( 2X, A11,2X,A,T30,' - ',A )"                             ! Output format for 11-character string parameters
   ! <<< End of arrays that use number defined in NWTC_MaxAryLen

!=======================================================================

      ! Create interface for a generic AllocAry that actually uses specific routines.

   INTERFACE AllocAry
      MODULE PROCEDURE AllCAry1
      MODULE PROCEDURE AllCAry2
      MODULE PROCEDURE AllCAry3
   !   MODULE PROCEDURE AllCAry4                               Not yet coded.
      MODULE PROCEDURE AllI1BAry1      ! 1-dimensional array of B1Ki integers
      MODULE PROCEDURE AllI2BAry1      ! 1-dimensional array of B2Ki integers
      MODULE PROCEDURE AllI4BAry1      ! 1-dimensional array of B4Ki integers
      MODULE PROCEDURE AllIAry2
      MODULE PROCEDURE AllIAry3
   !   MODULE PROCEDURE AllIAry4                               Not yet coded.
      MODULE PROCEDURE AllLAry1
      MODULE PROCEDURE AllLAry2
      MODULE PROCEDURE AllLAry3
   !   MODULE PROCEDURE AllLAry4                               Not yet coded.

      MODULE PROCEDURE AllR4Ary1       ! 1-dimensional array of SiKi reals
      MODULE PROCEDURE AllR8Ary1       ! 1-dimensional array of R8Ki reals
      MODULE PROCEDURE AllR16Ary1      ! 1-dimensional array of QuKi reals
      MODULE PROCEDURE AllR4Ary2       ! 2-dimensional array of SiKi reals
      MODULE PROCEDURE AllR8Ary2       ! 2-dimensional array of R8Ki reals
      MODULE PROCEDURE AllR16Ary2      ! 2-dimensional array of QuKi reals

      MODULE PROCEDURE AllRAry3
      MODULE PROCEDURE AllRAry4
      MODULE PROCEDURE AllRAry5
   END INTERFACE

   INTERFACE AllocPAry
      MODULE PROCEDURE AllIPAry1
      MODULE PROCEDURE AllIPAry2
      MODULE PROCEDURE AllRPAry2
      MODULE PROCEDURE AllRPAry3
!      MODULE PROCEDURE AllRPAry4   !not yet coded
   END INTERFACE


      ! Create interface for a generic ParseVar that actually uses specific routines.

   INTERFACE ParseVar                                                         ! Parses a character variable name and value from a string.
      MODULE PROCEDURE ParseChVar                                             ! Parses a character string from a string.
      MODULE PROCEDURE ParseDbVar                                             ! Parses a double-precision REAL from a string.
      MODULE PROCEDURE ParseInVar                                             ! Parses an INTEGER from a string.
      MODULE PROCEDURE ParseLoVar                                             ! Parses an LOGICAL from a string.
      MODULE PROCEDURE ParseSiVar                                             ! Parses a single-precision REAL from a string.
   END INTERFACE


      ! Create interface for a generic ParseAry that actually uses specific routines.

   INTERFACE ParseAry                                                         ! Parse an array of numbers from a string.
      MODULE PROCEDURE ParseDbAry                                             ! Parse an array of double-precision REAL values.
      MODULE PROCEDURE ParseInAry                                             ! Parse an array of whole numbers.
      MODULE PROCEDURE ParseLoAry                                             ! Parse an array of LOGICAL values.
      MODULE PROCEDURE ParseSiAry                                             ! Parse an array of single-precision REAL values.
   END INTERFACE


      ! Create interface for a generic ReadVar that actually uses specific routines.

   INTERFACE ReadVar
      MODULE PROCEDURE ReadCVar
      MODULE PROCEDURE ReadIVar
      MODULE PROCEDURE ReadLVar
      MODULE PROCEDURE ReadR4Var     ! 4-byte real
      MODULE PROCEDURE ReadR8Var     ! 8-byte real
      MODULE PROCEDURE ReadR16Var    ! 16-byte real
   END INTERFACE


      ! Create interface for a generic ReadAry that actually uses specific routines.

   INTERFACE ReadAry
      MODULE PROCEDURE ReadCAry
      MODULE PROCEDURE ReadIAry
      MODULE PROCEDURE ReadLAry
      MODULE PROCEDURE ReadR4Ary  ! read array of 4-byte reals
      MODULE PROCEDURE ReadR8Ary  ! read array of 8-byte reals
      MODULE PROCEDURE ReadR16Ary ! read array of 16-byte reals
   END INTERFACE


   INTERFACE ReadAryLines
      MODULE PROCEDURE ReadCAryLines
      MODULE PROCEDURE ReadR4AryLines
      MODULE PROCEDURE ReadR8AryLines
      MODULE PROCEDURE ReadR16AryLines
!     MODULE PROCEDURE ReadIAryLines         ! Not coded yet
!     MODULE PROCEDURE ReadLAryLines         ! Not coded yet
   END INTERFACE


      ! Create interface for a generic Num2LStr that actually uses specific routines.

   INTERFACE Num2LStr
      MODULE PROCEDURE Int2LStr        ! default integers
      MODULE PROCEDURE R2LStr4         ! 4-byte  reals
      MODULE PROCEDURE R2LStr8         ! 8-byte  reals
      MODULE PROCEDURE R2LStr16        ! 16-byte reals
   END INTERFACE


      ! Create interface for DispNVD so that we can pass in the name of the program

   INTERFACE DispNVD
      MODULE PROCEDURE DispNVD0        ! No arguments.
      MODULE PROCEDURE DispNVD1        ! Single argument of TYPE ProgDesc
      MODULE PROCEDURE DispNVD2        ! Two arguments of TYPE character
   END INTERFACE

      ! Create interface for writing matrix and array values (useful for debugging)
   INTERFACE WrMatrix
      MODULE PROCEDURE WrMatrix1R4     ! Single dimension matrix (Ary) of SiKi
      MODULE PROCEDURE WrMatrix2R4     ! Two dimension matrix of SiKi
      MODULE PROCEDURE WrMatrix1R8     ! Single dimension matrix (Ary) of R8Ki
      MODULE PROCEDURE WrMatrix2R8     ! Two dimension matrix of R8Ki
   END INTERFACE


CONTAINS

   ! It contains the following routines:

   !     SUBROUTINE AdjRealStr    ( NumStr )                                                                         ! Removes leading spaces and trailing zeros from strings created by real numbers.
   !     SUBROUTINE AllocAry           ( )                                                                                ! Generic interface for the All*Ary* routines (allocatable arrays).
   !     SUBROUTINE AllocPAry          ( )                                                                                ! Generic interface for the All*PAry* routines (pointer arrays).
   !     SUBROUTINE AllCAry1      ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D CHARACTER array.
   !     SUBROUTINE AllCAry2      ( Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )                                  ! Allocate a 2-D CHARACTER array.
   !     SUBROUTINE AllCAry3      ( Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )                         ! Allocate a 3-D CHARACTER array.
   !     SUBROUTINE AllI1BAry1    ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D 1-Byte INTEGER array.
   !     SUBROUTINE AllI2BAry1    ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D 2-Byte INTEGER array.
   !     SUBROUTINE AllI4BAry1    ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D 4-Byte INTEGER array.
   !     SUBROUTINE AllIAry2      ( Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )                                  ! Allocate a 2-D INTEGER array.
   !     SUBROUTINE AllIAry3      ( Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )                         ! Allocate a 3-D INTEGER array.
   !     SUBROUTINE AllLAry1      ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D LOGICAL array.
   !     SUBROUTINE AllLAry2      ( Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )                                  ! Allocate a 2-D LOGICAL array.
   !     SUBROUTINE AllLAry3      ( Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )                         ! Allocate a 3-D LOGICAL array.
   !     SUBROUTINE AllR4Ary1     ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D 4-Byte REAL array.
   !     SUBROUTINE AllR8Ary1     ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D 8-Byte REAL array.
   !     SUBROUTINE AllR16Ary1    ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 1-D 16-Byte REAL array.
   !     SUBROUTINE AllR4Ary2     ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 2-D 4-Byte REAL array.
   !     SUBROUTINE AllR8Ary2     ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 2-D 8-Byte REAL array.
   !     SUBROUTINE AllR16Ary2    ( Ary, AryDim, Descr, ErrStat, ErrMsg )                                            ! Allocate a 2-D 16-Byte REAL array.
   !     SUBROUTINE AllRAry3      ( Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )                         ! Allocate a 3-D REAL array.
   !     SUBROUTINE AllRAry4      ( Ary, AryDim1, AryDim2, AryDim3, AryDim4, Descr, ErrStat, ErrMsg )                ! Allocate a 4-D REAL array.
   !     SUBROUTINE AllRAry5      ( Ary, AryDim1, AryDim2, AryDim3, AryDim4, AryDim5, Descr, ErrStat, ErrMsg )       ! Allocate a 5-D REAL array.
   !     SUBROUTINE CheckArgs     ( InputFile [, ErrStat] )
   !     SUBROUTINE CheckIOS      ( IOS, Fil, Variable, VarType [,ErrStat, ErrMsg] [,TrapErrors] )
   !     SUBROUTINE ChkParseData  ( Words, ExpVarName, FileName, FileLineNum, NameIndx, ErrStat, ErrMsg )             ! Checks data to be parsed to ensure it has the right variable name and a value to go with it.
   !     SUBROUTINE ChkRealFmtStr ( RealFmt, RealFmtVar, ErrStat, ErrMsg )                            ! Test to see if a specified string is a valid format for real numbers.
   !     SUBROUTINE Conv2UC       ( Str )
   !     FUNCTION   CountWords    ( Line )
   !     FUNCTION   CurDate       ( )
   !     FUNCTION   CurTime       ( )
   !     SUBROUTINE DispNVD       ( )                                                                        ! Generic interface for DispNVD0, DispNVD1, DispNVD2.
   !     SUBROUTINE DispNVD0      ( )                                                                        ! Used when DispNVD() has no agruments.
   !     SUBROUTINE DispNVD1      ( ProgInfo )                                                               ! Used when DispNVD() is called with an argument of ProgDesc type.
   !     SUBROUTINE DispNVD2      ( Name, Ver )                                                              ! Used when DispNVD() is called with name and version.
   !     SUBROUTINE DispCopyrightLicense( ProgInfo )
   !     SUBROUTINE DLLTypePack        ( InData, ReKiBuf, DbKiBuf, IntKiBuf, ErrStat, ErrMsg, SizeOnly )
   !     SUBROUTINE DLLTypeUnPack      ( InData, ReKiBuf, DbKiBuf, IntKiBuf, ErrStat, ErrMsg )
   !     SUBROUTINE FindLine      ( Str , MaxLen , StrEnd )
   !     FUNCTION   GetErrStr          ( ErrID )
   !     SUBROUTINE GetNewUnit    ( UnIn [, ErrStat] [, ErrMsg] )
   !     FUNCTION   GetNVD        ( ProgDesc )
   !     FUNCTION   GetErrStr     ( ErrID )
   !     SUBROUTINE GetPath       ( GivenFil, PathName )
   !     SUBROUTINE GetRoot       ( GivenFil, RootName )
   !     SUBROUTINE GetTokens     ( Line, NumTok, Tokens, Error )
   !     SUBROUTINE GetWords      ( Line, Words, NumWords )
   !     SUBROUTINE InitInpErrs   ( InputErrors, MaxErrs, ErrStat, ErrMsg )                                                ! Initializes the InputErrors structure.
   !     FUNCTION   Int2LStr      ( Intgr )
   !     SUBROUTINE IntAry2Str         ( IntAry, Str, ErrStat, ErrMsg )
   !     SUBROUTINE NameOFile     ( InArg, OutExten, OutFile [, ErrStat] )
   !     SUBROUTINE NormStop      ( )
   !     FUNCTION   Num2LStr      ( Num )                                                                    ! Generic interface for Int2LStr, R2LStr4, R2LStr8, R2LStr16
   !     SUBROUTINE NWTC_DisplaySyntax ( DefaultInputFile, ThisProgName )
   !     SUBROUTINE OpenBInpFile  ( Un, InFile, ErrStat, ErrMsg )
   !     SUBROUTINE OpenBOutFile  ( Un, OutFile, ErrStat, ErrMsg )
   !     SUBROUTINE OpenEcho      ( Un, InFile, ErrStat, ErrMsg [, ProgVer] )
   !     SUBROUTINE OpenFInpFile  ( Un, InFile, ErrStat, ErrMsg )
   !     SUBROUTINE OpenFOutFile  ( Un, OutFile, ErrStat, ErrMsg )
   !     SUBROUTINE OpenFUnkFile  ( Un, OutFile, FailAbt, Failed, Exists, ErrStat, ErrMsg )
   !     SUBROUTINE OpenUInBEFile ( Un, InFile, RecLen, ErrStat, ErrMsg )
   !     SUBROUTINE OpenUInfile   ( Un, InFile, ErrStat, ErrMsg )
   !     SUBROUTINE OpenUOutfile  ( Un, OutFile, ErrStat, ErrMsg )
   !     SUBROUTINE ParseAry                                                                                                    ! generic interface for parsing arrays
   !     SUBROUTINE ParseChVar    ( FileInfo, LineNum, ExpVarName, ChVar, ErrStat, ErrMsg, UnEc )                          ! Parses a CHARACTER from a string. USE ParseVar instead.
   !     SUBROUTINE ParseDbAry    ( FileInfo, LineNum, AryName   , DbAry, AryLen , ErrStat, ErrMsg, UnEc )                       ! Parses a double-precision REAL array from a string. USE ParseAry instead.
   !     SUBROUTINE ParseDbVar    ( FileInfo, LineNum, ExpVarName, DbVar, ErrStat, ErrMsg, UnEc )                                ! Parses a double-precision REAL from a string. USE ParseVar instead.
   !     SUBROUTINE ParseInAry    ( FileInfo, LineNum, AryName   , InAry, AryLen , ErrStat, ErrMsg, UnEc )                       ! Parses a whole-number array from a string. USE ParseAry instead.
   !     SUBROUTINE ParseInclInfo ( InclInfo, FileName, RangeBeg, RangeEnd, ErrStat, ErrMsg )                              ! Parse the information in "@" include statements.
   !     SUBROUTINE ParseInVar    ( FileInfo, LineNum, ExpVarName, InVar, ErrStat, ErrMsg, UnEc )                                ! Parses a whole-number from a string. USE ParseVar instead.
   !     SUBROUTINE ParseLoAry    ( FileInfo, LineNum, AryName   , LoAry, AryLen , ErrStat, ErrMsg, UnEc )                       ! Parses a LOGICAL array from a string. USE ParseAry instead.
   !     SUBROUTINE ParseLoVar    ( FileInfo, LineNum, ExpVarName, LoVar, ErrStat, ErrMsg, UnEc )                                ! Parses a LOGICAL value from a string. USE ParseVar instead.
   !     SUBROUTINE ParseSiAry    ( FileInfo, LineNum, AryName   , SiAry, AryLen , ErrStat, ErrMsg, UnEc )                       ! Parses a single-precision REAL array from a string. USE ParseAry instead.
   !     SUBROUTINE ParseSiVar    ( FileInfo, LineNum, ExpVarName, SiVar, ErrStat, ErrMsg, UnEc )                                ! Parses a single-precision REAL from a string. USE ParseVar instead.
   !     SUBROUTINE ParseVar                                                                                                    ! generic interface for parsing variables   
   !     FUNCTION   PathIsRelative( GivenFil )
   !     SUBROUTINE PremEOF       ( Fil , Variable [, TrapErrors] [, ErrMsg] )
   !     SUBROUTINE ProcessComFile( TopFileName, FileInfo, ErrStat, ErrMsg )                                               ! Call ScanComFile and ReadComFile to fully process commented and possibly nested input files.
   !     SUBROUTINE ProgAbort     ( Message [, TrapErrors] )
   !     SUBROUTINE ProgPause                                                                                ! Pause output so the user has to hit <Enter> to continue.
   !     SUBROUTINE ProgWarn      ( Message )
   !     FUNCTION   R2LStr4       ( FltNum )                                                                 ! Convert  4-byte REALs to left-justified strings. USE Num2LStr() instead.
   !     FUNCTION   R2LStr8       ( FltNum )                                                                 ! Convert  8-byte REALs to left-justified strings. USE Num2LStr() instead.
   !     FUNCTION   R2LStr16      ( FltNum )                                                                 ! Convert 16-byte REALs to left-justified strings. USE Num2LStr() instead.
   !     SUBROUTINE ReadAry       ( UnIn, Fil, Ary, AryLen, AryName, AryDescr, ErrStat [, UnEc] )         ! Generic interface for ReadCAry, ReadIAry, ReadLAry, ReadR4Ary, ReadR8Ary and ReadR16Ary.
   !     SUBROUTINE ReadAryLines  ( UnIn, Fil, Ary, AryLen, AryName, AryDescr, ErrStat [, UnEc] )         ! Generic interface for ReadCAryLines, ReadRAryLines4, ReadRAryLines8, and ReadRAryLines16.
   !     SUBROUTINE ReadCAry      ( UnIn, Fil, CharAry, AryLen, AryName, AryDescr, ErrStat [, UnEc] )
   !     SUBROUTINE ReadCAryLines ( UnIn, Fil, CharAry, AryLen, AryName, AryDescr, ErrStat [, UnEc] )
   !     SUBROUTINE ReadCom       ( UnIn, Fil, ComName, ErrStat, ErrMsg [, UnEc] )                     ! Reads a comment line from an input file. (variable not returned)
   !     SUBROUTINE ReadComFile   ( FileInfo, FileIndx, StartLine, LastLine, ErrStat, ErrMsg )                             ! Recursive routine to read a formatted file (and files it includes) and strips out the comments, copying the remainder in a structure.
   !     SUBROUTINE ReadCVar      ( UnIn, Fil, CharVar, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )
   !     SUBROUTINE ReadFASTbin   ( UnIn, FASTdata , ErrStat, ErrMsg )                                      ! Read a FAST binary output file.
   !     SUBROUTINE ReadIAry      ( UnIn, Fil, IntAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg [, UnEc] )
   !     SUBROUTINE ReadIVar      ( UnIn, Fil, IntVar, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )
   !     SUBROUTINE ReadLAry      ( UnIn, Fil, LogAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg [, UnEc] )
   !     SUBROUTINE ReadLine      ( UnIn, CommChars, Line, LineLen, IOStat )                                 ! Reads a line from the specified input unit and returns the non-comment portion of the line.
   !     SUBROUTINE ReadLVar      ( UnIn, Fil, LogVar, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )
   !     SUBROUTINE ReadNum       ( UnIn, Fil, Word, VarName, ErrStat, ErrMsg [, UnEc] )
   !     SUBROUTINE ReadOutputList( UnIn, Fil, CharAry, AryLenRead, AryName, AryDescr, ErrStat, ErrMsg, UnEc )
   !     SUBROUTINE ReadR4Ary     ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )
   !     SUBROUTINE ReadR8Ary     ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )
   !     SUBROUTINE ReadR16Ary    ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )
   !     SUBROUTINE ReadAryLines  ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg [, UnEc] )     ! Generic interface for ReadCAryLines, ReadR4AryLines, ReadR8AryLines, and ReadR16AryLines
   !     SUBROUTINE ReadR4Var     ( UnIn, Fil, RealVar, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )             ! Reads a 4-byte real number from an input file. USE ReadVar instead.
   !     SUBROUTINE ReadR8Var     ( UnIn, Fil, RealVar, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )             ! Reads a 8-byte real number from an input file. USE ReadVar instead.
   !     SUBROUTINE ReadR16Var    ( UnIn, Fil, RealVar, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )             ! Reads a 16-byte real number from an input file. USE ReadVar instead.
   !     SUBROUTINE ReadStr       ( UnIn, Fil, CharVar, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )             ! Reads a string (up to 200 characters--until end-of-line) from an input file.
   !     SUBROUTINE ReadVar       ( UnIn, Fil, Var, VarName, VarDescr, ErrStat, ErrMsg [, UnEc] )                 ! Generic interface for ReadCVar, ReadIVar, ReadLVar, and ReadR*Var.
   !     SUBROUTINE RemoveNullChar     ( Str )
   !     SUBROUTINE ScanComFile   ( FirstFile, ThisFile, LastFile, StartLine, LastLine, NumLines, ErrStat, ErrMsg )        ! Recursive routine to scan commented input files.
   !     SUBROUTINE SetErrStat         ( ErrStatLcl, ErrMessLcl, ErrStat, ErrMess, RoutineName ) !note: moved to NWTC_Library_Types.f90
   !     SUBROUTINE Str2IntAry         ( Str, IntAry, ErrStat, ErrMsg )
   !     SUBROUTINE WaitTime      ( WaitSecs )
   !     SUBROUTINE WrBinFAST     ( FileName, FileID, DescStr, ChanName, ChanUnit, TimeData, AllOutData, ErrStat, ErrMsg )
   !     SUBROUTINE WrFileNR      ( Unit, Str )
   !     SUBROUTINE WrML          ( Str )
   !     SUBROUTINE WrMatrix           ( A, Un, ReFmt, MatName )                                                  ! generic interface to write 1- or 2- dimensional real 4 or 8 values to unit Un
   !     SUBROUTINE WrPr          ( Str )
   !     SUBROUTINE WrReAryFileNR      ( Unit, Ary, Fmt, ErrStat, ErrMsg )
   !     SUBROUTINE WrScr         ( Str )
   !     SUBROUTINE WrScr1        ( Str )                                                 use ----> WrScr( NewLine//Str )

!=======================================================================
   SUBROUTINE AdjRealStr( NumStr )

      ! This routine adjusts strings created from real numbers (4, 8, or 16-byte)
      ! It removes leading spaces and trailing zeros. It is intended to be called
      ! from routines R2LStr4, R2LStr8, and R2LStr16.

   CHARACTER(*), INTENT(INOUT) :: NumStr       ! String representing a real number (e.g., from R2LStr4)

         ! Local declarations.

   INTEGER                      :: IC          ! Character index.


   NumStr = ADJUSTL( NumStr )


      ! Replace trailing zeros and possibly the decimal point with blanks.
      ! Stop trimming once we find the decimal point or a nonzero.


      ! Don't remove (important!) trailing zeros if they are in the exponent:

   IF (INDEX( NumStr, "E" ) > 0 ) RETURN
   IF (INDEX( NumStr, "e" ) > 0 ) RETURN

      ! These are not in the exponent

   DO IC=LEN_TRIM( NumStr ),1,-1

      IF ( NumStr(IC:IC) == '.' )  THEN
         NumStr(IC:IC) = ' '
         RETURN
      ELSE IF ( NumStr(IC:IC) /= '0' )  THEN
         RETURN
      END IF

      NumStr(IC:IC) = ' '

   END DO ! IC


   END SUBROUTINE AdjRealStr
!=======================================================================
   SUBROUTINE AllCAry1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )

      ! This routine allocates a 1-D CHARACTER array.


      ! Argument declarations.

   CHARACTER(*), ALLOCATABLE         :: Ary    (:)                                 ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim                                     ! The size of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat

   
   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )


   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating memory for '//TRIM(Num2LStr(AryDim))//' characters in the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF

   RETURN
   END SUBROUTINE AllCAry1 
!=======================================================================
   SUBROUTINE AllCAry2 ( Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )

      ! This routine allocates a 2-D CHARACTER array.


      ! Argument declarations.

   CHARACTER(*), ALLOCATABLE         :: Ary    (:,:)                               ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.



   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating memory for '//TRIM(Num2LStr(AryDim1*AryDim2))//' characters in the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE AllCAry2
!=======================================================================
   SUBROUTINE AllCAry3 (  Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 3-D CHARACTER array.


      ! Argument declarations.

   CHARACTER(*), ALLOCATABLE         :: Ary    (:,:,:)                             ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim3                                    ! The size of the third dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim1,AryDim2,AryDim3) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating memory for '//TRIM(Num2LStr(AryDim1*AryDim2*AryDim3))//' characters in the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF



   RETURN
   END SUBROUTINE AllCAry3
!=======================================================================
   SUBROUTINE AllI1BAry1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 1-D INTEGER B1Ki array.


      ! Argument declarations.

   INTEGER(B1Ki),  ALLOCATABLE :: Ary    (:)                                 ! Array to be allocated
   INTEGER(IntKi), INTENT(IN)  :: AryDim                                     ! The size of the array
   CHARACTER(*),   INTENT(IN)  :: Descr                                      ! Brief array description
   INTEGER(IntKi), INTENT(OUT) :: ErrStat                                    ! Error status
   CHARACTER(*),   INTENT(OUT) :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim*1))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg = ' '
   END IF

   RETURN
   END SUBROUTINE AllI1BAry1
!=======================================================================
   SUBROUTINE AllI2BAry1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 1-D INTEGER B2Ki array.


      ! Argument declarations.

   INTEGER(B2Ki),  ALLOCATABLE :: Ary    (:)                                 ! Array to be allocated
   INTEGER(IntKi), INTENT(IN)  :: AryDim                                     ! The size of the array
   CHARACTER(*),   INTENT(IN)  :: Descr                                      ! Brief array description
   INTEGER(IntKi), INTENT(OUT) :: ErrStat                                    ! Error status
   CHARACTER(*),   INTENT(OUT) :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim*2))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg = ' '
   END IF

   RETURN
   END SUBROUTINE AllI2BAry1
!=======================================================================
   SUBROUTINE AllI4BAry1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 1-D INTEGER B1Ki array.


      ! Argument declarations.

   INTEGER(B4Ki),  ALLOCATABLE :: Ary    (:)                                 ! Array to be allocated
   INTEGER(IntKi), INTENT(IN)  :: AryDim                                     ! The size of the array
   CHARACTER(*),   INTENT(IN)  :: Descr                                      ! Brief array description
   INTEGER(IntKi), INTENT(OUT) :: ErrStat                                    ! Error status
   CHARACTER(*),   INTENT(OUT) :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim*4))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg = ' '
   END IF

   RETURN
   END SUBROUTINE AllI4BAry1
!=======================================================================
   SUBROUTINE AllIAry2 (  Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 2-D INTEGER array.


      ! Argument declarations.

   INTEGER(IntKi), ALLOCATABLE       :: Ary    (:,:)                               ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*BYTES_IN_INT))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF

   RETURN
   END SUBROUTINE AllIAry2
!=======================================================================
   SUBROUTINE AllIAry3 (  Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 3-D INTEGER array.


      ! Argument declarations.

   INTEGER(IntKi),  ALLOCATABLE      :: Ary    (:,:,:)                             ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim3                                    ! The size of the third dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status; if present, program does not abort on error
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat



   ALLOCATE ( Ary(AryDim1,AryDim2,AryDim3) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*AryDim3*BYTES_IN_INT))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF
   

   RETURN
   END SUBROUTINE AllIAry3
!=======================================================================
   SUBROUTINE AllIPAry1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )

      ! This routine allocates a 1-D INTEGER array.

      ! Argument declarations.

   INTEGER,      POINTER             :: Ary    (:)                                 ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim                                     ! The size of the array.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.


   IF ( ASSOCIATED(Ary) ) THEN
      DEALLOCATE(Ary)
      !ErrStat = ErrID_Warn
      !ErrMsg = " AllIPAry1: Ary already allocated."
   END IF

   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )
   
   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF
   
   Ary = 0

   RETURN
   END SUBROUTINE AllIPAry1 
!=======================================================================
   SUBROUTINE AllIPAry2 (  Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 2-D INTEGER array.

      ! Argument declarations.

   INTEGER,      POINTER             :: Ary    (:,:)                               ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat
   CHARACTER(*), INTENT(IN)          :: Descr                                       ! Brief array description.



   IF ( ASSOCIATED(Ary) ) THEN
      DEALLOCATE(Ary)
      !ErrStat = ErrID_Warn
      !ErrMsg = " AllIPAry2: Ary already allocated."
   END IF

   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )
   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF
   
   Ary = 0
   RETURN
   END SUBROUTINE AllIPAry2 
!=======================================================================
   SUBROUTINE AllRPAry2 (  Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )

      ! This routine allocates a 2-D REAL array.
      ! Argument declarations.

   REAL(ReKi),   POINTER             :: Ary    (:,:)                               ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.


   IF ( ASSOCIATED(Ary) ) THEN
      DEALLOCATE(Ary)
      !ErrStat = ErrID_Warn
      !ErrMsg = " AllRPAry2: Ary already allocated."
   END IF

   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )
   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*BYTES_IN_REAL))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF
   
   Ary = 0
   RETURN
   END SUBROUTINE AllRPAry2 
!=======================================================================
   SUBROUTINE AllRPAry3 (  Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg ) 


      ! This routine allocates a 3-D REAL array.

      ! Argument declarations.

   REAL(ReKi),   POINTER             :: Ary    (:,:,:)                             ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim3                                    ! The size of the third dimension of the array.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.


   IF ( ASSOCIATED(Ary) ) THEN
      DEALLOCATE(Ary)
      !ErrStat = ErrID_Warn
      !ErrMsg = " AllRPAry3: Ary already allocated."
   END IF

   ALLOCATE ( Ary(AryDim1,AryDim2,AryDim3) , STAT=ErrStat )
   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*AryDim3*BYTES_IN_REAL))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF
   
   Ary = 0
   RETURN
  END SUBROUTINE AllRPAry3
!=======================================================================
   SUBROUTINE AllLAry1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 1-D LOGICAL array.


      ! Argument declarations.

   LOGICAL,      ALLOCATABLE         :: Ary    (:)                                 ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim                                     ! The size of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status; if present, program does not abort on error
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat



   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating memory for '//TRIM(Num2LStr(AryDim))//&
                  ' logical values in the '//TRIM( Descr )//' array.'
      END IF      
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE AllLAry1
!=======================================================================
   SUBROUTINE AllLAry2 (  Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 2-D LOGICAL array.


      ! Argument declarations.

   LOGICAL,      ALLOCATABLE         :: Ary    (:,:)                               ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status; if present, program does not abort on error
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat



   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating memory for '//TRIM(Num2LStr(AryDim1*AryDim2))//&
                  ' logical values in the '//TRIM( Descr )//' array.'
      END IF      
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE AllLAry2
!=======================================================================
   SUBROUTINE AllLAry3 (  Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 3-D LOGICAL array.


      ! Argument declarations.
   LOGICAL,      ALLOCATABLE         :: Ary    (:,:,:)                             ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim3                                    ! The size of the third dimension of the array.

   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status; if present, program does not abort on error
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat



   ALLOCATE ( Ary(AryDim1,AryDim2,AryDim3) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating memory for '//TRIM(Num2LStr(AryDim1*AryDim2*AryDim3))//&
                  ' logical values in the '//TRIM( Descr )//' array.'
      END IF      
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE AllLAry3
!=======================================================================
   SUBROUTINE AllR4Ary1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 1-D 4-byte REAL array.


      ! Argument declarations.

   REAL(SiKi),      ALLOCATABLE      :: Ary    (:)                                 ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim                                     ! The size of the array.

   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim*BYTES_IN_SiKi))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF

   RETURN
   END SUBROUTINE AllR4Ary1
!=======================================================================
   SUBROUTINE AllR8Ary1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 1-D 8-byte REAL array.


      ! Argument declarations.

   REAL(R8Ki),      ALLOCATABLE      :: Ary    (:)                                 ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim                                     ! The size of the array.

   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat

   
   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim*BYTES_IN_R8Ki))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF

   RETURN
   END SUBROUTINE AllR8Ary1
!=======================================================================
   SUBROUTINE AllR16Ary1 ( Ary, AryDim, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 1-D 16-byte REAL array.


      ! Argument declarations.

   REAL(QuKi),      ALLOCATABLE      :: Ary    (:)                                 ! Array to be allocated
   INTEGER,      INTENT(IN)          :: AryDim                                     ! The size of the array.

   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim*BYTES_IN_QuKi))//' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE AllR16Ary1
!=======================================================================
   SUBROUTINE AllR4Ary2 (  Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 2-D 4-Byte REAL array.


      ! Argument declarations.

   REAL(SiKi), ALLOCATABLE           :: Ary    (:,:)                               ! Array to be allocated

   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )

   
   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*BYTES_IN_SiKi))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE AllR4Ary2
!=======================================================================
   SUBROUTINE AllR8Ary2 (  Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 2-D 8-Byte REAL array.


      ! Argument declarations.

   REAL(R8Ki), ALLOCATABLE           :: Ary    (:,:)                               ! Array to be allocated

   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat



   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*BYTES_IN_R8Ki))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE AllR8Ary2
!=======================================================================
   SUBROUTINE AllR16Ary2 (  Ary, AryDim1, AryDim2, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 2-D 4-Byte REAL array.


      ! Argument declarations.

   REAL(QuKi), ALLOCATABLE           :: Ary    (:,:)                               ! Array to be allocated

   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat



   ALLOCATE ( Ary(AryDim1,AryDim2) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*BYTES_IN_QuKi))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF

   RETURN
   END SUBROUTINE AllR16Ary2
!=======================================================================
   SUBROUTINE AllRAry3 (  Ary, AryDim1, AryDim2, AryDim3, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 3-D REAL array.


      ! Argument declarations.

   REAL(ReKi), ALLOCATABLE           :: Ary    (:,:,:)                             ! Array to be allocated

   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim3                                    ! The size of the third dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status; if present, program does not abort on error
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim1,AryDim2,AryDim3) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*AryDim3*BYTES_IN_REAL))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF

   RETURN
   END SUBROUTINE AllRAry3
!=======================================================================
   SUBROUTINE AllRAry4 (  Ary, AryDim1, AryDim2, AryDim3, AryDim4, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 4-D REAL array.


      ! Argument declarations.

   REAL(ReKi),      ALLOCATABLE      :: Ary    (:,:,:,:)                           ! Array to be allocated

   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim3                                    ! The size of the third dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim4                                    ! The size of the fourth dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status; if present, program does not abort on error
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim1,AryDim2,AryDim3,AryDim4) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*AryDim3*AryDim4*BYTES_IN_REAL))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF

   RETURN
   END SUBROUTINE AllRAry4
!=======================================================================
   SUBROUTINE AllRAry5 (  Ary, AryDim1, AryDim2, AryDim3, AryDim4, AryDim5, Descr, ErrStat, ErrMsg )


      ! This routine allocates a 5-D REAL array.


      ! Argument declarations.

   REAL(ReKi),      ALLOCATABLE      :: Ary    (:,:,:,:,:)                         ! Array to be allocated

   INTEGER,      INTENT(IN)          :: AryDim1                                    ! The size of the first dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim2                                    ! The size of the second dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim3                                    ! The size of the third dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim4                                    ! The size of the fourth dimension of the array.
   INTEGER,      INTENT(IN)          :: AryDim5                                    ! The size of the fourth dimension of the array.
   CHARACTER(*), INTENT(IN)          :: Descr                                      ! Brief array description.
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status; if present, program does not abort on error
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message corresponding to ErrStat


   ALLOCATE ( Ary(AryDim1,AryDim2,AryDim3,AryDim4,AryDim5) , STAT=ErrStat )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      IF ( ALLOCATED(Ary) ) THEN ! or Sttus=151 on IVF
         ErrMsg = 'Error allocating memory for the '//TRIM( Descr )//' array; array was already allocated.'
      ELSE
         ErrMsg = 'Error allocating '//TRIM(Num2LStr(AryDim1*AryDim2*AryDim3*AryDim4*AryDim5*BYTES_IN_REAL))//&
                  ' bytes of memory for the '//TRIM( Descr )//' array.'
      END IF
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF



   RETURN
   END SUBROUTINE AllRAry5
!=======================================================================
   SUBROUTINE CheckArgs ( InputFile, ErrStat, Arg2, Flag )


      ! This subroutine is used to check for command-line arguments.


      ! Argument declarations:
   INTEGER,      INTENT(  OUT),OPTIONAL :: ErrStat                                      ! Error status; if present, program does not abort on error

   CHARACTER(*), INTENT(INOUT)          :: InputFile                                    ! The name of the input file specified on the command line.
   CHARACTER(*), INTENT(  OUT),OPTIONAL :: Arg2                                         ! an optional 2nd argument
   CHARACTER(*), INTENT(  OUT),OPTIONAL :: Flag                                         ! an optional flag argument (e.g., restart)

      ! Local declarations:

   INTEGER                              :: IArg                                         ! The argument number.
   INTEGER                              :: NumArg                                       ! The number of arguments on the command line.
                                        
   INTEGER                              :: Error                                        ! Error Status: indicates if there was an error getting an argument.
   LOGICAL                              :: FirstArg                                     ! flag to determine if it's the first non-switch argument
   CHARACTER(LEN(InputFile))            :: Arg                                          ! A command-line argument.
   



      ! Find out how many arguments were entered on the command line.

   NumArg   = COMMAND_ARGUMENT_COUNT()
   FirstArg = .TRUE.

   IF ( PRESENT(Arg2) ) Arg2 = ""
   IF ( PRESENT(flag) ) flag = ""

      ! Parse them.

   IF ( NumArg .GT. 0 )  THEN

      DO IArg=1,NumArg

         CALL GET_COMMAND_ARGUMENT( IArg, Arg, STATUS=Error )

         IF ( Error /= 0 )  THEN
            CALL ProgAbort ( ' Error getting command-line argument #'//TRIM( Int2LStr( IArg ) )//'.', PRESENT(ErrStat) )
            IF ( PRESENT(ErrStat) ) THEN
               ErrStat = ErrID_Fatal
               RETURN
            END IF
         END IF

         IF ( Arg(1:1) == SwChar .OR. Arg(1:1) == '-' )  THEN
            IF (PRESENT(flag)) THEN
               CALL Conv2UC( Arg )
               Flag = Arg(2:) !this results in only the last flag
               IF ( TRIM(Flag) == 'RESTART' )  CYCLE         ! Get next argument (which will be input [checkpoint] file name)

            END IF
                                                
            CALL NWTC_DisplaySyntax( InputFile, ProgName )

            IF ( INDEX( 'Hh?', Arg(2:2)  ) > 0 )  THEN
               IF ( PRESENT(ErrStat) ) THEN
                  ErrStat = ErrID_Info !bjj? do we want to check if an input file was specified later?
                  RETURN
               ELSE
                  CALL ProgExit ( 1 )
               END IF
            ELSE
               CALL ProgAbort ( ' Invalid command-line switch "'//SwChar//TRIM( Arg(2:) )//'".', PRESENT(ErrStat) )
               IF ( PRESENT(ErrStat) ) THEN
                  ErrStat = ErrID_Fatal
                  RETURN
               END IF
            END IF ! ( INDEX( 'Hh?', Arg(2:2)  ) > 0 )

         ELSEIF ( FirstArg ) THEN
            InputFile = Arg
            FirstArg = .FALSE.
         ELSE   
            IF ( PRESENT(Arg2) ) THEN
               Arg2 = Arg
            END IF
         END IF ! ( Arg(1:1) == SwChar )

      END DO ! IArg

   END IF ! ( NumArg .GT. 0 )

   IF ( PRESENT( ErrStat ) ) ErrStat = ErrID_None

   RETURN

   END SUBROUTINE CheckArgs ! ( InputFile [, ErrStat] )
!=======================================================================
   SUBROUTINE ChkParseData ( Words, ExpVarName, FileName, FileLineNum, NameIndx, ErrStat, ErrMsg )


      ! This subroutine checks the data to be parsed to make sure it finds
      ! the expected variable name and an associated value.


         ! Arguments declarations.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(IN)             :: FileLineNum                   ! The number of the line in the file being parsed.
      INTEGER(IntKi), INTENT(OUT)            :: NameIndx                      ! The index into the Words array that points to the variable name.

      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.
      CHARACTER(*),   INTENT(IN)             :: ExpVarName                    ! The expected variable name.
      CHARACTER(*),   INTENT(IN)             :: FileName                      ! The name of the file being parsed.
      CHARACTER(*),   INTENT(IN)             :: Words       (2)               ! The two words to be parsed from the line.


         ! Local declarations.

      CHARACTER(20)                          :: ExpUCVarName                  ! The uppercase version of ExpVarName.
      CHARACTER(20)                          :: FndUCVarName                  ! The uppercase version of the word being tested.



         ! Convert the found and expected names to uppercase.

      FndUCVarName = Words(1)
      ExpUCVarName = ExpVarName

      CALL Conv2UC ( FndUCVarName )
      CALL Conv2UC ( ExpUCVarName )


         ! See which word is the variable name.  Generate an error if it is neither.
         ! If it is the first word, check to make sure the second word is not empty.

      IF ( TRIM( FndUCVarName ) == TRIM( ExpUCVarName ) )  THEN
         NameIndx = 1
         IF ( LEN_TRIM( Words(2) ) == 0 )  THEN
            CALL ExitThisRoutine ( ErrID_Fatal, NewLine//' >> A fatal error occurred when parsing data from "'//TRIM( FileName ) &
                      //'".'//NewLine//' >> The variable "'//TRIM( Words(1) )//'" was not assigned a value on line #' &
                      //TRIM( Num2LStr( FileLineNum ) )//'.' )
            RETURN
         ENDIF
      ELSE
         FndUCVarName = Words(2)
         CALL Conv2UC ( FndUCVarName )
         IF ( TRIM( FndUCVarName ) == TRIM( ExpUCVarName ) )  THEN
            NameIndx = 2
         ELSE
            CALL ExitThisRoutine ( ErrID_Fatal, NewLine//' >> A fatal error occurred when parsing data from "'//TRIM( FileName ) &
                     //'".'//NewLine//' >> The variable "'//TRIM( ExpVarName )//'" was not found on line #' &
                     //TRIM( Num2LStr( FileLineNum ) )//'.' )
            RETURN
         ENDIF
      ENDIF


      CALL ExitThisRoutine ( ErrID_None, ' ' )

      RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE ExitThisRoutine ( ErrID, Msg )

         ! This subroutine cleans up the parent routine before exiting.


            ! Argument declarations.

         INTEGER(IntKi), INTENT(IN)       :: ErrID                            ! The error identifier (ErrLev)

         CHARACTER(*),   INTENT(IN)       :: Msg                              ! The error message (ErrMsg)


            ! Local declarations.

         LOGICAL                          :: IsOpen                           ! A flag that indicates if the input unit is still open.


            ! Set error status/message

         ErrStat = ErrID
         ErrMsg  = Msg


         RETURN

      END SUBROUTINE ExitThisRoutine ! ( ErrID, Msg )

   END SUBROUTINE ChkParseData ! ( Words, ExpVarName, FileName, FileLineNum, NameIndx, ErrStat, ErrMsg )
!=======================================================================
   SUBROUTINE ChkRealFmtStr ( RealFmt, RealFmtVar, FmtWidth, ErrStat, ErrMsg )


      ! Test to make sure we have a valid format string for real numbers.


      ! Argument declarations.

   INTEGER(IntKi), INTENT(OUT)      :: ErrStat                               ! An error level to be returned to the calling routine.
   INTEGER(IntKi), INTENT(OUT)      :: FmtWidth                              ! The number of characters that will result from writes.

   CHARACTER(*), INTENT(OUT)        :: ErrMsg                                ! An error message to be returned to the calling routine.

   CHARACTER(*), INTENT(IN)         :: RealFmt                               ! The proposed format string.
   CHARACTER(*), INTENT(IN)         :: RealFmtVar                            ! The name of the variable storing the format string.


      ! Local delarations.

   REAL, PARAMETER                  :: TestVal    = -1.0                     ! The value to test the format specifier with.

   INTEGER                          :: IOS                                   ! An integer to store the I/O status of the attempted internal write.
   INTEGER, PARAMETER               :: TestStrLen  = 20                      ! A parameter for specifying the length of RealStr.

   CHARACTER(TestStrLen)            :: RealStr                               ! A string to test writing a real number to.



      ! Try writing TestVal to RealStr using RealFmt as the format.
      ! Determine the format width.

   WRITE (RealStr,'('//RealFmt//')',IOSTAT=IOS)  TestVal

   FmtWidth = Len_Trim( RealStr )


       ! Check to see if the format is invalid or if it did not have even a reasonable width.

   IF ( IOS /= 0 )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'The real-format specifier, '//TRIM(RealFmtVar)//', is invalid.  You set it to "'//TRIM( RealFmt )//'".'
      FmtWidth = 0
   ELSEIF ( INDEX( RealStr, '*' ) > 0 )  THEN
      ErrStat = ErrID_Severe
      ErrMsg = 'The real-format specifier, '//TRIM(RealFmtVar)//', is too narrow to print even '//TRIM(Num2LStr(TestVal)) &
             //'. You set it to "'//TRIM( RealFmt )//'".'
   ELSE
      ErrStat = ErrID_None
      ErrMsg = ""
   ENDIF


   RETURN
   END SUBROUTINE ChkRealFmtStr
!=======================================================================
   SUBROUTINE CheckIOS ( IOS, Fil, Variable, VarType, ErrStat, ErrMsg, TrapErrors )


      ! This routine checks the I/O status and prints either an end-of-file or
      ! an invalid-input message, and then aborts the program.


      ! Argument declarations.

   INTEGER,     INTENT(IN)           :: IOS                                   ! I/O status
   CHARACTER(*),INTENT(IN)           :: Fil                                   ! Name of input file
   CHARACTER(*),INTENT(IN)           :: Variable                              ! Variable name
   INTEGER,     INTENT(IN)           :: VarType                               ! Type of variable
   LOGICAL,     INTENT(IN), OPTIONAL :: TrapErrors                            ! Determines if the program should abort or return to calling function
   INTEGER,     INTENT(OUT),OPTIONAL :: ErrStat                               ! Error status
   CHARACTER(*),INTENT(OUT),OPTIONAL :: ErrMsg                                ! Error message (if present, no message is written to the screen)

      ! local variables
   LOGICAL                           :: TrapThisError                         ! The local version of TrapErrors
   CHARACTER(ErrMsgLen)              :: Msg                                   ! Temporary error message



   IF ( PRESENT( TrapErrors ) ) THEN
      TrapThisError = TrapErrors
   ELSE
      TrapThisError = .FALSE.
   END IF


   IF ( IOS < 0 )  THEN

      Msg = 'Premature EOF for file "'//TRIM( Fil )//'" occurred while trying to read '//TRIM( Variable )//'.'

      IF ( PRESENT(ErrStat) ) ErrStat = ErrID_Fatal
      IF ( PRESENT(ErrMsg) ) THEN
         ErrMsg = Msg
      ELSE
         CALL WrScr( ' ' )
         CALL ProgAbort( ' '//TRIM(Msg), TrapThisError )
      END IF

   ELSE IF ( IOS > 0 )  THEN

      SELECTCASE ( VarType )

      CASE ( NumType )
         Msg = 'Invalid numerical input'
      CASE ( FlgType )
         Msg = 'Invalid logical input'
      CASE ( StrType )
         Msg = 'Invalid character input'
      CASE DEFAULT
         Msg = 'Invalid input (unknown type)'
      ENDSELECT
      Msg = TRIM(Msg)//' for file "'//TRIM( Fil )//'" occurred while trying to read '//TRIM( Variable )//'.'

      IF ( PRESENT(ErrStat) ) ErrStat = ErrID_Fatal
      
      IF ( PRESENT(ErrMsg) ) THEN
         ErrMsg = Msg
      ELSE
         CALL WrScr( ' ' )
         CALL ProgAbort( ' '//TRIM(Msg), TrapThisError )
      END IF

   ELSE

      IF ( PRESENT(ErrStat) ) ErrStat = ErrID_None
      IF ( PRESENT(ErrMsg) ) ErrMsg = ""

   END IF


   RETURN
   END SUBROUTINE CheckIOS
!=======================================================================
   SUBROUTINE Conv2UC ( Str )


      ! This routine converts all the text in a string to upper case.


      ! Argument declarations.

   CHARACTER(*), INTENT(INOUT)  :: Str                                          ! The string to be converted to UC.


      ! Local declarations.

   INTEGER                      :: IC                                           ! Character index



   DO IC=1,LEN_TRIM( Str )

      IF ( ( Str(IC:IC) >= 'a' ).AND.( Str(IC:IC) <= 'z' ) )  THEN
         Str(IC:IC) = CHAR( ICHAR( Str(IC:IC) ) - 32 )
      ELSE
         Str(IC:IC) = Str(IC:IC)
      END IF

   END DO ! IC


   RETURN
   END SUBROUTINE Conv2UC
!=======================================================================
   FUNCTION CountWords ( Line )


      ! This subroutine is used to count the number of "words" in a line of text.
      ! It uses spaces, tabs, commas, semicolons, single quotes, and double quotes ("whitespace")
      !  as word separators.


      ! Function declaration.

   INTEGER                      :: CountWords                                   ! This function.


      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: Line                                         ! Count the words in this text string.


      ! Local declarations.

   INTEGER                      :: Ch                                           ! Character position.
   INTEGER                      :: NextWhite                                    ! Position of the next white space.



      ! Let's initialize the number of columns and the character pointer.

   CountWords = 0


      ! Let's make sure we have text on this line.

   IF ( LEN_TRIM( Line ) == 0 )  RETURN


      ! Count words separated by any combination of spaces, tabs, commas,
      ! semicolons, single quotes, and double quotes ("whitespace").

   Ch = 0

   DO

      NextWhite = SCAN( Line(Ch+1:) , ' ,;''"'//Tab )
      Ch        = Ch + NextWhite

      IF ( NextWhite > 1 )  THEN
         CountWords = CountWords + 1
      ELSE IF ( NextWhite == 1 )  THEN
         CYCLE
      ELSE
         EXIT
      END IF

   END DO


   RETURN
   END FUNCTION CountWords
!=======================================================================
   FUNCTION CurDate( )


      ! This function returns a character string encoded with the date in the form dd-mmm-ccyy.


      ! Function declaration.

   CHARACTER(11)                :: CurDate                                      ! This function


      ! Local declarations.

   CHARACTER(8)                 :: CDate                                        ! String to hold the returned value from the DATE_AND_TIME subroutine call.



   !  Call the system date function.

   CALL DATE_AND_TIME ( CDate )


   !  Parse out the day.

   CurDate(1:3) = CDate(7:8)//'-'


   !  Parse out the month.

   SELECT CASE ( CDate(5:6) )
      CASE ( '01' )
         CurDate(4:6) = 'Jan'
      CASE ( '02' )
         CurDate(4:6) = 'Feb'
      CASE ( '03' )
         CurDate(4:6) = 'Mar'
      CASE ( '04' )
         CurDate(4:6) = 'Apr'
      CASE ( '05' )
         CurDate(4:6) = 'May'
      CASE ( '06' )
         CurDate(4:6) = 'Jun'
      CASE ( '07' )
         CurDate(4:6) = 'Jul'
      CASE ( '08' )
         CurDate(4:6) = 'Aug'
      CASE ( '09' )
         CurDate(4:6) = 'Sep'
      CASE ( '10' )
         CurDate(4:6) = 'Oct'
      CASE ( '11' )
         CurDate(4:6) = 'Nov'
      CASE ( '12' )
         CurDate(4:6) = 'Dec'
   END SELECT


   !  Parse out the year.

   CurDate(7:11) = '-'//CDate(1:4)


   RETURN
   END FUNCTION CurDate
!=======================================================================
   FUNCTION CurTime( )


      ! This function returns a character string encoded with the time in the form "hh:mm:ss".


      ! Function declaration.

   CHARACTER(8)                 :: CurTime                                      ! This function.


      ! Local declarations.

   CHARACTER(10)                :: CTime                                        ! String to hold the returned value from the DATE_AND_TIME subroutine call.



   CALL DATE_AND_TIME ( TIME=CTime )

   CurTime = CTime(1:2)//':'//CTime(3:4)//':'//CTime(5:6)


   RETURN
   END FUNCTION CurTime
!=======================================================================
   SUBROUTINE DispCopyrightLicense( ProgInfo, AdditionalComment )

      ! This routine displays some text about copyright and license.

   TYPE( ProgDesc ), INTENT(IN)           :: ProgInfo    ! Contains the name and version info
   CHARACTER(*),     INTENT(IN), OPTIONAL :: AdditionalComment

      ! local variable
   INTEGER(IntKi)         :: DateLen   ! the trim length of the ProgInfo date field
   INTEGER(IntKi)         :: I         ! generic loop/index
   CHARACTER(4)           :: year      ! the year, determined from ProgInfo's date field
   CHARACTER(MaxWrScrLen) :: Stars     ! a line of '*******' characters

   DO I=1,MaxWrScrLen
      Stars(I:I)='*'
   END DO


   DateLen = LEN_TRIM(ProgInfo%date)
   IF (  DateLen > 3 ) THEN
      I = DateLen-4+1
      year = ProgInfo%date(I:)
   ELSE
      year = ''
   END IF


   CALL WrScr('')
   CALL WrScr(Stars)
   CALL WrScr( TRIM(GetNVD(ProgInfo)) )
   CALL WrScr('')
   CALL WrScr( 'Copyright (C) '//TRIM(year)//' National Renewable Energy Laboratory' )
   CALL WrScr('')
   CALL WrScr( 'This program comes with ABSOLUTELY NO WARRANTY. '//&
               'See the "license.txt" file distributed with this software for details.')   

   IF (PRESENT(AdditionalComment)) THEN
      CALL WrScr(Stars)
      CALL WrScr(Stars)
      CALL WrScr( AdditionalComment )
      CALL WrScr('')       
   END IF
   
   CALL WrScr(Stars)
   CALL WrScr('')


   END SUBROUTINE DispCopyrightLicense
!=======================================================================
   SUBROUTINE DLLTypePack( InData, ReKiBuf, DbKiBuf, IntKiBuf, ErrStat, ErrMsg, SizeOnly )
   
      ! This routine packs the DLL_Type data into an integer buffer.
      ! It is required for the FAST Registry.
   
      TYPE(DLL_Type),                INTENT(IN   ) :: InData
      REAL(ReKi),       ALLOCATABLE, INTENT(  OUT) :: ReKiBuf(:)
      REAL(DbKi),       ALLOCATABLE, INTENT(  OUT) :: DbKiBuf(:)
      INTEGER(IntKi),   ALLOCATABLE, INTENT(  OUT) :: IntKiBuf(:)
      INTEGER(IntKi),                INTENT(  OUT) :: ErrStat
      CHARACTER(*),                  INTENT(  OUT) :: ErrMsg
      LOGICAL,          OPTIONAL,    INTENT(IN   ) :: SizeOnly
      
         ! Local variable
      INTEGER(IntKi)                               :: Int_BufSz
      
      ErrStat = ErrID_None
      ErrMsg  = ""

         ! get size of buffer:
      Int_BufSz = LEN(InData%FileName) + LEN(InData%ProcName) + 1
      
      ALLOCATE( IntKiBuf(Int_BufSz), STAT=ErrStat )
      IF (ErrStat /= 0 ) THEN
         ErrStat = ErrID_Fatal
         ErrMsg  = ' DLLTypePack: Error allocating IntKiBuf.'
         RETURN
      END IF
            
      IF ( PRESENT(SizeOnly) ) THEN
         IF ( SizeOnly ) RETURN
      ENDIF      
      
      !..............
      ! Fill buffer
      !..............
      
         ! has the DLL procedure been loaded?
      IF ( C_ASSOCIATED(InData%ProcAddr)) THEN
         IntKiBuf(1) = 1
      ELSE
         IntKiBuf(1) = 0         
      END IF
      
         ! Put an ascii representation of the strings in the integer array
      CALL Str2IntAry( InData%FileName, IntKiBuf(2:), ErrStat, ErrMsg )
      CALL Str2IntAry( InData%ProcName, IntKiBuf((LEN(InData%FileName)+2):) , ErrStat, ErrMsg )
      
      
   END SUBROUTINE DLLTypePack
!=======================================================================
   SUBROUTINE DLLTypeUnPack( OutData, ReKiBuf, DbKiBuf, IntKiBuf, ErrStat, ErrMsg )
   
      ! This routine unpacks the DLL_Type data from an integer buffer.
      ! It is required for the FAST Registry.
   
      REAL(ReKi),       ALLOCATABLE, INTENT(IN   ) :: ReKiBuf(:)
      REAL(DbKi),       ALLOCATABLE, INTENT(IN   ) :: DbKiBuf(:)
      INTEGER(IntKi),   ALLOCATABLE, INTENT(IN   ) :: IntKiBuf(:)
      TYPE(DLL_Type),                INTENT(  OUT) :: OutData
      INTEGER(IntKi),                INTENT(  OUT) :: ErrStat
      CHARACTER(*),                  INTENT(  OUT) :: ErrMsg
      
         ! Local variable
      INTEGER(IntKi)                               :: Int_BufSz
      
      ErrStat = ErrID_None
      ErrMsg  = ""

      IF (.NOT. ALLOCATED(IntKiBuf) ) THEN
         ErrStat = ErrID_Fatal
         ErrMsg  = ' DLLTypeUnPack: invalid buffer.'
      END IF
                     
         ! Get an ascii representation of the strings from the integer array                           
      Int_BufSz = LEN(OutData%FileName) + 1
      CALL IntAry2Str( IntKiBuf(2:(Int_BufSz)), OutData%FileName, ErrStat, ErrMsg )
      IF (ErrStat >= AbortErrLev) RETURN
      Int_BufSz = Int_BufSz + 1
      CALL IntAry2Str( IntKiBuf(Int_BufSz: ), OutData%ProcName, ErrStat, ErrMsg )
      IF (ErrStat >= AbortErrLev) RETURN

      
      IF ( IntKiBuf(1) == 1 .AND. LEN_TRIM(OutData%FileName) > 0 .AND. LEN_TRIM(OutData%ProcName) > 0 ) THEN
         CALL LoadDynamicLib( OutData, ErrStat, ErrMsg )
      END IF
      
   END SUBROUTINE DLLTypeUnPack   
!=======================================================================
   SUBROUTINE DispNVD0


      ! This routine displays the name of the program, its version, and its release date.


      ! Print out program name, version, and date.

   CALL WrScr ( NewLine//' Running '//TRIM( ProgName )//' '//Trim( ProgVer )//'.' )


   RETURN
   END SUBROUTINE DispNVD0
!=======================================================================
   SUBROUTINE DispNVD1 ( ProgInfo, DispNWTCVer )


      ! This routine displays the name of the program, its version, and its release date.


   IMPLICIT NONE
   TYPE( ProgDesc ), INTENT(IN)        :: ProgInfo    ! Contains the name and version info
   LOGICAL,INTENT(IN),OPTIONAL         :: DispNWTCVer ! Option to display what version of the library is linked with the code

      ! Print out program name, version, and date.

      ! As a special case, display the library version with the program version
   IF ( PRESENT(DispNWTCVer) ) THEN
      IF ( DispNWTCVer .AND. ProgInfo%Name /= NWTC_Ver%Name ) THEN
         CALL WrScr ( NewLine//' Running '//TRIM( GetNVD( ProgInfo ) )//' linked with '//TRIM( GetNVD( NWTC_Ver ) )//'.' )
         RETURN
      END IF
   END IF

   CALL WrScr ( NewLine//' Running '//TRIM( GetNVD( ProgInfo ) )//'.' )


   RETURN
   END SUBROUTINE DispNVD1
!=======================================================================
   SUBROUTINE DispNVD2 ( Name, Ver )


      ! This routine displays the name of the program, its version, and its release date passed in as strings
      ! This routine is depricated and for legacy purposes only. Please don't use for any new code (Dec-2012)

   IMPLICIT NONE
   CHARACTER(*),  INTENT(IN)           :: Name     ! String containing the name of the program using the library
   CHARACTER(*),  INTENT(IN)           :: Ver      ! String containing the version and date info


      ! Print out program name, version, and date.

   CALL WrScr ( NewLine//' Running '//TRIM( Name )//' ('//Trim( Ver )//').' )


   RETURN
   END SUBROUTINE DispNVD2
!=======================================================================
   SUBROUTINE FindLine ( Str , MaxLen , StrEnd )


      ! This routine finds one line of text with a maximum length of MaxLen from the Str.
      ! It tries to break the line at a blank.


   IMPLICIT                        NONE


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: MaxLen                                       ! The maximum length of the string.
   INTEGER, INTENT(OUT)         :: StrEnd                                       ! The location of the end of the string.

   CHARACTER(*), INTENT(IN)     :: Str                                          ! The string to search.


      ! Local declarations:

   INTEGER         IC



   StrEnd = MaxLen

   IF ( LEN_TRIM( Str ) > MaxLen )  THEN

      IC = INDEX( Str(1:MaxLen), ' ', BACK = .TRUE. ) ! Find the last space in the line

      IF ( IC > 1 ) THEN ! We don't want to return just one character that's a space, or do we?

         StrEnd = IC-1    ! StrEnd > 0
         DO WHILE ( Str(StrEnd:StrEnd) == ' ' )
            StrEnd = StrEnd - 1
            IF ( StrEnd <= 0 ) THEN  ! This occurs if everything before IC is a space
               StrEnd = IC
               EXIT
            ENDIF
         ENDDO

      ENDIF ! IC > 1

   ENDIF ! LEN_TRIM( Str ) > MaxLen


   RETURN
   END SUBROUTINE FindLine
!=======================================================================
   SUBROUTINE GetNewUnit ( UnIn, ErrStat, ErrMsg )

      ! This routine returns a unit number not currently in use.


      ! Argument declarations.

   INTEGER,        INTENT(OUT)            :: UnIn                                         ! Logical unit for the file.
   INTEGER(IntKi), INTENT(OUT), OPTIONAL  :: ErrStat                                      ! The error status code; If not present code aborts
   CHARACTER(*),   INTENT(OUT), OPTIONAL  :: ErrMsg                                       ! The error message, if an error occurred


      ! Local declarations.

   INTEGER                                :: Un                                           ! Unit number
   LOGICAL                                :: Opened                                       ! Flag indicating whether or not a file is opened.
   INTEGER(IntKi), PARAMETER              :: StartUnit = 10                               ! Starting unit number to check (numbers less than 10 reserved)
   INTEGER(IntKi), PARAMETER              :: MaxUnit   = 99                               ! The maximum unit number available (or 10 less than the number of files you want to have open at a time)
   CHARACTER(ErrMsgLen)                   :: Msg                                          ! Temporary error message


      ! Initialize subroutine outputs

   Un = StartUnit

   IF ( PRESENT( ErrStat ) ) ErrStat = ErrID_None
   IF ( PRESENT( ErrMsg  ) ) ErrMsg  =  ''

      ! See if unit is connected to an open file. Check the next largest number until it is not opened.

   DO

      INQUIRE ( UNIT=Un , OPENED=Opened )

      IF ( .NOT. Opened )  EXIT
      Un = Un + 1

      IF ( Un > MaxUnit ) THEN

         Msg = 'GetNewUnit() was unable to find an open file unit specifier between '//TRIM(Num2LStr(StartUnit)) &
                                                                            //' and '//TRIM(Num2LStr(MaxUnit))//'.'

         IF ( PRESENT( ErrStat ) ) THEN
            ErrStat = ErrID_Severe
            IF ( PRESENT( ErrMsg) ) ErrMsg  =  Msg
         ELSE
            CALL ProgAbort( Msg )
         END IF

         EXIT           ! stop searching now

      END IF


   END DO

   UnIn = Un

   RETURN
   END SUBROUTINE GetNewUnit
!=======================================================================
   FUNCTION GetErrStr  ( ErrID )

      ! This function returns a description of the ErrID code

      ! Argument declarations.
   INTEGER(IntKi), INTENT(IN) :: ErrID

      ! Function delcaration
   CHARACTER(13)              :: GetErrStr

      SELECT CASE ( ErrID )
         CASE ( ErrID_None )
            GetErrStr = ''
         CASE ( ErrID_Info )
            GetErrStr = 'INFORMATION'
         CASE ( ErrID_Warn )
            GetErrStr = 'WARNING'
         CASE ( ErrID_Severe )
            GetErrStr = 'SEVERE ERROR'
         CASE ( ErrID_Fatal )
            GetErrStr = 'FATAL ERROR'
         CASE DEFAULT
            GetErrStr = 'Unknown ErrID'
      END SELECT


   END FUNCTION GetErrStr
!=======================================================================
   FUNCTION GetNVD ( ProgInfo )

      ! This function converts the three strings contained in the ProgDesc
      ! data type into a single string listing the program name,
      ! version, and release date.


      ! Argument declarations.

   TYPE( ProgDesc ), INTENT(IN)        :: ProgInfo    ! Contains the name and version info


      ! Function delcaration

   CHARACTER(200)                      :: GetNVD      ! A single string containing the name, date, and version info


      ! Print all the version info into a nice string:

      GetNVD = TRIM( ProgInfo%Name )//' ('//Trim( ProgInfo%Ver )//', '//Trim( ProgInfo%Date )//')'

   END FUNCTION GetNVD
!=======================================================================
   SUBROUTINE GetPath ( GivenFil, PathName )


      ! Let's parse the path name from the name of the given file.
      ! We'll count everything before (and including) the last "\" or "/".


      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: GivenFil                                     ! The name of the given file.
   CHARACTER(*), INTENT(OUT)    :: PathName                                     ! The path name of the given file.


      ! Local declarations.

   INTEGER                      :: I                                            ! DO index for character position.


      ! Look for path separators

   I = INDEX( GivenFil, '\', BACK=.TRUE. )
   I = MAX( I, INDEX( GivenFil, '/', BACK=.TRUE. ) )

   IF ( I == 0 ) THEN
      ! we don't have a path specified, return '.'
      PathName = '.'//PathSep
   ELSE
      PathName = GivenFil(:I)
   END IF


   RETURN
   END SUBROUTINE GetPath
!=======================================================================
   SUBROUTINE GetRoot ( GivenFil, RootName )


      ! Let's parse the root file name from the name of the given file.
      ! We'll count everything after the last period as the extension.


      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: GivenFil                                     ! The name of the given file.
   CHARACTER(*), INTENT(OUT)    :: RootName                                     ! The parsed root name of the given file.


      ! Local declarations.

   INTEGER                      :: I                                            ! DO index for character position.



      ! Deal with a couple of special cases.

   IF ( ( TRIM( GivenFil ) == "." ) .OR. (  TRIM( GivenFil ) == ".." ) )  THEN
      RootName = TRIM( GivenFil )
      RETURN
   END IF


      ! More-normal cases.

   DO I=LEN_TRIM( GivenFil ),1,-1


      IF ( GivenFil(I:I) == '.' )  THEN


         IF ( I < LEN_TRIM( GivenFil ) ) THEN                   ! Make sure the index I is okay
            IF ( INDEX( '\/', GivenFil(I+1:I+1)) == 0 ) THEN    ! Make sure we don't have the RootName in a different directory
               RootName = GivenFil(:I-1)
            ELSE
               RootName = GivenFil                              ! This does not have a file extension
            END IF
         ELSE
            IF ( I == 1 ) THEN
               RootName = ''
            ELSE
               RootName = GivenFil(:I-1)
            END IF
         END IF

         RETURN

      END IF
   END DO ! I

   RootName =  GivenFil


   RETURN
   END SUBROUTINE GetRoot
!=======================================================================
   SUBROUTINE GetTokens ( Line, NumTok, Tokens, Error )


      ! This routine will parse Line for NumTok "tokens" and return them in the Tokens array.
      ! This routine differs from GetWords() in that it uses only spaces as token separators.


      ! Argument declarations.

   INTEGER, INTENT(IN)          :: NumTok                                       ! The number of "words" to look for.

   LOGICAL, INTENT(OUT)         :: Error                                        ! Error flag to indicate an insuffient number of tokens were found.

   CHARACTER(*), INTENT(INOUT)  :: Line                                         ! The string to search.
   CHARACTER(*), INTENT(OUT)    :: Tokens  (:)                                  ! The tokens that were found.


      ! Local declarations.

   INTEGER                      :: IT                                           ! Token index
   INTEGER                      :: NextBlank                                    ! The location of the next blank character



   NextBlank = 0

   DO IT=1,NumTok

      Line      = ADJUSTL( Line(NextBlank+1:) )
      NextBlank = INDEX  ( Line , ' ' )

      IF ( NextBlank == 0 .OR. IT > SIZE(Tokens) )  THEN
        Error = .TRUE.
        RETURN
      END IF

      Tokens(IT) = Line(1:NextBlank-1)

   END DO ! IT

   Error = .FALSE.


   RETURN
   END SUBROUTINE GetTokens
!=======================================================================
   SUBROUTINE GetWords ( Line, Words, NumWords )


      ! This subroutine is used to get NumWords "words" from a line of text.


      ! Argument declarations.

   INTEGER, INTENT(IN)          :: NumWords                                     ! The number of words to look for.

   CHARACTER(*), INTENT(IN)     :: Line                                         ! The string to search.
   CHARACTER(*), INTENT(OUT)    :: Words(NumWords)                              ! The array of found words.


      ! Local declarations.

   INTEGER                      :: Ch                                           ! Character position within the string.
   INTEGER                      :: IW                                           ! Word index.
   INTEGER                      :: NextWhite                                    ! The location of the next whitespace in the string.



      ! Let's prefill the array with blanks.

   DO IW=1,NumWords
      Words(IW) = ' '
   END DO ! IW


      ! Let's make sure we have text on this line.

   IF ( LEN_TRIM( Line ) == 0 )  RETURN


      ! Parse words separated by any combination of spaces, tabs, commas,
      ! semicolons, single quotes, and double quotes ("whitespace").

   Ch = 0
   IW = 0

   DO

      NextWhite = SCAN( Line(Ch+1:) , ' ,;''"'//Tab )

      IF ( NextWhite > 1 )  THEN

         IW        = IW + 1
         Words(IW) = Line(Ch+1:Ch+NextWhite-1)

         IF ( IW == NumWords )  EXIT

         Ch = Ch + NextWhite

      ELSE IF ( NextWhite == 1 )  THEN

         Ch = Ch + 1

         CYCLE

      ELSE

         EXIT

      END IF

   END DO


   RETURN
   END SUBROUTINE GetWords
!=======================================================================
   SUBROUTINE IntAry2Str( IntAry, Str, ErrStat, ErrMsg )
   
      ! This routine converts an ASCII array of integers into an
      ! equivalent string (character array).
      ! This routine is the inverse of the Str2IntAry() routine.


         ! Argument declarations:
      INTEGER(IntKi), INTENT(IN)    :: IntAry(:)                                    ! ASCII array to convert to a string
      CHARACTER(*),   INTENT(OUT)   :: Str                                          ! The string representation of IntAry

      INTEGER(IntKi), INTENT(OUT)   :: ErrStat                                      ! Error status
      CHARACTER(*),   INTENT(OUT)   :: ErrMsg                                       ! Error message associated with ErrStat

         ! Argument declarations:
      INTEGER(IntKi)                :: I                                            ! generic loop counter
      INTEGER(IntKi)                :: LStr                                         ! length of the string
      INTEGER(IntKi)                :: LAry                                         ! length of the integer array


         ! Get the size of the arrays:
      LStr = LEN(Str)
      LAry = SIZE(IntAry)


      Str = ''

         ! Determine if the string will fit in the integer array:
      IF ( LAry > LStr ) THEN
         ErrStat = ErrID_Warn
         ErrMsg  = 'Int2Char:Array exceeds string size.'
         LAry    = LStr  ! we'll only convert the string values up to the array length
      ELSE
         ErrStat = ErrID_None
         ErrMsg  = ''
      END IF


         ! Convert the ASCII array to a string:
      DO I=1,LAry
         Str(I:I) = CHAR(IntAry(I))
      END DO

   END SUBROUTINE IntAry2Str   
!=======================================================================
   FUNCTION Int2LStr ( Intgr )


      ! This function returns a left-adjusted string representing the passed integer.



   CHARACTER(11)                :: Int2LStr                                     ! This function.


      ! Argument declarations.

   INTEGER, INTENT(IN)          :: Intgr                                        ! The integer to convert to a left-justified string.



   WRITE (Int2LStr,'(I11)')  Intgr

   Int2Lstr = ADJUSTL( Int2LStr )


   RETURN
   END FUNCTION Int2LStr
!=======================================================================
   SUBROUTINE NameOFile ( InArg, OutExten, OutFile, ErrStat, ErrMsg )


      ! Get the name of the input file from the InArgth command-line argument.
      ! Remove the extension if there is one, and append OutExten to the end.


      ! Argument declarations.

   INTEGER, INTENT(OUT)         :: ErrStat                                      ! Error status; if present, program does not abort on error
   INTEGER, INTENT(IN)          :: InArg                                        ! The number of the command-line argument that should hold the input file name.

   CHARACTER(*), INTENT(IN)     :: OutExten                                     ! The requested extension for the output file.
   CHARACTER(*), INTENT(OUT)    :: OutFile                                      ! The name of the output file.
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                       ! Description of error


      ! Local declarations.

   CHARACTER(100)               :: InFile                                       ! The name of the input file.
   CHARACTER(100)               :: RootName                                     ! The root name of the input file.



      ! See if the command line has enough arguments.

   IF ( InArg > COMMAND_ARGUMENT_COUNT() )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'NameOFile:Insufficient arguments on the command line (at least '//&
                         TRIM( Int2LStr( InArg ) )//' were expected).'
      RETURN
   ELSE
      ErrStat = ErrID_None
      ErrMsg = ''      
   END IF


      ! Get the root of the input file name (strip off the extension).

   CALL GET_COMMAND_ARGUMENT( InArg, InFile )
   CALL GetRoot ( TRIM( InFile ), RootName )

   OutFile = TRIM( RootName )//'.'//OutExten


   RETURN
   END SUBROUTINE NameOFile
!=======================================================================
   SUBROUTINE NormStop


      ! This routine performs a normal termination of the program.


   IF ( LEN_TRIM(ProgName) > 0 ) THEN
      CALL WrScr   ( NewLine//' '//TRIM( ProgName )//' terminated normally.' )
   ELSE
      CALL WrScr   ( NewLine//' Program terminated normally.' )
   END IF
   CALL WrScr    ( '' )
   CALL ProgExit ( 0 )


   END SUBROUTINE NormStop
!=======================================================================
   SUBROUTINE NWTC_DisplaySyntax( DefaultInputFile, ThisProgName )
   
      ! This routine displays the expected command-line syntax for 
      !  most software developed at the NWTC.
   
      CHARACTER(*),  INTENT(IN)  :: DefaultInputFile
      CHARACTER(*),  INTENT(IN)  :: ThisProgName
      
               
      CALL WrScr ( NewLine//' Syntax is:' )
      IF ( LEN_TRIM( DefaultInputFile ) == 0 )  THEN
         CALL WrScr ( NewLine//'    '//TRIM( ThisProgName )//' ['//SwChar//'h] <InputFile>' )
         CALL WrScr ( NewLine//' where:' )
         CALL WrScr ( NewLine//'    '//SwChar//'h generates this help message.' )
         CALL WrScr    ( '    <InputFile> is the name of the required primary input file.' )
      ELSE
         CALL WrScr ( NewLine//'    '//TRIM( ThisProgName )//' ['//SwChar//'h] [<InputFile>]' )
         CALL WrScr ( NewLine//' where:' )
         CALL WrScr ( NewLine//'    '//SwChar//'h generates this help message.' )
         CALL WrScr    ( '    <InputFile> is the name of the primary input file.  If omitted, the default file is "' &
                        //TRIM( DefaultInputFile )//'".' )
      END IF
      CALL WrScr    ( NewLine//' Note: values enclosed in square brackets [] are optional. Do not enter the brackets.')      
      CALL WrScr    ( ' ')
                     
   END SUBROUTINE NWTC_DisplaySyntax
!=======================================================================
   SUBROUTINE OpenBInpFile ( Un, InFile, ErrStat, ErrMsg )


      ! This routine opens a binary input file.

   IMPLICIT                        NONE



      ! Argument declarations.

   INTEGER(IntKi), INTENT(IN)       :: Un                                          ! Logical unit for the input file.
   INTEGER(IntKi), INTENT(OUT)      :: ErrStat                                     ! Error status: returns "fatal" if the file doesn't exist or can't be opened
   CHARACTER(*),   INTENT(OUT)      :: ErrMsg                                      ! Error message
   CHARACTER(*),   INTENT(IN)       :: InFile                                      ! Name of the input file.


      ! Local declarations.

      ! NOTE: Do not explicitly declare the precision of this variable [as in
      !       LOGICAL(1)] so that the statements using this variable work with
      !       any compiler:
   LOGICAL                      :: Exists                                       ! Flag indicating whether or not a file Exists.


   ErrStat = ErrID_None
   ErrMsg  = ''


      ! See if input file Exists.

   INQUIRE ( FILE=TRIM( InFile ) , EXIST=Exists )

   IF ( .NOT. Exists )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg  = 'OpenBInpFile:The input file, "'//TRIM( InFile )//'", was not found.'
      RETURN
   END IF


      ! Open input file.  Make sure it worked.
   OPEN( Un, FILE=TRIM( InFile ), STATUS='OLD', FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=ErrStat, ACTION='READ' )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg  = 'OpenBInpFile:Cannot open file "'//TRIM( InFile )//'" for reading. Another program may have locked it.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE OpenBInpFile
!=======================================================================
   SUBROUTINE OpenBOutFile ( Un, OutFile, ErrStat, ErrMsg )

      ! This routine opens a binary output file with stream access,
      ! implemented in standrad Fortran 2003.
      ! Valid in gfortran 4.6.1 and IVF 10.1 and later


      ! Argument declarations.

   INTEGER(IntKi),  INTENT(IN)       :: Un                                  ! Logical unit for the output file
   INTEGER(IntKi),  INTENT(OUT)      :: ErrStat                             ! Error status
   CHARACTER(*),    INTENT(OUT)      :: ErrMsg                              ! Error message
   CHARACTER(*),    INTENT(IN)       :: OutFile                             ! Name of the output file



      ! Open output file.  Make sure it worked.
   OPEN( Un, FILE=TRIM( OutFile ), STATUS='UNKNOWN', FORM='UNFORMATTED' , ACCESS='STREAM', IOSTAT=ErrStat, ACTION='WRITE' )

   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg  = 'OpenBOutFile:Cannot open file "'//TRIM( OutFile )//'". Another program may have locked it for writing.' &
                //' (IOSTAT is '//TRIM(Num2LStr(ErrStat))//')'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF



   RETURN
   END SUBROUTINE OpenBOutFile
!=======================================================================
   SUBROUTINE OpenEcho ( Un, OutFile, ErrStat, ErrMsg, ProgVer )


      ! This routine opens a formatted output file for the echo file.


      ! Argument declarations.

   INTEGER,        INTENT(INOUT)         :: Un                                        ! Logical unit for the input file.
   CHARACTER(*),   INTENT(IN)            :: OutFile                                   ! Name of the input file.
   INTEGER(IntKi), INTENT(OUT)           :: ErrStat                                   ! Error status
   CHARACTER(*),   INTENT(OUT)           :: ErrMsg                                    ! Error message

   TYPE(ProgDesc), INTENT(IN),  OPTIONAL :: ProgVer                                   ! Program version info to display in echo file


      ! local variables

   INTEGER(IntKi)                        :: ErrStat2                                   ! Temporary Error status
   CHARACTER(ErrMsgLen)                  :: ErrMsg2                                    ! Temporary Error message
   CHARACTER(*),PARAMETER                :: RoutineName = 'OpenEcho'

   ErrStat = ErrID_None
   ErrMsg  = ''


      ! Get a unit number for the echo file:

   IF ( Un < 0 ) THEN
      CALL GetNewUnit( Un, ErrStat2, ErrMsg2 )
         CALL SetErrStat(ErrStat2, ErrMsg2,ErrStat, ErrMsg, RoutineName )
   END IF


      ! Open the file for writing:

   CALL OpenFOutFile( Un, OutFile, ErrStat2, ErrMsg2 )
      CALL SetErrStat(ErrStat2, ErrMsg2,ErrStat, ErrMsg, RoutineName )
      IF ( ErrStat >= AbortErrLev ) RETURN


      ! Write a heading line to the file

   IF ( PRESENT( ProgVer ) ) THEN

      WRITE (Un,'(/,A)', IOSTAT=ErrStat2  )  'This file of echoed input was generated by '//TRIM(GetNVD(ProgVer))// &
                            ' on '//CurDate()//' at '//CurTime()//'.'

      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat(ErrID_Info, 'Could not write header information to the file.', ErrStat, ErrMsg, RoutineName )
      END IF

   END IF


   RETURN
   END SUBROUTINE OpenEcho
!=======================================================================
   SUBROUTINE OpenFInpFile ( Un, InFile, ErrStat, ErrMsg )


      ! This routine opens a formatted input file.


      ! Argument declarations.

   INTEGER,        INTENT(IN)          :: Un                                           ! Logical unit for the input file.
   CHARACTER(*),   INTENT(IN)          :: InFile                                       ! Name of the input file.
   INTEGER(IntKi), INTENT(OUT)         :: ErrStat                                      ! Error status
   CHARACTER(*),   INTENT(OUT)         :: ErrMsg                                       ! Error message


      ! Local declarations.

   INTEGER                      :: IOS                                                 ! I/O status of OPEN.

   LOGICAL                      :: Exists                                              ! Flag indicating whether or not a file Exists.
   CHARACTER(*), PARAMETER      :: RoutineName = 'OpenFInpFile'
   
   
   ErrStat = ErrID_None
   ErrMsg  = ""

      ! See if input file Exists.

   INQUIRE ( FILE=TRIM( InFile ) , EXIST=Exists )

   IF ( .NOT. Exists )  THEN
      CALL SetErrStat( ErrID_Fatal, 'The input file, "'//TRIM( InFile )//'", was not found.', ErrStat, ErrMsg, RoutineName)
   ELSE

      ! Open input file.  Make sure it worked.

      OPEN( Un, FILE=TRIM( InFile ), STATUS='OLD', FORM='FORMATTED', IOSTAT=IOS, ACTION='READ' )

      IF ( IOS /= 0 )  THEN

         CALL SetErrStat( ErrID_Fatal, 'Cannot open file "'//TRIM( InFile )//&
              '". Another program like MS Excel may have locked it for writing.', ErrStat,ErrMsg,RoutineName)
      END IF

   END IF


   RETURN
   END SUBROUTINE OpenFInpFile
!=======================================================================
   SUBROUTINE OpenFOutFile ( Un, OutFile, ErrStat, ErrMsg )


      ! This routine opens a formatted output file.


      ! Argument declarations.

   INTEGER, INTENT(IN)                   :: Un                                          ! Logical unit for the output file.
   CHARACTER(*), INTENT(IN)              :: OutFile                                     ! Name of the output file.

   INTEGER(IntKi), INTENT(OUT)           :: ErrStat                                     ! Error status
   CHARACTER(*),   INTENT(OUT)           :: ErrMsg                                      ! Error message



      ! Local declarations.

   INTEGER                                :: IOS                                         ! I/O status of OPEN
   CHARACTER(*), PARAMETER                :: RoutineName = 'OpenFOutFile'

   
      ! Open output file.  Make sure it worked.

   OPEN( Un, FILE=TRIM( OutFile ), STATUS='UNKNOWN', FORM='FORMATTED', IOSTAT=IOS, ACTION="WRITE" )


   IF ( IOS /= 0 )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg  = 'OpenFOutFile:Cannot open file "'//TRIM( OutFile )//&
         '". Another program like MS Excel may have locked it for writing.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ""      
   END IF


   RETURN
   END SUBROUTINE OpenFOutFile
!=======================================================================
   SUBROUTINE OpenFUnkFile ( Un, OutFile, FailAbt, Failed, Exists, ErrStat, ErrMsg )


      ! This routine opens a formatted output file and returns a flag telling if it already existed.


      ! Argument declarations.

   INTEGER, INTENT(IN)          :: Un                                           ! Logical unit for the output file.
   INTEGER(IntKi), INTENT(OUT)  :: ErrStat                                      ! Error status: returns "fatal" if the file doesn't exist or can't be opened
   CHARACTER(*),   INTENT(OUT)  :: ErrMsg                                       ! Error message

   LOGICAL, INTENT(OUT)         :: Exists                                       ! Flag that indicates if the file already existedo.
   LOGICAL, INTENT(IN)          :: FailAbt                                      ! Flag that tells this routine to abort if the open fails.
   LOGICAL, INTENT(OUT)         :: Failed                                       ! Flag that indicates if the open failed.

   CHARACTER(*), INTENT(IN)     :: OutFile                                      ! Name of the output file.


      ! Local declarations.

   INTEGER                      :: IOS                                          ! I/O status of OPEN.



      ! Check to see if the file already exists.

   INQUIRE ( FILE=TRIM( OutFile ) , EXIST=Exists )   


      ! Open output file.  Make sure it worked.

   OPEN( Un, FILE=TRIM( OutFile ), STATUS='UNKNOWN', FORM='FORMATTED', IOSTAT=IOS )


   IF ( IOS /= 0 )  THEN
      Failed = .TRUE.
      ErrStat = ErrID_Fatal
      ErrMsg = 'OpenFUnkFile:Cannot open file "'//TRIM( OutFile )//'".  Another program like MS Excel may have locked it for writing.'
      IF ( FailAbt )  CALL ProgAbort ( TRIM(ErrMsg) )
   ELSE
      Failed = .FALSE.
      ErrStat = ErrID_None
      ErrMsg = ''
   END IF


   RETURN
   END SUBROUTINE OpenFUnkFile
!=======================================================================
   SUBROUTINE OpenUInBEFile( Un, InFile, RecLen, ErrStat, ErrMsg )

      !  This routine opens an unformatted input file of RecLen-byte data records
      !  stored in Big Endian format.


      ! Argument declarations.

   INTEGER, INTENT(IN)           ::  Un                                         ! Logical unit for the input file
   CHARACTER(*), INTENT(IN)      ::  InFile                                     ! Name of the input file
   INTEGER, INTENT(IN)           ::  RecLen                                     ! The input file's record length in bytes
   INTEGER(IntKi), INTENT(OUT)   ::  ErrStat                                    ! Error status: returns "fatal" if the file doesn't exist or can't be opened
   CHARACTER(*),   INTENT(OUT)   ::  ErrMsg                                     ! Error message


      ! Local declarations.

   LOGICAL                       :: Exists                                       ! Flag to indicate if a file exists
   LOGICAL                       :: Error                                        ! Flag to indicate the open failed



      ! See if input file Exists.

   INQUIRE ( FILE=TRIM( InFile ) , EXIST=Exists )

   IF ( .NOT. Exists )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'OpenUInBEFile:The input file, "'//TRIM( InFile )//'", was not found.'
      RETURN
   END IF


      ! Open the file.

   CALL OpenUnfInpBEFile ( Un, InFile, RecLen, Error )

   IF ( Error )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'OpenUInBEFile:Cannot open file "'//TRIM( InFile )//'".  Another program may have locked it.'
      RETURN
   ELSE
      ErrStat = ErrID_None
      ErrMsg = ''
   END IF


   RETURN

   END SUBROUTINE OpenUInBEFile
!=======================================================================
   SUBROUTINE OpenUInfile ( Un, InFile, ErrStat, ErrMsg )


      !  This routine opens an unformatted input file.


      ! Argument declarations.

   INTEGER, INTENT(IN)         ::  Un                                           ! Logical unit for the input file
   INTEGER(IntKi), INTENT(OUT) ::  ErrStat                                      ! Error status: returns "fatal" if the file doesn't exist or can't be opened
   CHARACTER(*),   INTENT(OUT) ::  ErrMsg                                       ! Error message

   CHARACTER(*), INTENT(IN)    ::  InFile                                       ! Name of the input file


      ! Local declarations.

   INTEGER                     ::  IOS                                          ! Returned input/output status.

   LOGICAL                      :: Exists                                       ! Flag indicating whether or not a file Exists.



      ! See if input file Exists.

   INQUIRE ( FILE=TRIM( InFile ) , EXIST=Exists )

   IF ( .NOT. Exists )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'OpenUInfile:The input file, "'//TRIM( InFile )//'", was not found.'
      RETURN
   END IF


      ! Open the file.

   OPEN ( Un, FILE=TRIM( InFile ), STATUS='UNKNOWN', FORM=UnfForm, ACCESS='SEQUENTIAL', IOSTAT=IOS, ACTION='READ' )

   IF ( IOS /= 0 )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg  = 'OpenUInfile:Cannot open file "'//TRIM( InFile )//'". Another program may have locked it.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE OpenUInfile
!=======================================================================
   SUBROUTINE OpenUOutfile ( Un, OutFile, ErrStat, ErrMsg )


      !  This routine opens an unformatted output file.


      ! Argument declarations.

   INTEGER, INTENT(IN)            ::  Un                                        ! Logical unit for the output file
   INTEGER(IntKi), INTENT(OUT)    ::  ErrStat                                   ! Error status: returns "fatal" if the file doesn't exist or can't be opened
   CHARACTER(*),   INTENT(OUT)    ::  ErrMsg                                    ! Error message

   CHARACTER(*), INTENT(IN)       ::  OutFile                                   ! Name of the output file


      ! Local declarations.

   INTEGER                        ::  IOS                                       ! Returned input/output status.



      ! Open the file.

   OPEN ( Un, FILE=TRIM( OutFile ), STATUS='UNKNOWN', FORM=UnfForm, ACCESS='SEQUENTIAL', IOSTAT=IOS, ACTION='WRITE' )

   IF ( IOS /= 0 )  THEN
      ErrStat = ErrID_Fatal
      ErrMsg  = 'OpenUOutfile:Cannot open file "'//TRIM( OutFile )//'".  Another program may have locked it for writing.'
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE OpenUOutfile
!=======================================================================
   SUBROUTINE ParseChVar ( FileInfo, LineNum, ExpVarName, ChVar, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for two words.  One should be a
      ! the name of a character variable and the other a string.
      ! Generate an error message if the value is the wrong type or if only one "word" is found.

      ! WARNING: This routine assumes the "words" containing the variable name and value are <= 20 characters.


         ! Arguments declarations.


      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(OUT)            :: ChVar                         ! The CHARACTER variable to receive the input value.
      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.
      CHARACTER(*),   INTENT(IN)             :: ExpVarName                    ! The expected variable name.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.
      INTEGER(IntKi)                         :: NameIndx                      ! The index into the Words array that points to the variable name.

      CHARACTER(20)                          :: Words       (2)               ! The two "words" parsed from the line.
      CHARACTER(ErrMsgLen)                   :: ErrMsg2
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseChVar'

      
      ErrStat=ErrID_None
      ErrMsg = ""

      !' >> The text being parsed was :'//NewLine//'    "'//TRIM( FileInfo%Lines(LineNum) )//'
      
      CALL GetWords ( FileInfo%Lines(LineNum), Words, 2 )                     ! Read the first two words in Line.
      IF ( Words(2) == '' )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The variable "'//TRIM( ExpVarName )//'" was not assigned valid string value on line #' &
                   //TRIM( Num2LStr( LineNum ) )//'.'//NewLine//' >> The text being parsed was :'//NewLine &
                   //'    "'//TRIM( FileInfo%Lines(LineNum) )//'"',ErrStat,ErrMsg,RoutineName )
         RETURN
      ENDIF

      CALL ChkParseData ( Words, ExpVarName, FileInfo%FileList(FileInfo%FileIndx(LineNum)) &
                        , FileInfo%FileLine(LineNum), NameIndx, ErrStatLcl, ErrMsg2 )
      CALL SetErrStat(ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
         IF (ErrStat >= AbortErrLev) RETURN
         
      ChVar = Words(3-NameIndx)

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(1X,A15," = ",A20)')  Words
      END IF

      LineNum = LineNum + 1

      RETURN
   END SUBROUTINE ParseChVar
!=======================================================================
   SUBROUTINE ParseDbAry ( FileInfo, LineNum, AryName, DbAry, AryLen, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for AryLen REAL values.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      INTEGER, INTENT(IN)                    :: AryLen                        ! The length of the array to parse.

      REAL(DbKi), INTENT(OUT)                :: DbAry       (AryLen)          ! The double-precision REAL array to receive the input values.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(In)             :: AryName                       ! The array name we are trying to fill.
      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.

      CHARACTER(20), ALLOCATABLE             :: Words       (:)               ! The array "words" parsed from the line.
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseDbAry'


      ErrStat = ErrID_None
      ErrMsg  = ""
      
      ALLOCATE ( Words( AryLen ) , STAT=ErrStatLcl )
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for the Words array.',ErrStat,ErrMsg,RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF


      READ (FileInfo%Lines(LineNum),*,IOSTAT=ErrStatLcl)  DbAry
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The "'//TRIM( AryName )//'" array was not assigned valid REAL values on line #' &
                   //TRIM( Num2LStr( FileInfo%FileLine(LineNum) ) )//'.'//NewLine//' >> The text being parsed was :'//NewLine &
                   //'    "'//TRIM( FileInfo%Lines(LineNum) )//'"',ErrStat,ErrMsg,RoutineName )
         RETURN
         CALL Cleanup()         
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(A)')  TRIM( FileInfo%Lines(LineNum) )
      END IF

      LineNum = LineNum + 1
      CALL Cleanup()

      RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup ( )

         ! This subroutine cleans up the parent routine before exiting.

            ! Deallocate the Words array if it had been allocated.

         IF ( ALLOCATED( Words ) ) DEALLOCATE( Words )


         RETURN

      END SUBROUTINE Cleanup

   END SUBROUTINE ParseDbAry
!=======================================================================
   SUBROUTINE ParseDbVar ( FileInfo, LineNum, ExpVarName, DbVar, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for two words.  One should be a
      ! the name of a double-precision variable and the other a REAL value.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      REAL(DbKi), INTENT(OUT)                :: DbVar                         ! The double-precision REAL variable to receive the input value.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.
      CHARACTER(*),   INTENT(IN)             :: ExpVarName                    ! The expected variable name.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.
      INTEGER(IntKi)                         :: NameIndx                      ! The index into the Words array that points to the variable name.

      CHARACTER(20)                          :: Words       (2)               ! The two "words" parsed from the line.
      CHARACTER(ErrMsgLen)                   :: ErrMsg2
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseDbVar'


      ErrStat = ErrID_None
      ErrMsg  = ""

      CALL GetWords ( FileInfo%Lines(LineNum), Words, 2 )                     ! Read the first two words in Line.

      CALL ChkParseData ( Words, ExpVarName, FileInfo%FileList(FileInfo%FileIndx(LineNum)) &
                        , FileInfo%FileLine(LineNum), NameIndx, ErrStatLcl, ErrMsg2 )
         CALL SetErrStat(ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
         IF ( ErrStat >= AbortErrLev )  RETURN

      
      READ (Words(3-NameIndx),*,IOSTAT=ErrStatLcl)  DbVar
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, NewLine//'A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The variable "'//TRIM( Words(NameIndx) )//'" was not assigned valid REAL value on line #' &
                   //TRIM( Num2LStr( LineNum ) )//'.'//NewLine//' >> The text being parsed was :'//&
                   NewLine//'    "'//TRIM( FileInfo%Lines(LineNum) )//'"', ErrStat, ErrMsg, RoutineName)
         RETURN
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(1X,A15," = ",A20)')  Words
      END IF

      LineNum = LineNum + 1

      RETURN
   END SUBROUTINE ParseDbVar
!=======================================================================
   SUBROUTINE ParseInAry ( FileInfo, LineNum, AryName, InAry, AryLen, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for AryLen whole numbers.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      INTEGER, INTENT(IN)                    :: AryLen                        ! The length of the array to parse.

      INTEGER, INTENT(OUT)                   :: InAry       (AryLen)          ! The INTEGER array to receive the input values.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(In)             :: AryName                       ! The array name we are trying to fill.
      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.

      CHARACTER(20), ALLOCATABLE             :: Words       (:)               ! The array "words" parsed from the line.
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseInAry'

      ErrStat = ErrID_None
      ErrMsg  = ""


      ALLOCATE ( Words( AryLen ) , STAT=ErrStatLcl )
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for the Words array.',ErrStat,ErrMsg,RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF


      READ (FileInfo%Lines(LineNum),*,IOSTAT=ErrStatLcl)  InAry
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The "'//TRIM( AryName )//'" array was not assigned valid INTEGER values on line #' &
                   //TRIM( Num2LStr( FileInfo%FileLine(LineNum) ) )//'.'//NewLine//' >> The text being parsed was :'//NewLine &
                   //'    "'//TRIM( FileInfo%Lines(LineNum) )//'"',ErrStat,ErrMsg,RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(A)')  TRIM( FileInfo%Lines(LineNum) )
      END IF

      LineNum = LineNum + 1

      CALL Cleanup()
      
      RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup ( )

         ! This subroutine cleans up the parent routine before exiting.

            ! Deallocate the Words array if it had been allocated.

         IF ( ALLOCATED( Words ) ) DEALLOCATE( Words )


         RETURN

      END SUBROUTINE Cleanup

   END SUBROUTINE ParseInAry
!=======================================================================
   SUBROUTINE ParseInclInfo ( InclInfo, FileName, RangeBeg, RangeEnd, ErrStat, ErrMsg )


      ! This subroutine parses the include information that occurs after a "@" when processing an input file.


         ! Arguments declarations.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.

      INTEGER, INTENT(OUT)                   :: RangeBeg                      ! The beginning of a range of lines to be processed in an included file.
      INTEGER, INTENT(OUT)                   :: RangeEnd                      ! The end of a range of lines to be processed in an included file.

      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.
      CHARACTER(*),   INTENT(OUT)            :: FileName                      ! The file name that was parsed from InclInfo.
      CHARACTER(*),   INTENT(INOUT)          :: InclInfo                      ! The text following the "@" on an input line being processed.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.

      INTEGER                                :: DashLoc                       ! The possible location of the dash in the range text.

      CHARACTER( 20)                         :: InclInfoUC                    ! InclInfo converted to upper case.
      CHARACTER(512)                         :: Words       (2)               ! The two "words" parsed from the line.
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseInclInfo'

      ErrStat = ErrID_None
      ErrMsg  = ""

         ! Check for an integer at the beginning of the line.  If found, it is where
         ! we will start reading the included file.
         ! Check to make sure the case-independent string " in " is found between the number and the file name.

      InclInfoUC = InclInfo

      CALL Conv2UC  ( InclInfoUC )
      CALL GetWords ( InclInfoUC, Words, 2 )

      IF ( TRIM( Words(2) ) == 'IN' )  THEN

         DashLoc = INDEX( Words(1), '-' )

         IF ( DashLoc > 0 )  THEN                                             ! Must be in the form of "<num1>-<num2>".

            READ (Words(1)(:DashLoc-1),*,IOSTAT=ErrStatLcl)  RangeBeg         ! Parse the first number as the beginning fo the range.
            IF ( ErrStatLcl /= 0 )  THEN
               CALL SetErrStat(ErrID_Fatal,'Fatal error for an incorrectly formatted include-file line range.',ErrStat,ErrMsg,RoutineName)
               RETURN
            ENDIF ! ( ErrStatLcl /= 0 )

            READ (Words(1)(DashLoc+1:),*,IOSTAT=ErrStatLcl)  RangeEnd
            IF ( ErrStatLcl /= 0 )  THEN
               CALL SetErrStat(ErrID_Fatal,'Fatal error for an incorrectly formatted include-file line range.',ErrStat,ErrMsg,RoutineName)
               RETURN
            ENDIF ! ( ErrStatLcl /= 0 )


               ! Are the line numbers valid?

            IF ( RangeBeg <= 0 )  THEN
               CALL SetErrStat(ErrID_Fatal,'Fatal error for an incorrectly formatted include-file line range.'//NewLine// &
                  '    The start of the range must be > 0.',ErrStat,ErrMsg,RoutineName)
               RETURN
            ELSEIF ( RangeEnd < 0 )  THEN
               CALL SetErrStat(ErrID_Fatal,'Fatal error for an incorrectly formatted include-file line range.'//NewLine// &
                  '    The end of the range must be >= 0.',ErrStat,ErrMsg,RoutineName)
               RETURN
            ELSEIF ( ( RangeEnd > 0 ) .AND. ( RangeEnd < RangeBeg ) )  THEN
               CALL SetErrStat(ErrID_Fatal,'Fatal error for an incorrectly formatted include-file line range.'//NewLine// &
                  '    The end of the range must be >= '//TRIM( Num2LStr( RangeBeg ) )//' or = 0.',ErrStat,ErrMsg,RoutineName)
               RETURN
            ENDIF ! ( ErrStatLcl /= 0 )

         ELSE

            READ (Words(1),*,IOSTAT=ErrStatLcl)  RangeBeg
            IF ( ErrStatLcl /= 0 )  THEN                                      ! Was there a number after the "@"?  If so, assume it is the line to start reading.
               CALL SetErrStat(ErrID_Fatal,'Fatal error for an incorrectly formatted include-file line range.'//NewLine// &
                  '    The end of the range must be >= '//TRIM( Num2LStr( RangeBeg ) )//' or = 0.',ErrStat,ErrMsg,RoutineName)
               RETURN
            ELSE                                                              ! Number found.  Assume it is the line to start reading.
               RangeEnd = 0                                                   ! TEMP: Read entire file after the start line.
            ENDIF ! ( ErrStartLcl /= 0 )

         ENDIF ! ( DashLoc > 0 )

         FileName = ADJUSTL( InclInfo(INDEX( InclInfoUC, 'IN' )+3:) )         ! File name must be at least three characters after the "I" in "IN".

      ELSE
                                                                              ! Line did not have the form "@<int> in <filename>".
         FileName = ADJUSTL( InclInfo )                                       ! Shift the file name to the beginning of Line.
         RangeBeg = 1
         RangeEnd = 0

      ENDIF ! ( Words(2) == 'IN' )


         ! Check for quotes and remove them from the file name.
         ! If the file name is quote delimited, we should be able to read it as a quoted string.  Otherwise, leave it as is.

      IF ( INDEX( FileName, '"' )+INDEX( FileName, "'" ) > 0 )  THEN
         READ (FileName,*,IOSTAT=ErrStatLcl)  FileName  !,IOMSG=ErrMsg2
         IF ( ErrStatLcl /= 0 )  THEN
            CALL SetErrStat(ErrID_Fatal,'Fatal error for an incorrectly formatted include-file line range.',ErrStat,ErrMsg,RoutineName)
            RETURN
         ENDIF ! ( ErrStatLcl /= 0 )
      ENDIF ! ( INDEX( InclInfo, '"' )+INDEX( InclInfo, "'" ) > 0 )

      RETURN

   END SUBROUTINE ParseInclInfo
!=======================================================================
   SUBROUTINE ParseInVar ( FileInfo, LineNum, ExpVarName, InVar, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for two words.  One should be a
      ! variable name and the other an INTEGER value.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      INTEGER, INTENT(OUT)                   :: InVar                         ! The INTEGER variable to receive the input value.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.
      CHARACTER(*),   INTENT(IN)             :: ExpVarName                    ! The expected variable name.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.
      INTEGER(IntKi)                         :: NameIndx                      ! The index into the Words array that points to the variable name.

      CHARACTER(20)                          :: Words       (2)               ! The two "words" parsed from the line.
      CHARACTER(ErrMsgLen)                   :: ErrMsg2
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseInVar'

      ErrStat = ErrID_None
      ErrMsg  = ""


      CALL GetWords ( FileInfo%Lines(LineNum), Words, 2 )                                        ! Read the first two words in Line.

      CALL ChkParseData ( Words, ExpVarName, FileInfo%FileList(FileInfo%FileIndx(LineNum)) &
                        , FileInfo%FileLine(LineNum), NameIndx, ErrStatLcl, ErrMsg2 )
         CALL SetErrStat ( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
         IF (ErrStat >= AbortErrLev) RETURN

      READ (Words(3-NameIndx),*,IOSTAT=ErrStatLcl)  InVar
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, NewLine//' >> A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The variable "'//TRIM( Words(NameIndx) )//'" was not assigned valid INTEGER value on line #' &
                   //TRIM( Num2LStr( FileInfo%FileLine(LineNum) ) )//'.'//NewLine//&
                   ' >> The text being parsed was :'//NewLine//'    "'//TRIM( FileInfo%Lines(LineNum) )//'"', ErrStat, ErrMsg, RoutineName )
         RETURN
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(1X,A15," = ",A20)')  Words
      END IF

      LineNum = LineNum + 1

      RETURN

   END SUBROUTINE ParseInVar
!=======================================================================
   SUBROUTINE ParseLoAry ( FileInfo, LineNum, AryName, LoAry, AryLen, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for AryLen LOGICAL values.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      INTEGER, INTENT(IN)                    :: AryLen                        ! The length of the array to parse.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      LOGICAL, INTENT(OUT)                   :: LoAry       (AryLen)          ! The LOGICAL array to receive the input values.

      CHARACTER(*),   INTENT(In)             :: AryName                       ! The array name we are trying to fill.
      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.

      CHARACTER(20), ALLOCATABLE             :: Words       (:)               ! The array "words" parsed from the line.
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseLoAry'

      ErrStat = ErrID_None
      ErrMsg  = ""

      ALLOCATE ( Words( AryLen ) , STAT=ErrStatLcl )
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, NewLine//'Fatal error allocating memory for the Words array.',ErrStat,ErrMsg,RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF


      READ (FileInfo%Lines(LineNum),*,IOSTAT=ErrStatLcl)  LoAry
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The "'//TRIM( AryName )//'" array was not assigned valid LOGICAL values on line #' &
                   //TRIM( Num2LStr( FileInfo%FileLine(LineNum) ) )//'.'//NewLine//' >> The text being parsed was :'//NewLine &
                   //'    "'//TRIM( FileInfo%Lines(LineNum) )//'"',ErrStat,ErrMsg,RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(A)')  TRIM( FileInfo%Lines(LineNum) )
      END IF

      LineNum = LineNum + 1
      CALL Cleanup()

      RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup ( )

         ! This subroutine cleans up the parent routine before exiting.

            ! Deallocate the Words array if it had been allocated.

         IF ( ALLOCATED( Words ) ) DEALLOCATE( Words )

         RETURN

      END SUBROUTINE Cleanup

   END SUBROUTINE ParseLoAry
!=======================================================================
   SUBROUTINE ParseLoVar ( FileInfo, LineNum, ExpVarName, LoVar, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for two words.  One should be a
      ! variable name and the other a LOGICAL value.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      LOGICAL, INTENT(OUT)                   :: LoVar                         ! The LOGICAL variable to receive the input value.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.
      CHARACTER(*),   INTENT(IN)             :: ExpVarName                    ! The expected variable name.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.
      INTEGER(IntKi)                         :: NameIndx                      ! The index into the Words array that points to the variable name.

      CHARACTER(20)                          :: Words       (2)               ! The two "words" parsed from the line.
      CHARACTER(ErrMsgLen)                   :: ErrMsg2
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseLoVar'

      ErrStat = ErrID_None
      ErrMsg  = ""


      CALL GetWords ( FileInfo%Lines(LineNum), Words, 2 )                     ! Read the first two words in Line.

      CALL ChkParseData ( Words, ExpVarName, FileInfo%FileList(FileInfo%FileIndx(LineNum)) &
                        , FileInfo%FileLine(LineNum), NameIndx, ErrStatLcl, ErrMsg2 )
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
         RETURN
      ENDIF

      READ (Words(3-NameIndx),*,IOSTAT=ErrStatLcl)  LoVar

      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The variable "'//TRIM( Words(NameIndx) )//'" was not assigned valid LOGICAL value on line #' &
                   //TRIM( Num2LStr( LineNum ) )//'.'//NewLine//' >> The text being parsed was :'//NewLine &
                   //'    "'//TRIM( FileInfo%Lines(LineNum) )//'"', ErrStat, ErrMsg, RoutineName )
         RETURN
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(1X,A15," = ",A20)')  Words
      END IF

      LineNum = LineNum + 1

      RETURN

   END SUBROUTINE ParseLoVar
!=======================================================================
   SUBROUTINE ParseSiAry ( FileInfo, LineNum, AryName, SiAry, AryLen, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for two words.  One should be a
      ! variable name and the other a single-precision REAL value.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      INTEGER, INTENT(IN)                    :: AryLen                        ! The length of the array to parse.

      REAL(SiKi), INTENT(OUT)                :: SiAry       (AryLen)          ! The single-precision REAL array to receive the input values.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(In)             :: AryName                       ! The array name we are trying to fill.
      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.

      CHARACTER(20), ALLOCATABLE             :: Words       (:)               ! The array "words" parsed from the line.
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseSiAry'

      ErrStat = ErrID_None
      ErrMsg  = ""


      ALLOCATE ( Words( AryLen ) , STAT=ErrStatLcl )
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for the Words array.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF


      READ (FileInfo%Lines(LineNum),*,IOSTAT=ErrStatLcl)  SiAry
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, NewLine//' >> A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The "'//TRIM( AryName )//'" array was not assigned valid REAL values on line #' &
                   //TRIM( Num2LStr( FileInfo%FileLine(LineNum) ) )//'.'//NewLine//' >> The text being parsed was :'//NewLine &
                   //'    "'//TRIM( FileInfo%Lines(LineNum) )//'"', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(A)')  TRIM( FileInfo%Lines(LineNum) )
      END IF

      LineNum = LineNum + 1

      CALL Cleanup ( )

      RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup ( )

         ! This subroutine cleans up the parent routine before exiting.

            ! Deallocate the Words array if it had been allocated.

         IF ( ALLOCATED( Words ) ) DEALLOCATE( Words )

         RETURN

      END SUBROUTINE Cleanup

   END SUBROUTINE ParseSiAry
!=======================================================================
   SUBROUTINE ParseSiVar ( FileInfo, LineNum, ExpVarName, SiVar, ErrStat, ErrMsg, UnEc )

      ! This subroutine parses the specified line of text for two words.  One should be a
      ! the name of a single-precision variable and the other a REAL value.
      ! Generate an error message if the value is the wrong type.


         ! Arguments declarations.

      REAL(SiKi), INTENT(OUT)                :: SiVar                         ! The single-precision REAL variable to receive the input value.

      INTEGER(IntKi), INTENT(OUT)            :: ErrStat                       ! The error status.
      INTEGER(IntKi), INTENT(INOUT)          :: LineNum                       ! The number of the line to parse.

      INTEGER,        INTENT(IN), OPTIONAL   :: UnEc                          ! I/O unit for echo file. If present and > 0, write to UnEc.

      CHARACTER(*),   INTENT(OUT)            :: ErrMsg                        ! The error message, if ErrStat /= 0.
      CHARACTER(*),   INTENT(IN)             :: ExpVarName                    ! The expected variable name.

      TYPE (FileInfoType), INTENT(IN)        :: FileInfo                      ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                         :: ErrStatLcl                    ! Error status local to this routine.
      INTEGER(IntKi)                         :: NameIndx                      ! The index into the Words array that points to the variable name.

      CHARACTER(20)                          :: Words       (2)               ! The two "words" parsed from the line.
      CHARACTER(ErrMsgLen)                   :: ErrMsg2
      CHARACTER(*), PARAMETER                :: RoutineName = 'ParseSiVar'

      ErrStat = ErrID_None
      ErrMsg  = ""
      
      CALL GetWords ( FileInfo%Lines(LineNum), Words, 2 )                     ! Read the first two words in Line.

      CALL ChkParseData ( Words, ExpVarName, FileInfo%FileList(FileInfo%FileIndx(LineNum)) &
                        , FileInfo%FileLine(LineNum), NameIndx, ErrStatLcl, ErrMsg2 )
      CALL SetErrStat( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF ( ErrStat >= AbortErrLev )  RETURN

      READ (Words(3-NameIndx),*,IOSTAT=ErrStatLcl)  SiVar
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, NewLine//' >> A fatal error occurred when parsing data from "' &
                   //TRIM( FileInfo%FileList(FileInfo%FileIndx(LineNum)) )//'".'//NewLine//  &
                   ' >> The variable "'//TRIM( Words(NameIndx) )//'" was not assigned valid REAL value on line #' &
                   //TRIM( Num2LStr( LineNum ) )//'.'//NewLine//' >> The text being parsed was :'//NewLine// &
                   '    "'//TRIM( FileInfo%Lines(LineNum) )//'"', ErrStat, ErrMsg, RoutineName )
         RETURN
      ENDIF

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 )  WRITE (UnEc,'(1X,A15," = ",A20)')  Words
      END IF

      LineNum = LineNum + 1

      RETURN

   END SUBROUTINE ParseSiVar
!=======================================================================
   FUNCTION PathIsRelative ( GivenFil )


      ! Let's determine in the given file name is absolute or relative.
      !
      ! We'll consider an absolute path one that satisfies one of the
      ! following four criteria:
      !     1) It contains ":/"
      !     2) It contains ":\"
      !     3) It starts with "/"
      !     4) It starts with "\"
      ! All others are considered relative.



      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: GivenFil                                            ! The name of the given file.
   LOGICAL                      :: PathIsRelative                                      ! The function return value


      ! Determine if file name begins with an absolute path name or if it is relative

   PathIsRelative = .FALSE.

   IF ( ( INDEX( GivenFil, ':/') == 0 ) .AND. ( INDEX( GivenFil, ':\') == 0 ) ) THEN   ! No drive is specified (by ':\' or ':/')

      IF ( INDEX( '/\', GivenFil(1:1) ) == 0 ) THEN                                    ! The file name doesn't start with '\' or '/'

         PathIsRelative = .TRUE.

      END IF

   END IF

   RETURN
   END FUNCTION PathIsRelative
!=======================================================================
   SUBROUTINE PremEOF ( Fil , Variable, TrapErrors, ErrMsg )


      ! This routine prints out an EOF message and aborts the program.


      ! Argument declarations.

   CHARACTER(*), INTENT(IN)          :: Fil                                          ! The name of the file that ran out of data.
   CHARACTER(*), INTENT(IN)          :: Variable                                     ! The name of the variable we were trying to read at the time.
   LOGICAL, INTENT(IN), OPTIONAL     :: TrapErrors                                   ! Determines if the program should abort or return to calling function
   CHARACTER(*), INTENT(OUT),OPTIONAL:: ErrMsg                                       ! The name of the file that ran out of data.

      ! LOCAL variables
   LOGICAL                           :: TrapThisError                                ! The local version of TrapErrors
   CHARACTER(ErrMsgLen)              :: Msg                                          ! The local version of ErrMsg


   IF ( PRESENT( TrapErrors ) ) THEN
      TrapThisError = TrapErrors
   ELSE
      TrapThisError = .FALSE.
   END IF


   Msg = 'Premature EOF for file "'//TRIM( Fil )//'" while trying to read '//TRIM( Variable )//'.'

   IF ( PRESENT(ErrMsg) ) THEN
      ErrMsg = Msg
   ELSE
      CALL WrScr( ' ' )
      CALL ProgAbort( ' '//TRIM(Msg), TrapThisError )
   END IF


   RETURN
   END SUBROUTINE PremEOF ! ( Fil , Variable [, TrapErrors] [, ErrMsg] )
!=======================================================================
   SUBROUTINE ProcessComFile ( TopFileName, FileInfo, ErrStat, ErrMsg )


         ! This routine calls ScanComFile and ReadComFile to move non-comments in a set of nested
         ! files starting with TopFile into the FileInfo structure.


      IMPLICIT                                        NONE

         ! Argument declarations.

      INTEGER(IntKi), INTENT(OUT)                  :: ErrStat                 ! Error status.

      CHARACTER(*), INTENT(OUT)                    :: ErrMsg                  ! Error message.
      CHARACTER(*), INTENT(IN)                     :: TopFileName             ! The name of the top file in the nested structure.

      TYPE (FileInfoType), INTENT(OUT)             :: FileInfo                ! The derived type for holding the file information.


         ! Local declarations.

      INTEGER(IntKi)                               :: AryInd    = 0           ! The index into the FileInfo arrays.  There is no data in the arrays at the start.
      INTEGER(IntKi)                               :: ErrStatLcl              ! Error status local to this routine.
      INTEGER(IntKi)                               :: FileIndx  = 1           ! The index into the FileInfo%FileList array.  Start with the first file in the list.
      INTEGER(IntKi)                               :: RangeBeg  = 1           ! The first line in a range of lines to be included from a file.
      INTEGER(IntKi)                               :: RangeEnd  = 0           ! The last line in a range of lines to be included from a file.  Zero to read to the end of the file.

      INTEGER                                      :: File      = 0           ! Index into the arrays.
      
      CHARACTER(ErrMsgLen)                         :: ErrMsg2
      CHARACTER(*),       PARAMETER                :: RoutineName = 'ProcessComFile'
      TYPE (FNlist_Type), POINTER                  :: CurrFile                ! The current file being pointed to in the linked list.
      TYPE (FNlist_Type), POINTER                  :: FirstFile               ! The first file in the linked list (TopFile).
      TYPE (FNlist_Type), POINTER                  :: LastFile                ! The last file in the linked list.


         ! Scan the file, and it's included files, to determine how many lines will be kept and generate
         ! a linked list of the different files.
         ! This MUST be done before calling ReadComFile.

      ErrStat = ErrID_None
      ErrMsg  = ""
      
      ALLOCATE ( FirstFile ) !bjj: fix me , IOStat=ErrStatLcl2
      LastFile => FirstFile
      NULLIFY ( LastFile%Next )
      LastFile%Filename = TopFileName
      CurrFile => LastFile

      CALL ScanComFile ( FirstFile, CurrFile, LastFile, 1, 0, FileInfo%NumLines, ErrStatLcl, ErrMsg2 )
         CALL SetErrStat( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
         IF ( ErrStatLcl >= AbortErrLev )  THEN
            CALL Cleanup()
            RETURN
         ENDIF


         ! Count the number of different files in the linked list and allocate the array for the list of files.
         ! This MUST be done before calling ReadComFile.

      CurrFile => FirstFile
      FileInfo%NumFiles = 0

      DO
         IF ( .NOT. ASSOCIATED( CurrFile ) )  EXIT
         FileInfo%NumFiles = FileInfo%NumFiles + 1
         CurrFile => CurrFile%Next
      ENDDO

      ALLOCATE ( FileInfo%FileList( FileInfo%NumFiles ) , STAT=ErrStatLcl )
         IF ( ErrStatLcl /= 0 )  THEN
            CALL SetErrStat( ErrID_Fatal, 'Error allocating memory for the FileInfo%FileList array.' , ErrStat, ErrMsg, RoutineName )
            CALL Cleanup()
            RETURN
         ENDIF


         ! Copy the linked list of file names into the FileList array.
         ! This MUST be done before calling ReadComFile.

      CurrFile => FirstFile
      File     =  0
      DO
         IF ( .NOT. ASSOCIATED( CurrFile ) )  EXIT
         File = File + 1
         FileInfo%FileList(File) = CurrFile%Filename
         CurrFile => CurrFile%Next
      ENDDO


         ! Allocate the arrays to hold the non-comments, the files they occur in, and which lines they were found on.
         ! This MUST be done before calling ReadComFile.

      ALLOCATE ( FileInfo%FileLine( FileInfo%NumLines ) , STAT=ErrStatLcl )
         IF ( ErrStatLcl /= 0 )  THEN
            CALL SetErrStat( ErrID_Fatal, 'Error allocating memory for the FileInfo%FileLine array.' , ErrStat, ErrMsg, RoutineName )
            CALL Cleanup()
            RETURN
         ENDIF

      ALLOCATE ( FileInfo%FileIndx( FileInfo%NumLines ) , STAT=ErrStatLcl )
         IF ( ErrStatLcl /= 0 )  THEN
            CALL SetErrStat( ErrID_Fatal, 'Error allocating memory for the FileInfo%FileIndx array.' , ErrStat, ErrMsg, RoutineName )
            CALL Cleanup()
            RETURN
         ENDIF

      ALLOCATE ( FileInfo%Lines( FileInfo%NumLines ) , STAT=ErrStatLcl )
         IF ( ErrStatLcl /= 0 )  THEN
            CALL SetErrStat( ErrID_Fatal, 'Error allocating memory for the FileInfo%Lines array.' , ErrStat, ErrMsg, RoutineName )
            CALL Cleanup()
            RETURN
         ENDIF


         ! Read the file and save all but the comments.

      AryInd = 0
      CALL ReadComFile ( FileInfo, FileIndx, AryInd, RangeBeg, RangeEnd, ErrStatLcl, ErrMsg2 )
         CALL SetErrStat( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
         IF ( ErrStatLcl >= AbortErrLev )  THEN
            CALL Cleanup()
            RETURN
         ENDIF

      CALL Cleanup()         
      RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup (  )

         ! This subroutine cleans up all the allocatable arrays and closes the binary file

            ! Local arguments.

         TYPE (FNlist_Type), POINTER     :: NextFile    ! The next file being pointed to in the linked list.

            ! Deallocate the linked list of file names.

          CurrFile => FirstFile
          NextFile => CurrFile%Next
          DO
              DEALLOCATE(CurrFile)
              IF ( .NOT. ASSOCIATED( NextFile ) )  EXIT
              CurrFile => NextFile
              NextFile => CurrFile%Next
          ENDDO
          
!bjj: this needs to happen elsewhere...
          
         !IF ( ALLOCATED( FileInfo%FileLine ) ) DEALLOCATE( FileInfo%FileLine )
         !IF ( ALLOCATED( FileInfo%Lines    ) ) DEALLOCATE( FileInfo%FileIndx )
         !IF ( ALLOCATED( FileInfo%FileLine ) ) DEALLOCATE( FileInfo%FileList )
         !IF ( ALLOCATED( FileInfo%Lines    ) ) DEALLOCATE( FileInfo%Lines    )
                    
      END SUBROUTINE Cleanup 

   END SUBROUTINE ProcessComFile
!=======================================================================
   SUBROUTINE ProgAbort ( Message, TrapErrors, TimeWait, ErrLevel )


      ! This routine outputs fatal error messages and stops the program.


      ! Argument declarations.

   REAL(ReKi), INTENT(IN), OPTIONAL       :: TimeWait             ! Tells whether to wait for TimeWait s, or pause if <0.

   INTEGER(IntKi), INTENT(IN), OPTIONAL   :: ErrLevel             ! The error level to report to the OS.

   LOGICAL, INTENT(IN), OPTIONAL          :: TrapErrors           ! Determines if the program should abort or return to calling function

   CHARACTER(*), INTENT(IN)               :: Message              ! Error message.



   IF ( Beep )  CALL UsrAlarm

   CALL WrScr    ( Message )

   IF ( PRESENT(TrapErrors) )  THEN
      IF ( TrapErrors ) RETURN
   END IF

   IF ( LEN_TRIM(ProgName) > 0 ) THEN
      CALL WrScr ( NewLine//' Aborting '//TRIM( ProgName )//'.'//NewLine )
   ELSE
      CALL WrScr ( NewLine//' Aborting program.'//NewLine )
   END IF

      ! Do we pause (<0), proceed (=0), or wait (>0)?

   IF ( PRESENT( TimeWait ) )  THEN
      IF ( ( TimeWait < 0.0 ) .AND. KBInputOK )  THEN
         CALL ProgPause
      ELSE IF ( TimeWait > 0.0 )  THEN
         CALL WaitTime( TimeWait )
      END IF
   END IF


      ! Do we report a specific error level to the OS or use the default of 1?

   IF ( PRESENT( ErrLevel ) )  THEN
      CALL ProgExit ( ErrLevel )
   ELSE
      CALL ProgExit ( 1 )
   END IF


   END SUBROUTINE ProgAbort
!=======================================================================
   SUBROUTINE ProgPause()


      ! This routine pauses the program.



   CALL WrScr ( ' Hit the <Enter> key to continue.' )

   READ (*,'()')


   RETURN
   END SUBROUTINE ProgPause
!=======================================================================
   SUBROUTINE ProgWarn ( Message )


      ! This routine outputs non-fatal warning messages and returns to the calling routine.


      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: Message                                      ! Warning message.



   IF ( Beep )  CALL UsrAlarm
   CALL WrScr ( ' WARNING:  '//Message )


   RETURN
   END SUBROUTINE ProgWarn 
!=======================================================================
   FUNCTION R2LStr4 ( FltNum )

      ! This function converts a 4-byte floating point number to
      ! a left-aligned string.  It eliminates trailing zeroes
      ! and even the decimal point if it is not a fraction.


      ! Function declaration.

   CHARACTER(15)                :: R2LStr4                                         ! This function.


      ! Argument declarations.

   REAL(SiKi), INTENT(IN)       :: FltNum                                          ! The floating-point number to convert.


      ! Return a 0 if that's what we have.

   IF ( FltNum == 0.0_SiKi )  THEN
      R2LStr4 = '0'
      RETURN
   END IF


      ! Write the number into the string using G format and left justify it.

   WRITE (R2LStr4,'(1PG15.5)')  FltNum

   CALL AdjRealStr( R2LStr4 )


   RETURN
   END FUNCTION R2LStr4
!=======================================================================
   FUNCTION R2LStr8 ( FltNum )

      ! This function converts a 8-byte floating point number to
      ! a left-aligned string.  It eliminates trailing zeroes
      ! and even the decimal point if it is not a fraction.


      ! Function declaration.

   CHARACTER(15)                :: R2LStr8                                         ! This function.


      ! Argument declarations.

   REAL(R8Ki), INTENT(IN)       :: FltNum                                          ! The floating-point number to convert.


      ! Return a 0 if that's what we have.

   IF ( FltNum == 0.0_R8Ki )  THEN
      R2LStr8 = '0'
      RETURN
   END IF


      ! Write the number into the string using G format and left justify it.

   WRITE (R2LStr8,'(1PG15.5)')  FltNum

   CALL AdjRealStr( R2LStr8 )


   RETURN
   END FUNCTION R2LStr8
!=======================================================================
   FUNCTION R2LStr16 ( FltNum )

      ! This function converts a 16-byte floating point number to
      ! a left-aligned string.  It eliminates trailing zeroes
      ! and even the decimal point if it is not a fraction.


      ! Function declaration.

   CHARACTER(15)                :: R2LStr16                                        ! This function.


      ! Argument declarations.

   REAL(QuKi), INTENT(IN)       :: FltNum                                          ! The floating-point number to convert.


      ! Return a 0 if that's what we have.

   IF ( FltNum == 0.0_QuKi )  THEN
      R2LStr16 = '0'
      RETURN
   END IF


      ! Write the number into the string using G format and left justify it.

   WRITE (R2LStr16,'(1PG15.5)')  FltNum

   CALL AdjRealStr( R2LStr16 )


   RETURN
   END FUNCTION R2LStr16 !  ( FltNum )
!======================================================================
   SUBROUTINE ReadCAry ( UnIn, Fil, CharAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values separated by whitespace into a character array (either on same line or multiple lines).


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: AryLen                                          ! Length of the array.
   INTEGER, INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER, INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER, INTENT(OUT)         :: ErrStat                                         ! Error status
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                          ! Error message describing ErrStat

   CHARACTER(*), INTENT(OUT)    :: CharAry(AryLen)                                 ! Real variable being read.
   CHARACTER(*), INTENT(IN)     :: AryDescr                                        ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)     :: AryName                                         ! Text string containing the variable name.
   CHARACTER(*), INTENT(IN)     :: Fil                                             ! Name of the input file.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the string array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.


   READ (UnIn,*,IOSTAT=IOS)  ( CharAry(Ind), Ind=1,AryLen )

   CALL CheckIOS ( IOS, Fil, TRIM( AryName ), StrType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_StrAryFrmt)  TRIM( AryName ), AryDescr, ( TRIM( CharAry(Ind) ), Ind=1,MIN(AryLen,NWTC_MaxAryLen) )
   END IF


   RETURN
   END SUBROUTINE ReadCAry
!=======================================================================
   SUBROUTINE ReadCAryLines ( UnIn, Fil, CharAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into a real array from the next AryLen lines of the input file.


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: AryLen                                          ! Length of the array.
   INTEGER, INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER, INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER, INTENT(OUT)         :: ErrStat                                         ! Error status
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                          ! Error message describing ErrStat

   CHARACTER(*), INTENT(OUT)    :: CharAry(AryLen)                                 ! Char variable being read.

   CHARACTER(*), INTENT(IN)     :: Fil                                             ! Name of the input file.
   CHARACTER(*), INTENT(IN)     :: AryDescr                                        ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)     :: AryName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the real array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.


    ErrStat = ErrID_None
    ErrMsg = ""

   DO Ind=1,AryLen
      READ (UnIn,*,IOSTAT=IOS)  CharAry(Ind)

      CALL CheckIOS ( IOS, Fil, TRIM( AryName )//'('//TRIM( Int2LStr( Ind ) )//')', StrType, ErrStat, ErrMsg )

      IF (ErrStat >= AbortErrLev) RETURN

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 ) &
            WRITE (UnEc,Ec_StrFrmt)  TRIM( AryName )//'('//TRIM( Int2LStr( Ind ) )//')', AryDescr, TRIM(CharAry(Ind))
      END IF
   END DO

   RETURN
   END SUBROUTINE ReadCAryLines
!=======================================================================
   SUBROUTINE ReadCom ( UnIn, Fil, ComName, ErrStat, ErrMsg, UnEc )

      ! This routine reads a comment from the next line of the input file.


      ! Argument declarations:

   INTEGER,        INTENT(IN)          :: UnIn                                     ! I/O unit for input file.
   INTEGER,        INTENT(IN), OPTIONAL:: UnEc                                     ! I/O unit for echo file. If present and > 0, write to UnEc
   CHARACTER(*),   INTENT(IN)          :: Fil                                      ! Name of the input file.
   CHARACTER(*),   INTENT(IN)          :: ComName                                  ! Text string containing the comment name.
   INTEGER(IntKi), INTENT(OUT)         :: ErrStat                                  ! Error status; if present, program does not abort on error
   CHARACTER(*),   INTENT(OUT)         :: ErrMsg                                   ! Error message



      ! Local declarations:

   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.

   CHARACTER(200)               :: Comment                                         ! Text string containing the comment.



   READ (UnIn,'(A)',IOSTAT=IOS)  Comment

   CALL CheckIOS ( IOS, Fil, ComName, StrType, ErrStat, ErrMsg )


   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,'(A)')  Comment
   END IF


   RETURN
   END SUBROUTINE ReadCom
!=============================================================================
   RECURSIVE SUBROUTINE ReadComFile ( FileInfo, FileIndx, AryInd, StartLine, LastLine, ErrStat, ErrMsg )


      ! This routine opens and reads the contents of a file with comments and stores the good stuff in the FileInfo structure.
      ! You need to call ScanComFile() first to count the number of lines and get the list of files in the recursive tree.
      ! This information needs to be stored in the FileInfo structure before calling this routine.


      ! Argument declarations.

   INTEGER(IntKi), INTENT(INOUT)             :: AryInd                        ! The current index into the FileInfo arrays.
   INTEGER(IntKi), INTENT(OUT)               :: ErrStat                       ! Error status.
   INTEGER(IntKi), INTENT(IN)                :: FileIndx                      ! The pointer to file name in the list of files.
   INTEGER(IntKi), INTENT(IN)                :: LastLine                      ! The last line to read from this file.  Includes blank and comment lines. Zero means read to the end of file.
   INTEGER(IntKi), INTENT(IN)                :: StartLine                     ! The line at which to start processing this file.  Includes blank and comment lines.

   CHARACTER(*), INTENT(OUT)                 :: ErrMsg                        ! Error message.

   TYPE (FileInfoType), INTENT(INOUT)        :: FileInfo                      ! The derived type for holding the file information.


      ! Local declarations.

   INTEGER(IntKi)                            :: ErrStatLcl                    ! Error status local to this routine.

   INTEGER                                   :: File                          ! The index into the FileList array.
   INTEGER                                   :: FileLine                      ! The current line of the input file.
   INTEGER                                   :: LineLen                       ! The length of the line returned from ReadLine().
   INTEGER                                   :: NewIndx                       ! The index into the FileList array that applied to the next file to be processed.
   INTEGER                                   :: RangeBeg                      ! The first line in a range of lines to be included from a file.
   INTEGER                                   :: RangeEnd                      ! The last line in a range of lines to be included from a file.
   INTEGER                                   :: UnIn                          ! The unit number used for the input file.
                                                                              ! Should the comment characters be passed to this routine instead of being hard coded? -mlb
   CHARACTER(3), PARAMETER                   :: CommChars = '!#%'             ! Comment characters that mark the end of useful input.
   CHARACTER(1024)                           :: IncFileName                   ! The name of a file that this one includes.
   CHARACTER(512)                            :: Line                          ! The contents of a line returned from ReadLine() with comment removed.
   CHARACTER(ErrMsgLen)                      :: ErrMsg2
   CHARACTER(*), PARAMETER                   :: RoutineName = 'ReadComFile'

   
   ErrStat = ErrID_None
   ErrMsg  = ""
   
      ! Open the input file.

   CALL GetNewUnit ( UnIn, ErrStatLcl, ErrMsg2 )
      CALL SetErrStat( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL OpenFInpFile ( UnIn, FileInfo%FileList(FileIndx), ErrStatLcl, ErrMsg2 )
      CALL SetErrStat( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF ( ErrStat >= AbortErrLev )  THEN
         CALL Cleanup()
         RETURN
      END IF
      


      ! Skip the beginning of the file, if requested.

   IF ( StartLine > 1 )  THEN
      DO FileLine=1,StartLine-1
         READ(UnIn,'()',IOStat=ErrStatLcl)
         IF (ErrStatLcl /= 0) THEN
            CALL SetErrStat( ErrID_Fatal, "Error reading file beginning.", ErrStat, ErrMsg, RoutineName )
            CALL Cleanup()
            RETURN
         END IF         
      ENDDO ! FileLine
   ENDIF ! ( StartLine > 1 )

   FileLine = StartLine - 1


      ! Read the data.

   ErrStatLcl = 0

   DO WHILE ( ErrStatLcl == 0 )


         ! Stop processing when CurrLine > LastLine.  If LastLine is zero, read to the end of file.

      FileLine = FileLine + 1

      IF ( ( LastLine > 0 ) .AND. ( FileLine > LastLine ) )  EXIT


         ! Process the next line.

      CALL ReadLine ( UnIn, CommChars, Line, LineLen, ErrStatLcl )            ! Reads a line.  Returns what is before the first comment character.

      IF ( ( ErrStatLcl == 0 )  .AND. ( LineLen > 0 ) )  THEN ! ErrStatLcl is IOStat from Read statement

         Line = ADJUSTL( Line )


            ! Is this line trying to include another file?  If so, recursively process it.

         IF ( Line(1:1) == '@' )  THEN


               ! Parse the contents of everything after the "@" to determine the name of the include file and the optional line range.

            CALL ParseInclInfo ( Line(2:), IncFileName, RangeBeg, RangeEnd, ErrStatLcl, ErrMsg2 )
               CALL SetErrStat( ErrStatLcl, TRIM( FileInfo%FileList(FileIndx) )//':Line#'//TRIM( Num2LStr( FileLine ) ) &
                                //':'//TRIM(ErrMsg2), ErrStat, ErrMsg, RoutineName )
               IF ( ErrStat >= AbortErrLev )  THEN
                  CALL Cleanup()
                  RETURN
               END IF
               ErrStatLcl = 0

               ! Which file in the prestored list is the new one?

            DO File=1,FileInfo%NumFiles
               IF ( TRIM( FileInfo%FileList(File) ) == TRIM( IncFileName ) )  THEN
                  NewIndx = File
                  EXIT
               ENDIF ! ( TRIM( FileInfo%FileList(File) ) == TRIM( Line(2:) ) )
            ENDDO ! File


               ! Let's recursively process this new file.

            CALL ReadComFile ( FileInfo, NewIndx, AryInd, RangeBeg, RangeEnd, ErrStatLcl, ErrMsg2 )
               CALL SetErrStat( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
               IF ( ErrStat >= AbortErrLev )  THEN
                  CALL Cleanup()
                  RETURN
               END IF
               ErrStatLcl = 0

         ELSE


               ! Not a file name.  Add this line to stack.

            AryInd                    = AryInd + 1
            FileInfo%FileLine(AryInd) = FileLine
            FileInfo%FileIndx(AryInd) = FileIndx
            FileInfo%Lines   (AryInd) = Line

         ENDIF ! ( Line(1:1) == '@' )

      ENDIF ! ( ( ErrStatLcl == 0 )  .AND. ( LineLen > 0 ) )

   ENDDO ! WHILE ( ErrStatLcl == 0 )

   CALL Cleanup(  )

   RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup ( )

         ! This subroutine cleans up all the allocatable arrays, sets the error status/message and closes the binary file

            ! Close the input file.

         CLOSE ( UnIn )

      END SUBROUTINE Cleanup

   END SUBROUTINE ReadComFile
!=======================================================================
   SUBROUTINE ReadCVar ( UnIn, Fil, CharVar, VarName, VarDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a single character variable from the next line of the input file.


      ! Argument declarations:

   INTEGER,        INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER,        INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER(IntKi), INTENT(OUT)         :: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),   INTENT(OUT)         :: ErrMsg                                          ! Error message

   CHARACTER(*),   INTENT(OUT)         :: CharVar                                         ! Integer variable being read.
   CHARACTER(*),   INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER(*),   INTENT(IN)          :: VarDescr                                        ! Text string describing the variable.
   CHARACTER(*),   INTENT(IN)          :: VarName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                             :: IOS                                             ! I/O status returned from the read statement.



   READ (UnIn,*,IOSTAT=IOS)  CharVar


   CALL CheckIOS ( IOS, Fil, VarName, StrType, ErrStat, ErrMsg )


   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_StrFrmt)  VarName, VarDescr, '"'//TRIM( CharVar )//'"'
   END IF


   RETURN
   END SUBROUTINE ReadCVar
!=======================================================================
   SUBROUTINE ReadFASTbin ( UnIn, Init, FASTdata, ErrStat, ErrMsg )

      ! This routine reads the contents of a FAST binary output file (FASTbinFile) and stores it in FASTdata.
      ! It is assumed that the name of the binary file is preloaded into FASTdata%File by the calling procedure.


      ! Argument declarations.

   INTEGER(IntKi),      INTENT(  OUT)     :: ErrStat                 ! An optional error level to be returned to the calling routine.
   INTEGER(IntKi),      INTENT(INOUT)     :: UnIn                    ! The IO unit for the FAST binary file.

   LOGICAL,             INTENT(IN)        :: Init                    ! A flag to tell the routine to read only the file header for initialization purposes.

   CHARACTER(*),        INTENT(  OUT)     :: ErrMsg                  ! An optional error message to be returned to the calling routine.

   TYPE (FASTdataType), INTENT(INOUT)     :: FASTdata                ! The derived type for holding FAST output data.


      ! Local declarations.

   REAL(R8Ki)                             :: TimeIncr                ! The increment for the time data when a time channel is not included.
   REAL(R8Ki)                             :: TimeOff                 ! The offset for the time data when a time channel is included.
   REAL(R8Ki)                             :: TimeOut1                ! The first output data when a time channel is not included.
   REAL(R8Ki)                             :: TimeScl                 ! The slope for the time data when a time channel is included.

   REAL(ReKi), ALLOCATABLE                :: ColMax(:)               ! The maximum value of the column data.
   REAL(ReKi), ALLOCATABLE                :: ColMin(:)               ! The minimum value of the column data.

   REAL(SiKi), ALLOCATABLE                :: ColOff(:)               ! The offset for the column data.
   REAL(SiKi), ALLOCATABLE                :: ColScl(:)               ! The slope for the column data.

   INTEGER(IntKi)                         :: IChan                   ! The channel index used for DO loops.
   INTEGER(IntKi)                         :: IChr                    ! The character index used for DO loops.
   INTEGER(IntKi)                         :: IRow                    ! The row index used for DO loops.
   INTEGER(IntKi)                         :: LenDesc                 ! The length of the description string, DescStr.
   INTEGER(IntKi), PARAMETER              :: MaxLenDesc = 1024       ! The maximum allowed length of the description string, DescStr.
   INTEGER(IntKi), PARAMETER              :: MaxChrLen  = 10         ! The maximum length for channel names and units.

   INTEGER(B4Ki), ALLOCATABLE             :: TmpTimeArray(:)         ! This array holds the normalized time channel that was read from the binary file.
   INTEGER(B4Ki)                          :: Tmp4BInt                ! This scalar temporarially holds a 4-byte integer that was stored in the binary file

   INTEGER(B2Ki)                          :: FileType                ! The type of FAST data file (1: Time channel included in file; 2: Time stored as start time and step).
   INTEGER(B2Ki), ALLOCATABLE             :: TmpInArray(:,:)         ! This array holds the normalized channels that were read from the binary file.

   INTEGER(B1Ki), ALLOCATABLE             :: DescStrASCII(:)         ! The ASCII equivalent of DescStr.
   INTEGER(B1Ki)                          :: TmpStrASCII(MaxChrLen)  ! The temporary ASCII equivalent of a channel name or units.

   INTEGER(IntKi)                         :: ErrStat2
   CHARACTER(ErrMsgLen)                   :: ErrMsg2
   CHARACTER(*), PARAMETER                :: RoutineName = 'ReadFASTbin'

   
   ErrStat = ErrID_None
   ErrMsg  = ""

   
   
      !  Open data file.

   CALL OpenBInpFile ( UnIn, FASTdata%File, ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF (ErrStat >= AbortErrLev) THEN
         CALL Cleanup()
         RETURN
      END IF
      


      ! Process the requested data records of this file.

   CALL WrScr ( NewLine//' =======================================================' )
   CALL WrScr ( ' Reading in data from file "'//TRIM( FASTdata%File )//'".'//NewLine )


      ! Read some of the header information.

   READ (UnIn, IOSTAT=ErrStat2)  FileType
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading FileType from file "'//TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   READ (UnIn, IOSTAT=ErrStat2)  Tmp4BInt
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading the number of channels from file "' &
                                      //TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF
   FASTdata%NumChans = Tmp4BInt  ! possible type conversion

   READ (UnIn, IOSTAT=ErrStat2)  Tmp4BInt
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading the number of records from file "' &
                                          //TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF
   FASTdata%NumRecs = Tmp4BInt ! possible type conversion


      ! Time is done differently for the two file types.

   IF ( FileType == FileFmtID_WithTime )  THEN

      READ (UnIn, IOSTAT=ErrStat2)  TimeScl
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading TimeScl from file "'//TRIM( FASTdata%File ) &
                                           //'".', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF

      READ (UnIn, IOSTAT=ErrStat2)  TimeOff
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading TimeOff from file "'//TRIM( FASTdata%File ) &
                                           //'".', ErrStat, ErrMsg, RoutineName )
         RETURN
         CALL Cleanup()
      ENDIF

   ELSE

      READ (UnIn, IOSTAT=ErrStat2)  TimeOut1
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading TimeOut1 from file "'//TRIM( FASTdata%File ) &
                                           //'".', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF

      READ (UnIn, IOSTAT=ErrStat2)  TimeIncr
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading TimeIncr from file "'//TRIM( FASTdata%File ) &
                                           //'".', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF

   END IF ! IF ( FileType == FileFmtID_WithTime )


      ! Allocate the necessary arrays.

   ALLOCATE ( ColMax( FASTdata%NumChans ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for ColMax array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   ALLOCATE ( ColMin( FASTdata%NumChans ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for ColMin array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   ALLOCATE ( ColOff( FASTdata%NumChans ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for ColOff array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   ALLOCATE ( FASTdata%ChanNames( FASTdata%NumChans+1 ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for FASTdata%ChanNames array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   ALLOCATE ( FASTdata%ChanUnits( FASTdata%NumChans+1 ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat( ErrID_Fatal, 'Fatal error allocating memory for FASTdata%ChanUnits array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   ALLOCATE ( ColScl( FASTdata%NumChans ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for ColScl array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   ALLOCATE ( TmpInArray( FASTdata%NumRecs, FASTdata%NumChans ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for the TmpInArray array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   IF ( FileType == FileFmtID_WithTime ) THEN
      ALLOCATE ( TmpTimeArray( FASTdata%NumRecs ) , STAT=ErrStat2 )
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for the TmpTimeArray array.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF
   END IF

   ALLOCATE ( FASTdata%Data( FASTdata%NumRecs, FASTdata%NumChans+1 ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for the FASTdata%Data array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF


      ! Read more of the header information.

   READ (UnIn, IOSTAT=ErrStat2)  ColScl
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading the ColScl array from file "' &
                                          //TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   READ (UnIn, IOSTAT=ErrStat2)  ColOff
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading the ColOff array from file "' &
                                          //TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   READ (UnIn, IOSTAT=ErrStat2)  LenDesc
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading LenDesc from file "'//TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF
   LenDesc = MIN( LenDesc, MaxLenDesc )

   ALLOCATE ( DescStrASCII( LenDesc ) , STAT=ErrStat2 )
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error allocating memory for the DescStrASCII array.', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   READ (UnIn, IOSTAT=ErrStat2)  DescStrASCII
   IF ( ErrStat2 /= 0 )  THEN
      CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading the DescStrASCII array from file "' &
                                      //TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
      CALL Cleanup()
      RETURN
   ENDIF

   FASTdata%Descr = ''

   DO IChr=1,LenDesc
      FASTdata%Descr(IChr:IChr) = CHAR( DescStrASCII(IChr) )
   END DO

   TmpStrASCII(:) = ICHAR( ' ' )
   DO IChan=1,FASTdata%NumChans+1
      READ (UnIn, IOSTAT=ErrStat2)  TmpStrASCII
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading the title of Channel #'//Int2LStr(  IChan )// &
                                          ' from file "'//TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF
      FASTdata%ChanNames(IChan) = ''
      DO IChr=1,MaxChrLen
         FASTdata%ChanNames(IChan)(IChr:IChr) = CHAR( TmpStrASCII(IChr) )
      END DO
   END DO

   TmpStrASCII(:) = ICHAR( ' ' )
   DO IChan=1,FASTdata%NumChans+1
      READ (UnIn, IOSTAT=ErrStat2)  TmpStrASCII
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading the units of Channel #'//Int2LStr(  IChan )// &
                                          ' from file "'//TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF
      FASTdata%ChanUnits(IChan) = ''
      DO IChr=1,MaxChrLen
         FASTdata%ChanUnits(IChan)(IChr:IChr) = CHAR( TmpStrASCII(IChr) )
      END DO
   END DO


      ! Return if we only wanted to read the header.

   IF ( Init )  THEN
      CALL Cleanup()
      RETURN
   ENDIF


      ! If the file contains a time channel (as opposed to just initial time and time step), read it.
      ! There are four bytes per time value.

   IF ( FileType == FileFmtID_WithTime ) THEN

      READ (UnIn, IOSTAT=ErrStat2)  TmpTimeArray                                 ! Time data stored in normalized 32-bit integers
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading time data from file "'//TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF

   END IF ! FileType


      ! Put time data in the data array.

   IF ( FileType == FileFmtID_WithTime )  THEN
      FASTdata%Data(:,1) = ( TmpTimeArray(:) - TimeOff )/TimeScl;
      FASTdata%TimeStep  = FASTdata%Data(2,1) - FASTdata%Data(1,1)
   ELSE
      FASTdata%Data(:,1) = REAL( TimeOut1, DbKi ) + REAL( TimeIncr, DbKi )*[ (IRow, IRow=0,FASTdata%NumRecs-1 ) ];
      FASTdata%TimeStep  = TimeIncr
   END IF


      ! Read the FAST channel data.

   DO IRow=1,FASTdata%NumRecs
      READ (UnIn, IOSTAT=ErrStat2)  TmpInArray(IRow,:)
      IF ( ErrStat2 /= 0 )  THEN
         CALL SetErrStat ( ErrID_Fatal, 'Fatal error reading channel data from file "'//TRIM( FASTdata%File )//'".', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF
   END DO ! IRow=1,FASTdata%NumRecs


      ! Denormalize the data one row at a time and store it in the FASTdata%Data array.

   DO IRow=1,FASTdata%NumRecs
      FASTdata%Data(IRow,2:) = ( TmpInArray(IRow,:) - ColOff(:) )/ColScl(:)
   END DO ! IRow=1,FASTdata%NumRecs


   CALL Cleanup( )
   RETURN

   !=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup ( )

         ! This subroutine cleans up all the allocatable arrays, sets the error status/message and closes the binary file


            ! Deallocate arrays created in this routine.

         IF ( ALLOCATED( ColMax             ) ) DEALLOCATE( ColMax             )
         IF ( ALLOCATED( ColMin             ) ) DEALLOCATE( ColMin             )
         IF ( ALLOCATED( ColOff             ) ) DEALLOCATE( ColOff             )
         IF ( ALLOCATED( ColScl             ) ) DEALLOCATE( ColScl             )
         IF ( ALLOCATED( DescStrASCII       ) ) DEALLOCATE( DescStrASCII       )
         IF ( ALLOCATED( TmpInArray         ) ) DEALLOCATE( TmpInArray         )
         IF ( ALLOCATED( TmpTimeArray       ) ) DEALLOCATE( TmpTimeArray       )


            ! Close file

         CLOSE ( UnIn )

      END SUBROUTINE Cleanup

   END SUBROUTINE ReadFASTbin
!=======================================================================
   SUBROUTINE ReadIAry ( UnIn, Fil, IntAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into an integer array from the next AryLen lines of the input file.


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: AryLen                                          ! Length of the array.
   INTEGER, INTENT(OUT)         :: IntAry(AryLen)                                  ! Integer array being read.
   INTEGER, INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER, INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER, INTENT(OUT)         :: ErrStat                                         ! Error status
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                          ! Error message associated with ErrStat

   CHARACTER(*), INTENT(IN)     :: Fil                                             ! Name of the input file.
   CHARACTER(*), INTENT(IN)     :: AryDescr                                        ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)     :: AryName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the integer array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   READ (UnIn,*,IOSTAT=IOS)  ( IntAry(Ind), Ind=1,AryLen )

   CALL CheckIOS ( IOS, Fil, TRIM( AryName ), NumType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 ) THEN
            WRITE( UnEc, Ec_IntAryFrmt ) TRIM( AryName ), AryDescr, IntAry(1:MIN(AryLen,NWTC_MaxAryLen))
         END IF
   END IF !present(unec)




   RETURN
   END SUBROUTINE ReadIAry
!=======================================================================
   SUBROUTINE ReadIVar ( UnIn, Fil, IntVar, VarName, VarDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a single integer variable from the next line of the input file.


      ! Argument declarations:

   INTEGER,        INTENT(OUT)         :: IntVar                                          ! Integer variable being read.
   INTEGER,        INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER,        INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER(IntKi), INTENT(OUT)         :: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),   INTENT(OUT)         :: ErrMsg                                          ! Error message

   CHARACTER(*),   INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER(*),   INTENT(IN)          :: VarDescr                                        ! Text string describing the variable.
   CHARACTER(*),   INTENT(IN)          :: VarName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                             :: IOS                                             ! I/O status returned from the read statement.

   CHARACTER(30)                       :: Word                                            ! String to hold the first word on the line.


   CALL ReadNum ( UnIn, Fil, Word, VarName, ErrStat, ErrMsg )   
   IF ( ErrStat >= AbortErrLev ) RETURN  ! If we're about to read a T/F and treat it as a number, we have a less severe ErrStat


   READ (Word,*,IOSTAT=IOS)  IntVar


   CALL CheckIOS ( IOS, Fil, VarName, NumType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_IntFrmt)  IntVar, VarName, VarDescr
   END IF


   RETURN
   END SUBROUTINE ReadIVar
!=======================================================================
   SUBROUTINE ReadLAry ( UnIn, Fil, LogAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into an logical array from the next AryLen lines of the input file.


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: AryLen                                          ! Length of the array.
   INTEGER, INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER, INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER, INTENT(OUT)         :: ErrStat                                         ! Error status
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                          ! Error message associated with ErrStat

   LOGICAL, INTENT(OUT)         :: LogAry(AryLen)                                  ! Logical array being read.

   CHARACTER(*), INTENT(IN)     :: Fil                                             ! Name of the input file.
   CHARACTER(*), INTENT(IN)     :: AryDescr                                        ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)     :: AryName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the integer array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   READ (UnIn,*,IOSTAT=IOS)  ( LogAry(Ind), Ind=1,AryLen )

   CALL CheckIOS ( IOS, Fil, TRIM( AryName ), FlgType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) THEN
         WRITE( UnEc, Ec_LgAryFrmt ) TRIM( AryName ), AryDescr, LogAry(1:MIN(AryLen,NWTC_MaxAryLen))
      END IF
   END IF !present(unec)

   RETURN
   END SUBROUTINE ReadLAry
!=============================================================================
SUBROUTINE ReadLine ( UnIn, CommChars, Line, LineLen, IOStat )


      ! This routine reads a line from the specified input file and returns the non-comment
      ! portion of the line.


      ! Argument declarations.

   INTEGER(IntKi), INTENT(OUT)               :: IOStat                       ! Error status.

   INTEGER, INTENT(IN)                       :: UnIn                          ! The unit number for the file being read.
   INTEGER, INTENT(OUT)                      :: LineLen                       ! The length of the line returned from ReadLine().

   CHARACTER(*), INTENT(IN)                  :: CommChars                     ! The list of possible comment characters.
   CHARACTER(*), INTENT(OUT)                 :: Line                          ! The decommented line being returned to the calling routine.

      ! Local declarations.

   INTEGER                                    :: CommLoc                      ! The left-most location of a given comment character in the Line.
   INTEGER                                    :: FirstComm                    ! The location of first comment character in the Line.
   INTEGER                                    :: IC                           ! The index for the character location in the string.
   INTEGER                                    :: NumCommChars                 ! The number of comment characters in the CommChars array.


   READ (UnIn,'(A)',IOSTAT=IOStat)  Line

   IF ( IOStat /= 0 )  THEN
      Line    = ''
      LineLen = 0
      RETURN
   ENDIF

   LineLen      = LEN_TRIM( Line )
   NumCommChars = LEN_TRIM( CommChars )

   IF ( ( NumCommChars == 0 ) .OR. ( LineLen == 0 ) )  RETURN

   FirstComm = MIN( LEN( Line ), LineLen + 1 )

   DO IC=1,NumCommChars
      CommLoc = INDEX( Line, CommChars(IC:IC) )
      IF ( CommLoc > 0 )  THEN
         FirstComm = MIN( CommLoc, FirstComm )
      ENDIF
   END DO

   Line    = Line(:FirstComm-1)
   LineLen = LEN_TRIM( Line )


   RETURN
   END SUBROUTINE ReadLine
!=======================================================================
   SUBROUTINE ReadLVar ( UnIn, Fil, LogVar, VarName, VarDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a single logical variable from the next line of the input file.


      ! Argument declarations:

   INTEGER,        INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER,        INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER(IntKi), INTENT(OUT)         :: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),   INTENT(OUT)         :: ErrMsg                                          ! Error message

   LOGICAL,        INTENT(OUT)         :: LogVar                                          ! Logical variable being read.

   CHARACTER(*),   INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER(*),   INTENT(IN)          :: VarDescr                                        ! Text string describing the variable.
   CHARACTER(*),   INTENT(IN)          :: VarName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                             :: IOS                                             ! I/O status returned from the read statement.


   READ (UnIn,*,IOSTAT=IOS)  LogVar

   CALL CheckIOS ( IOS, Fil, VarName, FlgType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN


   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_LgFrmt)  LogVar, VarName, VarDescr
   END IF


   RETURN
   END SUBROUTINE ReadLVar
!=======================================================================
   SUBROUTINE ReadNum ( UnIn, Fil, Word, VarName, ErrStat, ErrMsg )


      ! This routine reads a single word from a file and tests to see if it's a pure number (no true or false).


      ! Argument declarations:

   INTEGER,       INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER(IntKi),INTENT(OUT)         :: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),  INTENT(OUT)         :: ErrMsg                                          ! Error message

   CHARACTER(*),  INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER(*),  INTENT(IN)          :: VarName                                         ! Text string containing the variable name.
   CHARACTER(*),  INTENT(Out)         :: Word                                            ! Text string containing the first word from the input line.


      ! Local declarations:

   INTEGER                            :: IOS                                             ! I/O status returned from the read statement.



      ! Read in the first word of the input line.  Check I/O status.

   READ (UnIn,*,IOSTAT=IOS)  Word


   CALL CheckIOS ( IOS, Fil, VarName, NumType, ErrStat, ErrMsg )


   IF (ErrStat >= AbortErrLev) RETURN


      ! See if the word starts with a T or F.  If so, flag it as an invalid number.

   IF ( INDEX( 'FTft', Word(:1) ) > 0 )  THEN
      
      ErrStat = ErrID_Severe
      ErrMsg = 'ReadNum:Invalid numeric input for file "'//TRIM( Fil )//'". "'//TRIM( Word )// &
               '" found when trying to read the number, '//TRIM( VarName )//'.'

   END IF



   RETURN
   END SUBROUTINE ReadNum
!=======================================================================
   SUBROUTINE ReadOutputList ( UnIn, Fil, CharAry, AryLenRead, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads up to MaxAryLen values from an input file and store them in CharAry(:).
      ! These values represent the names of output channels, and they are specified in the format
      ! required for OutList(:) in FAST input files.
      ! The end of this list is specified with the line beginning with the 3 characters "END".


      ! Argument declarations:

   INTEGER,      INTENT(OUT)         :: AryLenRead                                 ! Length of the array that was actually read.
   INTEGER,      INTENT(IN)          :: UnIn                                       ! I/O unit for input file.
   INTEGER,      INTENT(IN)          :: UnEc                                       ! I/O unit for echo file (if > 0).
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message

   CHARACTER(*), INTENT(OUT)         :: CharAry(:)                                 ! Character array being read (calling routine dimensions it to max allowable size).

   CHARACTER(*), INTENT(IN)          :: Fil                                        ! Name of the input file.
   CHARACTER(*), INTENT(IN)          :: AryDescr                                   ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)          :: AryName                                    ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                          :: MaxAryLen                                   ! Maximum length of the array being read
   INTEGER                          :: NumWords                                    ! Number of words contained on a line


   CHARACTER(1000)                  :: OutLine                                     ! Character string read from file, containing output list
   CHARACTER(3)                     :: EndOfFile


      ! Initialize some values

   ErrStat = ErrID_None
   ErrMsg  = ''
   MaxAryLen  = SIZE(CharAry)
   AryLenRead = 0

   CharAry = ''


      ! Read in all of the lines containing output parameters and store them in CharAry(:).
      ! The end of this list is specified with the line beginning with END.

   DO

      CALL ReadVar ( UnIn, Fil, OutLine, AryName, AryDescr, ErrStat, ErrMsg, UnEc )
      IF ( ErrStat >= AbortErrLev ) RETURN

      EndOfFile = OutLine(1:3)            ! EndOfFile is the 1st 3 characters of OutLine
      CALL Conv2UC( EndOfFile )           ! Convert EndOfFile to upper case
      IF ( EndOfFile == 'END' )  EXIT     ! End of OutList has been reached; therefore, exit this DO

      NumWords = CountWords( OutLine )    ! The number of words in OutLine.

      AryLenRead = AryLenRead + NumWords  ! The total number of output channels read in so far.

         ! Check to see if the maximum # allowable in the array has been reached.

      IF ( AryLenRead > MaxAryLen )  THEN

         ErrStat = ErrID_Fatal
         ErrMsg = 'ReadOutputList:The maximum number of output channels allowed is '//TRIM( Int2LStr(MaxAryLen) )//'.'
         RETURN

      ELSE

         CALL GetWords ( OutLine, CharAry((AryLenRead - NumWords + 1):AryLenRead), NumWords )

      END IF

   END DO


   RETURN
   END SUBROUTINE ReadOutputList
!=======================================================================
   SUBROUTINE ReadR4Ary ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into a 4-byte real array separated by white space
      ! (possibly on the same line of the input file).


      ! Argument declarations:

   INTEGER,      INTENT(IN)          :: AryLen                                     ! Length of the array.
   INTEGER,      INTENT(IN)          :: UnIn                                       ! I/O unit for input file.
   INTEGER,      INTENT(IN),OPTIONAL :: UnEc                                       ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message


   REAL(SiKi), INTENT(INOUT)         :: RealAry(AryLen)                            ! Real array being read.

   CHARACTER(*), INTENT(IN)          :: Fil                                        ! Name of the input file.
   CHARACTER(*), INTENT(IN)          :: AryDescr                                   ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)          :: AryName                                    ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the real array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   READ (UnIn,*,IOSTAT=IOS)  ( RealAry(Ind), Ind=1,AryLen )

   CALL CheckIOS ( IOS, Fil, TRIM( AryName ), NumType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) THEN
         WRITE( UnEc, Ec_ReAryFrmt ) TRIM( AryName ), AryDescr, RealAry(1:MIN(AryLen,NWTC_MaxAryLen))
      END IF
   END IF


   RETURN
   END SUBROUTINE ReadR4Ary
!=======================================================================
   SUBROUTINE ReadR8Ary ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into a 8-byte real array separated by white space
      ! (possibly on the same line of the input file).


      ! Argument declarations:

   INTEGER,      INTENT(IN)          :: AryLen                                     ! Length of the array.
   INTEGER,      INTENT(IN)          :: UnIn                                       ! I/O unit for input file.
   INTEGER,      INTENT(IN),OPTIONAL :: UnEc                                       ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message


   REAL(R8Ki), INTENT(INOUT)         :: RealAry(AryLen)                            ! Real array being read.

   CHARACTER(*), INTENT(IN)          :: Fil                                        ! Name of the input file.
   CHARACTER(*), INTENT(IN)          :: AryDescr                                   ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)          :: AryName                                    ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the real array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   READ (UnIn,*,IOSTAT=IOS)  ( RealAry(Ind), Ind=1,AryLen )

   CALL CheckIOS ( IOS, Fil, TRIM( AryName ), NumType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) THEN
         WRITE( UnEc, Ec_ReAryFrmt ) TRIM( AryName ), AryDescr, RealAry(1:MIN(AryLen,NWTC_MaxAryLen))
      END IF
   END IF

   RETURN
   END SUBROUTINE ReadR8Ary
!=======================================================================
   SUBROUTINE ReadR16Ary ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into a 16-byte real array separated by white space
      ! (possibly on the same line of the input file).


      ! Argument declarations:

   INTEGER,      INTENT(IN)          :: AryLen                                     ! Length of the array.
   INTEGER,      INTENT(IN)          :: UnIn                                       ! I/O unit for input file.
   INTEGER,      INTENT(IN),OPTIONAL :: UnEc                                       ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER,      INTENT(OUT)         :: ErrStat                                    ! Error status
   CHARACTER(*), INTENT(OUT)         :: ErrMsg                                     ! Error message


   REAL(QuKi), INTENT(INOUT)         :: RealAry(AryLen)                            ! Real array being read.

   CHARACTER(*), INTENT(IN)          :: Fil                                        ! Name of the input file.
   CHARACTER(*), INTENT(IN)          :: AryDescr                                   ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)          :: AryName                                    ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the real array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   READ (UnIn,*,IOSTAT=IOS)  ( RealAry(Ind), Ind=1,AryLen )

   CALL CheckIOS ( IOS, Fil, TRIM( AryName ), NumType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) THEN
         WRITE( UnEc, Ec_ReAryFrmt ) TRIM( AryName ), AryDescr, RealAry(1:MIN(AryLen,NWTC_MaxAryLen))
      END IF
   END IF


   RETURN
   END SUBROUTINE ReadR16Ary
!=======================================================================
   SUBROUTINE ReadR4AryLines ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into a real array from the next AryLen lines of the input file.


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: AryLen                                          ! Length of the array.
   INTEGER, INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER, INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER, INTENT(OUT)         :: ErrStat                                         ! Error status
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                          ! Error message associated with ErrStat

   REAL(SiKi), INTENT(OUT)      :: RealAry(AryLen)                                 ! Real (4-byte) array being read.

   CHARACTER(*), INTENT(IN)     :: Fil                                             ! Name of the input file.
   CHARACTER(*), INTENT(IN)     :: AryDescr                                        ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)     :: AryName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the real array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   ErrStat = ErrID_None
   ErrMsg  = ""

   DO Ind=1,AryLen
      READ (UnIn,*,IOSTAT=IOS)  RealAry(Ind)

      CALL CheckIOS ( IOS, Fil, TRIM( AryName )//'('//TRIM( Num2LStr( Ind ) )//')', NumType, ErrStat, ErrMsg )

      IF (ErrStat >= AbortErrLev) RETURN

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 ) &
            WRITE (UnEc,Ec_ReFrmt)  RealAry(Ind), TRIM( AryName )//'('//TRIM( Int2LStr( Ind ) )//')', AryDescr
      END IF
   END DO

   RETURN
   END SUBROUTINE ReadR4AryLines
!=======================================================================
   SUBROUTINE ReadR8AryLines ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into a real array from the next AryLen lines of the input file.


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: AryLen                                          ! Length of the array.
   INTEGER, INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER, INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER, INTENT(OUT)         :: ErrStat                                         ! Error status
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                          ! Error message associated with ErrStat

   REAL(R8Ki), INTENT(OUT)      :: RealAry(AryLen)                                 ! Real (8-byte) array being read.

   CHARACTER(*), INTENT(IN)     :: Fil                                             ! Name of the input file.
   CHARACTER(*), INTENT(IN)     :: AryDescr                                        ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)     :: AryName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the real array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   ErrStat = ErrID_None
   ErrMsg  = ""
   
   DO Ind=1,AryLen
      READ (UnIn,*,IOSTAT=IOS)  RealAry(Ind)

      CALL CheckIOS ( IOS, Fil, TRIM( AryName )//'('//TRIM( Num2LStr( Ind ) )//')', NumType, ErrStat, ErrMsg )

      IF (ErrStat >= AbortErrLev) RETURN

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 ) &
             WRITE (UnEc,Ec_ReFrmt)  RealAry(Ind), TRIM( AryName )//'('//TRIM( Int2LStr( Ind ) )//')', AryDescr
      END IF
   END DO

   RETURN
   END SUBROUTINE ReadR8AryLines
!=======================================================================
   SUBROUTINE ReadR16AryLines ( UnIn, Fil, RealAry, AryLen, AryName, AryDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a AryLen values into a real array from the next AryLen lines of the input file.


      ! Argument declarations:

   INTEGER, INTENT(IN)          :: AryLen                                          ! Length of the array.
   INTEGER, INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER, INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER, INTENT(OUT)         :: ErrStat                                         ! Error status
   CHARACTER(*), INTENT(OUT)    :: ErrMsg                                          ! Error message associated with ErrStat

   REAL(QuKi), INTENT(OUT)      :: RealAry(AryLen)                                 ! Real (16-byte) array being read.

   CHARACTER(*), INTENT(IN)     :: Fil                                             ! Name of the input file.
   CHARACTER(*), INTENT(IN)     :: AryDescr                                        ! Text string describing the variable.
   CHARACTER(*), INTENT(IN)     :: AryName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                      :: Ind                                             ! Index into the real array.  Assumed to be one digit.
   INTEGER                      :: IOS                                             ! I/O status returned from the read statement.



   ErrStat = ErrID_None
   ErrMsg  = ""
   
   DO Ind=1,AryLen
      READ (UnIn,*,IOSTAT=IOS)  RealAry(Ind)

      CALL CheckIOS ( IOS, Fil, TRIM( AryName )//'('//TRIM( Num2LStr( Ind ) )//')', NumType, ErrStat, ErrMsg )

      IF (ErrStat >= AbortErrLev) RETURN

      IF ( PRESENT(UnEc) )  THEN
         IF ( UnEc > 0 ) &
                WRITE (UnEc,Ec_ReFrmt)  RealAry(Ind), TRIM( AryName )//'('//TRIM( Int2LStr( Ind ) )//')', AryDescr
      END IF
   END DO

   RETURN
   END SUBROUTINE ReadR16AryLines
!=======================================================================
   SUBROUTINE ReadR4Var ( UnIn, Fil, RealVar, VarName, VarDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a single double (real) variable from the next line of the input file.
      ! New code should call ReadVar instead of directly calling this routine.


      ! Argument declarations:

   REAL(SiKi),    INTENT(OUT)         :: RealVar                                         ! Real (4-byte) variable being read.
   INTEGER(IntKi),INTENT(OUT)         :: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),  INTENT(OUT)         :: ErrMsg                                          ! Error message

   INTEGER,       INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER,       INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc

   CHARACTER( *), INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER( *), INTENT(IN)          :: VarDescr                                        ! Text string describing the variable.
   CHARACTER( *), INTENT(IN)          :: VarName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                            :: IOS                                             ! I/O status returned from the read statement.
   CHARACTER(30)                      :: Word                                            ! String to hold the first word on the line.



   CALL ReadNum ( UnIn, Fil, Word, VarName, ErrStat, ErrMsg )
   IF ( ErrStat >= AbortErrLev) RETURN  ! If we're about to read a T/F and treat it as a number, we have a less severe ErrStat


   READ (Word,*,IOSTAT=IOS)  RealVar

   CALL CheckIOS ( IOS, Fil, VarName, NumType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN


   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_ReFrmt)  RealVar, VarName, VarDescr
   END IF

   RETURN
   END SUBROUTINE ReadR4Var
!=======================================================================
   SUBROUTINE ReadR8Var ( UnIn, Fil, RealVar, VarName, VarDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a single double (real) variable from the next line of the input file.
      ! New code should call ReadVar instead of directly calling this routine.


      ! Argument declarations:

   REAL(R8Ki),    INTENT(OUT)         :: RealVar                                         ! Real (8-byte) variable being read.
   INTEGER(IntKi),INTENT(OUT)         :: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),  INTENT(OUT)         :: ErrMsg                                          ! Error message

   INTEGER,       INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER,       INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc

   CHARACTER( *), INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER( *), INTENT(IN)          :: VarDescr                                        ! Text string describing the variable.
   CHARACTER( *), INTENT(IN)          :: VarName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                            :: IOS                                             ! I/O status returned from the read statement.

   CHARACTER(30)                      :: Word                                            ! String to hold the first word on the line.



   CALL ReadNum ( UnIn, Fil, Word, VarName, ErrStat, ErrMsg )
   IF ( ErrStat >= AbortErrLev) RETURN  ! If we're about to read a T/F and treat it as a number, we have a less severe ErrStat


   READ (Word,*,IOSTAT=IOS)  RealVar

   CALL CheckIOS ( IOS, Fil, VarName, NumType, ErrStat, ErrMsg )


   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_ReFrmt)  RealVar, VarName, VarDescr
   END IF


   RETURN
   END SUBROUTINE ReadR8Var
!=======================================================================
   SUBROUTINE ReadR16Var ( UnIn, Fil, RealVar, VarName, VarDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a single double (real) variable from the next line of the input file.
      ! New code should call ReadVar instead of directly calling this routine.


      ! Argument declarations:

   REAL(QuKi),    INTENT(OUT)         :: RealVar                                         ! Real (16-byte) variable being read.
   INTEGER(IntKi),INTENT(OUT),OPTIONAL:: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),  INTENT(OUT),OPTIONAL:: ErrMsg                                          ! Error message

   INTEGER,       INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER,       INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc

   CHARACTER( *), INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER( *), INTENT(IN)          :: VarDescr                                        ! Text string describing the variable.
   CHARACTER( *), INTENT(IN)          :: VarName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                            :: IOS                                             ! I/O status returned from the read statement.

   CHARACTER(30)                      :: Word                                            ! String to hold the first word on the line.




   CALL ReadNum ( UnIn, Fil, Word, VarName, ErrStat, ErrMsg )
   IF ( ErrStat >= AbortErrLev) RETURN  ! If we're about to read a T/F and treat it as a number, we have a less severe ErrStat


   READ (Word,*,IOSTAT=IOS)  RealVar

   CALL CheckIOS ( IOS, Fil, VarName, NumType, ErrStat, ErrMsg )


   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_ReFrmt)  RealVar, VarName, VarDescr
   END IF


   RETURN
   END SUBROUTINE ReadR16Var
!=======================================================================
   SUBROUTINE ReadStr ( UnIn, Fil, CharVar, VarName, VarDescr, ErrStat, ErrMsg, UnEc )


      ! This routine reads a string from the next line of the input file.


      ! Argument declarations:

   INTEGER,        INTENT(IN)          :: UnIn                                            ! I/O unit for input file.
   INTEGER,        INTENT(IN), OPTIONAL:: UnEc                                            ! I/O unit for echo file. If present and > 0, write to UnEc
   INTEGER(IntKi), INTENT(OUT)         :: ErrStat                                         ! Error status; if present, program does not abort on error
   CHARACTER(*),   INTENT(OUT)         :: ErrMsg                                          ! Error message

   CHARACTER(*),   INTENT(OUT)         :: CharVar                                         ! Integer variable being read.
   CHARACTER(*),   INTENT(IN)          :: Fil                                             ! Name of the input file.
   CHARACTER(*),   INTENT(IN)          :: VarDescr                                        ! Text string describing the variable.
   CHARACTER(*),   INTENT(IN)          :: VarName                                         ! Text string containing the variable name.


      ! Local declarations:

   INTEGER                             :: IOS                                             ! I/O status returned from the read statement.



   READ (UnIn,'(A)',IOSTAT=IOS)  CharVar

   CALL CheckIOS ( IOS, Fil, VarName, StrType, ErrStat, ErrMsg )

   IF (ErrStat >= AbortErrLev) RETURN

   IF ( PRESENT(UnEc) )  THEN
      IF ( UnEc > 0 ) &
         WRITE (UnEc,Ec_StrFrmt)  VarName, VarDescr, '"'//TRIM( CharVar )//'"'
   END IF



   RETURN
   END SUBROUTINE ReadStr
!=======================================================================   
   SUBROUTINE RemoveNullChar( Str )
   
      ! This routine removes trailing C_NULL characters, which can be present when
      ! passing strings between C and Fortran
      
      CHARACTER(*), INTENT(INOUT) :: Str
   
      INTEGER(IntKi)  :: I
   
         I = INDEX( Str, C_NULL_CHAR ) - 1 
         IF ( I > 0 ) Str = Str(1:I) 
   
   END SUBROUTINE RemoveNullChar   
!=============================================================================
   RECURSIVE SUBROUTINE ScanComFile ( FirstFile, ThisFile, LastFile, StartLine, LastLine, NumLines, ErrStat, ErrMsg )


         ! This routine opens and scans the contents of a file with comments counting non-comment lines.
         ! If a line has "@Filename" on a line, it recursively scans that file to add the non-comment lines
         ! to the total.
         ! This routine is typically called before ReadComFile() to count the number on non-comment lines
         ! that will need to be stored.
         ! It also adds to a linked list of unique file names that are in the call chain.


      IMPLICIT                                        NONE


         ! Argument declarations.

      INTEGER(IntKi), INTENT(OUT)                  :: ErrStat                 ! Error status.
      INTEGER(IntKi), INTENT(IN)                   :: LastLine                ! The last line to read from this file.  Includes blank and comment lines. Zero means read to the end of file.
      INTEGER(IntKi), INTENT(INOUT)                :: NumLines                ! The total number of non-comment lines scanned so far.
      INTEGER(IntKi), INTENT(IN)                   :: StartLine               ! The line at which to start processing this file.  Includes blank and comment lines.

      CHARACTER(*), INTENT(OUT)                    :: ErrMsg                  ! Error message.

      TYPE (FNlist_Type), POINTER, INTENT(IN)      :: FirstFile               ! The first file in the linked list.
      TYPE (FNlist_Type), POINTER, INTENT(INOUT)   :: LastFile                ! The last file in the linked list.
      TYPE (FNlist_Type), POINTER, INTENT(IN)      :: ThisFile                ! The last file in the linked list.


         ! Local declarations.

      INTEGER(IntKi)                               :: ErrStatLcl              ! Error status local to this routine and/or IOStatus.

      INTEGER                                      :: CurrLine                ! The current line in the file.
      INTEGER                                      :: RangeBeg                ! The first line in a range of lines to be included from a file.
      INTEGER                                      :: RangeEnd                ! The last line in a range of lines to be included from a file.
      INTEGER                                      :: LineLen                 ! The length of the line returned from ReadLine().
      INTEGER                                      :: UnIn                    ! The unit number used for the input file.

      LOGICAL                                      :: FileFound               ! A flag that is set to TRUE if this file has already been read.
      LOGICAL                                      :: IsOpen                  ! A flag that is set to TRUE if this file is already open.

! Should the comment characters be passed to this routine instead of being hard coded? -mlb
      CHARACTER(3), PARAMETER                      :: CommChars = '!#%'       ! Comment characters that mark the end of useful input.
      CHARACTER(1024)                              :: FileName                ! The name of this file being processed.
      CHARACTER(1024)                              :: IncFileName             ! The name of a file that this one includes.
      CHARACTER(512)                               :: Line                    ! The contents of a line returned from ReadLine() with comment removed.
      CHARACTER(ErrMsgLen)                         :: ErrMsg2
      CHARACTER(*),       PARAMETER                :: RoutineName = 'ScanComFile'

      TYPE (FNlist_Type), POINTER                  :: CurrFile                ! The current file being pointed to in the linked list.
      TYPE (FNlist_Type), POINTER                  :: NewFile                 ! The file being pointed to in the linked list is is to be included by ThisFile.


      ErrStat = ErrID_None
      ErrMsg  = ""

         ! Is this file already open from earlier in the recursion.  That would be bad.

      FileName = ThisFile%Filename
      INQUIRE ( FILE=Filename, OPENED=IsOpen )
      IF ( IsOpen )  THEN
         CALL SetErrStat( ErrID_Fatal, 'Fatal error scanning "'//TRIM( Filename ) &
                          //'". A file cannot directly or indirectly include itself.', ErrStat, ErrMsg, RoutineName )
         RETURN
      ENDIF


         ! Open the input file.
      UnIn = -1
      CALL GetNewUnit ( UnIn, ErrStatLcl, ErrMsg2 )

      CALL OpenFInpFile ( UnIn, Filename, ErrStatLcl, ErrMsg2 )
      IF ( ErrStatLcl /= 0 )  THEN
         CALL SetErrStat( ErrStatLcl, ErrMsg2, ErrStat, ErrMsg, RoutineName )
         CALL Cleanup()
         RETURN
      ENDIF ! ( ErrStatLcl /= 0 )


         ! Skip the beginning of the file, if requested.

      IF ( StartLine > 1 )  THEN
         DO CurrLine=1,StartLine-1
            READ(UnIn,'()', IOStat=ErrStatLcl)
            IF (ErrStatLcl /= 0) THEN
               CALL SetErrStat( ErrID_Fatal, "Error reading file beginning.", ErrStat, ErrMsg, RoutineName )
               CALL Cleanup()
               RETURN
            END IF            
         ENDDO ! CurrLine
      ENDIF ! ( StartLine > 1 )

      CurrLine = StartLine - 1


         ! Make sure LastLine >= FirstLine unless it is zero.

      IF ( LastLine > 0 )  THEN
         IF ( StartLine > LastLine )  THEN
            CALL SetErrStat( ErrID_Fatal, 'Fatal error: LastLine must be >= StartLine unless it is zero.', ErrStat, ErrMsg, RoutineName )
            CALL Cleanup()
            RETURN
         ENDIF ! ( StartLine > LastLine )
      ENDIF ! ( LastLine > 0 )


         ! Scan the file to learn the number of non-comment lines and total number of files, including included files.

      ErrStatLcl = 0

      DO WHILE ( ErrStatLcl == 0 )


            ! Stop processing when CurrLine > LastLine.  If LastLine is zero, read to the end of file.

         CurrLine = CurrLine + 1

         IF ( ( LastLine > 0 ) .AND. ( CurrLine > LastLine ) )  EXIT


            ! Process the next line.

         CALL ReadLine ( UnIn, CommChars, Line, LineLen, ErrStatLcl )  ! Reads a line.  Returns what is before the first comment character.

         IF ( ( ErrStatLcl == 0 )  .AND. ( LineLen > 0 ) )  THEN ! ErrStatLcl is IOStatus from read statement

            Line = ADJUSTL( Line )


               ! Is this line trying to include another file?

            IF ( Line(1:1) == '@' )  THEN


                  ! Parse the contents of everything after the "@" to determine the name of the include file and the optional line range.

               CALL ParseInclInfo ( Line(2:), IncFileName, RangeBeg, RangeEnd, ErrStatLcl, ErrMsg2 )
                  CALL SetErrStat( ErrStatLcl, TRIM( FileName )//':Line#'//TRIM( Num2LStr( CurrLine ) )//':'//TRIM(ErrMsg2), ErrStat, ErrMsg, RoutineName )
                  IF (ErrStat >= AbortErrLev) THEN
                     CALL Cleanup()
                     RETURN
                  END IF
                  ErrStatLcl = 0


                  ! Check to see if this file has been opened before.

               CurrFile => FirstFile
               FileFound = .FALSE.

               DO
                  IF ( .NOT. ASSOCIATED( CurrFile ) )  EXIT
                  IF ( TRIM( IncFileName ) == TRIM( CurrFile%FileName ) )  THEN
                     FileFound = .TRUE.
                     NewFile => CurrFile
                     EXIT
                  ENDIF
                  CurrFile => CurrFile%Next
               ENDDO


                  ! We have not seen this file before.  Add it to the list.

               IF ( .NOT. FileFound )  THEN
                  ALLOCATE ( LastFile%Next )
                  LastFile => LastFile%Next
                  NULLIFY ( LastFile%Next )
                  LastFile%FileName = TRIM( IncFileName )
                  NewFile => LastFile
               ENDIF ! ( .NOT. FileFound )

               CALL ScanComFile ( FirstFile, NewFile, LastFile, RangeBeg, RangeEnd, NumLines, ErrStatLcl, ErrMsg2 )
                  CALL SetErrStat( ErrStatLcl, TRIM( FileName )//':Line#'//TRIM( Num2LStr( CurrLine ) )//':'//TRIM(ErrMsg2), ErrStat, ErrMsg, RoutineName )
                  IF (ErrStat >= AbortErrLev) THEN
                     CALL Cleanup()
                     RETURN
                  END IF
                  ErrStatLcl = 0

            ELSE

               NumLines = NumLines + 1

            ENDIF ! ( Line(1:1) == '@' )

         ENDIF ! IF ( ( ErrStatLcl == 0 )  .AND. ( LineLen > 0 ) )

      ENDDO ! WHILE ( ErrStatLcl == 0 )

      CALL Cleanup()


      RETURN

!=======================================================================
   CONTAINS
   !=======================================================================
      SUBROUTINE Cleanup ( )

         ! This subroutine cleans up the parent routine before exiting.

            ! Local declarations.

         LOGICAL                          :: IsOpen                           ! A flage that indicates if the input unit is still open.


            ! Close the file if it it open..

         INQUIRE ( UnIn, OPENED=IsOpen )
         IF ( IsOpen )  CLOSE ( UnIn )

         RETURN

      END SUBROUTINE Cleanup

   END SUBROUTINE ScanComFile
!=======================================================================
   SUBROUTINE Str2IntAry( Str, IntAry, ErrStat, ErrMsg )
   
      ! This routine converts a string (character array) into an 
      ! equivalent ASCII array of integers.
      ! This routine is the inverse of the IntAry2Str() routine.

         ! Argument declarations:
      CHARACTER(*),   INTENT(IN)    :: Str                                          ! The string to convert
      INTEGER(IntKi),  INTENT(OUT)  :: IntAry(:)                                    ! ASCII representation of Str

      INTEGER(IntKi), INTENT(OUT)   :: ErrStat                                      ! Error status
      CHARACTER(*),   INTENT(OUT)   :: ErrMsg                                       ! Error message associated with ErrStat

         ! Argument declarations:
      INTEGER(IntKi)                :: I                                            ! generic loop counter
      INTEGER(IntKi)                :: LStr                                         ! length of the string
      INTEGER(IntKi)                :: LAry                                         ! length of the integer array


         ! Get the size of the arrays:
      LStr = LEN(Str)
      LAry = SIZE(IntAry)


         ! Determine if the string will fit in the integer array:
      IF ( LStr > LAry ) THEN
         ErrStat = ErrID_Warn
         ErrMsg  = 'Char2Int:String exceeds array size.'
         LStr    = LAry  ! we'll only convert the string values up to the array length
      ELSE
         ErrStat = ErrID_None
         ErrMsg  = ''
      END IF


         ! Convert the string to an ASCII array:
      DO I=1,LStr
         IntAry(I) = ICHAR(Str(I:I), IntKi)
      END DO

   END SUBROUTINE Str2IntAry   
!=======================================================================
   SUBROUTINE WaitTime ( WaitSecs )


      ! This routine pauses program executaion for a specified
      ! number of seconds.


   IMPLICIT NONE


      ! Argument declarations:

   REAL(ReKi), INTENT(IN)       :: WaitSecs                                        ! The number of seconds to wait.


      ! Local declarations:

   REAL(ReKi)                   :: EndCounts                                       ! The number of counts when wait time is over.

   INTEGER                      :: Counts                                          ! Current number of counts on the system clock.
   INTEGER                      :: CountMax                                        ! Maximum number of counts possible on the system clock.
   INTEGER                      :: CountRate                                       ! Number of counts per second on the system clock.



   CALL SYSTEM_CLOCK ( Counts, CountRate, CountMax )
   EndCounts = Counts + INT( WaitSecs*CountRate )

   DO
      CALL SYSTEM_CLOCK ( Counts, CountRate, CountMax )
      IF ( Counts > EndCounts )  EXIT
   END DO


   RETURN
   END SUBROUTINE WaitTime
!=======================================================================
   SUBROUTINE WrBinFAST(FileName, FileID, DescStr, ChanName, ChanUnit, TimeData, AllOutData, ErrStat, ErrMsg)

   ! This subroutine opens a binary file named FileName, and writes a the AllOutData Matrix to a 16-bit packed 
   ! binary file. A text DescStr is written to the file as well as the text in the ChanName and ChanUnit arrays.
   !  The file is closed at the end of this subroutine call (and on error).
   ! NOTE: Developers may wish to inquire if the file can be opened at the start of a simulation to ensure that 
   !       it's available before running the simulation (i.e., don't run a code for a long time only to find out 
   !       that the file cannot be opened for writing).


   IMPLICIT                     NONE

   INTEGER(IntKi), PARAMETER     :: LenName     = ChanLen            ! Number of characters allowed in a channel name
   INTEGER(IntKi), PARAMETER     :: LenUnit     = ChanLen            ! Number of characters allowed in a channel unit

      ! Passed data (sorted by element size, then alphabetical)

   REAL(DbKi),        INTENT(IN) :: TimeData(:)                      ! The time being output to the file (if using FileFmtID_WithoutTime: element 1 is the first output time, element 2 is the delta t)
   REAL(ReKi),        INTENT(IN) :: AllOutData(:,:)                  ! All of the data being written to the file (except time; note that the channels are the rows and time is the column--this is done for speed of saving the array)
   INTEGER(IntKi),    INTENT(OUT):: ErrStat                          ! Indicates whether an error occurred (see NWTC_Library)
   INTEGER(B2Ki),     INTENT(IN) :: FileID                           ! File ID, used to determine format of output file (use FileFmtID_WithTime or FileFmtID_WithoutTime)

   CHARACTER(LenName),INTENT(IN) :: ChanName(:)                      ! The output channel names (including Time)
   CHARACTER(LenUnit),INTENT(IN) :: ChanUnit(:)                      ! The output channel units (including Time)
   CHARACTER(*),      INTENT(IN) :: DescStr                          ! Description to write to the binary file (e.g., program version, date, & time)
   CHARACTER(*),      INTENT(OUT):: ErrMsg                           ! Error message associated with the ErrStat
   CHARACTER(*),      INTENT(IN) :: FileName                         ! Name of the file to write the output in


         ! Parameters required for scaling Real data to 16-bit integers

   REAL(R8Ki), PARAMETER         :: Int32Max =  65535.0              ! Largest integer represented in 4 bytes
   REAL(R8Ki), PARAMETER         :: Int32Min = -65536.0              ! Smallest integer represented in 4 bytes
   REAL(R8Ki), PARAMETER         :: Int32Rng = Int32Max - Int32Min   ! Max Range of 4-byte integer

   REAL(SiKi), PARAMETER         :: IntMax   =  32767.0              ! Largest integer represented in 2 bytes
   REAL(SiKi), PARAMETER         :: IntMin   = -32768.0              ! Smallest integer represented in 2 bytes
   REAL(SiKi), PARAMETER         :: IntRng   = IntMax - IntMin       ! Max Range of 2 byte integer


         ! Local variables

   REAL(DbKi)                    :: TimeMax                          ! Maximum value of the time data
   REAL(DbKi)                    :: TimeMin                          ! Minimum value of the time data
   REAL(R8Ki)                    :: TimeOff                          ! Offset for the time data
   REAL(R8Ki)                    :: TimeScl                          ! Slope for the time data
   REAL(R8Ki)                    :: TimeOut1                         ! The first output time
   REAL(R8Ki)                    :: TimeIncrement                    ! The delta t

   REAL(ReKi), ALLOCATABLE       :: ColMax(:)                        ! Maximum value of the column data
   REAL(ReKi), ALLOCATABLE       :: ColMin(:)                        ! Minimum value of the column data
   REAL(SiKi), ALLOCATABLE       :: ColOff(:)                        ! Offset for the column data
   REAL(SiKi), ALLOCATABLE       :: ColScl(:)                        ! Slope for the column data


   INTEGER(IntKi)                :: ErrStat2                         ! temporary error status
   INTEGER(IntKi)                :: I                                ! Generic loop counter
   INTEGER(IntKi)                :: IC                               ! Loop counter for the output channel
   INTEGER(IntKi)                :: IT                               ! Loop counter for the timestep
   INTEGER(IntKi)                :: J                                ! Generic counter
   INTEGER(IntKi)                :: LenDesc                          ! Length of the description string, DescStr
   INTEGER(IntKi)                :: NT                               ! Number of time steps
   INTEGER(IntKi)                :: NumOutChans                      ! Number of output channels
   INTEGER(IntKi)                :: UnIn                             ! Unit number for the binary file

   INTEGER(B2Ki), ALLOCATABLE    :: TmpOutArray(:)                   ! This array holds the normalized output channels before being written to the binary file
   INTEGER(B4Ki), ALLOCATABLE    :: TmpTimeArray(:)                  ! This array holds the normalized output time channel before being written to the binary file
   INTEGER(B1Ki), ALLOCATABLE    :: DescStrASCII(:)                  ! The ASCII equivalent of DescStr
   INTEGER(B1Ki), ALLOCATABLE    :: ChanNameASCII(:)                 ! The ASCII equivalent of ChanName
   INTEGER(B1Ki), ALLOCATABLE    :: ChanUnitASCII(:)                 ! The ASCII equivalent of ChanUnit

   CHARACTER(ErrMsgLen)          :: ErrMsg2                          ! temporary error message
   CHARACTER(*), PARAMETER       :: RoutineName = 'WrBinFAST'

   !...............................................................................................................................
   ! Initialize some values
   !...............................................................................................................................

   ErrStat     = ErrID_None             ! No error has yet occurred
   ErrMsg      = ''                     ! No error has yet occurred
   NumOutChans = SIZE(AllOutData,1)     ! The number of output channels
   NT          = SIZE(AllOutData,2)     ! The number of time steps to be written
   LenDesc     = LEN_TRIM( DescStr )    ! Length of the string that contains program name, version, date, and time

      ! Generate the unit number for the binary file
   UnIn = 0
   CALL GetNewUnit( UnIn, ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   !...............................................................................................................................
   ! Open the binary file for output
   !...............................................................................................................................

   CALL OpenBOutFile ( UnIn, TRIM(FileName), ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF ( ErrStat >= AbortErrLev ) THEN
         CALL Cleanup()
         RETURN
      END IF
      

   !...............................................................................................................................
   ! Allocate arrays
   !...............................................................................................................................

   CALL AllocAry( ColMax, NumOutChans, 'column maxima (ColMax)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL AllocAry( ColMin, NumOutChans, 'column minima (ColMin)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL AllocAry( ColOff, NumOutChans, 'column offsets (ColOff)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL AllocAry( ColScl, NumOutChans, 'column scales (ColScl)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL AllocAry( TmpOutArray, NumOutChans*NT, 'temporary output array (TmpOutArray)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL AllocAry( ChanNameASCII, (1+NumOutChans)*LenName , 'temporary channel name array (ChanNameASCII)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL AllocAry( ChanUnitASCII, (1+NumOutChans)*LenUnit, 'temporary channel unit names (ChanUnitASCII)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL AllocAry( DescStrASCII, LenDesc, 'temporary file description (DescStrASCII)', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   IF ( FileID == FileFmtID_WithTime ) THEN
      CALL AllocAry( TmpTimeArray, NT, 'temporary output time array (TmpTimeArray)', ErrStat2, ErrMsg2 )
         CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   END IF

   IF ( ErrStat >= AbortErrLev ) THEN
      CALL Cleanup( )
      RETURN
   END IF
      

   !...............................................................................................................................
   ! Convert character strings to ASCII
   !...............................................................................................................................

      ! Description string (DescStr)

   DO I=1,LenDesc
      DescStrASCII(I) = IACHAR( DescStr(I:I) )
   END DO

      ! Channel names (ChanName)
   J = 1
   DO IC = 1,SIZE(ChanName)
      DO I=1,LenName
         ChanNameASCII(J) = IACHAR( ChanName(IC)(I:I) )
         J = J + 1
      END DO
   END DO

      ! Channel units (ChanUnit)
   J = 1
   DO IC = 1,SIZE(ChanUnit)
      DO I=1,LenUnit
         ChanUnitASCII(J) = IACHAR( ChanUnit(IC)(I:I) )
         J = J + 1
      END DO
   END DO

   !...............................................................................................................................
   ! Find the range of our output channels
   !...............................................................................................................................
!BJJ: This scaling has issues if the channel contains NaN.


   ColMin(:) = AllOutData(:,1_IntKi)         ! Initialize the Min values for each channel
   ColMax(:) = AllOutData(:,1_IntKi)         ! Initialize the Max values for each channel

   DO IT=2,NT                                ! Loop through the remaining time steps

      DO IC=1,NumOutChans                    ! Loop through the output channels

         IF ( AllOutData(IC,IT) > ColMax(IC) ) THEN
            ColMax(IC) = AllOutData(IC,IT)
         ELSEIF ( AllOutData(IC,IT) < ColMin(IC) ) THEN
            ColMin(IC) = AllOutData(IC,IT)
         ENDIF

      ENDDO !IC

   ENDDO !IT


   IF ( FileID == FileFmtID_WithTime ) THEN
      TimeMin   = TimeData(1)                   ! Initialize the Min time value
      TimeMax   = MAX(TimeData(1),TimeData(NT)) ! Initialize the Max time value

      DO IT=2,NT                                ! Loop through the remaining time steps
         IF ( TimeData(IT) > TimeMax ) THEN
            TimeMax = TimeData(IT)
         ELSEIF ( TimeData(IT) < TimeMin ) THEN
            TimeMin = TimeData(IT)
         ENDIF
      ENDDO !IT

   ELSE ! FileFmtID_WithoutTime
         ! Convert DbKi to R8Ki, if necessary
      TimeOut1      = TimeData(1)                ! The first output time
      TimeIncrement = TimeData(2)                ! The time increment
   END IF ! FileID

   !...............................................................................................................................
   ! Calculate the scaling parameters for each channel
   !...............................................................................................................................
   DO IC=1,NumOutChans                    ! Loop through the output channels

      IF ( ColMax(IC) == ColMin(IC) ) THEN
         ColScl(IC) = 1
      ELSE
         ColScl(IC) = IntRng/REAL( ColMax(IC) - ColMin(IC), SiKi )
      ENDIF

      ColOff(IC) = IntMin - ColScl(IC)*REAL( ColMin(IC), SiKi )

   ENDDO !IC


   IF ( FileID == FileFmtID_WithTime ) THEN
      IF ( TimeMax == TimeMin ) THEN
         TimeScl = 1
      ELSE
         TimeScl = Int32Rng/REAL( TimeMax - TimeMin, R8Ki )
      ENDIF

      TimeOff = Int32Min - TimeScl*REAL( TimeMin, R8Ki )

   END IF ! FileID

   !...............................................................................................................................
   ! Convert channels to 16-bit integers (packed binary)
   !...............................................................................................................................
   J = 1
   DO IT=1,NT                                ! Loop through the time steps
      DO IC=1,NumOutChans                    ! Loop through the output channels

         TmpOutArray(J) =  NINT( Max( Min( REAL( ColScl(IC)*AllOutData(IC,IT) + ColOff(IC), SiKi), IntMax ), IntMin) , B2Ki )
         J = J + 1

      ENDDO !IC

   ENDDO !IT


   IF ( FileID == FileFmtID_WithTime ) THEN  ! Pack the time into 32-bit integers
      DO IT=1,NT                             ! Loop through the time steps
         TmpTimeArray(IT) = NINT( Max( Min( REAL( TimeScl*TimeData(IT) + TimeOff, R8Ki), Int32Max ), Int32Min) , B4Ki )
      ENDDO !IT
   END IF ! FileID

   !...............................................................................................................................
   ! Write the output file header
   !...............................................................................................................................

   WRITE (UnIn, IOSTAT=ErrStat2)   INT( FileID             , B2Ki )            ! FAST output file format
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing FileID to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF

   WRITE (UnIn, IOSTAT=ErrStat2)   INT( NumOutChans        , B4Ki )            ! The number of output channels
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing NumOutChans to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF


   WRITE (UnIn, IOSTAT=ErrStat2)   INT( NT                 , B4Ki )            ! The number of time steps
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing NT to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF


   IF ( FileID == FileFmtID_WithTime ) THEN
         ! Write the slope and offset for the time channel

      WRITE (UnIn, IOSTAT=ErrStat2)  TimeScl                                  ! The time slope for scaling
         IF ( ErrStat2 /= 0 ) THEN
            CALL SetErrStat( ErrID_Fatal, 'Error writing TimeScl to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
            CALL Cleanup( )
            RETURN
         END IF

      WRITE (UnIn, IOSTAT=ErrStat2)  TimeOff                                  ! The time offset for scaling
         IF ( ErrStat2 /= 0 ) THEN
            CALL SetErrStat( ErrID_Fatal, 'Error writing TimeOff to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
            CALL Cleanup( )
            RETURN
         END IF

   ELSE ! FileFmtID_WithoutTime
         ! Write the first output time and the time step

      WRITE (UnIn, IOSTAT=ErrStat2)  TimeOut1                                  ! The first output time
         IF ( ErrStat2 /= 0 ) THEN
            CALL SetErrStat( ErrID_Fatal, 'Error writing TimeOut1 to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
            CALL Cleanup( )
            RETURN
         END IF

      WRITE (UnIn, IOSTAT=ErrStat2)  TimeIncrement                             ! The time increment (between subsequent outputs)
         IF ( ErrStat2 /= 0 ) THEN
            CALL SetErrStat( ErrID_Fatal, 'Error writing TimeIncrement to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
            CALL Cleanup( )
            RETURN
         END IF

   END IF

   WRITE (UnIn, IOSTAT=ErrStat2)  ColScl(:)                                    ! The channel slopes for scaling
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing ColScl to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF

   WRITE (UnIn, IOSTAT=ErrStat2)  ColOff(:)                                    ! The channel offsets for scaling
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing ColOff to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF

   WRITE (UnIn, IOSTAT=ErrStat2)   INT( LenDesc            , B4Ki )            ! The number of characters in the string
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing LenDesc to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF

   WRITE (UnIn, IOSTAT=ErrStat2)  DescStrASCII                                 ! DescStr converted to ASCII
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing file description to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF

   WRITE (UnIn, IOSTAT=ErrStat2)  ChanNameASCII                                 ! ChanName converted to ASCII
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing channel names to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF


   WRITE (UnIn, IOSTAT=ErrStat2)  ChanUnitASCII                                 ! ChanUnit converted to ASCII
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing channel units to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF

   !...............................................................................................................................
   ! Write the channel data
   !...............................................................................................................................
   IF ( FileID == FileFmtID_WithTime ) THEN
      WRITE (UnIn, IOSTAT=ErrStat2)  TmpTimeArray                               ! TimeData converted to packed binary (32-bit)
         IF ( ErrStat2 /= 0 ) THEN
            CALL SetErrStat( ErrID_Fatal, 'Error writing time data to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
            CALL Cleanup( )
            RETURN
         END IF
   END IF ! FileID


   WRITE (UnIn, IOSTAT=ErrStat2)  TmpOutArray                                  ! AllOutData converted to packed binary (16-bit)
      IF ( ErrStat2 /= 0 ) THEN
         CALL SetErrStat( ErrID_Fatal, 'Error writing channel data to the FAST binary file.', ErrStat, ErrMsg, RoutineName )
         CALL Cleanup( )
         RETURN
      END IF

   !...............................................................................................................................
   ! We're finished: clean up ALLOCATABLE arrays and close the file
   !...............................................................................................................................

   CALL Cleanup()
   RETURN

!..................................................................................................................................
   CONTAINS
      !............................................................................................................................
      SUBROUTINE Cleanup()
      ! This subroutine cleans up all the allocatable arrays and closes the binary file.
      !............................................................................................................................
      
            ! Deallocate local arrays:
         IF ( ALLOCATED( ColMax        ) ) DEALLOCATE( ColMax )
         IF ( ALLOCATED( ColMin        ) ) DEALLOCATE( ColMin )
         IF ( ALLOCATED( ColOff        ) ) DEALLOCATE( ColOff )
         IF ( ALLOCATED( ColScl        ) ) DEALLOCATE( ColScl )
         IF ( ALLOCATED( TmpTimeArray  ) ) DEALLOCATE( TmpTimeArray )
         IF ( ALLOCATED( TmpOutArray   ) ) DEALLOCATE( TmpOutArray )
         IF ( ALLOCATED( DescStrASCII  ) ) DEALLOCATE( DescStrASCII )
         IF ( ALLOCATED( ChanNameASCII ) ) DEALLOCATE( ChanNameASCII )
         IF ( ALLOCATED( ChanUnitASCII ) ) DEALLOCATE( ChanUnitASCII )
      
            ! Close file:
         CLOSE ( UnIn )
      
      END SUBROUTINE Cleanup
   !...............................................................................................................................
   END SUBROUTINE WrBinFAST
!==================================================================================================================================
   SUBROUTINE WrFileNR ( Unit, Str )


      ! This routine writes out a string to the file connected to Unit without following it with a new line.


      ! Argument declarations.

   INTEGER, INTENT(IN)          :: Unit                                         ! I/O unit for input file.

   CHARACTER(*), INTENT(IN)     :: Str                                          ! String to be written without a newline at the end.



   WRITE (Unit,'(A)',ADVANCE='NO')  Str


   RETURN
   END SUBROUTINE WrFileNR
!=======================================================================
   SUBROUTINE WrMatrix1R4( A, Un, ReFmt, MatName )
   
      ! This routine writes all the values of a 1-dimensional matrix, A, 
      ! of 4-byte real numbers to unit Un, using ReFmt for each individual value
      ! in the array. If MatName is present, it also preceeds the matrix
      ! with "MatName" and the number of rows (length of A) and columns (1).
      ! Useful for debugging and/or writing summary files.
      
      REAL(SiKi),             INTENT(IN) :: A(:)
      INTEGER,           INTENT(IN) :: Un
      CHARACTER(*),           INTENT(IN) :: ReFmt     ! Format for printing ReKi numbers  
      CHARACTER(*), OPTIONAL, INTENT(IN) :: MatName

      INTEGER        :: ErrStat
      INTEGER        :: nr  ! size (rows and columns) of A
      CHARACTER(256) :: Fmt


      nr = SIZE(A,1)

      IF ( PRESENT(MatName) ) THEN
         WRITE( Un, '(A,": ",A," x ",A)', IOSTAT=ErrStat ) TRIM(MatName), TRIM(Num2LStr(nr)), "1"
      END IF      
      
      Fmt = "(2x, "//TRIM(Num2LStr(nr))//"(1x,"//ReFmt//"))"

      WRITE( Un, Fmt, IOSTAT=ErrStat ) A(:)
      IF (ErrStat /= 0) THEN
         CALL WrScr('Error '//TRIM(Num2LStr(ErrStat))//' writing matrix in WrMatrix1R4().')
         RETURN
      END IF

   RETURN
   END SUBROUTINE WrMatrix1R4
!=======================================================================
   SUBROUTINE WrMatrix1R8( A, Un, ReFmt, MatName )
   
      ! This routine writes all the values of a 1-dimensional matrix, A, 
      ! of 8-byte real numbers to unit Un, using ReFmt for each individual value
      ! in the array. If MatName is present, it also preceeds the matrix
      ! with "MatName" and the number of rows (length of A) and columns (1).
      ! Useful for debugging and/or writing summary files.
   
      REAL(R8Ki),             INTENT(IN) :: A(:)
      INTEGER,        INTENT(IN) :: Un
      CHARACTER(*),   INTENT(IN) :: ReFmt   ! Format for printing ReKi numbers
      CHARACTER(*), OPTIONAL, INTENT(IN) :: MatName

      INTEGER        :: ErrStat
      INTEGER                            :: nr  ! size (rows and columns) of A
      CHARACTER(256)                     :: Fmt
   
   
      nr = SIZE(A,1)

      IF ( PRESENT(MatName) ) THEN
         WRITE( Un, '(A,": ",A," x ",A)', IOSTAT=ErrStat ) TRIM(MatName), TRIM(Num2LStr(nr)), "1"
      END IF
      
      Fmt = "(2x, "//TRIM(Num2LStr(nr))//"(1x,"//ReFmt//"))"   
   
      WRITE( Un, Fmt, IOSTAT=ErrStat ) A(:)
      IF (ErrStat /= 0) THEN
         CALL WrScr('Error '//TRIM(Num2LStr(ErrStat))//' writing matrix in WrMatrix1R8().')
         RETURN
      END IF

   RETURN
   END SUBROUTINE WrMatrix1R8
!=======================================================================
   SUBROUTINE WrMatrix2R4( A, Un, ReFmt, MatName )
   
      ! This routine writes all the values of a 2-dimensional matrix, A, 
      ! of 4-byte real numbers to unit Un, using ReFmt for each individual value
      ! in the array. If MatName is present, it also preceeds the matrix
      ! with "MatName" and the number of rows and columns in A.
      ! Useful for debugging and/or writing summary files.
   
      REAL(SiKi),             INTENT(IN) :: A(:,:)
      INTEGER,                INTENT(IN) :: Un
      CHARACTER(*),           INTENT(IN) :: ReFmt   ! Format for printing ReKi numbers  
      CHARACTER(*), OPTIONAL, INTENT(IN) :: MatName

      INTEGER                            :: ErrStat
      INTEGER        :: nr, nc  ! size (rows and columns) of A
      INTEGER        :: i       ! indices into A
      CHARACTER(256) :: Fmt


      nr = SIZE(A,1)
      nc = SIZE(A,2)

      IF ( PRESENT(MatName) ) THEN
         WRITE( Un, '(A,": ",A," x ",A)', IOSTAT=ErrStat ) TRIM(MatName), TRIM(Num2LStr(nr)), TRIM(Num2LStr(nc))
      END IF
      
      Fmt = "(2x, "//TRIM(Num2LStr(nc))//"(1x,"//ReFmt//"))"

      DO i=1,nr
         WRITE( Un, Fmt, IOSTAT=ErrStat ) A(i,:)
         IF (ErrStat /= 0) THEN
            CALL WrScr('Error '//TRIM(Num2LStr(ErrStat))//' writing matrix in WrMatrix2R4().')
            RETURN
         END IF


      END DO

   RETURN
   END SUBROUTINE WrMatrix2R4
!=======================================================================
   SUBROUTINE WrMatrix2R8( A, Un, ReFmt, MatName )
   
      ! This routine writes all the values of a 2-dimensional matrix, A, 
      ! of 8-byte real numbers to unit Un, using ReFmt for each individual value
      ! in the array. If MatName is present, it also preceeds the matrix
      ! with "MatName" and the number of rows and columns in A.
      ! Useful for debugging and/or writing summary files.
   
      REAL(R8Ki),             INTENT(IN) :: A(:,:)
      INTEGER,                INTENT(IN) :: Un
      CHARACTER(*),           INTENT(IN) :: ReFmt   ! Format for printing ReKi numbers  
      CHARACTER(*), OPTIONAL, INTENT(IN) :: MatName

      INTEGER                            :: ErrStat
      INTEGER                            :: nr, nc  ! size (rows and columns) of A
      INTEGER                            :: i       ! indices into A
      CHARACTER(256)                     :: Fmt
   
   
      nr = SIZE(A,1)
      nc = SIZE(A,2)

      IF ( PRESENT(MatName) ) THEN
         WRITE( Un, '(A,": ",A," x ",A)', IOSTAT=ErrStat ) TRIM(MatName), TRIM(Num2LStr(nr)), TRIM(Num2LStr(nc))
      END IF
      
      Fmt = "(2x, "//TRIM(Num2LStr(nc))//"(1x,"//ReFmt//"))"   

      DO i=1,nr
         WRITE( Un, Fmt, IOSTAT=ErrStat ) A(i,:)
         IF (ErrStat /= 0) THEN
            CALL WrScr('Error '//TRIM(Num2LStr(ErrStat))//' writing matrix in WrMatrix2R8().')
            RETURN
         END IF
         
         
      END DO

   RETURN
   END SUBROUTINE WrMatrix2R8
!=======================================================================  
   SUBROUTINE WrML ( Str )


      ! This routine writes out a string in the middle of a line.


      ! Argument declarations.

   CHARACTER(*)                 :: Str



   CALL WrNR ( Str )


   RETURN
   END SUBROUTINE WrML
!=======================================================================
   SUBROUTINE WrPr ( Str )


      ! This routine writes out a prompt to the screen without
      ! following it with a new line, though a new line precedes it.


      ! Argument declarations:

   CHARACTER(*), INTENT(IN)     :: Str                                          ! The prompt string to print.



   CALL WrScr ( ' ' )
   CALL WrNR  ( TRIM( Str )//' > ' )


   RETURN
   END SUBROUTINE WrPr
!=======================================================================
   SUBROUTINE WrReAryFileNR ( Unit, Ary, Fmt, ErrStat, ErrMsg  )


      ! This routine writes out a real array to the file connected to Unit without following it with a new line.


      ! Argument declarations.

   INTEGER,      INTENT(IN)     :: Unit                                         ! I/O unit for input file.
   REAL(ReKi),   INTENT(IN)     :: Ary (:)                                      ! Array to be written without a newline at the end.
   CHARACTER(*), INTENT(IN)     :: Fmt                                          ! Fmt of one element to be written.

   INTEGER(IntKi), INTENT(OUT)  :: ErrStat                                      ! Error status
   CHARACTER(*),   INTENT(OUT)  :: ErrMsg                                       ! Error message associated with ErrStat

      ! Local variables:
   CHARACTER(50)                :: Fmt2                                         ! Fmt of entire array to be written (will be copied).



   IF ( SIZE(Ary) == 0 ) THEN
      ErrStat = ErrID_None
      ErrMsg  = ''
      RETURN
   END IF
   

   WRITE(Fmt2,*) SIZE(Ary)
   Fmt2 = '('//TRIM(Fmt2)//'('//TRIM(Fmt)//'))'

   WRITE (Unit,Fmt2,ADVANCE='NO',IOSTAT=ErrStat)  Ary
   IF ( ErrStat /= 0 ) THEN
      ErrStat = ErrID_Fatal
      ErrMsg = 'WrReAryFileNR:Error '//TRIM(Num2LStr(ErrStat))//' occurred while writing to file using this format: '//TRIM(Fmt2)
   ELSE
      ErrStat = ErrID_None
      ErrMsg  = ''
   END IF


   RETURN
   END SUBROUTINE WrReAryFileNR
!=======================================================================
   RECURSIVE SUBROUTINE WrScr ( InStr )


      ! This routine writes out a string to the screen.


   IMPLICIT                        NONE


      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: InStr                                        ! The input string to write to the screen.


      ! Local declarations.

   INTEGER                      :: Beg                                          ! The beginning of the next line of text.
   INTEGER                      :: Indent                                       ! The amunt to be indented.
   INTEGER                      :: LStr                                         ! The length of the remaining portion of the string.
   INTEGER                      :: MaxLen                                       ! Maximum number of columns to be written to the screen.
   INTEGER                      :: NewLineIndx                                  ! The string index where the NewLine character occurs

   CHARACTER(10)                :: Frm                                          ! Format specifier for the output.
   CHARACTER(LEN(InStr))        :: Str                                          ! The next string to be processed



   Str = InStr

         ! Check if we are writing multiple lines:

   NewLineIndx = INDEX( Str, NewLine, BACK=.TRUE. )
   IF ( NewLineIndx > 0  ) THEN     ! The user requested a new line
      IF ( NewLineIndx == 1 ) THEN  ! The first character is a new line, so write a blank line
         CALL WrScr( '' )
      ELSE
         CALL WrScr( Str(:NewLineIndx-1) ) ! Write everything up to the new line (recursively)
      END IF
      Str = Str( (NewLineIndx + LEN(NewLine)): ) ! Remove the part we already wrote to the screen (also remove the NewLine character)
   END IF


      ! Find the amount of indent.  Create format.

   MaxLen = MaxWrScrLen
   Indent = LEN_TRIM( Str ) - LEN_TRIM( ADJUSTL( Str ) )
   Indent = MIN( Indent, MaxLen-2 )                                              ! at least 2 characters per line
   MaxLen = MaxLen - Indent
   IF ( Indent > 0 )  THEN
      Frm    = '(1X,  X,A)'
      WRITE (Frm(5:6),'(I2)')  Indent
   ELSE
      Frm    = '(1X,A)'
   END IF


   !  Break long messages into multiple lines.

   Beg  = Indent + 1
   LStr = LEN_TRIM( Str(Beg:) )



   DO WHILE ( Lstr > MaxLen )

      CALL FindLine ( Str(Beg:) , MaxLen , LStr )

      CALL WriteScr( TRIM( ADJUSTL( Str(Beg:Beg+LStr-1) ) ), Frm )

      Beg = Beg + LStr


         ! If we have a space at the beginning of the string, let's get rid of it

      DO WHILE ( Beg < LEN_TRIM( Str ) .AND. Str(Beg:Beg) == ' ' )
         Beg = Beg + 1
      ENDDO

      LStr = LEN_TRIM( Str(Beg:) )

   ENDDO

   CALL WriteScr( TRIM( ADJUSTL( Str(Beg:Beg+LStr-1) ) ), Frm )


   RETURN
   END SUBROUTINE WrScr
!=======================================================================
   SUBROUTINE WrScr1 ( Str )


      ! This routine writes out a string to the screen after a blank line.
      ! This routine is DEPRECATED. Call WrScr directly instead.


      ! Argument declarations.

   CHARACTER(*)                 :: Str                                         ! The string to print.



   !CALL WrScr ( ' ' )
   !CALL WrScr ( TRIM( Str ) )

   CALL WrScr( NewLine//TRIM( Str ) )


   RETURN
   END SUBROUTINE WrScr1
!=======================================================================

END MODULE NWTC_IO
