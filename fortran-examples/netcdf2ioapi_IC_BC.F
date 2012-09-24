      PROGRAM netcdf2ioapi_IC_BC
      
      USE NETCDF     ! netCDF modules
      USE M3UTILIO   ! IOAPI modules
      
      IMPLICIT NONE

!*** vars adapted from NCF2IOAPI_Edgar4.F received from Zac Adelman
      CHARACTER*16 :: progname = 'netcdf2ioapiICBC' ! make fit in 16

!... netCDF related variables ... 
      INTEGER :: infileid    ! Input file ID
      INTEGER :: status      ! return value (from netCDF calls)
      INTEGER :: nglatt      ! number of global attributes?
      INTEGER :: unlimid     ! DimID for time variable
      CHARACTER*16 :: units  ! attribute=units?
      CHARACTER*30 :: name
      INTEGER :: ndims       ! Number of dimensions
! DIMID is arg for calls to NF90_INQ_DIMID, NF90_INQUIRE_DIMENSION
      INTEGER :: dimid
      INTEGER, ALLOCATABLE      :: ndimid(:)       ! Dimension ID
      CHARACTER*30, ALLOCATABLE :: dimname(:)      ! Dimension name
      INTEGER, ALLOCATABLE      :: dimlen(:)       ! Dimension length
      CHARACTER*30, SAVE, ALLOCATABLE :: outvar(:) ! output variable name 
      INTEGER :: nvars                       ! Number of variables      
      CHARACTER*30 :: vname                  ! Variable name
      INTEGER :: VTYPE                       ! Variable type
      INTEGER :: VNDIM                       ! Number of dimension
      INTEGER :: VDIMS                       ! Variable Dimension
      INTEGER :: VARID                       ! Variable ID
      INTEGER :: NVATT                       ! Number attribute
      CHARACTER*30, ALLOCATABLE :: oname(:)  ! Output variable
      CHARACTER*16, ALLOCATABLE :: V_LIST(:) ! Variable number
      INTEGER, ALLOCATABLE :: OINDX(:)       ! Out variable index
      INTEGER :: OVARS                       ! Total variable to extract
      INTEGER :: OVARSIN

!... IOAPI related variable ...
      INTEGER :: LOGDEV      ! logfile unit#
      INTEGER :: NCOL, NROW  ! number of datavar columns and rows
      INTEGER :: NLAY, NSTEP ! number of datavar layers and timesteps
      INTEGER :: JDATE, JTIME, JSTEP
      CHARACTER*16 :: OUTFILE = 'OUTFILE' ! name of output envvar
      CHARACTER*160 MESG     ! messages to user
      REAL, ALLOCATABLE    :: INBUF (:,:,:)  ! Data buffer array
      CHARACTER*256 fname    ! Input filename (via envvar=INFILE)

!... Other variables ...
      INTEGER :: C, T, L     ! Counters
      LOGICAL :: FIRSTIME = .TRUE.  ! initial datavar iteration
      INTEGER :: YR,MN,DT           ! YYYY, MM, DD: year, month, day
! for JDATE format (!= JDATE var above), see CMAQ wiki, section=
! "Required Libraries" >
! "Input/Output Applications Programming Interface (I/O API)" >
! "Files, Logical Names, and Physical Names"
      INTEGER :: DATE               ! input YYYYMMDD in format=JDATE
      CHARACTER*8 DATECHAR          ! input YYYYMMDD as character
!      INTEGER :: SEC                ! input timestep sec
      INTEGER :: IDATE              ! decoded from DATE
!      INTEGER :: ITIME              ! input HHMMSS
      INTEGER :: OUTYR  ! TODO: rid: output year
      INTEGER :: OUTMN  ! TODO: rid: output month
      REAL, ALLOCATABLE :: PSURF(:,:)  ! surface pressure
! "hybrid <A|B> coefficient at layer midpoints"?
      REAL, ALLOCATABLE :: HYAM(:)
      REAL, ALLOCATABLE :: HYBM(:)
      INTEGER, ALLOCATABLE :: TIME(:)

      INTERFACE ! see get_envlist.f in this folder
         SUBROUTINE GET_ENVLIST ( ENV_VAR, nvars, VAL_LIST )
            IMPLICIT NONE
            CHARACTER( * ),  INTENT ( IN )  :: ENV_VAR
            INTEGER,         INTENT ( OUT ) :: nvars
            CHARACTER( 16 ), INTENT ( OUT ) :: VAL_LIST( : )
         END SUBROUTINE GET_ENVLIST
      END INTERFACE

