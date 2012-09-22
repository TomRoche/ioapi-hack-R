      PROGRAM netcdf2ioapi_IC_BC

! see also below CHARACTER*16 :: PROGNAME 
!***********************************************************************
!  DESCRIPTION:
!       Convert raw netCDF file to netCDF IOAPI format
!
!  PRECONDITIONS REQUIRED:
!       setenv OUTFILE for output filename
!
!  SUBROUTINES AND FUNCTIONS CALLED:
!       Require netCDF and IOAPI libraries
!
!  REVISION  HISTORY:
!       Jack Chen - create program=NCF2IOAPI
!       JC - added 2D/3D file output from JCA
!       JC - added time check with input netCDF
!       1/29/2008 -- bkoo (ENVIRON) - removed hard coded info,
!                                   - add UAE-specific coding
!       Tom Roche, Sep 2012: recode for N2O inputs
!***********************************************************************
      
      USE NETCDF     ! netCDF modules
      USE M3UTILIO   ! IOAPI modules
      
      IMPLICIT NONE

!*** vars from NCF2IOAPI_Edgar4.F received from Zac Adelman

      CHARACTER*16 :: PROGNAME = 'netcdf2ioapi_IC_BC'
      
!... netCDF related variables ... 
      INTEGER :: INFILEID        ! Input file ID
!      INTEGER :: ARFILEID        ! Area file ID
      INTEGER :: NGLATT          ! number of global attributes?
      INTEGER :: UNLIMID         ! DimID for time variable
      CHARACTER*16 :: UNITS      ! attribute=units?
      CHARACTER*30 :: NAME
      CHARACTER*16 :: TrimNAME
      
      INTEGER :: NDIMS                             ! Number of dimensions
! DIMID is arg for calls to NF90_INQ_DIMID, NF90_INQUIRE_DIMENSION
      INTEGER :: DIMID
      INTEGER, ALLOCATABLE      :: NDIMID(:)       ! Dimension ID
      CHARACTER*30, ALLOCATABLE :: DIMNAME(:)      ! Dimension name
      INTEGER, ALLOCATABLE      :: DIMLEN(:)       ! Dimension length
      CHARACTER*30, SAVE, ALLOCATABLE :: OUTVAR(:) ! output variable name 

      INTEGER :: NVARS                       ! Number of variables      
      CHARACTER*30 :: VNAME                  ! Variable name
      INTEGER :: VTYPE                       ! Variable type
      INTEGER :: VNDIM                       ! Number of dimension
      INTEGER :: VDIMS                       ! Variable Dimension
      INTEGER :: VARID                       ! Variable ID
      INTEGER :: NVATT                       ! Number attribute
      CHARACTER*30, ALLOCATABLE :: ONAME(:)  ! Output variable
      CHARACTER*16, ALLOCATABLE :: V_LIST(:) ! Variable number
      INTEGER, ALLOCATABLE :: OINDX(:)       ! Out variable index
      INTEGER :: OVARS                       ! Total variable to extract
      INTEGER :: OVARSIN

!... IOAPI related variable ...
      INTEGER :: LOGDEV      ! logfile unit#
      INTEGER :: NCOL, NROW  ! number of datavar columns and rows
      INTEGER :: NLAY, NSTEP ! number of datavar layers and timesteps
      INTEGER :: JDATE, JTIME, JSTEP
!      CHARACTER*16 :: OUTFILE2D = 'OUTFILE2D', OUTFILE3D = 'OUTFILE3D'
      CHARACTER*16 :: OUTFILE = 'OUTFILE'
      CHARACTER*160 MESG     ! messages to user
      
      REAL, ALLOCATABLE    :: INBUF (:,:,:)  ! Data buffer array
!      REAL, ALLOCATABLE    :: ARBUF (:,:,:)  ! Data buffer for layers

!... Other variables ...
      INTEGER :: C, T, STATUS, L  ! Counters
      CHARACTER*256    FNAME      ! Input filename (via envvar=INFILE)

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
!      INTEGER :: DEFJSTEP, MDT, MHISF
!      REAL :: SEC2YR, KG2TON
!      REAL :: PREF
!      REAL, ALLOCATABLE :: PSURF(:,:), HYAM(:), HYBM(:)
      REAL, ALLOCATABLE :: PSURF(:,:)  ! surface pressure
! "hybrid <A|B> coefficient at layer midpoints"?
      REAL, ALLOCATABLE :: HYAM(:)
      REAL, ALLOCATABLE :: HYBM(:)
      INTEGER, ALLOCATABLE :: TIME(:)

      INTERFACE ! see get_envlist.f in this folder
         SUBROUTINE GET_ENVLIST ( ENV_VAR, NVARS, VAL_LIST )
            IMPLICIT NONE
            CHARACTER( * ),  INTENT ( IN )  :: ENV_VAR
            INTEGER,         INTENT ( OUT ) :: NVARS
            CHARACTER( 16 ), INTENT ( OUT ) :: VAL_LIST( : )
         END SUBROUTINE GET_ENVLIST
      END INTERFACE

