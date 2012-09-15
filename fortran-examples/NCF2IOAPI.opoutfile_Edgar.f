      SUBROUTINE OPOUTFILE ( SDATE, STIME, JSTEP, NCFID, 
     &                       OVARS, ONAME, OFL2D )

C**********************
C     Set output netCDF-IOAPI file variables and open output  
C     Output grid info extracted from netCDF file (input NCFID, opened)
C    
C     1/29/2008 -- bkoo (ENVIRON) - removed hard coded info
C

!... Modules ...
      USE NETCDF
      USE M3UTILIO

      IMPLICIT NONE

!... External Functions


!... INCLUDES for netCDF-IOAPI...
c      INCLUDE 'PARMS3.EXT'      ! I/O API constants
c      INCLUDE 'FDESC3.EXT'      ! I/O API file description data structure
c      INCLUDE 'IODECL3.EXT'     ! I/O API function declarations

!... Argument variables
      INTEGER,       INTENT(IN) :: SDATE  ! IOAPI file start date YYYYDDD
      INTEGER,       INTENT(IN) :: STIME  ! IOAPI file start time HHMMSS
      INTEGER,       INTENT(IN) :: JSTEP  ! IOAPI timestep HHMSS
      INTEGER,       INTENT(IN) :: NCFID  ! netCDF input file id
      INTEGER,       INTENT(IN) :: OVARS  ! number of putput variable
      CHARACTER*(*), INTENT(IN) :: ONAME( OVARS ) ! output varible name
      CHARACTER*(*), INTENT(IN) :: OFL2D  ! output 2D IOAPI logical name
c      CHARACTER*(*), INTENT(IN) :: OFL3D  ! output 3D IOAPI logical name

!... Local variables
      INTEGER, SAVE :: NCOL
      INTEGER, SAVE :: NROW
      INTEGER, SAVE :: NLAY
      CHARACTER*16  OUNIT
      CHARACTER*30  ODESC
      CHARACTER*16  VNAME
      CHARACTER*30  NAME
      CHARACTER*30  TrimNAME
      INTEGER DIMID, VARID, VTYPE, VNDIM
      INTEGER N2DVARS, N3DVARS
      INTEGER :: STATUS                   ! IO status
      INTEGER :: C                        ! counters
      REAL, SAVE, ALLOCATABLE :: SIGMA(:) ! sigma layer
      CHARACTER, SAVE, ALLOCATABLE :: OUTVAR(:) ! output variable name 
      REAL, SAVE, DIMENSION(2) :: XPAR, YPAR
      CHARACTER*256 MESG, UNITS
      LOGICAL, SAVE :: FIRSTIME = .TRUE.
      CHARACTER*16 :: PROGNAME = 'OPOUTFILE' ! program name

!... Begin Code ...
      IF ( FIRSTIME ) THEN
         FIRSTIME = .FALSE.

!... get grid def. 
         CALL CHECK(NF90_INQ_DIMID(NCFID,'lon',DIMID))
         CALL CHECK(NF90_INQUIRE_DIMENSION(NCFID,DIMID,len=NCOL))
         CALL CHECK(NF90_INQ_DIMID(NCFID,'lat',DIMID))
         CALL CHECK(NF90_INQUIRE_DIMENSION(NCFID,DIMID,len=NROW))

         CALL CHECK(NF90_INQ_VARID(NCFID,'lon',VARID))
         CALL CHECK(NF90_GET_VAR(NCFID,VARID,XPAR,COUNT=(/2/),
     &                                            STRIDE=(/NCOL-1/)))
         CALL CHECK(NF90_INQ_VARID(NCFID,'lat',VARID))
         CALL CHECK(NF90_GET_VAR(NCFID,VARID,YPAR,COUNT=(/2/),
     &                                            STRIDE=(/NROW-1/)))

      ENDIF ! FIRSTIME

!... setup IOAPI 
!... IOAPI grid info
         GDNAM3D = 'MOZART_GRID'
         GDTYP3D = LATGRD3          ! latlon grid, LATGRD3=1
         FTYPE3D = GRDDED3          ! Gridded data format

         CALL CHECK(NF90_GET_ATT(NCFID,NF90_GLOBAL,'title',FDESC3D(1)))
         FDESC3D(2) = 'Converted to I/O API format by MOZART2CMAQ'

         P_ALP3D = BADVAL3          ! These are not used for LATLON grid
         P_BET3D = BADVAL3
         P_GAM3D = BADVAL3
         XCENT3D = BADVAL3
         YCENT3D = BADVAL3
         XORIG3D = XPAR(1)          ! Grid origin X
         IF ( XORIG3D .GT. 180. ) XORIG3D = XORIG3D - 360.
         YORIG3D = YPAR(1)          ! Grid origin Y
         NROWS3D = NROW             ! N-Hemis only
         NCOLS3D = NCOL
         XCELL3D = (XPAR(2)-XPAR(1))/REAL(NCOL-1) ! x grid distance dlon
         YCELL3D = (YPAR(2)-YPAR(1))/REAL(NROW-1) ! y grid distance dlat

         PRINT*,'XORIG3D: ',XORIG3D,'YORIG3D: ',YORIG3D
         PRINT*,'XCELL3D: ',XCELL3D,'YCELL3D: ',YCELL3D

!... IOAPI time info
         SDATE3D = SDATE
         STIME3D = STIME
         TSTEP3D = JSTEP

!... setup 2D variables
         N2DVARS = 0
         DO C = 1, OVARS, 1
               N2DVARS = N2DVARS + 1
               VNAME3D( N2DVARS ) = ONAME(C)
               MESG = ' '
               CALL CHECK(NF90_GET_ATT(NCFID,VARID,'units',UNITS))
! force the output units to tons/yr
               UNITS3D( N2DVARS ) = 'tons/yr' 
               
	       MESG = ' '
               CALL CHECK(NF90_GET_ATT(NCFID,3,'long_name',MESG))
               VDESC3D( N2DVARS ) = TRIM(MESG)
               VTYPE3D( N2DVARS ) = M3REAL    ! HARDCODED all data type REAL
         ENDDO
         NVARS3D = N2DVARS
         NLAYS3D = 1

!... Open 2D IOAPI file ...
         IF ( N2DVARS > 0 ) THEN
            IF ( .NOT. OPEN3( OFL2D, FSCREA3, PROGNAME ) ) THEN
                MESG = 'Could not open file "'//TRIM(OFL2D)//
     &                 '" for output'
                CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
            ENDIF
         ENDIF

!.....................................
      CONTAINS
!- checks error status after each netcdf, prints out text message each time
!   an error code is returned.
      subroutine check(status)
        integer, intent ( in) :: status

        if(status /= nf90_noerr) then
          print *,'netCDF error:', trim(nf90_strerror(status))

        end if
      end subroutine check

         ENDSUBROUTINE OPOUTFILE
         
