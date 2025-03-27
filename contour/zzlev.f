      SUBROUTINE ZZLEV(NLEV,NLEV1,ZLEV,Z1,Z2,Z3,LABC,LWGT,LWGT1)

      DIMENSION ZLEV(*), LABC(*), LWGT(*)
   
  600 FORMAT(1X,' NUMBER OF CONTUR LEVELS = ',I12,/,
     & ' THIS PROGRAM ALLOWS FOR A MAXIMUM OF',
     & ' 51 CONTOUR LEVELS ONLY ',/,' EXECUTION IS TERMINATED')

      ZMIN=MIN(Z1,Z2)
      ZMAX=MAX(Z1,Z2)
      ZINC=ABS(Z3)
      IF(ABS(ZINC).GT.0.0)   GO TO 2000
      NLEV=1
      ZLEV(1)=ZMIN
      GO TO 5000
 2000 CONTINUE
      NLEV=NINT((ZMAX-ZMIN)/ZINC) + 1
      IF(NLEV.LE.NLEV1)   GO TO 3000
      WRITE(6,600)NLEV
      STOP
 3000 CONTINUE
      DO 4000 I=1,NLEV
      LABC(I)=LABC(1)
      ZLEV(I)=(I-1)*ZINC + ZMIN
      LWGT(I)=LWGT1
      IF( LWGT1 .EQ. 3 )   GO TO 4000
      IF( LWGT1 .NE. 2 )   THEN
       IF( LWGT1 .EQ. 1 )   THEN
        IF(MOD(NINT(ZLEV(I)),10).EQ.0 )   LWGT(I)= 2
       ELSE
        IF( ZLEV(I) .GE. 0.0 )   LWGT(I)=-1
       END IF
      END IF
 4000 CONTINUE
 5000 CONTINUE

      RETURN
      END