!*** end vars from NCF2IOAPI_Edgar4.F received from Zac Adelman
!*** vars from readnet.for for IC_BC=2008N2O_restart.nc---------------

      INCLUDE 'netcdf.inc' ! why do I need this? I have USE NETCDF above

!      PARAMETER (nvars=13) ! counted by gennet.f, written to readnet.for
      INTEGER, PARAMETER :: r_nvarc = 13 ! number of vars read, const
      INTEGER i            ! ... and counter incrementing over it
      INTEGER*4 :: r_nvars ! number of vars read, as returned by NCINQ
C     VARIABLE IDS RUN SEQUENTIALLY FROM 1 TO r_nvarc= 13
      INTEGER*4 r_rc   ! return value
      INTEGER*4 ilen    ! string index
      INTEGER*4 ncfid   ! netCDF file ID
      INTEGER*4 ivarid  ! netCDF datavar ID
      INTEGER*4 r_rdid  ! netCDF record dimension ID (unlimited dim)
      INTEGER vartyp    ! netCDF datavar type
      INTEGER nvdim     ! number of datavar's dimensions
      INTEGER j         ! ... and counter incrementing over it
      INTEGER r_nva     ! number of datavar's attributes
      INTEGER r_nga     ! number of global attributes
      INTEGER*4 ndsize  ! size of dimension
      INTEGER*4 lenstr  ! (yet another?) string length
      CHARACTER*50 long_name(r_nvarc)
      CHARACTER*50 read_name(100)

C     ****read VARIABLES FOR THIS NETCDF FILE****

      REAL*8      read_N2O   (  144,   96,   56)
      REAL*8      read_lon   (  144)
      REAL*8      read_lat   (   96)
      REAL*8      read_lev   (   56)
      REAL*8      read_P0    
      REAL*8      read_hyam  (   56)
      REAL*8      read_hybm  (   56)
      REAL*8      read_hyai  (   57)
      REAL*8      read_hybi  (   57)
      REAL*8      read_ilev  (   57)
      REAL*8      read_PS    (  144,   96)
      INTEGER*4   read_date
      INTEGER*4   read_datesec  
C*************************************
!      character*80 input_file
! TODO: get envvar=OUTFILE
      CHARACTER*80 :: input_file = '2008N2O_restart.nc'
      INTEGER*4 START(10)
      INTEGER*4 COUNT(10)
      INTEGER READ_VDIMS(10) !ALLOW UP TO 10 DIMENSIONS
      CHARACTER*31 DUMMY

C      LONG NAMES FOR EACH VARIABLE
! gennet.f generates nulls, instead s/^@/\s/g

      data long_name/
     *'N2O                                               ',
     *'longitude                                         ',
     *'latitude                                          ',
     *'hybrid level at layer midpoints (1000*(A+B))      ',
     *'reference pressure                                ',
     *'hybrid A coefficient at layer midpoints           ',
     *'hybrid B coefficient at layer midpoints           ',
     *'hybrid A coefficient at layer interfaces          ',
     *'hybrid B coefficient at layer interfaces          ',
     *'hybrid level at layer interface (1000*(A+B))      ',
     *'Surface Pressure                                  ',
     *'current date as 6 digit integer (YYMMDD)          ',
     *'seconds to complete current date                  '/

!      write(6,1)
! 1    format(' enter your input file')
!      read(5,2) input_file
! 2    format(a80)
      ilen = INDEX(input_file,'   ')
      ncfid = NCOPN(input_file(1:ilen-1),0,r_rc)

C    statements to fill read_N2O                            

