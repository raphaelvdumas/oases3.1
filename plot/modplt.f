      SUBROUTINE MODPLT(*,TITLE,OPTS,F,H0,H1,R1,MODQTY,HGT,
     & XLEN,YLEN,NOP,LUEIGF,OPENED,ICURV)

      PARAMETER (IBUFF=51, IBUFF1=IBUFF+1)

      INTEGER OPENED

      CHARACTER*3 XBTYPE, YBTYPE
      CHARACTER*4 TITLE(20), TITLEX, TITLEY, ZZ
      CHARACTER*12 OPTS
      DIMENSION XTS(IBUFF), XTS1(IBUFF1)
      COMMON /PLT/SCALF
      COMMON/XAX/X1,XL,XLEFT,XRIGHT,XSCALE,XINC,DX,
     % X1PL,XDUM4,IXDUM1,XDUM5,XDUM6,DIVX,XVAL(100),NXVAL
      COMMON/XAXC/TITLEX(20),XBTYPE
      COMMON/YAX/Y1,YL,YUP,YDOWN,YSCALE,YINC,DY,
     % Y1PL,YDUM4,IYDUM1,YDUM5,YDUM6,DIVY,YVAL(100),NYVAL,
     % YBOX
      COMMON/YAXC/TITLEY(20),YBTYPE
      COMMON /XYLAST/XLAST,YLAST,AXISX,AXISY,ISGN
      EQUIVALENCE (XTS(1),XTS1(2))
      DATA MODULO/6/
  200 FORMAT(1H ,//,'  WARNING: NEGATIVE DATA VALUE(S) USED TO DEFINE YA
     % XIS OF',/,11X,'  OPTION MODES IS/ARE SET TO ZERO')
  300 FORMAT(1H ,//,'  WRONG YAXIS DEFINITION FOR OPTION MODES ',
     % /,'  PLOT IS NOT EXECUTED.')
  400 FORMAT(1H ,//,'  Y1= ',F8.1,/,'  Y2= ',F8.1)
C
      xold=0E0
      yold=0E0
      X1PL=1.5
      Y1PL=1.
      XORIG=X1PL*2.54
      YORIG=Y1PL*2.54
      XSCALE=ABS(XRIGHT-XLEFT)/XLEN
      YSCALE=ABS(YDOWN-YUP)/YLEN
      XSAVE=XSCALE
      YSAVE=YSCALE
C
      READ(LUEIGF,*)MINMOD
      READ(LUEIGF,*)LI0
      READ(LUEIGF,*)LI1
C
      MAXMOD=MINMOD+MODQTY-1
C
      IF(YUP.EQ.YDOWN)   THEN
      IF(YDOWN.EQ.0.0)   THEN
      YDOWN=H0
      ELSE
      WRITE(6,300)
      WRITE(6,*) ' YUP,YDOWN,YSCALE,YINC '
      WRITE(6,*) YUP,YDOWN,YSCALE,YINC
      STOP
      END IF
      END IF
C
      Y1=YUP
      Y2=YDOWN
C
C
C
      H01=H0+H1
      IF(Y1.GE.0.0)   GO TO 1040
      Y1=0.0
      WRITE(6,200)
 1040 CONTINUE
      IF(Y2.GE.0.0)   GO TO 1080
      Y2=0.0
      WRITE(6,200)
 1080 CONTINUE
C
      IF(Y1.LE.Y2)   GO TO 1120
C
      YMIN=Y2
      YMAX=Y1
      IF(YMAX.GT.H01)   YMAX=H01
      YUP=YMAX
      YDOWN=YMIN
      YREF=H01-YMIN
      GO TO 1160
 1120 CONTINUE
      YMIN=Y1
      YMAX=Y2
C     IF(YMAX.GT.H01)   YMAX=H01
      YUP=YMIN
      YDOWN=YMAX
      YREF=H01-YMAX
 1160 CONTINUE
      IF(YMAX.GT.YMIN)   GO TO 1200
      WRITE(6,300)
      WRITE(6,400) Y1,Y2
      STOP ' ERROR DETECTED IN SUB MODPLT '
 1200 CONTINUE
      HGTCH=(2.0*HGT)/3.0
C   LI0=1 IS FIRST POINT BELOW THE SEA SURFACE
C   LI1=1 IS THE SECOND POINT IN THE SEDIMENT
      H0STEP=H0/LI0
      IF(LI1.GT.0)   H1STEP=H1/LI1

      DO 4000   IMIN=MINMOD,MAXMOD,2*MODULO
      IMAX=IMIN+2*MODULO-1
      IF(IMAX.GT.MAXMOD)   IMAX=MAXMOD
      DO 2800   NM1=IMIN,IMAX,MODULO
      SCALF=1.0
      NM2=NM1+MODULO-1
      IF(NM2.GT.IMAX)   NM2=IMAX
      XSCALE=XSAVE/6.
      YSCALE=YSAVE
CCC
      IF( NOP .EQ. 0)   THEN
CCC
      CALL NEWPLT(NSHEET,TITLE,56,0)
      CALL PLOT(XORIG,YORIG,-3)
      XSCALE=XSAVE/SCALF
      YSCALE=YSAVE/SCALF
      HGT=HGT*SCALF
      AXISX=ABS((XRIGHT-XLEFT)/(XSCALE*2.54))
      AXISY=ABS((YUP-YDOWN)/(YSCALE*2.54))
      AXMAX=MODULO*AXISX
      CALL SYMBOL(0.0,AXISY+HGT/2,HGT,'  F=',0.,4)
      CALL NUMBER(999.,999.,HGT,F,0.,1)
      CALL SYMBOL(999.,999.,HGT,'Hz ',0.,3)
      CALL PLOT(0.,AXISY,3)
      CALL PLOT(AXMAX,AXISY,2)
      CALL SYMBOL(AXMAX-12*HGT,AXISY+HGT/2,HGT,OPTS,0.,12)
      CALL PLOT(AXMAX,AXISY,3)
      CALL PLOT(AXMAX,0.,2)
      CALL PLOT(0.0,0.0,2)
      DX=1.0/(XSCALE*2.54)
      IF(XLEFT.GT.XRIGHT)   DX=-DX
      Y=-0.2
      XCHAR=2.5*HGT
      IF(XLEFT.GE.0.0)   XCHAR=2*HGT
      CALL NUMBER(-XCHAR,Y,HGT,XLEFT,0.,2)
      CALL NUMBER(ABS(XLEFT*DX)-0.3*HGT,Y,HGT,0.,0.,-1)
      CALL PLOT(ABS(XRIGHT-XLEFT)*DX,0.,3)
      CALL PLOT(ABS(XRIGHT-XLEFT)*DX,0.1,2)
      XCHAR=2*HGT
      IF(XRIGHT.LT.0.0)   XCHAR=2.3*HGT
      CALL NUMBER(ABS(XRIGHT-XLEFT)*DX-XCHAR,Y,HGT,XRIGHT,0.,2)
      IF((H0.GT.YMIN).AND.(H0.LT.YMAX))  THEN
C
C   PLOTTING OF WATER-SEDIMENT INTERFACE LINE.
C
      IF(Y1.LT.Y2)  Y=(YMAX-H0)/(YSCALE*2.54)
      IF(Y1.GT.Y2)  Y=(H0-YMIN)/(YSCALE*2.54)
      CALL PLOT(0.,Y,3)
      CALL PLOT(AXMAX,Y,2)
      END IF
      NMODE=NM2-NM1+1
      FNM1=NM1
      FNM2=NM2
      IF(NMODE.GT.1)   GO TO 1600
      N=ALOG10(FNM1)+5+1
      Y=-0.50
      X=(AXMAX-N*HGTCH)/2.
      CALL SYMBOL(X,Y,HGTCH,'MODE',0.,4)
      CALL NUMBER(X+5.0*HGTCH,Y,HGTCH,FNM1,0.,-1)
      GO TO 1700
 1600 CONTINUE
      N=ALOG10(FNM1)+IFIX(ALOG10(FNM2))+6+2
      Y=-0.50
      X=(AXMAX-N*HGT)/2.
      CALL SYMBOL(X,Y,HGT,'MODES',0.,5)
      CALL NUMBER(X+7.0*HGT,Y,HGT,FNM1,0.,-1)
      CALL SYMBOL(999.,999.,HGT,'- ',0.,2)
      CALL NUMBER(999.,999.,HGT,FNM2,0.,-1)
 1700 CONTINUE
      CALL SYMBOL(0.,-0.8,HGT,TITLE,0.,80)
      CALL YAXLIN(HGT)

      XREF=ABS(XLEFT*DX)
      DO 1800   N=1,NMODE
      X=XREF+(N-1)*AXISX
      CALL PLOT(X,0.0,3)
      CALL PLOT(X,AXISY,2)
 1800 CONTINUE
CCC
      END IF
CCC
C
C
C   PLOTTING OF MODE SHAPES STARTS HERE
C
C
      DO 2600   I=NM1,NM2
C
      XTS1(1)=0.0
      IP=3
      K=1-MINMOD+1
      XREF=ABS(XLEFT*DX)+MOD(I-MINMOD,MODULO)*AXISX
C
      DO 2300   I1=1,LI0,IBUFF
      I2=MIN0(I1+IBUFF-1,LI0)
      NPOINT=I2-I1+1
      READ(LUEIGF,*) (XTS(J),J=1,NPOINT)
CCC
      IF( NOP .EQ. 0)   THEN
CCC
      IF(YMIN.LE.H0)   THEN
       IF( (I1.EQ.1).AND.(YMIN.EQ.0.0) )   THEN
        CALL PLOT(XREF,-YMAX*DY,3)
        IP=2
       END IF
       npcnt=0
       DO 2200   J=1,NPOINT
       HW=(I1+J-1)*H0STEP
       IF((HW.GE.YMIN).AND.(HW.LE.YMAX))   THEN
        IF(IP.EQ.3)   THEN
         Y=-(YMAX-YMIN)*DY
         X=XTS1(J)+((XTS1(J+1)-XTS1(J))/H0STEP)*AMOD(HMIN,H0STEP)
         X=XREF + X*DX
         CALL PLOT(X,Y,IP)
         IP=2
         Y=-(YMAX-HW)*DY
         CALL PLOT(X,Y,IP)
        ELSE
         Y=-(YMAX-HW)*DY
         X=XREF + XTS(J)*DX
         if (npcnt.gt.500) then
          call plot(-1.0,-1.0,3)
          call plot(xold,yold,3)
          CALL PLOT(X,Y,IP)
          npcnt=1
         else
          CALL PLOT(X,Y,IP)
          npcnt=npcnt+1
         end if
        END IF
       ELSE
        IF(IP.EQ.2)   THEN
         HW=YMAX
         Y=0.0
         X=XTS(J-1)+((XTS(J)-XTS(J-1))/H0STEP)*AMOD(HW,H0STEP)
         X=XREF + X*DX
         CALL PLOT(X,Y,IP)
         IP=3
         GO TO 2300
        END IF
       END IF
       xold=x
       yold=y
 2200  CONTINUE
      END IF
      XTS1(1)=XTS(NPOINT)
CCC
      END IF
CCC
 2300 CONTINUE
C
      IF(LI1.GT.0)   THEN
C   INITIAL VALUE IN SEDIMENT LAYER
      XTS1(1)= XTS1(1)/R1
      IF((YMIN.LE.H0).AND.(YMAX.GT.H0))   THEN
      X=XREF + XTS1(1)*DX
      IF( NOP .EQ. 0)   CALL PLOT(X,Y,IP)
      xold=x
      yold=y
      END IF
C
      DO 2500   I1=LI0+1,LI0+LI1,IBUFF
      I2=MIN0(I1+IBUFF-1,LI0+LI1)
      NPOINT=I2-I1+1
      READ(LUEIGF,*) (XTS(J),J=1,NPOINT)
CCC
      IF( NOP .EQ. 0)   THEN
CCC
      IF(YMAX.GT.H0)   THEN
       npcnt=0
       DO 2400   J=1,NPOINT
       HS=(I1-LI0+J-1)*H1STEP + H0
       IF((HS.GE.YMIN).AND.(HS.LE.YMAX))   THEN
        IF(IP.EQ.3)   THEN
         Y=-(YMAX-YMIN)*DY
         X=XTS1(J)+((XTS1(J+1)-XTS1(J))/H1STEP)*AMOD(YMIN-H0,H1STEP)
         X=XREF + X*DX
         CALL PLOT(X,Y,IP)
         IP=2
         Y=-(YMAX-HS)*DY
         CALL PLOT(X,Y,IP)
        ELSE
         Y=-(YMAX-HS)*DY
         X=XREF + XTS(J)*DX
         if (npcnt.gt.500) then
          call plot(-1.0,-1.0,3)
          call plot(xold,yold,3)
          CALL PLOT(X,Y,IP)
          npcnt=1
         else
          CALL PLOT(X,Y,IP)
          npcnt=npcnt+1
         end if
        END IF
       ELSE
        IF(IP.EQ.2)   THEN
         HS=YMAX
         Y=0.0
         X=XTS(J-1)+((XTS(J)-XTS(J-1))/H1STEP)*AMOD(HS-H0,H1STEP)
         X=XREF + X*DX
         CALL PLOT(X,Y,IP)
         IP=3
         GO TO 2500
        END IF
CCC
       END IF
CCC
       xold=x
       yold=y
 2400  CONTINUE
      END IF
      XTS1(1)=XTS(NPOINT)
      END IF
 2500 CONTINUE
      END IF
 2600 CONTINUE
C
      IF( NOP .EQ. 0)   CALL PLOT(0.,0.,999)
 2800 CONTINUE
 4000 CONTINUE

      IF( NOP .EQ. 0)   THEN
        OPENED=0 
        ICURV=0
      END IF

      RETURN 1
      END
