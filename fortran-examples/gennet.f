C
C     PROGRAM GENNET.FOR
C
C     Test program to read any netCDF file
C                                                     Barry Schwartz
C                                                     October 1993
c                                                     modified Apr 1996
C     
C
C     This program will ask the user for the name of a netcdf file
C     to read. It will open that file and using the proper netCDF
C     calls, get info on the variables and their dimensions. It then
C     generates a FORTRAN program that can be used to actually read the
C     netCDF file and fills the variables with data. This program
C     can be used to read ANY netCDF file. The user only has to
C     write fortran statements to print the data or pass to another
C     program. Once you have generated a program, you may use it
C     to read any file of that data type; i.e., the program is general
C     until the powers to be change variable attributes. 
C    
C     to compile: f77 gennet.for /usr/local/netcdf/lib/libnetcdf.a
C       
C
      include 'netcdf.inc' !THIS INCLUDE FILE CONTAINS CONSTANTS,ETC
C
      PARAMETER (MVRLEN=3) !MAX NUMBER OF VALID-RANGE VALUES
      PARAMETER (MTLEN=80) !MAX LENGTH OF TITLE ATTRIBUTES
      INTEGER NCID,RCODE,NDIMS,NVARS,NATTS,RECDIM,DIMID,VARID
      INTEGER VARTYP(100),VDIMS(100),vvdims(100,10),NVATTS(100)
      CHARACTER*31 DIMNAM(100) !ARRAY HOLDING DIMENSION NAMES
      CHARACTER*31 VARNAM(100) !ARRAY HOLDING VARIABLE NAMES
      CHARACTER*31 ATTNAM(100,10) !array holding attribute name
      character*50 long_name(100)
      INTEGER DIMSIZ(100) !ARRAY HOLDING DIMENSION SIZES
      INTEGER nvdims(100)
      INTEGER ATTYPE(100,10),ATTLEN(100,10)
C                       !NOTE MAX NUMBER OF VARIABLES IS 100
C                       !     MAX NUMBER OF ATTRIBUTES PER VAR=10 
C      INTEGER START(50,10),COUNT(50,10) !ALLOW 50 VARIABLES WITH 10 DIMS 
      CHARACTER*11 AVARTYP(6),AVT(100)
      CHARACTER*72 INPUT_FILE
      DATA AVARTYP /'LOGICAL*1','CHARACTER*1','INTEGER*2',
     +'INTEGER*4','REAL*4','REAL*8'/  
c
C     
      open(unit=10,file='readnet.for',status='unknown')
c 
      WRITE(6,5)
    5 FORMAT(' ENTER NETCDF FILE NAME')
      READ(5,6) INPUT_FILE
    6 FORMAT(A72)
C
C     OPEN NETCDF FILE

      NCID=NCOPN(INPUT_FILE,NCNOWRIT,RCODE)
C
C     write(6,10) NCID,RCODE
  10  format('ncid= ',i6,1x,' rcode= ',i5)
c_________________________________________________________________
C   ***inquire about the number of dimensions, varaibles, attributes
c          DIMENSION IDS RUN SEQUENTIALLY FROM 1 TO NDIMS
C
      CALL NCINQ(NCID,NDIMS,NVARS,NATTS,RECDIM,RCODE)
c
C     WRITE(6,20) NDIMS,NVARS,NATTS,RECDIM,RCODE
C   20 FORMAT('NDIMS= ',I3,' NVARS= ',I3,' NATTS= ',I3,
C     1'RECDIM= ',I6,' RCODE FROM NCINQ= ',I5)
c 
c   ***now store the dimension names and sizes in arrays
c
      DO 100 I=1,NDIMS !NUMBER OF DIMENSIONS RETURNED FROM NCINQ
      DIMID=I
      CALL NCDINQ(NCID,DIMID,DIMNAM(I),DIMSIZ(I),RCODE)
C
C     DIMENSION IDS ARE I, I.E, 1,NDIMS       
C     DIMNAM ARE DIMENSION NAMES (CHARACTER IDS)
C     DIMSIZ IS THE SIZE OF EACH DIMENSION
C
C     RECDIM IS THE ID OF THE RECORD DIMENSION
C
      IF(RECDIM.NE.-1) NUMRECS=DIMSIZ(RECDIM)
      IF(RCODE.NE.0) THEN
