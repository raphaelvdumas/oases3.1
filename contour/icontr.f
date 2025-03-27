      SUBROUTINE ICONTR(SD,NPX,NPY,NPXRD,NPYRD,NXIND,NXKAB,
     & NZX,NZY,Z,FREQ,EXTP,FORM,BUFFER,NRANGE,RD)
      PARAMETER (NLEV1=51)
      CHARACTER*3 XBTYPE, YBTYPE, FORM, EXTP, SDPLOT, RDPLOT, BWCOL,
     &            LINEP
      CHARACTER*4 TITLE,TITLEX,TITLEY
      CHARACTER*28 SDUNIT
      CHARACTER*72 WORD
      CHARACTER*80 FILENM,FIGMER
      DIMENSION SECTOR(28), Z(NZX,NZY), BUFFER(NRANGE)
      COMMON /CHFLAG/ BWCOL, LINEP
      COMMON /HSFLAG/ IFIRST,ILAST,CYL,FOM,PRB,SEG,ISEG,
     &                IFR,SDFLAG,NCL
      COMMON /PARA/LABPT,NSM,NDIV,CAY,NARC,NRNG,HGTPT,HGT,
     & LABC(51),LWGT(51)
      COMMON /PARAC/TITLE(20), SDPLOT, RDPLOT
      COMMON /SNAPSHOT/ SCFAC
      COMMON /STEP/ XSTEP, YSTEP
      COMMON /XAX/X1,XL,XLEFT,XRIGHT,XSCALE,XINC,DX,
     & X1PL,XLPL,NX,X1GRID,XLGRID,DIVX,XVAL(100),NXVAL
      COMMON /XAXC/TITLEX(20),XBTYPE
      COMMON /YAX/Y1,YL,YUP,YDOWN,YSCALE,YINC,DY,
     & Y1PL,YLPL,NY,Y1GRID,YLGRID,DIVY,YVAL(100),NYVAL
      COMMON /YAXC/TITLEY(20),YBTYPE
      COMMON /ZAX/ZMIN,ZMAX,ZINC,NLEV,ZLEV(NLEV1)
      DATA FIGMER(1:20)/'Figure of Merit (dB)'/
C
  200 FORMAT(20A4)
  201 FORMAT(1X,/,' ****  TITLE ON PLOT :   ',/,
     & 1X,20A4,/)
  300 FORMAT(A80)
  360 FORMAT(A72)
  400 FORMAT(F15.4)
  420 FORMAT(F15.4,3X,A28)
  520 FORMAT(1X,/,' ***  SIGMA = ',E10.3,' *** ',/)
  540 FORMAT(1X,' EXECUTION TERMINATED BEACUSE OF ARRAY SIZE',
     & ' LIMITATION.',/,' PROBLEM DETECTED IN SUB ICONDR .')
  560 FORMAT(1X,' WARNING : ACCEPTABLE VALUES FOR NDIV ARE 1,2 AND 4 ',/,
     & '  ACTUAL VALUE IS ',I3,'. PLOTTING IS DONE WITH NDIV = 1 ')
  600 FORMAT(1X,'NLEV = ',' THIS PROGRAM ALLOWS ONLY 51 LEVELS FOR',
     & ' CONTOURING',/,'EXECUTION TERMINATED')
  700 FORMAT(1X,' TOO MANY GRID POINTS (NX,NY TOO LARGE)',/,
     & ' EXECUTION TERMINATED BECAUSE OF ARRAY SIZE LIMITATIONS',/)
C
      XBTYPE='LIN'
      YBTYPE='LIN'
C
      READ(55,200)TITLE
      WRITE(6,201)TITLE
C
      READ(55,300)FILENM
      IF (IFIRST.GT.0) THEN
       IFIRST=0
       CALL FILETYPE(FORM,FILENM,55,17)
      END IF
C
      READ(55,200)TITLEX
      READ(55,400)X1
      READ(55,400)XL
      RMAX=MAX(X1,XL)
      READ(55,400)XLEFT
      READ(55,400)XRIGHT
      READ(55,360) WORD
      CALL AXLEN(XBTYPE,XLEFT,XRIGHT,WORD,XSCALE,XLEN,55)
C      READ(55,400)XSCALE
      READ(55,400)XINC
      XINC=SIGN(XINC,XRIGHT-XLEFT)
C
      READ(55,200)TITLEY
      READ(55,400)YUP
      READ(55,400)YDOWN
      READ(55,360) WORD
      CALL AXLEN(YBTYPE,YUP,YDOWN,WORD,YSCALE,YLEN,55)
C      READ(55,400)YSCALE
      READ(55,400)YINC
      YINC=ABS(YINC)
      IF( YUP .GT. YDOWN )   YINC=-YINC
C
      READ(55,400)DUMMY
      NPX=NINT(DUMMY)
C
      XSTEP=ABS(XL-X1)/(NPX-1)
      npxrd=npx
C
      IF(EXTP.EQ.'GRD')   THEN
       X1GRID=XLEFT
       XLGRID=XRIGHT
      ELSE
       IF(XLEFT .LT. XRIGHT)   THEN
        X1GRID=MAX(MIN(X1,XL),XLEFT)
        XLGRID=MIN(MAX(X1,XL),XRIGHT)
       ELSE
        X1GRID=MIN(XLEFT,MAX(X1,XL))
        XLGRID=MAX(XRIGHT,MIN(X1,XL))
       END IF
      END IF