! get the netCDF variable ID as integer
! not sure why the space padding
      ivarid = NCVID(ncfid, 'N2O                            ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  10 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  10  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_N2O, r_rc)

C    statements to fill read_lon                            

      ivarid = NCVID(ncfid,'lon                            ',r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  20 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  20  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_lon, r_rc)

C    statements to fill read_lat                            

      ivarid = NCVID(ncfid, 'lat                            ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  30 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  30  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_lat, r_rc)

C    statements to fill read_lev                       

      ivarid = NCVID(ncfid, 'lev                            ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  40 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  40  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_lev, r_rc)

C    statements to fill read_P0                        

      ivarid = NCVID(ncfid, 'P0                             ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  50 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  50  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_P0, r_rc)

C    statements to fill read_hyam                      

      ivarid = NCVID(ncfid, 'hyam                           ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  60 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  60  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_hyam, r_rc)

C    statements to fill read_hybm                      

      ivarid = NCVID(ncfid, 'hybm                           ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  70 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  70  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_hybm, r_rc)

C    statements to fill read_hyai                      

      ivarid = NCVID(ncfid, 'hyai                           ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  80 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  80  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_hyai, r_rc)

C    statements to fill read_hybi                      

      ivarid = NCVID(ncfid, 'hybi                           ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO  90 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
  90  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_hybi, r_rc)

C    statements to fill read_ilev                      

      ivarid = NCVID(ncfid, 'ilev                           ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO 100 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
 100  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_ilev, r_rc)

C    statements to fill read_PS                        

      ivarid = NCVID(ncfid, 'PS                             ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO 110 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
 110  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_PS, r_rc)

C    statements to fill read_date                      

      ivarid = NCVID(ncfid, 'date                           ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO 120 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
 120  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_date, r_rc)

C    statements to fill read_datesec                   

      ivarid = NCVID(ncfid, 'datesec                        ', r_rc)
      CALL NCVINQ(ncfid, ivarid, DUMMY, vartyp, nvdim, READ_VDIMS, r_nva, r_rc)
      lenstr=1
      DO 130 J=1, nvdim
      CALL NCDINQ(ncfid, READ_VDIMS(J), DUMMY, ndsize, r_rc)
      lenstr=lenstr*ndsize
      START(J)=1
      COUNT(J)=ndsize
 130  CONTINUE
      CALL NCVGT(ncfid, ivarid, START, COUNT, read_datesec, r_rc)

C     following code: checks output code code against current input file

      CALL NCINQ(ncfid, ndims, r_nvars, r_nga, r_rdid, r_rc)
      IF (r_nvars .ne. r_nvarc) WRITE(6, 150)
  150 FORMAT('number of variables has changed')
C
      DO 220 i=1, r_nvarc
      DO 180 j=1, r_nvars
      CALL NCAGTC(ncfid, j, 'long_name', read_name(j), 50, r_rc)
      ilen = INDEX(long_name(i), '   ')
! gennet.f generates spurious "'" in next line
      IF (long_name(i)(1:ilen-1) .eq. read_name(j)(1:ilen-1)) go to 220
  180 CONTINUE
      WRITE(6, 190) read_name(j)
  190 FORMAT('unknown variable ', a50)
      WRITE(6, 200)
  200 FORMAT('rerun gennet')
      STOP
  220 CONTINUE
C
      CALL NCCLOS(ncfid, r_rc)

C     HERE IS WHERE YOU WRITE STATEMENTS TO USE THE DATA

! If you leave these in (as generated by gennet.f),
!      STOP
!      END
! ifort goes nuts: notably, you'll get
! netcdf2ioapi_IC_BC.F(362): error #6362: The data types of the argument(s) are invalid.   [TRIM]
!       status = NF90_OPEN(TRIM(fname), NF90_NOWRITE, infileid)
! ------------------------------^

!*** end vars from readnet.for for IC_BC=2008N2O_restart.nc-----------

!.... Initialize the I/O API ...
      LOGDEV = INIT3()        ! initialization returns logfile unit#

!... Get input filename ...
      CALL NAMEVAL('INFILE', fname)
      WRITE(LOGDEV,*),'Input file:', fname
      status = NF90_OPEN(TRIM(fname), NF90_NOWRITE, infileid)
      IF (status /= NF90_NOERR) STOP "Error open input file"

! indicate that we have not yet been into ...
      IF ( FIRSTIME ) THEN
        FIRSTIME = .FALSE.

!... List dimensions ...
        CALL CHECK(NF90_INQUIRE(INFILEID,NDIMS,NVARS,NGLATT,UNLIMID))
        ALLOCATE ( NDIMID(NDIMS), DIMNAME(NDIMS),
     &             DIMLEN(NDIMS), STAT = STATUS )
        IF ( STATUS /= 0 )
     &    STOP "error allocating NDIMID/DIMNAME/DIMLEN arrays"

        PRINT 310,'DimID','DimName','DimLEN'
        DO C = 1, NDIMS, 1
          CALL CHECK(NF90_INQUIRE_DIMENSION(INFILEID,C,DIMNAME(C),
     &                 DIMLEN(C)))
          PRINT 309,C,TRIM(DIMNAME(C)),DIMLEN(C)
        ENDDO

!... Get output variables and their index ... 
        OVARSIN = 0
        OVARS = 0
        OVARS = MAX( OVARSIN, NVARS )

        ALLOCATE( OUTVAR( OVARS ), STAT = STATUS )
        IF ( STATUS /= 0 ) STOP "error allocating OUTVAR array"
         
        ALLOCATE ( ONAME ( OVARS ), OINDX( OVARS ),
     &             V_LIST ( OVARS ), STAT = STATUS )
        IF ( STATUS /= 0 )
     &    STOP "error allocating ONAME/OINDX/V_LIST arrays"

        IF ( OVARSIN .GT. 0 ) THEN
          OVARS = OVARSIN
          CALL GET_ENVLIST ('OINDX',OVARS,V_LIST)
          DO C = 1, OVARS, 1
            READ( V_LIST( C ), '( I4 )' ) OINDX( C )
          ENDDO
        ENDIF

!... List variables ...
        PRINT*,'Inquire variables...'
        PRINT 310,'V_Index','V_Dims','V_NAME','V_UNIT','V_DESC','Dim_ID'
        IF ( OVARSIN .EQ. 0 ) OVARS = 0
        DO C = 1, NVARS, 1
          MESG = ' '
          VNAME = ' '
          UNITS = ' '
          CALL CHECK(NF90_INQUIRE_VARIABLE(INFILEID,C,VNAME,VTYPE,
     &               VNDIM,NDIMID,NVATT))
          CALL CHECK(NF90_GET_ATT(INFILEID,C,'long_name',MESG))
          CALL CHECK(NF90_GET_ATT(INFILEID,C,'units',UNITS))
          PRINT 311,C,VNDIM,TRIM(VNAME),TRIM(UNITS),TRIM(MESG),
     &             (NDIMID(L),L=1,VNDIM)
          IF ( OVARSIN .EQ. 0 .AND. VNDIM .EQ. 2 ) THEN
            OVARS = OVARS + 1
            OINDX( OVARS ) = C
          ENDIF
        ENDDO

309     FORMAT (I3,',',5x,a,',',5x,I3)
310     FORMAT (6(a,',',10x))
311     FORMAT (I3,', ',I2,', ',3(a,', '),10(I2))

!... Get variable name, unit, desc ...
! C is INTEGER counter, OVARS is number of output variables
        DO C = 1, OVARS, 1
          UNITS = ' '
          MESG = ' '
          CALL CHECK(NF90_INQUIRE_VARIABLE(INFILEID,OINDX(C),ONAME(C),
     &               VTYPE,VNDIM,NDIMID,NVATT))
          CALL CHECK(NF90_GET_ATT(INFILEID,OINDX(C),'long_name',MESG))
          CALL CHECK(NF90_GET_ATT(INFILEID,OINDX(C),'units',UNITS))
          PRINT*,'Variable: ',ONAME(C),' -- ',
     &            TRIM(UNITS),':',TRIM(MESG)
          PRINT*,'Variable dimension:',VNDIM 
          PRINT*,'Variable dimension id:',NDIMID(1:VNDIM)
          PRINT*,'Variable name: ',OUTVAR(C)
        ENDDO

!... Allocate data buffer ...
        CALL CHECK(NF90_INQ_DIMID(INFILEID,'lon',DIMID))
        CALL CHECK(NF90_INQUIRE_DIMENSION(INFILEID,DIMID,len=NCOL))
        CALL CHECK(NF90_INQ_DIMID(INFILEID,'lat',DIMID))
        CALL CHECK(NF90_INQUIRE_DIMENSION(INFILEID,DIMID,len=NROW))
        ALLOCATE ( INBUF  ( NCOL, NROW, 1 ), STAT = STATUS )
        IF ( STATUS /= 0 ) STOP "error allocating INBUF array"
        OUTYR = 0   ! set to open file for the first time
      ENDIF  ! End FIRSTIME: just getting variables?

      NSTEP = 1
      PRINT*,'Total timestep:',NSTEP

      ALLOCATE ( TIME(NSTEP), STAT = STATUS )
      IF ( STATUS /= 0 ) STOP "error allocating TIME array"

!... Loop through time here if time dependent ...
      TIME = 0
      DO T = 1, NSTEP, 1

!... Check input vs output timesteps
! orig:   DATE = ENVINT('STDATE','Data start date (YYYMMDD)',0,STATUS) 
        DATE = ENVINT('STDATE','Data start date (YYYYMMDD)',0,STATUS) 
        WRITE(DATECHAR,'(I8)') DATE
        YR = STR2INT(DATECHAR(1:4))
        MN = STR2INT(DATECHAR(5:6))
        DT = STR2INT(DATECHAR(7:8))

        PRINT*,'DATECHAR: ', DATECHAR
        PRINT*,'YR: ',YR,'MN: ',MN,'DT: ',DT
        IDATE = 1000 * YR +  JULIAN( YR, MN, DT )
        JSTEP = 0
        PRINT*,'idate = ',IDATE
        PRINT*,'jstep = ',JSTEP

!... New file each year ...
! TODO: remove me! just convert this one file!
        IF ( OUTYR .EQ. 0 ) THEN  ! open file only once - bkoo
          JDATE = IDATE
          JTIME = 0 
          PRINT*,'ovars,oname: ', OVARS,ONAME
          PRINT*,'outvar: ', OUTVAR
          CALL OPOUTFILE(JDATE, JTIME, JSTEP, INFILEID, OVARS, OUTVAR, OUTFILE)
          OUTYR = YR
        ENDIF

9100    FORMAT( 10( A, :, I8, :, 1X ) )
! C is INTEGER counter, OVARS is number of output variables
        DO C = 1, OVARS, 1
          INBUF = 0
          CALL CHECK(NF90_INQ_VARID(INFILEID,ONAME(C),VARID)) ! get VID from name
          CALL CHECK(NF90_INQUIRE_VARIABLE(INFILEID,VARID,VNAME,
     &               VTYPE,VNDIM,NDIMID,NVATT))

! For 2D data
          IF ( VNDIM == 2 ) THEN  
          PRINT*, 'Writing output data'
            CALL CHECK(NF90_GET_VAR(INFILEID,VARID,
     &             INBUF(:,:,1),START=(/1,1,T/))) ! get data
            IF ( .NOT. WRITE3(OUTFILE,OUTVAR(C),JDATE,JTIME,
     &            INBUF(:,:,1))) THEN
                MESG = 'Could not write to "'//TRIM(OUTFILE)//'"'
                CALL M3EXIT( PROGNAME, JDATE, JTIME, MESG, 2 )
            ENDIF
          ENDIF
        ENDDO ! end looping over output vars

!... Increment time by tstep ...
        CALL NEXTIME ( JDATE, JTIME, JSTEP )
      ENDDO ! end looping timesteps DO T = 1, NSTEP, 1

!... Close netCDF input file ...
      MESG = 'Close input netCDF file: '//TRIM(fname)
      CALL M3MESG(MESG)
      CALL CHECK(NF90_CLOSE(infileid))
      CALL M3EXIT(progname, 0, 0, ' ', 0) 

!.....................................
      CONTAINS 
! checks error status after each netcdf, 
! print message each time an error code is returned. 
      SUBROUTINE CHECK(status)
        INTEGER, INTENT (in) :: status
        IF (status /= NF90_NOERR) then 
          PRINT *,'netCDF error:', TRIM(NF90_STRERROR(status))
        END IF
      END SUBROUTINE CHECK
      
      ENDPROGRAM