C                    WRITE(6,75) I
   75 FORMAT(' NONE ZERO RETURN CODE: DIMENSION ID= ',I3)
                     STOP 80
                     ENDIF
C     WRITE(6,70) I,DIMNAM(I),DIMSIZ(I)
   70 FORMAT(' DIMENSION ID= ',I3,' NAME= ',A31,' SIZE= ',I3) 
  100 CONTINUE
C
C     DONE 
C___________________________________________________________________
C                        VARIABLES
C
C     VARIABLES LIKE DIMENSIONS..RUN SEQUENTIALLY FROM 1 TO NVARS
      DO 200 I=1,NVARS 
      VARID=I
c
c     get long_names
c
      call ncagtc(ncid,i,'long_name',long_name(i),mtlen,rcode)
C
C     NCVINQ gets vaiable names, their types and their shapes
C
      CALL NCVINQ(NCID,VARID,VARNAM(I),VARTYP(I),NVDIMS(I),
     +VDIMS,NVATTS(I),RCODE)
c
c     BE CAREFUL...VDIMS IS AN ARRAY (SIZE NVDIMS(I) THUS THE USE OF 2ND ARRAY
      IF(NVDIMS(I).NE.0) THEN 
      DO 175 K=1,NVDIMS(I)
      VVDIMS(I,K)=VDIMS(K) !VVDIMS CONTAINS THE DIMENSION ID'S
  175 CONTINUE
                          ENDIF  
C  
C     VARNAM=VARIABLE NAMES
C     VARTYP=VARIABLE TYPES
C     NVDIMS=NUMBER OF DIMENSIONS FOR VARIABLE
C     VVDIMS= NVDIMS DIMENSION IDS FOR THIS VARIABLE
C     NVATTS=NUMBER OF ATTRIBUTES FOR VARIABLE
C
C     WRITE(6,150) VARID,VARNAM(I),VARTYP(I),NVDIMS(I),NVATTS(I),
C    +(vvdims(i,k),k=1,nvdims(i))
  150 FORMAT(/,' VAR ID= ',I2,' VARNAM= ',A10,' VARTYP= ',I1,
     +' NVDIMS= ',I1,'NUM ATTS=',i2,' vdims= ',<nvdims(i)>i3)
  200 CONTINUE
C
C
C     DONE WITH VARIABLES....
C_____________________________________________________________________
C                            NOW GET INFO ON THE VARIABLE'S ATTRIBUTES
C
      DO 300 I=1,NVARS !GET ATTRIBUTES FOR ALL VARIABLES
      VARID=I
      DO 250 J=1,NVATTS(I)
      CALL NCANAM(NCID,VARID,J,ATTNAM(I,J),RCODE) !get attribute names
C
C     GET ATTRIBUTE TYPES AND LENGTH 
      CALL NCAINQ(NCID,VARID,ATTNAM(I,J),ATTYPE(I,J),ATTLEN(I,J),
     +RCODE)
C
C     GET ATTRIBUTE VALUES; BE CAREFUL FIRST MUST KNOW IF CHAR OR NUMBER      
C
C      IF(ATTYPE(I,J).EQ.2) THEN
C                           IF(ATTLEN(I,J).GT.MTLEN) THEN
C                           WRITE(6,245) 
C  245 FORMAT(' PROBLEM WITH ATTRIBUTE NAME: TOO LONG')
C                           STOP
C                                                    ENDIF           
C      CALL NCAGTC(NCID,VARID,ATTNAM(I,J),ATTIT(I,J),MTLEN,RCODE)
C                            ENDIF
C      IF(ATTYPE(I,J).NE.2) THEN
C      CALL NCAGT(NCID,VARID,ATTNAM(I,J),VRVAL(I,J),RCODE)  
  250 CONTINUE
C
C      WRITE(6,275) VARNAM(I),(J,ATTNAM(I,J),ATTYPE(I,J),ATTLEN(I,J),
C     1J=1,NVATTS(I))
  275 FORMAT(/,' VARIABLE= ',A31,
     +<NVATTS(I)>(/,' ATTRIBUTE #',I2,' IS: ',A31,'TYPE= ',I3,
     +' LEN= ',I3))      
C
C     END OF ATTRIBUTE CALLS
C    
  300 CONTINUE 
C
C****************************************************************
C              ****DONE NOW GENERATE FORTRAN PROGRAM INTERFACE*****
C
      DO 500 I=1,NVARS
C
      VARID=I
      AVT(I)=AVARTYP(VARTYP(VARID)) !AVT IS THE CHARACTER NAME OF VARTYP
  500 CONTINUE
C
C     NOW GENERATE FORTRAN TEMPLATE WITH VARIABLE TYPES, NAMES AND DIMS
C                          ALLOW VARIABLEs TO HAVE 4 DIMENSIONS
c
      write(10,510) INPUT_FILE
  510 FORMAT('C     FORTRAN TEMPLATE FOR FILE= ',A40)
c     write(10,515)
c 515 format(6x,'INCLUDE',1H','netcdf.inc',1H')
      WRITE(10,550) NVARS
  550 FORMAT(6X,'PARAMETER (NVARS=',I2,')',' !NUMBER OF VARIABLES')
      IF(RECDIM.NE.-1) WRITE(10,554) dimsiz(recdim) 
  554 FORMAT(6X,'PARAMETER (NREC=',I6,')   !CHANGE THIS TO GENERALIZE')
      WRITE(10,575) NVARS
  575 FORMAT('C     VARIABLE IDS RUN SEQUENTIALLY FROM 1 TO NVARS=',I3)
      WRITE(10,576)
  576 FORMAT(6X,'INTEGER*4 RCODE')
C
C      WRITE(6,576)
C 576 FORMAT(6X,'CHARACTER*40 INPUT_FILE')
      IF(RECDIM.NE.-1) WRITE(10,577) 
  577 FORMAT(6X,'INTEGER*4 RECDIM')
      write(10,578)
  578 format(6x,'CHARACTER*50 long_name(nvars)')
      write(10,584)
  584 format(6x,'CHARACTER*50 name(100)')

      write(10,579)
c
  579 format('C     ****VARIABLES FOR THIS NETCDF FILE****',
     1/,'C')
      DO 600 I=1,NVARS
      VARID=I
C
      IF(NVDIMS(VARID).EQ.0) WRITE(10,582) AVT(VARID),VARNAM(VARID)
  582 format(6x,a,1x,a)     
C      
      IF(NVDIMS(VARID).EQ.1) THEN ! 1single dimension variable
      IF(RECDIM.NE.-1) THEN 
                       IF(VVDIMS(VARID,1).EQ.RECDIM)
     1                 WRITE(10,580) AVT(VARID),VARNAM(VARID)
  580                  FORMAT(6x,A,1X,A,'(NREC)')
                       IF(VVDIMS(VARID,1).NE.RECDIM)	
     1                 WRITE(10,583) AVT(VARID),VARNAM(VARID),
     1                 DIMSIZ(VVDIMS(VARID,1))
  583                  FORMAT(6X,A,1X,A,'(',I5,')')                    
                       ENDIF 
      IF(RECDIM.EQ.-1) WRITE(10,581) AVT(VARID),VARNAM(VARID),
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID))
  581 FORMAT(6X,A,1X,A,'(',I5,')')
                             ENDIF 
      IF(NVDIMS(VARID).EQ.2) THEN ! double dimension variable
      IF(RECDIM.NE.-1) WRITE(10,585) AVT(VARID),VARNAM(VARID),
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID)-1)
  585 FORMAT(6X,A,1X,A,'(',I5,',NREC)')
      IF(RECDIM.EQ.-1) WRITE(10,586) AVT(VARID),VARNAM(VARID),
