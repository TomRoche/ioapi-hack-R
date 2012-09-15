
C***********************************************************************
C   Portions of Models-3/CMAQ software were developed or based on      *
C   information from various groups: Federal Government employees,     *
C   contractors working on a United States Government contract, and    *
C   non-Federal sources (including research institutions).  These      *
C   research institutions have given the Government permission to      *
C   use, prepare derivative works, and distribute copies of their      *
C   work in Models-3/CMAQ to the public and to permit others to do     *
C   so.  EPA therefore grants similar permissions for use of the       *
C   Models-3/CMAQ software, but users are requested to provide copies  *
C   of derivative works to the Government without restrictions as to   *
C   use by others.  Users are responsible for acquiring their own      *
C   copies of commercial software associated with Models-3/CMAQ and    *
C   for complying with vendor requirements.  Software copyrights by    *
C   the MCNC Environmental Modeling Center are used with their         *
C   permissions subject to the above restrictions.                     *
C***********************************************************************

C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /master/scratch/avise/cmaqv4.3/models/CCTM/src/util/util/get_envlist.f,v 1.1.1.1 2003/09/11 16:26:37 sjr Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE GET_ENVLIST ( ENV_VAR, NVARS, VAL_LIST )

C get a list env var (quoted string of items delimited by white space,
C commas or semi-colons) and parse out the items into variables. Two data
C types: character strings and integers (still represented as strings in
C the env var vaules).
C Examples:
C 1)   setenv AVG_CONC_VARS "O3 NO NO2"
C 2)   setenv AVG_CONC_LAYS "2 5"          < start at two, end at 5
C 3)   setenv NPCOLSXNPROWS "4 3"
C 4)   setenv BCOL_ECOL "3 8"
C 5)   setenv BROW_EROW "2 10"
C 6)   setenv BLAY_ELAY "1 5"

C In example (1), not only parse out the named items "O3", "NO" and "NO2",
C but also obtain the count on the number of itmes (=3).

      IMPLICIT NONE

      CHARACTER( * ), INTENT ( IN ) :: ENV_VAR
      INTEGER, INTENT ( OUT ) :: NVARS
      CHARACTER( 16 ), INTENT ( OUT ) :: VAL_LIST( : )

      CHARACTER(  16 ) :: PNAME = 'GET_ENVLIST'
      CHARACTER( 256 ) :: E_VAL
      CHARACTER(   1 ) :: CHR
      CHARACTER(  96 ) :: XMSG
      INTEGER STATUS

      INTEGER :: JP( SIZE( VAL_LIST ) ), KP( SIZE( VAL_LIST ) )
      INTEGER IP, V

C               env_var_name description default_env_var_name
C                    |          |          |   env_var_value
C                    |          |          |        |
      CALL ENVSTR( ENV_VAR, 'Env_Var', 'VARLIST', E_VAL, STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'Environment variable ' // ENV_VAR // ' not set'
         CALL M3EXIT( PNAME, 0, 0, XMSG, 2 )
         END IF
C Parse:

      NVARS = 1

C dont count until 1st char in string

      IP = 0

101   CONTINUE
      IP = IP + 1
      IF ( IP .GT. 256 ) GO TO 301
      CHR = E_VAL( IP:IP )
      IF ( CHR .EQ. ' ' .OR. ICHAR ( CHR ) .EQ. 09 ) GO TO 101
      JP( NVARS ) = IP   ! 1st char

201   CONTINUE
      IP = IP + 1
      IF ( IP .GT. 256 ) THEN
         XMSG = 'Environment variable value too long'
         CALL M3EXIT( PNAME, 0, 0, XMSG, 2 )
         END IF
      CHR = E_VAL( IP:IP )
      IF ( CHR .NE. ' ' .AND.
     &     CHR .NE. ',' .AND.
     &     CHR .NE. ';' .OR.
     &     ICHAR ( CHR ) .EQ. 09 ) THEN  ! 09 = horizontal tab
         GO TO 201
         ELSE
         KP( NVARS ) = IP - 1 ! last char in this item
         NVARS = NVARS + 1
         END IF 

      GO TO 101

301   CONTINUE
      NVARS = NVARS - 1

      DO V = 1, NVARS
         VAL_LIST( V ) = E_VAL( JP( V ):KP( V ) )
         END DO

      RETURN 
      END