!*** end vars from NCF2IOAPI_Edgar4.F received from Zac Adelman
!*** vars from readnet.for for IC_BC=2008N2O_restart.nc



!*** end vars from readnet.for for IC_BC=2008N2O_restart.nc
!*** BEGIN CODE ***
!.... Initialize the I/O API ...
      LOGDEV = INIT3()        ! initialization returns logfile unit#

!... Get input filename ...
      CALL NAMEVAL( 'INFILE', FNAME )

      WRITE(LOGDEV,*),'Input file:', FNAME
      STATUS = NF90_OPEN(PATH=TRIM(FNAME),MODE=NF90_NOWRITE,
     &                   NCID=INFILEID)
      IF (STATUS /= NF90_NOERR) STOP "Error open input file"

      IF ( FIRSTIME ) THEN 
         FIRSTIME = .FALSE.

!... Open Cell Area file....
!      CALL NAMEVAL( 'AREAFILE', ANAME )
!
!      WRITE(LOGDEV,*),'Cell Area Input file:', ANAME
!      STATUS = NF90_OPEN(PATH=TRIM(ANAME),MODE=NF90_NOWRITE,
!     &                   NCID=ARFILEID)
!      IF (STATUS /= NF90_NOERR) STOP "Error open area input file"

!... List dimensions ...
         CALL CHECK(NF90_INQUIRE(INFILEID,NDIMS,NVARS,NGLATT,UNLIMID))
         ALLOCATE ( NDIMID(NDIMS), DIMNAME(NDIMS),
     &              DIMLEN(NDIMS), STAT = STATUS )
         IF ( STATUS /= 0 )
     &            STOP "error allocating NDIMID/DIMNAME/DIMLEN arrays"

         PRINT 10,'DimID','DimName','DimLEN'
         DO C = 1, NDIMS, 1
            CALL CHECK(NF90_INQUIRE_DIMENSION(INFILEID,C,DIMNAME(C),
     &                 DIMLEN(C)))
            PRINT 9,C,TRIM(DIMNAME(C)),DIMLEN(C)
         ENDDO

!... Get output variables and their index ... 
         OVARSIN = 0
         OVARS = 0
         OVARS = MAX( OVARSIN, NVARS )

         ALLOCATE( OUTVAR( OVARS ), STAT = STATUS )
         IF ( STATUS /= 0 ) STOP "error allocating OUTVAR array"
         
         ALLOCATE ( ONAME ( OVARS ), OINDX( OVARS ),
     &              V_LIST ( OVARS ),
     &              STAT = STATUS )
         IF ( STATUS /= 0 )
     &               STOP "error allocating ONAME/OINDX/V_LIST arrays"

         IF ( OVARSIN .GT. 0 ) THEN
           OVARS = OVARSIN
           CALL GET_ENVLIST ('OINDX',OVARS,V_LIST)

           DO C = 1, OVARS, 1
              READ( V_LIST( C ), '( I4 )' ) OINDX( C )
           ENDDO
         ENDIF

!... List variables ...
         PRINT*,'Inquire variables...'
         PRINT 10,'V_Index','V_Dims','V_NAME','V_UNIT','V_DESC','Dim_ID'
         IF ( OVARSIN .EQ. 0 ) OVARS = 0
         DO C = 1, NVARS, 1
            MESG = ' '
            VNAME = ' '
            UNITS = ' '
            CALL CHECK(NF90_INQUIRE_VARIABLE(INFILEID,C,VNAME,VTYPE,
     &                 VNDIM,NDIMID,NVATT))
            CALL CHECK(NF90_GET_ATT(INFILEID,C,'long_name',MESG))
            CALL CHECK(NF90_GET_ATT(INFILEID,C,'units',UNITS))
            PRINT 11,C,VNDIM,TRIM(VNAME),TRIM(UNITS),TRIM(MESG),
     &               (NDIMID(L),L=1,VNDIM)
            IF ( OVARSIN .EQ. 0 .AND. VNDIM .EQ. 2 ) THEN
              OVARS = OVARS + 1
              OINDX( OVARS ) = C
            ENDIF
         ENDDO

9     FORMAT (I3,',',5x,a,',',5x,I3)
10    FORMAT (6(a,',',10x))
11    FORMAT (I3,', ',I2,', ',3(a,', '),10(I2))

!... Get variable name, unit, desc ...
! C is INTEGER counter, OVARS is number of output variables
        DO C = 1, OVARS, 1

            UNITS = ' '
            MESG = ' '
            CALL CHECK(NF90_INQUIRE_VARIABLE(INFILEID,OINDX(C),ONAME(C),
     &                 VTYPE,VNDIM,NDIMID,NVATT))
            CALL CHECK(NF90_GET_ATT(INFILEID,OINDX(C),'long_name',MESG))
            CALL CHECK(NF90_GET_ATT(INFILEID,OINDX(C),'units',UNITS))