c     +(DIMSIZ(VVDIMS(VARID,J)),J=NVDIMS(VARID),1,-1)
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID))

  586 FORMAT(6X,A,1X,A,'(',I5,',',I5,')') 
                             ENDIF
      IF(NVDIMS(VARID).EQ.3) THEN ! triple dimension variable
      IF(RECDIM.NE.-1) WRITE(10,590) AVT(VARID),VARNAM(VARID),
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID)-1)
C     +(DIMSIZ(VVDIMS(VARID,J)),J=NVDIMS(VARID)-1,1,-1)
  590 FORMAT(6X,A,1X,A,'(',I5,',',I5,',NREC)')
      IF(RECDIM.EQ.-1) WRITE(10,591) AVT(VARID),VARNAM(VARID),
C     +(DIMSIZ(VVDIMS(VARID,J)),J=NVDIMS(VARID),1,-1)
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID))
  591 FORMAT(6X,A,1X,A,'(',I5,',',I5,',',I5,')')
                             ENDIF
      IF(NVDIMS(VARID).EQ.4) THEN !variable with 4 dimensions (rare)
      IF(RECDIM.NE.-1) WRITE(10,595) AVT(VARID),VARNAM(VARID),
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID)-1)
C     +(DIMSIZ(VVDIMS(VARID,J)),J=NVDIMS(VARID)-1,1,-1) 
  595 FORMAT(6X,A,1X,A,'(',I5,',',I5,',',I5,',NREC)')
      IF(RECDIM.EQ.-1) WRITE(10,596) AVT(VARID),VARNAM(VARID),
