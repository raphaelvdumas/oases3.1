      PROGRAM OASINV
c ********************************************************
c *                       OASES                          *
c *  Ocean Acoustic and Seismic Exploration Synthetics   *
c *                   Copyright (C)                      *
c *                  Henrik Schmidt                      *
c *       Massachusetts Institute of Technology          *
c *               Cambridge, MA 02139                    *
c ********************************************************
c

C     ENVIRONMENT  INVERSION REPLICAS 
C     Version 2.0, Update 9-Apr-1996
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C          
C     May 6, 1994: Broadband CRB included using new ABB
c                  algorithms.
c     
      INCLUDE 'compar.f'
      INCLUDE 'comnla.f'
      INCLUDE 'comnp.f'
      INCLUDE 'comnrd.f'
      INCLUDE 'srccoo.f'
      INCLUDE 'recarr.f'
      INCLUDE 'corrfn.f'
      INCLUDE 'noiprm.f'
      INCLUDE 'pesbuf.f'
      INCLUDE 'invbuf.f'

      INTEGER SRTPUT,SRTGET                                         

      LOGICAL CRARAO,NPWBF,INTPLT,DRCONT,RRCONT
      LOGICAL ITYPLT,NFRPLT,GAMPLT,INTERP
      LOGICAL LOGBUF
      LOGICAL GETFLG, PUTFLG,RINFLG,ROTFLG,corsns
      logical contz,contx

      CHARACTER*6  BOPT(10),CRAOPT(6)
      CHARACTER*6  OPTION(2)
      CHARACTER*4  TITLE(20)
      CHARACTER*40 FILENM
      character*80 ptit,xtxt,ztxt
      character*12 cr_tit(9)

      real sspec2(np)

      DIMENSION IBOPT(10)
      DIMENSION X(NP2,3),FF(2,NP3),PX(MODULO)              
      DIMENSION RDUP(3),RDDOWN(3),CYAXIS(3),RDINC(3)
      DIMENSION FFS(2,NP),XS(NP2)     
      integer laytsav(nla)

      COMMON /RTITLE/ TITLE                                         
      COMMON /REPLIC/ ZSMIN,ZSMAX,XSMIN,XSMAX,YSMIN,YSMAX,
     1                NSRCZ,NSRCX,NSRCY

      EQUIVALENCE (NREC,ISPACE),(LF,NUMFR)
      EQUIVALENCE (X(1,1),CFF(1,1)),(XS(1),CFFS(1))        
      EQUIVALENCE (FF(1,1),CFF(1,1)),(FFS(1,1),CFFS(1))        

      DATA OPTION /'OASNR ','      '/                    
      DATA BOPT   /' BE   ',' ML   ',' TML  ',' MCM  ',6*'      '/
      DATA CRAOPT /' DX   ',' DY   ',' DZ   ',' DV   ',
     -             ' GAM  ',' LEV  ' /
      data cr_tit /'Depth,      ',
     &             'Comp. speed,',
     &             'Shear speed,',
     &             'Comp. attn.,',
     &             'Shear attn.,',
     &             'Density,    ',
     &             'Rougness,   ',
     &             'Corr. Len.  ',
     &             'Flow vel.   '/
c

C ********************  some FORMATS  *******************
          