!            IF ( TRIM(ONAME (C)) .EQ. 'emi_nox' ) THEN
!               OUTVAR(C) = 'NOX'
!            ELSE IF ( TRIM(ONAME (C)) .EQ. 'emi_co' ) THEN
!               OUTVAR(C) = 'CO'
!            ENDIF 
            PRINT*,'Variable: ',ONAME(C),' -- ',
     &              TRIM(UNITS),':',TRIM(MESG)
            PRINT*,'Variable dimension:',VNDIM 
            PRINT*,'Variable dimension id:',NDIMID(1:VNDIM)
            print*,'Variable name: ',OUTVAR(C)
         ENDDO

!... Allocate data buffer ...
         CALL CHECK(NF90_INQ_DIMID(INFILEID,'lon',DIMID))
         CALL CHECK(NF90_INQUIRE_DIMENSION(INFILEID,DIMID,len=NCOL))
         CALL CHECK(NF90_INQ_DIMID(INFILEID,'lat',DIMID))
         CALL CHECK(NF90_INQUIRE_DIMENSION(INFILEID,DIMID,len=NROW))
!         ALLOCATE ( INBUF  ( NCOL, NROW, 1 ),
!     &              ARBUF  ( NCOL, NROW, 1 ),
!     &              STAT = STATUS )
         ALLOCATE ( INBUF  ( NCOL, NROW, 1 ),
     &              STAT = STATUS )
!         IF ( STATUS /= 0 ) STOP "error allocating INBUF/LYBUF arrays"
         IF ( STATUS /= 0 ) STOP "error allocating INBUF array"

         OUTYR = 0   ! set to open file for the first time
      ENDIF  ! End FIRSTIME: just getting variables?

      NSTEP = 1
      PRINT*,'Total timestep:',NSTEP

      ALLOCATE ( TIME(NSTEP), STAT = STATUS )
         IF ( STATUS /= 0 ) 
     &                  STOP "error allocating TIME array"

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
         print*,'idate = ',IDATE
         print*,'jstep = ',JSTEP

!... New file each year ...
! TODO: remove me! just convert this one file!
         IF ( OUTYR .EQ. 0 ) THEN  ! open file only once - bkoo
            JDATE = IDATE
            JTIME = 0 
            print*,'ovars,oname: ', OVARS,ONAME
            print*,'outvar: ', OUTVAR
            CALL OPOUTFILE ( JDATE, JTIME, JSTEP, INFILEID, 
     &                       OVARS, OUTVAR, OUTFILE )
            OUTYR = YR
         ENDIF

9100  FORMAT( 10( A, :, I8, :, 1X ) )
! C is INTEGER counter, OVARS is number of output variables
         DO C = 1, OVARS, 1
            INBUF = 0
!            ARBUF = 0
            CALL CHECK(NF90_INQ_VARID(INFILEID,ONAME(C),VARID)) ! get VID from name
            CALL CHECK(NF90_INQUIRE_VARIABLE(INFILEID,
     &                 VARID,VNAME,
     &                 VTYPE,VNDIM,NDIMID,NVATT))
! Get Cell Areas
!              CALL CHECK(NF90_GET_VAR(ARFILEID,3,
!     &               ARBUF(:,:,1),START=(/1,1,T/))) ! get data

! For 2D data
            IF ( VNDIM == 2 ) THEN  
            print*, 'Writing output data'
              CALL CHECK(NF90_GET_VAR(INFILEID,VARID,
     &               INBUF(:,:,1),START=(/1,1,T/))) ! get data
!              ! Convert from kg(N)/m2-s to tons/yr
!              print*,'NOTE: Converting from kg/m2-s to tons/yr'
!              SEC2YR = 60.0*60.0*24.0*365.0
!              KG2TON = 0.00110231
!              INBUF(:,:,1) = INBUF(:,:,1)*SEC2YR*KG2TON
!              ! Convert from m2 to cell area
!              INBUF(:,:,1) = INBUF(:,:,1)*ARBUF(:,:,1)
              IF ( .NOT. WRITE3(OUTFILE,OUTVAR(C),JDATE,JTIME,
     &              INBUF(:,:,1))) THEN
                  MESG = 'Could not write to "'//TRIM(OUTFILE)//'"'
                  CALL M3EXIT( PROGNAME, JDATE, JTIME, MESG, 2 )
              ENDIF
            ENDIF
         ENDDO

!... Increment time by tstep ...
         CALL NEXTIME ( JDATE, JTIME, JSTEP )
      ENDDO ! end looping timesteps DO T = 1, NSTEP, 1

!... Close netCDF input file ...
      MESG = 'Close input netCDF file: '//TRIM( FNAME )
      CALL M3MESG( MESG )
      CALL CHECK(NF90_CLOSE(INFILEID))


      CALL M3EXIT(PROGNAME,0,0,' ',0) 

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
      
      ENDPROGRAM