C     +(DIMSIZ(VVDIMS(VARID,J)),J=NVDIMS(VARID),1,-1)
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID))
  596 FORMAT(6X,A,1X,A,'(',I5,',',I5,',',I5,',',I5,')')
                             ENDIF
      IF(NVDIMS(VARID).EQ.5) THEN
      IF(RECDIM.NE.-1) WRITE(10,597) AVT(VARID),VARNAM(VARID),
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID)-1)
 597  FORMAT(6X,A,1X,A,'(',I5,',',I5,',',I5,',',I5,',NREC)')
 598  FORMAT(6X,A,1X,A,'(',I5,',',I5,',',I5,',',I5,',',I5,')')
      IF(RECDIM.EQ.-1) WRITE(10,598) AVT(VARID),VARNAM(VARID),
     +(DIMSIZ(VVDIMS(VARID,J)),J=1,NVDIMS(VARID))
                              ENDIF
C
  600 CONTINUE
      write(10,602)
  602 format('C*************************************')
      write(10,603)
 603  format(6x,'character*80 input_file')
      write(10,605)
  605 format(6x,'INTEGER*4 START(10)',/,6X,'INTEGER*4 COUNT(10)')
      WRITE(10,620)
  620 FORMAT(6X,'INTEGER VDIMS(10) !ALLOW UP TO 10 DIMENSIONS')
      WRITE(10,621)
  621 FORMAT(6X,'CHARACTER*31 DUMMY')

C     WRITE OUT THE STATEMENTS TO DECLARE START AND COUNT FOR EACH VARIABLE
C      DO 624 I=1,NVARS
C      WRITE(10,622) I,NVDIMS(I)
C  622 FORMAT(6X,'INTEGER*4 START',I2.2,'(',I1,')')
C      WRITE(10,623) I,NVDIMS(I)
C  623 FORMAT(6X,'INTEGER*4 COUNT',I2.2,'(',I1,')')
c
C  624 CONTINUE
C
C     generate data statements with variable ids and types and names
c
C     WRITE(10,750)
C 750 FORMAT(6X,'DATA VARS/')
C      WRITE(10,775) (VARNAM(I),I=1,NVARS) !check this
C  775 FORMAT(<NVARS-1>(5X,'+',1H',A31,2H',/),5X,'+',1H',A31,2H'/)
C      WRITE(10,778)
C  778 FORMATM(6X,'DATA VARTYP/')
C      WRITE(10,779) (VARTYP(I),I=1,NVARS)
C  779 FORMAT(5X,'+',<NVARS-1>(I1,','),I1,'/')
C      WRITE(10,780) 
C  780 FORMAT(6X,'DATA NVDIMS/')
C      WRITE(10,790) (NVDIMS(I),I=1,NVARS)
C  790 FORMAT(5X,'+',<NVARS-1>(I1,','),I1,'/')
C      WRITE(10,805)
C  805 FORMAT(6X,'DATA DIMSIZ/')
C      WRITE(10,810) (DIMSIZ(I),I=1,NDIMS)
C  810 FORMAT(5X,'+',<NDIMS-1>(I5,','),I5,'/')
C      GENERATE START AND COUNT DATA ARRAYS
c
C     generate statements to CREATE DATA STATEMENTS FOR START AND COUNT
c
C      DO 875 I=1,NVARS
C      IF(NVDIMS(I).EQ.1) THEN
C      WRITE(10,829) I,START(I,1)
C  829 FORMAT(6X,'DATA START',I2.2,'/',I1,'/')
C      WRITE(10,830) I,COUNT(I,1)
C  830 FORMAT(6X,'DATA COUNT',I2.2,'/',I5,'/')
C                           ELSE
C      WRITE(10,831) I,(START(I,J),J=1,NVDIMS(I))
C  831 FORMAT(6X,'DATA START',I2.2,'/',<NVDIMS(I)-1>(I1,','),
C     +I1,'/')
C      WRITE(10,835) I,(COUNT(I,J),J=1,NVDIMS(I))
C  835 FORMAT(6X,'DATA COUNT',I2.2,'/',<NVDIMS(I)-1>(I5,','),
C     +I5,'/')
C                           ENDIF
C
C  875 CONTINUE
C
c     write an array of long_names
c
      write(10,889)
 889  format('C',/,'C      LONG NAMES FOR EACH VARIABLE',/,'C')
      write(10,890) 
 890  format(6x,'data long_name/')
      do 895 i=1,nvars-1
      write(10,894) long_name(i)
 894  format(5x,'*',1h',a50,1h',',')
 895  continue
      write(10,896) long_name(nvars)
 896  format(5x,'*',1h',a50,1h','/',/,'C')