200   FORMAT(20A4)                
210   FORMAT(//1H ,'OASI Version 2.0, Update 9-Apr-1996',
     &       //1H ,20A4)   
220   FORMAT(1H ,F10.2,2X,F10.3,2X,F10.3,2X,F10.1)
310   FORMAT(//1H ,'INTEGRANDS BUILT, iz,ix= ',2i5,
     &                ' CPU=',F12.3)
350   FORMAT(//1H ,'    DEPTH        ALPHA       BETA      ATTENA     '
     -,          '  ATTENB         RHO       ROUGHNESS'//
     -       1H ,3F12.5,2F12.8,2F12.5  )  
500   FORMAT(1H ,' ',
     &      /1H ,'SOURCE FREQUENCY:',F10.2,' HZ ',
     &      /1H ,'------------------------------')
550   FORMAT(//1H ,3X,2HLS,5X,5HICUT1,5X,5HICUT2,/(1X,I5,2I10))
551   FORMAT(//1H ,'TOTAL   CONTINUOUS  DISCRETE  EVANESCENT',
     1        /(1X,I5,3I10))
600   FORMAT(//,'  CMIN = ',G15.6,' M/S ',/,'  CMAX = ',G15.6,' M/S')
650   FORMAT(1H ,' CCUT1= ',G15.6,' M/S ',/,'  CCUT2= ',G15.6,' M/S')
6010  FORMAT(1H ,I8,10X,A40)
          
          
C ******************************************************         
          
      DEBUG=.FALSE.
      NBEAMF = 3
      INDEX0 = 0
      NUMREP = 0
      NPNT   = 0          
      INPFIL = 40
      IOUFIL = 41
      MODU   = MODULO
      ITXX   = NP2
      PI     = 4.0*ATAN(1.0)           
      AI     = CMPLX(0.,1.)             
      CNUL   = CMPLX(0.,0.)
      IR     = 1 
      LS     = 1
      LAYS(1)= 2
      DELTA  = 1.
      THETA  = 0.
      FOCDEP = 0.
      LTYP   = 1
      LINA   = 0
      NFLAG  = .FALSE.
      ICNTIN = 0

      SRTPUT = 0                                                    
      SRTGET = 0                                                    
      IDUM1  = 0                                                    
      IDUM2  = 0                                                    
c >>> Initialize Bessel function origin
      brk_0=0e0
      mbf_0=0
c >>> Initialize roughness spectra
      goff=.false.
      pierson=.false.
          
C*****
C*  Read Input File  (unit 1 = input)
C*****          
          
      CALL OPFILR(1,IOER)
      IF (IOER.GT.0) STOP '>>>> ERROR: INPUT FILE NOT FOUND <<<<'
      READ(1,200)   TITLE            
      WRITE(6,210)  TITLE           
C*****  OPEN OUTPUT FILES for NOISE COVARIANCE MATRICES
C       (unit 26 =    )

      CALL OPFILW(26,IOER)
      WRITE(26,200) TITLE

      CALL GETOPT (IPROF,ICNTIN,MFAC,IPARES,IBOPT,CRARAO,NPWBF,
     -             INTPLT,DRCONT,RRCONT,ITYPLT,NFRPLT,GAMPLT,
     -             GETFLG,PUTFLG,RINFLG,ROTFLG,INTERP,
     -             corsns)

C*****  READ IN FREQUENCY DATA

      IF (ICNTIN.GT.0) THEN
        READ(1,*) FREQ1,FREQ2,NFREQ,OFFDBIN
      ELSE
        OFFDBIN=0.0
        READ(1,*) FREQ1,FREQ2,NFREQ             
      END IF
      FREQ=0.5*(FREQ1+FREQ2)
      IF (NFREQ.GT.1) THEN
        DLFREQ=(FREQ2-FREQ1)/(NFREQ-1)
      ELSE
        DLFREQ=1.0
      END IF

C*****  READ IN ENVIRONMENTAL DATA

      CALL INENVI
      write(6,*) "Read environment, NUML = ", numl
      NUMI=NUML-1                 
      do i=1,numl
       laytsav(i)=laytyp(i)
      end do    
C*****  READ IN COORDINATES FOR RECEIVER ARRAY

      CALL INPRCV

      IF (IR.GT.NRD) THEN
         WRITE(6,*) '*** TOO MANY RECEIVER DEPTHS ***'
         STOP
      END IF

      DO JJ=1,IR
         CALL RECEIV(V,NUML,RDC(JJ),LAY(JJ),Z(JJ))                 
      end do

C*****  READ NOISE DATA  (noise levels in dB)
      IF (CALNSE.or.trfout) THEN
       CALL NOIPAR(INTPLT)
      END IF

C*****  READ IN MEDIUM PARAMETERS FOR WHICH REPLICA FIELDS
C       HAVE TO BE CALCULATED
      write(6,*) 'IPARES block'
      IF (IPARES.EQ.1) THEN
         NSRCZ=0
         NSRCX=0
         NSRCY=1
c >>> read source coordinates
         read(1,*) zsc(1),xsc(1),ysc(1),rslevdb
         rslev=10.0**(rslevdb/10.0)
c >>> read parameters to perturb
         READ(1,*) jlayz,jparz,ZSMIN,ZSMAX,NSRCZ
c         write(6,*)  jlayz,jparz,ZSMIN,ZSMAX,NSRCZ
         if (jparz.eq.6 .and. (.not.eof_layer(jlayz))) then
          zsmin=zsmin*1e3
          zsmax=zsmax*1e3
         end if
         READ(1,*) jlayx,jparx,XSMIN,XSMAX,NSRCX
c         write(6,*) jlayx,jparx,XSMIN,XSMAX,NSRCX
         if (jparx.eq.6 .and. (.not.eof_layer(jlayx))) then
          xsmin=xsmin*1e3
          xsmax=xsmax*1e3
         end if
         IF (NSRCZ.GT.NSMAX.OR.NSRCX.GT.NSMAX) THEN
c           write(6,*) 'nsrcz,nsrcx,nsmag=',nsrcz,nsrcx,nsmag
           STOP '>>> TOO MANY REPLICA POINTS <<<'
         END IF
          delx=abs(xsmax-xsmin)*1e-3
          delz=abs(zsmax-zsmin)*1e-3
C
C       WRITE OUT REPLICA FILE HEADER FOR OPTION ROTFLG
C
         IF (ROTFLG) THEN
           CALL PUTREP(CFILE)
         END IF
C
            rfc=1e3
            XSC(1)=RFC*Xsc(1)
            YSC(1)=RFC*Ysc(1)
                    
C*****  WAVENUMBER PARAMETERS FOR REPLICA

         READ(1,*)CMINSIN,CMAXSIN        
         READ(1,*)NWSIN,ICUT1S,ICUT2S
         if (nwsin.lt.0) then
          write(6,*) '>>> Automatic sampling for REPLICAS <<<'
          rmaxs=sqrt(xsc(1)**2+ysc(1)**2)/rfc
          rmins=0.1*rmaxs
          write(6,*) 'Rmax=',rmaxs,' km'
          icntin=1
          OFFDB=0E0
          CALL AUTSMN(CMINSIN,CMAXSIN,RMINS,RMAXS,CMINS,CMAXS,
     &                NWVNOS,ICUT1S,ICUT2S)
         else       
          cmins=cminsin
          cmaxs=cmaxsin
          NWVNOS=MIN0(NWSIN,NP)
          ICUT2S=MIN0(NWSIN,ICUT2S)
          ICUT1S=MAX0(1,ICUT1S)
         end if
         NFLAG=.FALSE.
         IF (CMINS.EQ.0)            STOP '*** CMIN MUST BE NON-ZERO ***'
         SLOW1S = 2*PI / CMAXS
         SLOW2S = 2*PI / CMINS               
         IF (CMINS.LE.0.OR.CMINS.GT.CMAXS) 
     -                              STOP '*** CMIN/CMAX CONFLICT ***'
         WRITE(6,*)
         WRITE(6,*) 'WAVENUMBER PARAMETERS FOR REPLICAS:'
         WRITE(6,600)CMINS,CMAXS       
         WRITE(6,550)NWVNOS,ICUT1S,ICUT2S
      END IF
C
C     OPEN SCRATCH FILE FOR INTEGRAND CONTOUR DATA
C
       IF (CALNSE.AND.DRCONT.AND.INTPLT) THEN
         NDEC=NWVNON/NCONM
         IF (NDEC.GT.0) THEN
           NCON=(NWVNON-1)/NDEC+1
         ELSE
           NDEC=1
           NCON=NWVNON
         END IF
         do ii=1,3
          conmax(ii)=-200.0
         end do
        CALL OPNBUF(27,NCON,NFREQ*NRCV,100)
        CALL OPFILW(28,IOER)
        CALL OPFILW(29,IOER)
       END IF
          
C
C     CHECK WHETHER TO INVOKE DEFAULT CONTOUR OFFSET
C
      IF (ICNTIN.GT.0.AND.OFFDBIN.LT.1E-10) THEN
       IF (IPARES.GT.0) THEN
        OFFDB=60.0*V(LAYS((LS-1)/2+1),2)*(1E0/CMINS-1E0/CMAXS)/NWVNOS
       ELSE IF (NDNS.GT.0) THEN
        OFFDB=60.0*V(LAYS((LS-1)/2+1),2)*(1E0/CMIND-1E0/CMAXD)/NWVNOD
       ELSE IF (SNLEVDB.GT.0.01) THEN
        OFFDB=60.0*V(LAYS((LS-1)/2+1),2)*(SLS(3)-SLS(2))/NWS(2)
       ELSE IF (DPLEVDB.GT.0.01) THEN
        OFFDB=60.0*V(LAYS((LS-1)/2+1),2)*(SLD(3)-SLD(2))/NWD(2)
       ELSE
        OFFDB=OFFDBIN
       END IF
        WRITE(6,*) 
        WRITE(6,*) 'DEFAULT CONTOUR OFFSET APPLIED,',OFFDB,
     &             ' dB/wavelength'
      ELSE
       OFFDB=OFFDBIN
      END IF

      OFFDBS=OFFDB
      OFFDB=0.0

      NWVNO=NWVNON
      CMIN=CMINN
      CMAX=CMAXN
      ICUT1=1
      ICUT2=NWVNO                      

C*****  OPEN PLOT AND CHECK FILES

      CALL OPFILW(19,IOER)
      CALL OPFILW(20,IOER)
      CALL OPFILW(21,IOER)
      WRITE(19,6010) MODU,'MODU'


C*****  PLOT OF VELOCITY PROFILE IF OPTION 'Z' WAS CHOSEN

      IF (IPROF.GT.0) THEN
         READ(1,*) VPLEFT,VPRIGHT,VPLEN,VPINC
         READ(1,*) DPUP,DPLO,DPLEN,DPINC
         CALL PLPROF(TITLE,VPLEN,DPLEN,VPLEFT,VPRIGHT,VPINC,
     2               DPUP,DPLO,DPINC)
      END IF

C*****  OPEN SCRATCH FILE FOR NOISE AND FIELD CORRELLATION MATRICES
      IF (CALNSE) THEN
        LRECN=2*NRCV*NRCV
        ISI=NFREQ
        CALL OPNBUF(32,LRECN,ISI,2*NRNR/64+1)
      END IF
  
C *****  OPEN SCRATCH FILE FOR REPLICA FIELDS
c      IF (IPARES.GT.0) THEN
c        LRECORD=2*NRCV
c        ISI=NSRCZ*NSRCX*NSRCY*NFREQ
c        CALL OPNBUF(31,LRECORD,ISI,500)
c      END IF
        irsave=ir
        ir=1                   
        nplsav=nplots
        nplots=nrcv
        lxp1=nint(freq1/dlfreq)+1
        mx=nint(freq2/dlfreq)+1
        nx=512
 432    nx=nx*2
        if  (nx.gt.np) stop '>>> Too many frequencies <<<'
        if (nx.lt.2*mx) go to 432
        dt=1e0/(nx*dlfreq)
        freqs=(freq1+freq2)*0.5        
c
c >>> source assumed to by oasp type 6 (BW match)
c
        if (nfreq.gt.1.and.freq1.ne.freq2) then
         istyp=6
         call spulse(freqs,dt,nx,lxp1,mx)
         call cvmags(cffs(1),2,sspec2(1),1,nx/2)
         smx=0e0
         do jj=lxp1,mx
          smx=smx+sspec2(jj)*dlfreq
         end do
         do jj=lxp1,mx
          sspec2(jj)=sspec2(jj)/smx
          write(6,*) jj,sspec2(jj)
         end do
        else
         sspec2(lxp1)=1E0
        end if
c >>> open TRF file and write header for option T
       IF (TRFOUT) THEN 
        CALL TRFHEAD('trf',TITLE,dep(1),dep(nrcv),
     &               1.0,1.0,
     &              NX,LXP1,MX,DT,FREQS,SD)
       END IF
      ir=irsave    
      nplots=nplsav


C**********************  BEGIN FREQUENCY LOOP  *************************

      TOTTIM=0.0
      CALL CLTIME
      do i=1,numl
       laytyp(i)=laytsav(i)
      end do    
      CALL PINIT1
      IF (DEBUG) CALL PREQV(NUML,NUMI)
      CALL RDTIME(T1)
      TOTTIM=TOTTIM+T1
c >>>
c >>> save original parameters
c >>>
      if (ipares.gt.0) then
       if (eof_layer(jlayz)) then
          call eof_svp(jlayz,dep_h(jlayz),dep_t(jlayz),dep_d(jlayz))
       else
          contz=.false.
          vsavz=v(jlayz,jparz) 
c >>> check for continuous ssp
          if (jparz.eq.2.and.jlayz.gt.2) then
             if (abs(v(jlayz,2)+v(jlayz-1,3)).lt.1e-3) then
                contz=.true.
             end if
          end if      
       end if 
       if (eof_layer(jlayx)) then
          call eof_svp(jlayx,dep_h(jlayx),dep_t(jlayx),dep_d(jlayx))
       else
          contx=.false.
          vsavx=v(jlayx,jparx) 
          if (jparx.eq.2.and.jlayx.gt.2) then
             if (abs(v(jlayx,2)+v(jlayx-1,3)).lt.1e-3) then
                contx=.true.
             end if
          end if      
       end if
 
       if (crarao) then
c >>> clear Fisher info arrays
        call vclr(ad2,1,nsmax*nsmax)
        call vclr(agam,1,nsmax*nsmax)
        call vclr(afish,1,4*nsmax*nsmax)
        call vclr(cli,1,4*nsmax*nsmax)
        call vclr(clij,1,8*nsmax*nsmax)
       end if
      end if

      DO 20 IFR=1,NFREQ        

      TIMF=0
      CALL CLTIME
      FREQ=FREQ1+(IFR-1)*DLFREQ
      WRITE(6,500)FREQ  
      WRITE(26,*) FREQ,' FREQUENCY'          
      DSQ=2E0*PI*FREQ             
      CSQ=DSQ*DSQ             
c >>> restore original parameters
      do i=1,numl
       laytyp(i)=laytsav(i)
      end do    
      if (ipares.gt.0) then
       if (eof_layer(jlayz)) then
          call eof_svp(jlayz,dep_h(jlayz),dep_t(jlayz),dep_d(jlayz))
       else
          v(jlayz,jparz)=vsavz 
          if (contz) then
             v(jlayz-1,3)=-v(jlayz,2)
          end if
       end if
       if (eof_layer(jlayx)) then
          call eof_svp(jlayx,dep_h(jlayx),dep_t(jlayx),dep_d(jlayx))
       else
          v(jlayx,jparx)=vsavx 
          if (contx) then
             v(jlayx-1,3)=-v(jlayx,2)
          end if
       end if
      end if

C*****  NOISE CALCULATION SECTION
      IF (CALNSE.or.trfout) THEN
       CALL NOICAL(MFAC,INTPLT,DRCONT,INTERP,corsns)

C **** WRITE OUT NOISE COVARIANCE MATRIX
       if (calnse) then
        CALL PUTXSM(CORRNS,NRCV,IFR,IERR)
c >>> invert ambient noise covariance matrix for Cramer-Rao bounds
        if (crarao) then
         call cmatin(nrcv,coramb,cninv)
        end if  

C*****  PLOT NOISE INTENSITIES VS RECEIVER NUMBER

        IF (ITYPLT.AND.NRCV.GT.1) THEN
         CALL PLNOIS(FREQ,TITLE,20.0,12.0)
        END IF
       end if
      END IF

C*****  RESTORE WAVENUMBER PARAMETERS FOR REPLICA FIELDS

      IF (IPARES.EQ.1) THEN
         ICDR = 0
          NWVNO=NWVNOS
          CMIN=CMINS
          CMAX=CMAXS
          icut1=1
          icut2=nwvno
          ICW1=ICUT1S
          ICW2=ICUT2S                      
          SLOW1=SLOW1S
          SLOW2=SLOW2S
         WK0=FREQ*SLOW1
         WKMAX=FREQ*SLOW2    
         DLWVNO = ( WKMAX - WK0 ) / ( FLOAT(NWVNO-1) )      
         FNI5=DLWVNO*FNIFAC
c >>> frequency index
         ixfr=nint(freq/dlfreq)+1
c >>> source parameters
           LS=1
           SDC(1)=ZSC(1)
           CALL SOURCE(V,NUML,SDC(1),LAYS(1),ZUS(1),ZLS(1))
           CALL sinit

C        *****  CALCULATE REPLICA FIELDS 
         WRITE(6,*)
         WRITE(6,*) 'REPLICA FIELD CALCULATION'
         WRITE(6,*) '-------------------------'
         DO 703 ISRCZ=2,NSRCZ-1
           zval = zsmin+(isrcz-1)*((zsmax-zsmin)/(nsrcz-1))
           if (nsrcz.gt.1) then
             if (eof_layer(jlayz)) then
                dh =dep_h(jlayz)
                dt =dep_t(jlayz)
                dd =dep_d(jlayz)
                if (jparz .eq. 3) then
                   dh = zval
                else if (jparz .eq. 4) then
                   dt = zval 
                else if (jparz .eq. 5) then
                   dd = zval
                end if
                call eof_svp(jlayz,dh,dt,dd)
             else
                v(jlayz,jparz)=zval
                if (contz) then
                   v(jlayz-1,3)=-v(jlayz,2)
                end if
             end if
            end if
          DO 703 ISRCx=2,NSRCx-1
             xval = xsmin+(isrcx-1)*((xsmax-xsmin)/(nsrcx-1))
             if (nsrcx.gt.1) then
                if (eof_layer(jlayx)) then
                   dh =dep_h(jlayx)
                   dt =dep_t(jlayx)
                   dd =dep_d(jlayx)
                   if (jparx .eq. 3) then
                      dh = xval 
                   else if (jparx .eq. 4) then
                      dt = xval
                   else if (jparx .eq. 5) then
                      dd = xval
                   end if
                   call eof_svp(jlayx,dh,dt,dd)
                else
                   v(jlayx,jparx)=xval
                   if (contx) then
                      v(jlayx-1,3)=-v(jlayx,2)
                   end if
                end if
             end if
             OFFDB=OFFDBS
             do i=1,numl
                laytyp(i)=laytsav(i)
             end do    
c >>> reinitialize source and receiver pointers in case layering changed

            CALL SOURCE(V,NUML,SDC(1),LAYS(1),ZUS(1),ZLS(1))

            DO JJ=1,IR
             CALL RECEIV(V,NUML,RDC(JJ),LAY(JJ),Z(JJ))                 
            end do

            call pinit1
            CALL PINIT2
            CALL RDTIME(T1)
            CALL CLTIME
            TIMF=TIMF+T1

            CALL CALIN3
            CALL CHKSOL

            CALL RDTIME(T1)
            CALL CLTIME
            TIMF=TIMF+T1
            WRITE(6,310) isrcz,isrcx,T1
            write(92,*) isrcz,isrcx
C
C   *****  REPLICA FIELD INTEGRATION
c
            CALL RFLD(1,1,ROTFLG,INTERP)
            CALL CLSBUF(LUGRN)
            if (crarao) then
             call vmov(cfile,1,afield,1,2*nrcv)
c >>> Cramer-Rao bounds
c >>> x-direction
             write(6,*) '>>> x-perturbation'
             if (eof_layer(jlayx)) then
                dh =dep_h(jlayx)
                dt =dep_t(jlayx)
                dd =dep_d(jlayx)
                if (jparx .eq. 3) then
                   dh = xval + delx
                else if (jparx .eq. 4) then
                   dt = xval + delx
                else if (jparx .eq. 5) then
                   dd = xval + delx
                end if
                call eof_svp(jlayx,dh,dt,dd)
             else
                v(jlayx,jparx)=v(jlayx,jparx)+delx
                if (contx) v(jlayx-1,3)=-v(jlayx,2)
             end if
             OFFDB=OFFDBS
             do i=1,numl
              laytyp(i)=laytsav(i)
             end do    

c >>> reinitialize source and receiver pointers in case layering changed

             CALL SOURCE(V,NUML,SDC(1),LAYS(1),ZUS(1),ZLS(1))

             DO JJ=1,IR
              CALL RECEIV(V,NUML,RDC(JJ),LAY(JJ),Z(JJ))                 
             end do

             call pinit1
             CALL PINIT2
             CALL RDTIME(T1)
             CALL CLTIME
             TIMF=TIMF+T1

             CALL CALIN3
             CALL CHKSOL
 
             CALL RDTIME(T1)
             CALL CLTIME
             TIMF=TIMF+T1
             WRITE(6,310) isrcz,isrcx,T1
C
C   *****  REPLICA FIELD INTEGRATION

             CALL RFLD(1,1,.false.,INTERP)
             call cvsub(cfile,2,afield,2,xfield,2,nrcv)
             call vsmul(xfield,1,1e0/delx,xfield,1,2*nrcv)
             CALL CLSBUF(LUGRN)

             if (eof_layer(jlayx)) then
                dh =dep_h(jlayx)
                dt =dep_t(jlayx)
                dd =dep_d(jlayx)
                if (jparx .eq. 3) then
                   dh = xval
                else if (jparx .eq. 4) then
                   dt = xval
                else if (jparx .eq. 5) then
                   dd = xval
                end if
                call eof_svp(jlayx,dh,dt,dd)
             else
                v(jlayx,jparx)=v(jlayx,jparx)-delx
                if (contx) v(jlayx-1,3)=-v(jlayx,2)
             end if
c >>> z-direction
             write(6,*) '>>> z-perturbation'
             if (eof_layer(jlayz)) then
                dh =dep_h(jlayz)
                dt =dep_t(jlayz)
                dd =dep_d(jlayz)
                if (jparz .eq. 3) then
                   dh = zval + delz
                else if (jparx .eq. 4) then
                   dt = zval + delz
                else if (jparx .eq. 5) then
                   dd = zval + delz
                end if
                call eof_svp(jlayz,dh,dt,dd)
             else
                v(jlayz,jparz)=v(jlayz,jparz)+delz
                if (contz) v(jlayz-1,3)=-v(jlayz,2)
             end if
             OFFDB=OFFDBS
             do i=1,numl
              laytyp(i)=laytsav(i)
             end do    

c >>> reinitialize source and receiver pointers in case layering changed

             CALL SOURCE(V,NUML,SDC(1),LAYS(1),ZUS(1),ZLS(1))

             DO JJ=1,IR
              CALL RECEIV(V,NUML,RDC(JJ),LAY(JJ),Z(JJ))                 
             end do

             call pinit1
             CALL PINIT2
             CALL RDTIME(T1)
             CALL CLTIME
             TIMF=TIMF+T1

             CALL CALIN3
             CALL CHKSOL

             CALL RDTIME(T1)
             CALL CLTIME
             TIMF=TIMF+T1
             WRITE(6,310) isrcz,isrcx,T1
C
C   *****  REPLICA FIELD INTEGRATION

             CALL RFLD(1,1,.false.,INTERP)
             call cvsub(cfile,2,afield,2,zfield,2,nrcv)
             call vsmul(zfield,1,1e0/delz,zfield,1,2*nrcv)
             CALL CLSBUF(LUGRN)
             if (eof_layer(jlayz)) then
                dh =dep_h(jlayz)
                dt =dep_t(jlayz)
                dd =dep_d(jlayz)
                if (jparz .eq. 3) then
                   dh = zval
                else if (jparx .eq. 4) then
                   dt = zval
                else if (jparx .eq. 5) then
                   dd = zval
                end if
                call eof_svp(jlayz,dh,dt,dd)
             else
                v(jlayz,jparz)=v(jlayz,jparz)-delz
                if (contz) v(jlayz-1,3)=-v(jlayz,2)
             end if
c >>> now compute the components of the Fisher info matrix
             call fiscom(isrcx,isrcz,rslev,sspec2(ixfr))
           end if
           CALL RDTIME(T1)
           CALL CLTIME
           TIMF=TIMF+T1
           WRITE(6,315) T1
 315      FORMAT(1H ,'REPLICA FIELDS DONE,                  CPU=',F12.3)
703      CONTINUE
      END IF
 
      CALL RDTIME(T1)
      TIMF=TIMF+T1
      TOTTIM=TOTTIM+TIMF
      WRITE(6,311) FREQ,TIMF
311   FORMAT(1H ,'FREQ. ',F8.2,' Hz DONE,               CPU=',F12.3)

20    CONTINUE

C************************* END of FREQUENCY LOOP **********************
      if (crarao) then
c
c >>> compute and plot incoherent Cramer-Rao bounds
c
c >>> Make plot entry for Cramer-Rao bounds
       ptit='INCOHERENT CRAMER-RAO BOUNDS'
       write(xtxt,'(a,a,i3,a)') cr_tit(jparx),' layer',jlayx,'$'
       write(ztxt,'(a,a,i3,a)') cr_tit(jparz),' layer',jlayz,'$'
       call autoax(XsMIN,XsMAX,XLEFT,XRIGHT,XINC,XDIV,NXDIF)
       call autoax(zsMIN,zsMAX,ylo,yup,yINC,yDIV,NyDIF)
       xdiv=1e0
       ydiv=1e0
       CALL PLPWRI(OPTION,PTIT,TITLE,0,' ',12.0,12.0,
     &             0,Xleft,xright,XINC,XDIV,XTXT,'LIN',
     &             YLO,YUP,YINC,YDIV,ZTXT,'LIN',
     &             (nsrcz-2)*(nsrcx-2))
       write(26,*) '>>> INCOHERENT BOUNDS <<<'
       do isrcz=2,nsrcz-1
          zval = zsmin+(isrcz-1)*((zsmax-zsmin)/(nsrcz-1))
c          if (nsrcz.gt.1) then
c             v(jlayz,jparz)=zval
c             if (contz) v(jlayz-1,3)=-v(jlayz,2)
c          end if
          do isrcx=2,nsrcx-1
             xval = xsmin+(isrcx-1)*((xsmax-xsmin)/(nsrcx-1))
c             if (nsrcx.gt.1) then
c                v(jlayx,jparx)=xval
c                if (contx) v(jlayx-1,3)=-v(jlayx,2)
c             end if
             call crbound(xval,zval,
     &            afish(1,1,isrcx,isrcz))
          end do
       end do
c
c >>> compute and plot coherent Cramer-Rao bounds
c
c >>> Make plot entry for Cramer-Rao bounds
       ptit='COHERENT CRAMER-RAO BOUNDS'
       write(xtxt,'(a,a,i3,a)') cr_tit(jparx),' layer',jlayx,'$'
       write(ztxt,'(a,a,i3,a)') cr_tit(jparz),' layer',jlayz,'$'
       call autoax(XsMIN,XsMAX,XLEFT,XRIGHT,XINC,XDIV,NXDIF)
       call autoax(zsMIN,zsMAX,ylo,yup,yINC,yDIV,NyDIF)
       xdiv=1e0
       ydiv=1e0
       CALL PLPWRI(OPTION,PTIT,TITLE,0,' ',12.0,12.0,
     &             0,Xleft,xright,XINC,XDIV,XTXT,'LIN',
     &             YLO,YUP,YINC,YDIV,ZTXT,'LIN',
     &             (nsrcz-2)*(nsrcx-2))
       write(26,*) '>>> COHERENT BOUNDS <<<'
       do isrcz=2,nsrcz-1
          zval = zsmin+(isrcz-1)*((zsmax-zsmin)/(nsrcz-1))
c          if (nsrcz.gt.1) then
c             v(jlayz,jparz)=zval
c             if (contz) v(jlayz-1,3)=-v(jlayz,2)
c          end if
          do isrcx=2,nsrcx-1
             xval = xsmin+(isrcx-1)*((xsmax-xsmin)/(nsrcx-1))
c             if (nsrcx.gt.1) then
c                v(jlayx,jparx)=xval
c                if (contx) v(jlayx-1,3)=-v(jlayx,2)
c             end if
c     >>> Coherent Fisher info matrix
             do i=1,2
                do j=1,2
                   afish_f(i,j)=rslev**2*agam(isrcx,isrcz)*
     &               ( real( ad2(isrcx,isrcz)*clij(i,j,isrcx,isrcz)
     &               -conjg(cli(i,isrcx,isrcz))*cli(j,isrcx,isrcz))
     &               +agam(isrcx,isrcz)*
     &               real(cli(i,isrcx,isrcz))*real(cli(j,isrcx,isrcz)))
                end do
             end do  
             call crbound(xval,zval,afish_f(1,1))
          end do
       end do
      end if
      


C*****  ENDFILE ON BUFFER FILES
      IF (CALNSE)THEN
         CALL ENFBUF(32)
      END IF
c      IF (IPARES.GT.0) THEN
c         CALL ENFBUF(31)
c      END IF

C *** NOISE GRAPHICS

      IF (CALNSE) THEN
       IF (DRCONT.AND.INTPLT) CALL ENFBUF(27)

C*****  PLOT OF NOISE INTENSITY SPECTRA

       IF (NFRPLT.AND.(NFREQ.GT.1)) THEN
         DO 22 IRCV=1,NRCV
          CALL PLNFSP(IRCV,FREQ1,DLFREQ,NFREQ,TITLE,20.0,12.0)
22       CONTINUE
       END IF

C*****  CONTOUR PLOTS OF INTEGRANDS VERSUS FREQUENCY

       IF (DRCONT.AND.INTPLT) THEN
        DO 710 JR=1,IR
         do 710 ii=1,3
         IF (IOUT(II).NE.0) THEN
          CALL RWDBUF(27)
          XLEFT=0
          XRIGHT=1E0/CMINN
          XINC=INT(XRIGHT*1E4/5E0)*1E-4
          XSCALE=(XRIGHT-XLEFT)/20.0
          IF (FREQ2.LE.FREQ1/10E0) THEN
            YDOWN=0E0
          ELSE
            YDOWN=FREQ2
          END IF
          IF (FREQ1.LE.FREQ2/10E0) THEN
            YUP=0E0
          ELSE
            YUP=FREQ1
          END IF
          YINC=INT(ABS(YDOWN-YUP)*1E1/5E0)*1E-1
          YSCALE=ABS(YDOWN-YUP)/12.0
          ZMIN=10.0*INT(0.1*CONMAX(II))
          ZINC=1E1
          ZMAX=ZMIN-ZINC*10E0
          CALL NOIVFW(TITLE,NCON,NFREQ,NCON,NFREQ,XLEFT,XRIGHT,
     1                XSCALE,XINC,YUP,YDOWN,YSCALE,YINC,ZMIN,ZMAX,
     2                ZINC,0.0,FLOAT(II),FREQ1,FREQ2,1E0/CMAXN,
     3                XRIGHT,II)
          DO 709 IFREQ=1,NFREQ
            DO 708 JRT=1,IR
             do 708 jj=1,3
              CALL RDBUF(27,FFS,NCON)
              IF (JRT.EQ.JR.and.jj.eq.ii) THEN
                WRITE(29,'(1X,6G13.5)') (XS(JJJ),JJJ=1,NCON)
              END IF
 708        CONTINUE
 709      CONTINUE
         end if
 710    CONTINUE
        CLOSE(28)
        CLOSE(29)
       END IF

       OPTION(2)='PLTEND'
       WRITE(19,777) OPTION
       WRITE(20,777) OPTION
      END IF

      WRITE(6,9960)

 777  FORMAT(1H ,2A6)
 9960 FORMAT(//1H ,'*** OASES NOISE AND REPLICA V-1.3 FINISHED ***')

C*****  CLOSE BUFFER FILES
      IF (CALNSE) THEN
       CALL CLSBUF(32)
      END IF
c      IF (IPARES.EQ.1) THEN
c        CALL CLSBUF(31)
c      END IF

      WRITE(6,9962) TOTTIM
 9962 FORMAT(//1H ,'*** TOTAL TIME: ',F10.3,' SECONDS ***')

      END  

C*********************** END OF OASNS MAIN ROUTINE *******************
C
      SUBROUTINE GETOPT (IPROF,ICNTIN,MFAC,IPARES,IBOPT,CRARAO,NPWBF,
     -                   INTPLT,DRCONT,RRCONT,ITYPLT,NFRPLT,GAMPLT,
     -                   GETFLG,PUTFLG,RINFLG,ROTFLG,INTERP,
     -                   corsns)
c ********************************************************
c *                       OASES                          *
c *  Ocean Acoustic and Seismic Exploration Synthetics   *
c *                   Copyright (C)                      *
c *                  Henrik Schmidt                      *
c *       Massachusetts Institute of Technology          *
c *               Cambridge, MA 02139                    *
c ********************************************************
c

C     INPUT OF OPTIONS
C          modified by Bruce H Pasewark   September 30, 1986
C              real (i.e. experimental)  field option added
C
C     current options : B C D E F G H I J M N O P Q R S T W X Z (1-9)
C     future options  : A K L U V Y
      INCLUDE 'compar.f'
      LOGICAL CRARAO,NPWBF,INTPLT,DRCONT,RRCONT,
     -        ITYPLT,NFRPLT,GAMPLT,INTERP,corsns
      LOGICAL GETFLG, PUTFLG, RINFLG, ROTFLG                        
      LOGICAL SECCHAR
      CHARACTER*1 OPT(40)

      DIMENSION IBOPT(10)

      COMMON /MCMLM/ MAXIN,MCMDIR

      WRITE(6,300)                
 300  FORMAT(//1H ,'OPTIONS:',/)    

      MAXIN   = 1
      IPRINT  = 0
      NOUT    = 0
      IREF    = 0
      ISTYP   = 0
      KPLOT   = 0
      ICDR    = 0
      IPROF   = 0
      ICNTIN  = 0
      MFAC    = 0
      IPARES  = 0
      NBOPT   = 0

      DO 10 I=1,3                 
         IOUT(I)  = 0     
10    CONTINUE
      DO 20 I=1,10
         IBOPT(I) = 0
 20   CONTINUE
      CRARAO = .FALSE.              
      GAMPLT = .FALSE.              
      NPWBF  = .TRUE.
      INTPLT = .FALSE.
      DRCONT = .FALSE.
      RRCONT = .FALSE.
      ITYPLT = .FALSE.
      NFRPLT = .FALSE.
      GETFLG = .FALSE.                                              
      PUTFLG = .FALSE.                                              
      RINFLG = .FALSE.                                              
      ROTFLG = .FALSE.                                              
      SHEAR=.FALSE.
      SECCHAR=.FALSE.
      INTERP=.FALSE.
      CALNSE=.FALSE.
      trfout=.false.
c >>> default is uncorrelated sources
      corsns=.false.

      READ(1,200) OPT             
 200  FORMAT(40A1)                

      DO 50 I=1,40   
         IF (SECCHAR) THEN
           SECCHAR=.FALSE.
           GO TO 50             
         ELSE IF (OPT(I).EQ.'K'.OR.OPT(I).EQ.'k') THEN
            IF (INTPLT) GO TO 50
            INTPLT=.TRUE.
            WRITE(6,309)
309          FORMAT(1H ,'NOISE KERNELS PLOTTED')

         ELSE IF (OPT(I).EQ.'C') THEN
            IF (DRCONT) GO TO 50
            DRCONT=.TRUE.
            intplt=.true.
            WRITE(6,308)
308          FORMAT(1H ,'NOISE KERNEL CONTOURS')

         ELSE IF (OPT(I).EQ.'c') THEN
            IF (crarao) GO TO 50
            crarao=.TRUE.
            WRITE(6,'(1h ,a)') 'Cramer-Rao lower bounds'

         ELSE IF (OPT(I).EQ.'P'.OR.OPT(I).EQ.'p') THEN
            IF (ITYPLT) GO TO 50
            ITYPLT=.TRUE.
            WRITE(6,310)
310          FORMAT(1H ,'NOISE INTENSITY PLOTS')

         ELSE IF (OPT(I).EQ.'F'.OR.OPT(I).EQ.'f') THEN
            IF (NFRPLT) GO TO 50
            NFRPLT=.TRUE.
            WRITE(6,311)
311          FORMAT(1H ,'NOISE SPECTRUM PLOTS')

         ELSE IF (OPT(I).EQ.'Z'.OR.OPT(I).EQ.'z') THEN
            IF (IPROF.GT.0) GO TO 50
            IPROF=1
            WRITE(6,314)
314          FORMAT(1H ,'PLOT OF VELOCITY PROFILES')

         ELSE IF (OPT(I).EQ.'J'.OR.OPT(I).EQ.'j') THEN
            IF (ICNTIN.GT.0) GO TO 50
            ICNTIN=1
            WRITE(6,315)
315          FORMAT(1H ,'COMPLEX INTEGRATION CONTOUR')

         ELSE IF (OPT(I).EQ.'R'.OR.OPT(I).EQ.'r') THEN
            IF (IPARES.GT.0) GO TO 50
            IPARES=1
            ROTFLG=.TRUE.
            WRITE(6,316)
316         FORMAT(1H ,'GENERATION OF REPLICA FIELDS')

         ELSE IF (OPT(I).EQ.'N'.OR.OPT(I).EQ.'n') THEN
            IF (CALNSE) GO TO 50
            CALNSE=.TRUE.
            WRITE(6,319)
319         FORMAT(1H ,'GENERATION OF NOISE COVARIANCE MATRIX')
         ELSE IF (OPT(I).EQ.'T') THEN
            IF (TRFOUT) GO TO 50
            TRFOUT=.TRUE.
            WRITE(6,321)
 321        FORMAT(1H ,'CREATING TRANSFER FUNCTION FILE')

         ELSE IF (OPT(I).EQ.'I'.OR.OPT(I).EQ.'i') THEN
            IF (INTERP) GO TO 50
            INTERP=.TRUE.
            WRITE(6,317)
317         FORMAT(1H ,'FFT INTEGRATION AND INTERPOLATION APPLIED')

         ELSE IF (OPT(I).EQ.'Q'.OR.OPT(I).EQ.'q') THEN
            IF (DEBUG) GO TO 50
            DEBUG=.TRUE.
            WRITE(6,318)
318         FORMAT(1H ,'>>>> DEBUGGING ENABLED <<<<')

         ELSE IF (ICHAR(OPT(I)).GT.ICHAR('0').AND.
     -            ICHAR(OPT(I)).LE.ICHAR('9')) THEN
            IF (MFAC.EQ.0) THEN
               MFAC=ICHAR(OPT(I))-ICHAR('0')
               corsns=.true.
               WRITE(6,*) 'SOURCE DIRECTIONALITY, M=',MFAC
            END IF

         END IF	

50    CONTINUE
C
      IF (MFAC.EQ.0) THEN
          MFAC=1
          WRITE(6,*) 'UNCORRELATED SURFACE NOISE SOURCES'
      END IF

      IF (NOUT.EQ.0) THEN
         IOUT(1)=1                   
         NOUT=1                      
      END IF

      RETURN                      
      END
      subroutine fiscom(isrcx,isrcz,slevel,sspec2)
c ********************************************************
c *                       OASES                          *
c *  Ocean Acoustic and Seismic Exploration Synthetics   *
c *                   Copyright (C)                      *
c *                  Henrik Schmidt                      *
c *       Massachusetts Institute of Technology          *
c *               Cambridge, MA 02139                    *
c ********************************************************
c
      INCLUDE 'compar.f'
      INCLUDE 'comnla.f'
      INCLUDE 'comnp.f'
      INCLUDE 'comnrd.f'
      INCLUDE 'srccoo.f'
      INCLUDE 'recarr.f'
      INCLUDE 'corrfn.f'
      INCLUDE 'corrfs.f'      
      INCLUDE 'pesbuf.f'
      INCLUDE 'invbuf.f'
      complex ccc
c >>> complex conjugates
      call cvconj(afield,2,cbuf,2,nrcv)
      call cvconj(xfield,2,cbuf(1+nrcv),2,nrcv)
      call cvconj(zfield,2,cbuf(1+2*nrcv),2,nrcv)
c >>> calculate d2
      call cmmul(cninv,nrcv,nrcv,afield,1,arg)
      call cmmul(cbuf,1,nrcv,arg,1,ccc)
      ad2_f=real(ccc)
c >>> calculate li_1
      call cmmul(cninv,nrcv,nrcv,xfield,1,arg)
      call cmmul(cbuf,1,nrcv,arg,1,cli_f(1))
c >>> calculate lij_11
      call cmmul(cbuf(1+nrcv),1,nrcv,arg,1,clij_f(1,1))
c >>> calculate lij_12
      call cmmul(cbuf(1+2*nrcv),1,nrcv,arg,1,clij_f(1,2))
c >>> calculate li_2
      call cmmul(cninv,nrcv,nrcv,zfield,1,arg)
      call cmmul(cbuf,1,nrcv,arg,1,cli_f(2))
c >>> calculate lij_21
      call cmmul(cbuf(1+nrcv),1,nrcv,arg,1,clij_f(2,1))
c >>> calculate lij_22
      call cmmul(cbuf(1+2*nrcv),1,nrcv,arg,1,clij_f(2,2))
c >>> calculate gamma
      agam_f=2E0/(1E0+slevel*ad2_f)
c >>> Incoherent Fisher info matrix
      do i=1,2
       do j=1,2
        afish_f(i,j)=(slevel*sspec2)**2*agam_f*
     &            ( real(ad2_f*clij_f(i,j)-conjg(cli_f(i))*cli_f(j))
     &                +agam_f*real(cli_f(i))*real(cli_f(j)))
       end do
      end do  
c >>> add to integrals
      ad2(isrcx,isrcz)=ad2(isrcx,isrcz)+sspec2*ad2_f
      do i=1,2
       cli(i,isrcx,isrcz)=cli(i,isrcx,isrcz)+sspec2*cli_f(i)
       do j=1,2
        clij(i,j,isrcx,isrcz)=clij(i,j,isrcx,isrcz)+sspec2*clij_f(i,j)
        afish(i,j,isrcx,isrcz)=afish(i,j,isrcx,isrcz)+afish_f(i,j)
       end do
      end do
      agam(isrcx,isrcz)=2E0/(1E0+slevel*ad2(isrcx,isrcz))
      return
      end
      SUBROUTINE crbound(xval,zval,ixyz)
c ********************************************************
c *                       OASES                          *
c *  Ocean Acoustic and Seismic Exploration Synthetics   *
c *                   Copyright (C)                      *
c *                  Henrik Schmidt                      *
c *       Massachusetts Institute of Technology          *
c *               Cambridge, MA 02139                    *
c ********************************************************
c
c >>> Computes cramer-rao bounds
c     xval:    Value of x-parameter
c     zval:    Value of z-parameter

      INCLUDE 'compar.f'
      INCLUDE 'comnla.f'
      INCLUDE 'comnp.f'
      INCLUDE 'comnrd.f'
      INCLUDE 'srccoo.f'
      INCLUDE 'recarr.f'
      INCLUDE 'corrfn.f'
      INCLUDE 'corrfs.f'      
      INCLUDE 'pesbuf.f'
	
      COMPLEX CC,CNORM
      COMPLEX CVV(2,2),CXZ(2,2),CLAMB(2),CWORK(2)
      COMPLEX DIRIND


      REAL WXYZ(2,2)
      REAL ALAMB(2),IXYZ(2,2),JXYZ(2,2),VV(2,2),EWORK(2),x(3),y(3)
      REAL FFS(2,NP)
      REAL ALAM(NPMAX)
      CHARACTER*10 TYP(3)
      CHARACTER*6 CRTYP(4)

      EQUIVALENCE (LF,NUMFR),(NREC,ISPACE)
      EQUIVALENCE (CFFS(1),FFS(1,1))

      DATA TYP    /'PRESSURE  ','VERT.PART.','HOR.PART. '/
      DATA CRTYP  /'HYDROP','X-GEOP','Y-GEOP','Z-GEOP'/

 300  FORMAT(2(1X,G13.6,1X,G13.6,'i'))

           WRITE(26,*) 'xval,zval ',xval,zval
           WRITE(26,*) 'JXX,JXZ,JZX,JZZ :'
           WRITE(26,*) iXYZ(1,1),iXYZ(1,2),iXYZ(2,1),iXYZ(2,2)

          CALL MATIN(2,iXYZ,JXYZ,IERR)
          IF (IERR.GT.0) STOP '*** JXYZ SINGULAR ***'
           WRITE(26,*) 'JXX,JXZ,JZX,JZZ (INVERSE):'
           WRITE(26,*) JXYZ(1,1),JXYZ(1,2),JXYZ(2,1),JXYZ(2,2)
           write(77,*) sqrt(abs(jxyz(1,1)))
           write(78,*) sqrt(abs(jxyz(2,2)))
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C     CALCULATE EIGENVALUES
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
          IERR = 0
C          CALL F02ABF(JXYZ,3,3,ALAMB,VV,3,EWORK,IERR)
          call vclr(cxz,1,8)
          CALL VMOV(JXYZ,1,cxz,2,4)
c          CALL EIGRF(WXYZ,3,3,1,CLAMB,CVV,3,CWORK,IERR)
c           stop '>>> PAREST41: EIGRF not available <<<'
          call eigen(cxz,2,2,alamb,cvv,ierr)
          CALL VMOV(CVV,2,VV,1,4)
          IF (IERR.NE.0) STOP '*** EIGENVALUE ERROR WITH JXYZ ***'
    
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
           WRITE(26,*) 'LAM1-2         ',ALAMB(1),ALAMB(2)
           WRITE(26,*) 'EIGENVECTORS     ',VV(1,1),VV(1,2)
           WRITE(26,*) '                 ',VV(2,1),VV(2,2)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c >>> orient eigenvectors 
       if (abs(vv(1,1)).ge.abs(vv(2,1))) then
        if (vv(1,1).lt.0e0) then
         sg1=-1.0
        else 
         sg1=1.0
        end if
       else
        if (vv(2,1).lt.0) then
         sg1=-1.0
        else
         sg1=1.0
        end if
       end if
       if (abs(vv(1,2)).ge.abs(vv(2,2))) then
        if (vv(1,2).lt.0e0) then
         sg2=-1.0
        else 
         sg2=1.0
        end if
       else
        if (vv(2,2).lt.0) then
         sg2=-1.0
        else
         sg2=1.0
        end if
       end if
       x(1)=sg1*sqrt(alamb(1))*vv(1,1) + xval
       y(1)=sg1*sqrt(alamb(1))*vv(2,1) + zval
       x(2)=xval
       y(2)=zval
       x(3)=sg2*sqrt(alamb(2))*vv(1,2) + xval
       y(3)=sg2*sqrt(alamb(2))*vv(2,2) + zval
       CALL PLTWRI(3,0.,0.,0.,0.,x(1),1,y(1),1)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C     CALCULATE DOF (abb algoritm 1994 SACLANT conference)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
          IERR = 0
          do ix=1,2
           do iz=1,2
             cxz(ix,iz)=jxyz(ix,iz)*sqrt(ixyz(ix,ix)*ixyz(iz,iz))
           end do
          end do
          call eigen(cxz,2,2,alamb,cvv,ierr)
          IF (IERR.NE.0) STOP '*** EIGENVALUE ERROR WITH JXYZ ***'
          effn=(alamb(1)+alamb(2))**2/(alamb(1)**2+alamb(2)**2)    
          write(26,*) 'Neff=',effn
      RETURN
      END  

      BLOCK DATA NOIBLK
c ********************************************************
c *                       OASES                          *
c *  Ocean Acoustic and Seismic Exploration Synthetics   *
c *                   Copyright (C)                      *
c *                  Henrik Schmidt                      *
c *       Massachusetts Institute of Technology          *
c *               Cambridge, MA 02139                    *
c ********************************************************
c
      INCLUDE 'compar.f'
      CHARACTER*4 TITLE(20)
      COMMON /RTITLE/ TITLE    
C
C**** DEFINITION OF MAX REAL ARGUMENT TO THE EXPONENTIAL FUNCTION
      COMMON /ARGMAX/ AM
C**** THE FOLLOWING DEFINITION SHOULD BE USED FOR THE FPS164
CFPS  DATA AM /300./
C**** THE FOLLOWING DEFINITION SHOULD BE USED FOR THE VAX
      DATA AM /65./     
      DATA OMEGIM /0.0/
      DATA TITLE  /20*'    '/      
      DATA PROGNM /'OASNR '/  
      DATA LUGRN,LUTRF,LUTGRN,LUTTRF /30,35,30,35/
      DATA SHEAR,DECOMP,SCTOUT,NFLAG,PADE 
     &     /.FALSE.,.FALSE.,.FALSE.,.FALSE.,.FALSE./
      DATA MSUFT,MBMAX,MBMAXI,SRCTYP,ISROW,ISINC /1,1,2,1,1,0/
      data bintrf /.true./
      END