C
      READ(55,400)DUMMY
      NPY=NINT(DUMMY)
      READ(55,400)DIVX
      IF(DIVX.EQ.0.0)DIVX=1.0E-3
      READ(55,400)DIVY
      IF(DIVY.EQ.0.0)DIVY=1.0
      READ(55,400)FLAGRC
      READ(55,400)YL
      READ(55,400)Y1
      YMIN=MIN(Y1,YL)
      YMAX=MAX(Y1,YL)
      YAXMIN=MIN(YUP,YDOWN)
      YAXMAX=MAX(YUP,YDOWN)
      YGRIDMIN=MAX(YMIN,YAXMIN)
      YGRIDMAX=MIN(YMAX,YAXMAX)
      YSTEP=(Y1-YL)/(NPY-1)
      IF(EXTP.EQ.'GRD')   THEN
       Y1GRID=YDOWN
       YLGRID=YUP
      ELSE
       IF(YUP .LT. YDOWN)   THEN
        YLGRID=YGRIDMIN
        Y1GRID=YGRIDMAX
       ELSE
        YLGRID=YGRIDMAX
        Y1GRID=YGRIDMIN
       END IF
      END IF
      NPYRD=NPY 
C
C      READ(55,420) SD, SDUNIT
      CALL NOVALUE(SDFLAG,SD,55,SDUNIT)
      SDPLOT='m  '
      CALL UNIT(SDUNIT,SDPLOT)
      READ(55,400)DUMMY
      NX=nint(DUMMY)
      READ(55,400)DUMMY
      NY=nint(DUMMY)
      DY=(YLGRID-Y1GRID)/(NY-1)
      IF(NX*NY. GT. NZX*NZY)   THEN
       WRITE(6,700)
       STOP
      END IF
      READ(55,400)FREQ
      DX=(XLGRID-X1GRID)/(NX-1)
      NX10=NX/10
      NXIND=MIN0(57,NX)
      NXKAB=MAX0(7,NX10+2)
      READ(55,*) RD
      READ(55,400)CAY
      READ(55,400)DUMMY
      NRNG=NINT(DUMMY)
C SECTION TO DETERMINE THE CONTOURLEVELS (ARRAY ZLEV).
      READ(55,400)ZMIN
      READ(55,400)ZMAX
      READ(55,400)ZINC
C TYPE 4 INFORMATION
      READ(55,400)X1PL
      READ(55,*) SIGMA
      READ(55,400)Y1PL
      READ(55,400)DUMMY
      NSM=NINT(DUMMY)
      READ(55,400)HGTPT
      READ(55,400)HGT
      READ(55,400)DUMMY
      LABPT=NINT(DUMMY)
      READ(55,400)DUMMY
      NDIV=NINT(DUMMY)
      IF( (NDIV.NE.1) .AND.
     &    (NDIV.NE.2) .AND.
     &    (NDIV.NE.4) )     THEN
       WRITE(6,560) NDIV
       NDIV=1
      END IF
      READ(55,400)DUMMY
      NARC=NINT(DUMMY)
      READ(55,400)DUMMY
      LABC(1)=NINT(DUMMY)
      READ(55,400)DUMMY
      LWGT1=NINT(DUMMY)

CCCCCC      CALL BOTTOM

      CALL REDATA(Z,NPX,NPY,NPXRD,1,NPYRD,NPYRD,SECTOR,FORM,FLAGRC)
C      CLOSE(17)
      NPX=NPXRD
      NPY=NPYRD
c
C
      IF(CYL.GT.0.0)   THEN
       PLANE=SECTOR(5)
       RSTEP=SECTOR(6)
       IF(ABS(RSTEP-XSTEP).GT.RSTEP*.10E-2)
     & WRITE(6,*)' SUB ICONTR,WARNING, XSTEP.NE.RSTEP',XSTEP,RSTEP    
       CALL CYLSPR(Z,NPXRD,NPYRD,PLANE,RSTEP,X1,XL)
      END IF
C
      IF((X1-XL)*(XLEFT-XRIGHT) .LT. 0.0)   THEN
       CALL XREV(Z,NPXRD,NPYRD)
       T=X1
       X1=XL
       XL=T
      END IF
C
      IF(FOM.GT.0.)   THEN
       IF(NRANGE .LT. NPXRD)   THEN
        WRITE(6,540)
        STOP
       END IF
       DO 2400   I=1,5
       I1=(I-1)*4 + 1
       TITLEX(I)=FIGMER(I1:I1+3)
 2400  CONTINUE
       DO 2600   I=6,20
       TITLEX(I)='    '
 2600 CONTINUE
       WRITE(6,520) SIGMA
       CALL STATIST(Z,NPXRD,NX,NPYRD,ZMIN,ZMAX,ZINC,SIGMA,
     & RMAX,BUFFER)
       DIVX=1.0
       XAXLGT=ABS(XLEFT-XRIGHT)/XSCALE
       XLEFT=ZMIN
       X1=ZMIN
       X1GRID=ZMIN
       XRIGHT=ZMAX
       XL=ZMAX
       XLGRID=ZMAX
       XINC= SIGN(5.,XRIGHT-XLEFT)
       XSCALE=ABS(XLEFT-XRIGHT)/XAXLGT
       ZMIN=10.
       ZMAX=100.
       ZINC=10.
      ELSE IF(PRB.GT.0.0)   THEN
       CALL PROBAB(Z,NPXRD,NX,NPYRD,ZMIN,ZMAX,ZINC,SIGMA,
     & RMAX,BUFFER)
       ZMIN=0.1
       ZMAX=1
       ZINC=.1
      END IF
      IF( (FOM+PRB .GT. 0.) .AND. (BWCOL .NE. 'COL') )   THEN
       ZMIN= ZMIN + ZMIN
       ZINC= ZINC + ZINC
      END IF
C
      CALL ZZLEV(NLEV,NLEV1,ZLEV,ZMIN,ZMAX,ZINC,
     & LABC,LWGT,LWGT1)
      RETURN
      END