c
C     write statement to open file
c      WRITE(10,1000) INPUT_FILE
c 1000 FORMAT(6X,'NCID=NCOPN(',1H',A40,1H',/,5x,'+',
c     +',NCNOWRIT,RCODE)')
c
      write(10,900)
 900  format(6x,'write(6,1)')
      write(10,910)
 910  format(' 1',4x,'format(',1h',' enter your input file',1h',')')
      write(10,920)
 920  format(6x,'read(5,2) input_file')
      write(10,930)
 930  format(' 2',4x,'format(a80)')
      write(10,940)
 940  format(6x,'ilen=index(input_file,',1h','   ',1h',')')
      write(10,950)
 950  format(6x,'ncid=ncopn(input_file(1:ilen-1),0,rcode)')
c
      
C     get info on the record dimension for this file
      IF(RECDIM.NE.-1) THEN
      WRITE(10,1001)
 1001 FORMAT(6X,'CALL NCINQ(NCID,NDIMS,NVARS,NGATTS,RECDIM,RCODE)')
      WRITE(10,1002)
 1002 FORMAT(6X,'CALL NCDINQ(NCID,RECDIM,DUMMY,NRECS,RCODE)')
      WRITE(10,1003)
 1003 FORMAT('C     !NRECS! NOW CONTAINS NUM RECORDS FOR THIS FILE')
                       ENDIF   
c      
c*****************************************************
c
c     GET INFO ON THE DIMENSIONS
C
C     recdim will contain the id of the record dimension
C     NOW READY TO GENERATE CALL STATEMENTRS TO FILL VARIABLES WITH
c     VALUES
c
C     in order to make the generated program usable, we need info
C     on the dimensions of the variables. If we do this in the pgm,
C     the only variable not with a constant dimension is the record
c     variable.
c     
      DO 1500 I=1,NVARS
      write(10,1010) varnam(i)

 1010 format('C',/,'C    statements to fill ',a31,/,'C') 
      LENSTR=1
      K=0
C     generate code to get the variable id from its name to be safe
c
      write(10,1012) varnam(i)
 1012 format(6x,'ivarid = ncvid(ncid,',1H',a31,1H',',rcode)')
      if(rcode.ne.0) then
                     write(6,1013) varnam(i)
 1013 format(' something has changed in this data: rerun gennet')
                     stop
                     endif
c                
      WRITE(10,1015) 
 1015 FORMAT(6X,'CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,',
     1'VDIMS,NVS,RCODE)')
C     here we get number of sdims and their ids nvdim and vdims
      WRITE(10,1018)
 1018 FORMAT(6X,'LENSTR=1')
      II=I*10
      WRITE(10,1020) II
 1020 FORMAT(6X,'DO ',I3,' J=1,NVDIM')
      WRITE(10,1025)
