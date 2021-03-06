C     FORTRAN TEMPLATE FOR FILE= 2008N2O_restart.nc                      
      PARAMETER (NVARS=13) !NUMBER OF VARIABLES
C     VARIABLE IDS RUN SEQUENTIALLY FROM 1 TO NVARS= 13
      INTEGER*4 RCODE
      CHARACTER*50 long_name(nvars)
      CHARACTER*50 name(100)
C     ****VARIABLES FOR THIS NETCDF FILE****
C
      REAL*8      N2O                            (  144,   96,   56)
      REAL*8      lon                            (  144)
      REAL*8      lat                            (   96)
      REAL*8      lev                            (   56)
      REAL*8      P0                             
      REAL*8      hyam                           (   56)
      REAL*8      hybm                           (   56)
      REAL*8      hyai                           (   57)
      REAL*8      hybi                           (   57)
      REAL*8      ilev                           (   57)
      REAL*8      PS                             (  144,   96)
      INTEGER*4   date                           
      INTEGER*4   datesec                        
C*************************************
      character*80 input_file
      INTEGER*4 START(10)
      INTEGER*4 COUNT(10)
      INTEGER VDIMS(10) !ALLOW UP TO 10 DIMENSIONS
      CHARACTER*31 DUMMY
C
C      LONG NAMES FOR EACH VARIABLE
C
      data long_name/
     *'N2O                                               ',
     *'longitude                                         ',
     *'latitude                                          ',
     *'hybrid level at layer midpoints (1000*(A+B))      ',
     *'reference pressure                                ',
     *'hybrid A coefficient at layer midpoints           ',
     *'hybrid B coefficient at layer midpoints           ',
     *'hybrid A coefficient at layer interfaces          ',
     *'hybrid B coefficient at layer interfaces          ',
     *'hybrid level at layer interface (1000*(A+B))      ',
     *'Surface Pressure                                  ',
     *'current date as 6 digit integer (YYMMDD)          ',
     *'seconds to complete current date                  '/
C
      write(6,1)
 1    format(' enter your input file')
      read(5,2) input_file
 2    format(a80)
      ilen=index(input_file,'   ')
      ncid=ncopn(input_file(1:ilen-1),0,rcode)
C
C    statements to fill N2O                            
C
      ivarid = ncvid(ncid,'N2O                            ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  10 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  10  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +N2O                            ,RCODE)
C
C    statements to fill lon                            
C
      ivarid = ncvid(ncid,'lon                            ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  20 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  20  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +lon                            ,RCODE)
C
C    statements to fill lat                            
C
      ivarid = ncvid(ncid,'lat                            ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  30 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  30  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +lat                            ,RCODE)
C
C    statements to fill lev                            
C
      ivarid = ncvid(ncid,'lev                            ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  40 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  40  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +lev                            ,RCODE)
C
C    statements to fill P0                             
C
      ivarid = ncvid(ncid,'P0                             ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  50 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  50  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +P0                             ,RCODE)
C
C    statements to fill hyam                           
C
      ivarid = ncvid(ncid,'hyam                           ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  60 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  60  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +hyam                           ,RCODE)
C
C    statements to fill hybm                           
C
      ivarid = ncvid(ncid,'hybm                           ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  70 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  70  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +hybm                           ,RCODE)
C
C    statements to fill hyai                           
C
      ivarid = ncvid(ncid,'hyai                           ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  80 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  80  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +hyai                           ,RCODE)
C
C    statements to fill hybi                           
C
      ivarid = ncvid(ncid,'hybi                           ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO  90 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
  90  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +hybi                           ,RCODE)
C
C    statements to fill ilev                           
C
      ivarid = ncvid(ncid,'ilev                           ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO 100 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
 100  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +ilev                           ,RCODE)
C
C    statements to fill PS                             
C
      ivarid = ncvid(ncid,'PS                             ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO 110 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
 110  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +PS                             ,RCODE)
C
C    statements to fill date                           
C
      ivarid = ncvid(ncid,'date                           ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO 120 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
 120  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +date                           ,RCODE)
C
C    statements to fill datesec                        
C
      ivarid = ncvid(ncid,'datesec                        ',rcode)
      CALL NCVINQ(NCID,ivarid,DUMMY,NTP,NVDIM,VDIMS,NVS,RCODE)
      LENSTR=1
      DO 130 J=1,NVDIM
      CALL NCDINQ(NCID,VDIMS(J),DUMMY,NDSIZE,RCODE)
      LENSTR=LENSTR*NDSIZE
      START(J)=1
      COUNT(J)=NDSIZE
 130  CONTINUE
      CALL NCVGT(NCID,ivarid,START,COUNT,
     +datesec                        ,RCODE)

C
C     following code: checks output code code against current input file
C
C
      call ncinq(ncid,ndims,nvarsc,ngatts,nrecdim,rcode)
      if(nvarsc.ne.nvars) write(6,150)
  150 format('number of variables has changed')
C
      do 220 i=1,nvars
      do 180 j=1,nvarsc
      call ncagtc(ncid,j,'long_name',name(j),50,rcode)
      ilen=index(long_name(i),'   ')
      if(long_name(i)(1:ilen-1).eq.name(j)(1:ilen-1))' go to 220
  180 continue
      write(6,190) name(j)
  190 format('unknown variable ',a50)
      write(6,200)
  200 format('rerun gennet')
      stop
  220 continue
C
      CALL NCCLOS(NCID,RCODE)
C
C
C     HERE IS WHERE YOU WRITE STATEMENTS TO USE THE DATA
C
C
C
      STOP
      END