C     here we get the size of each nvdim dimension in ndsize
 1025 FORMAT(6X,'CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)')
      WRITE(10,1030)
 1030 FORMAT(6X,'LENSTR=LENSTR*NDSIZE')
      WRITE(10,1035) 
 1035 FORMAT(6X,'START(J)=1',/,6X,'COUNT(J)=NDSIZE')
      WRITE(10,1040) II
 1040 FORMAT(1X,I3,'  CONTINUE')
c      DO 1100 J=1,NVDIMS(I)
C      LENSTR= LENSTR*COUNT(I,J) !NEEDED FOR CHARACTER VARIABLES
C      START(I,J)=1
C      INDEX=VVDIMS(I,J)
C      COUNT(I,J)=DIMSIZ(INDEX)
c      WRITE(10,1025) J,START(I,J),J,COUNT(I,J)
c 1025 FORMAT(6X,'START(',I1,')=',I5,/,6X,'COUNT(',I1,')=',I5) 
C 1100 CONTINUE      
      IF(VARTYP(I).EQ.2) THEN !CHARACTER VAIABLES
      WRITE(10,1250) VARNAM(I)
 1250 FORMAT(6X,'CALL NCVGTC(NCID,ivarid,START,COUNT',
     1',',/,5x,'+',A31,',LENSTR,RCODE)')
                                           ELSE
      WRITE(10,1350) VARNAM(I)
 1350 FORMAT(6X,'CALL NCVGT(NCID,ivarid,START,COUNT',
     1',',/,5x,'+',A31,',RCODE)')
                                           ENDIF
 1500 CONTINUE
C     
c     write code to check the nlong_names against those in the data array
c     and to check to see if number of variables has changed
c
      write(10,1501)
 1501 format(/,'C',/,'C',5x,'following code: checks output code code',
     *' against current input file',/,'C')
c
      write(10,1502)
 1502 format('C',/,6x,
     *'call ncinq(ncid,ndims,nvarsc,ngatts,nrecdim,rcode)')
      n1 = (i+1)*10
      write(10,1503) n1
 1503 format(6x,'if(nvarsc.ne.nvars) write(6,',i3,')')
      write(10,1504) n1
 1504 format(2x,i3,1x,'format(',1h','number of variables has changed',
     *1h',')')
c
      n8=(i+8)*10
      write(10,1505) n8
 1505 format('C',/,6x,'do ',i3,' i=1,nvars')
      n4=(i+4)*10
      write(10,1508) n4
 1508 format(6x,'do ',i3,' j=1,nvarsc')
      write(10,1510)
 1510 format(6x,'call ncagtc(ncid,j,',1h','long_name',1h',
     *',name(j),50,rcode)')
      write(10,1511)
 1511 format(6x,'ilen=index(long_name(i),',1h','   ',1h',')')
      write(10,1515) n8
 1515 format(6x,'if(long_name(i)(1:ilen-1).eq.name(j)(1:ilen-1))'
     *' go to ',i3)
      write(10,1520) n4
 1520 format(2x,i3,1x,'continue')
      n5=(i+5)*10
      write(10,1525) n5
 1525 format(6x,'write(6,',i3,')',' name(j)')
      write(10,1530) n5
 1530 format(2x,i3,1x,'format(',1h','unknown variable ',1h',',a50)')
      n6=(i+6)*10
      write(10,1535) n6
 1535 format(6x,'write(6,',i3,')')
      write(10,1540) n6
 1540 format(2x,i3,1x,'format(',1h','rerun gennet',1h',')')
      write(10,1550)
 1550 format(6x,'stop')
      write(10,1555) n8
 1555 format(2x,i3,1x,'continue')
c
      
      write(10,1599)
 1599 format('C',/,6x,'CALL NCCLOS(NCID,RCODE)',/,'C')
c
      WRITE(10,1700)
      WRITE(10,1600)
 1600 FORMAT('C     HERE IS WHERE YOU WRITE STATEMENTS TO USE THE DATA')
      WRITE(10,1700)
 1700 FORMAT('C')
      WRITE(10,1700)
      WRITE(10,1700)
      WRITE(10,1800)
 1800 FORMAT(6X,'STOP')
      WRITE(10,1900)
 1900 FORMAT(6X,'END')
C
C
      WRITE(6,2000)
 2000 FORMAT(' ***GENERATED FORTRAN PGM CALLED readnet.for***')
C
      STOP
      END
