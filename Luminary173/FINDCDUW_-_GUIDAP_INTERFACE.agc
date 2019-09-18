### FILE="Main.annotation"
## Copyright:   Public domain.
## Filename:    FINDCDUW_-_GUIDAP_INTERFACE.agc
## Purpose:     A section of Luminary revision 173.
##              It is part of the reconstructed source code for the second
##              (unflown) release of the flight software for the Lunar
##              Module's (LM) Apollo Guidance Computer (AGC) for Apollo 14.
##              The code has been recreated from a reconstructed copy of
##              Luminary 178, as well as Luminary memo 167 (revision 1).
##              It has been adapted such that the resulting bugger words
##              exactly match those specified for Luminary 173 in NASA
##              drawing 2021152N, which gives relatively high confidence
##              that the reconstruction is correct.
## Reference:   pp. 899-917
## Assembler:   yaYUL
## Contact:     Ron Burkey <info@sandroid.org>.
## Website:     www.ibiblio.org/apollo/index.html
## Warning:     THIS PROGRAM IS STILL UNDERGOING RECONSTRUCTION
##              AND DOES NOT YET REFLECT THE ORIGINAL CONTENTS OF
##              LUMINARY 173.
## Mod history: 2019-09-18 MAS  Created from Luminary 178.

## Page 899
# PROGRAM NAME:   FINDCDUW

# MOD NUMBER:     1         68 07 15

# MOD AUTHOR:     KLUMPP

# OBJECTS OF MOD: 1.        TO SUPPLY COMMANDED GIMBAL ANGLES FOR NOUN 22.
#                 2.        TO MAINTAIN CORRECT AND CURRENT THRUST
#                           DIRECTION DATA IN ALL MODES.  THIS IS DONE BY
#                           FETCHING FOR THE THRUST DIRECTION FILTER THE
#                           CDUD'S IN PNGCS-AUTO, THE CDU'S IN ALL OTHER
#                           MODES.
#                 3.        TO SUBSTITUTE A STOPRATE FOR THE NORMAL
#                           AUTOPILOT COMMANDS WHENEVER
#                           1) NOT IN PNGCS-AUTO, OR
#                           2) ENGINE IS OFF.

# FUNCTIONAL DESCRIPTION:

# FINDCDUW PROVIDES THE INTERFACES BETWEEN THE VARIOUS POWERED FLITE GUIDANCE PROGRAMS
# AND THE DIGITAL AUTOPILOT.  THE INPUTS TO FINDCDUW ARE THE THRUST COMMAND VECTOR
# AND THE WINDOW COMMAND VECTOR, AND THE OUTPUTS ARE THE GIMBAL ANGLE
# INCREMENTS, THE COMMANDED ATTITUDE ANGLE RATES, AND THE COMMANDED
# ATTITUDE LAG ANGLES (WHICH ACCOUNT FOR THE ANGLES BY WHICH THE BODY WILL
# LAG BEHIND A RAMP COMMAND IN ATTITUDE ANGLE DUE TO THE FINITE ANGULAR
# ACCELERATIONS AVAILABLE).

# FINDCDUW ALINES THE ESTIMATED THRUST VECTOR FROM THE THRUST DIRECTION
# FILTER WITH THE THRUST COMMAND VECTOR, AND, WHEN  XOVINHIB  SET,
# ALINES THE +Z HALF OF THE LM ZX PLANE WITH THE WINDOW COMMAND VECTOR.

## Page 900
# SPECIFICATIONS:

# INITIALIZATION: A SINGLE INTERPRETIVE CALL TO  INITCDUW  IS REQUIRED
#                 BEFORE EACH GUIDED MANEUVER USING FINDCDUW.

# CALL:           INTERPRETIVE CALL TO FINDCDUW WITH THE THRUST COMMAND
#                 VECTOR IN MPAC.  INTERPRETIVE CALL TO FINDCDUW -2 WITH
#                 THE THRUST COMMAND VECTOR IN UNFC/2 AND NOT IN MPAC.

# RETURNS:        NORMAL INTERPRETIVE IN ALL CASES

#                 1.       NORMALLY ALL AUTOPILOT CMDS ARE ISSUED.

#                 2.       IF NOT PNGCS AUTO, DO STOPRATE AND RETURN
#                          WITHOUT ISSUING AUTOPILOT CMDS.

#                 3.       IF ENGINE OFF, DO STOPRATE AND RETURN WITHOUT
#                          ISSUING AUTOPILOT CMDS.

# ALARMS:         00401 IF INPUTS DETERMINE AN ATTITUDE IN GIMBAL LOCK.
#                          FINDCDUW DRIVES CDUXD AND CDUYD TO THE RQD VALUES,
#                          BUT DRIVES CDUZD ONLY TO THE GIMBAL LOCK CONE.
#                 00402 IF UNFC/2 OR UNWC/2 PRODUCE OVERFLOW WHEN
#                          UNITIZED USING NORMUNIT.  FINDCDUW ISSUES
#                          STOPRATE AS ONLY INPUT TO AUTOPILOT.

# INPUTS:         UNFC/2   THRUST COMMAND VECTOR, NEED NOT BE SEMI-UNIT.
#                 UNWC/2   WINDOW COMMAND VECTOR, NEED NOT BE SEMI-UNIT.
#                 OGABIAS  POSSIBLE BIAS FOR OUTER GIMBAL ANGLE (ZEROED IN INITCDUW), UNITS OF PI.
#                 XOVINHIB FLAG DENOTING X AXIS OVERRIDE INHIBITED.
#                 CSMDOCKD FLAG DENOTING CSM DOCKED.
#                 STEERSW  FLAG DENOTING INSUFF THRUST FOR THRUST DIR FLTR.

# OUTPUTS:        DELCDUX,Y,Z
#                 OMEGAPD,+1,+2
#                 DELPEROR,+1,+2
#                 CPHI,+1,+2 FOR NOUN22

# DEBRIS:         FINDCDUW DESTROYS SINCDUX,Y,Z AND COSCDUX,Y,Z BY
#                 WRITING INTO THESE LOCATIONS THE SINES AND COSINES
#                 OF THE CDUD'S IN PNGCS-AUTO, OF THE CDU'S OTHERWISE.

## Page 901
# INITIALIZATION FOR FINDCDUW

                BANK            30
                SETLOC          FCDUW
                BANK

                EBANK=          ECDUW

                COUNT*          $$/FCDUW

INITCDUW        SSP             VLOAD
                                OGABIAS
                                0
                                UNITX
                STORE           UNFV/2
                STORE           UNWC/2
                RVQ

# FINDCDUW PRELIMINARIES

                VLOAD                                   # FINDCDUW -2: ENTRY WHEN UNFC/2 PRE-STORD
                                UNFC/2                  # INPUT VECTORS NEED NOT BE SEMI-UNIT
FINDCDUW        BOV             SETPD                   # FINDCDUW: ENTRY WHEN UNFC/2 IN MPAC
                                FINDCDUW                # INTERPRETER NOW INITIALIZED
                                22                      # LOCS 0 THRU 21 FOR DIRECTION COSINE MAT
                STQ             EXIT
                                QCDUWUSR                # SAVE RETURN ADDRESS

# MORE HAUSKEEPING

                CA              ECDUWL
                XCH             EBANK                   # SET EBANK
                TS              ECDUWUSR                # SAVE USER'S EBANK

                CA              DAPBOOLS
                MASK            CSMDOCKD                # CSMDOCKD MUST NOT BE BIT15
                CCS             A
                CA              ONE                     # INDEX IF CSM DOCKED
                TS              NDXCDUW

                CA              XOVINHIB                # XOVINHIB MUST NOT BE BIT15
                TS              FLPAUTNO                # SET TO POS-NON-ZERO FLAG PNGCS AUTO NOT

                MASK            DAPBOOLS
                TS              FLAGOODW                # FLAGOODW = ANY PNZ NUMBER IF XOV INHIBTD

## Page 902
# FETCH BASIC DATA

                INHINT                                  # RELINT AT PAUTNO (TC INTPRET)

                CA              CDUX                    # FETCH CDUX,CDUY,CDUZ IN ALL CASES, BUT
                TS              CDUSPOTX                #      REPLACE BELOW IF PNGCS AUTO
                CA              CDUY
                TS              CDUSPOTY
                CA              CDUZ
                TS              CDUSPOTZ

                CA              BIT10                   # PNGCS CONTROL BIT
                EXTEND
                RAND            CHAN30
                CCS             A
                TCF             PAUTNO                  # NOT PNGCS (BITS INVERTED)

                CA              BIT14                   # AUTO MODE BIT
                EXTEND
                RAND            CHAN31
                CCS             A
                TCF             PAUTNO                  # NOT AUTO (BITS INVERTED)

                TS              FLPAUTNO                # RESET FLAG PNGCS AUTO NOT

                CA              CDUXD                   # PNGCS AUTO: FETCH CDUXD,CDUYD,CDUZD
                TS              CDUSPOTX
                CA              CDUYD
                TS              CDUSPOTY
                CA              CDUZD
                TS              CDUSPOTZ

## Page 903
# FETCH INPUTS

PAUTNO          TC              INTPRET                 # ENTERING THRUST CMD STILL IN MPAC
                RTB
                                NORMUNIT
                STOVL           UNX/2                   # SEMI-UNIT THRUST CMD AS INITIAL UNX/2
                                UNWC/2
                RTB             RTB
                                NORMUNIT
                                QUICTRIG                # ALWAYS RQD TO OBTAIN TRIGS OF CDUD'S
                STOVL           UNZ/2                   # SEMI-UNIT WINDOW CMD AS INITIAL UNZ/2
                                DELV
                BOVB            UNIT
                                NOATTCNT                # AT LEAST ONE ENTERING CMD VCT ZERO
                BOV             CALL
                                AFTRFLTR                # IF UNIT DELV OVERFLOWS, SKIP FILTER
                                *SMNB*                  # YIELDS UNIT(DELV) IN VEH COORDS FOR FLTR

# THRUST DIRECTION FILTER

                EXIT

                CA              UNFVY/2                 # FOR RESTARTS, UNFV/2 ALWAYS INTACT, MPAC
                LXCH            MPAC            +3      #      RENEWED AFTER RETURN FROM CALLER,
                TC              FLTRSUB                 #      TWO FILTER UPDATES MAY BE DONE.
                TS              UNFVY/2                 # UNFV/2 NEED NOT BE EXACTLY SEMI-UNIT.

                CA              UNFVZ/2
                LXCH            MPAC            +5
                TC              FLTRSUB
                TS              UNFVZ/2

                TC              INTPRET                 # COMPLETES FILTER

## Page 904
# FIND A SUITABLE WINDOW POINTING VECTOR

AFTRFLTR        SLOAD           BHIZ                    # IF XOV NOT INHIBITED, GO FETCH ZNB
                                FLAGOODW
                                FETCHZNB
                VLOAD           CALL
                                UNZ/2
                                UNWCTEST

FETCHZNB        VLOAD
                                ZNBPIP
                STCALL          UNZ/2
                                UNWCTEST

                VLOAD           VCOMP                   # Z AND -X CAN'T BOTH PARALLEL UNFC/2
                                XNBPIP
                STORE           UNZ/2

# COMPUTE THE REQUIRED DIRECTION COSINE MATRIX

DCMCL           VLOAD           VXV
                                UNZ/2
                                UNX/2
                UNIT            PUSH                    # UNY/2 FIRST ITERATION
                VXV             VSL1
                                UNX/2
                STORE           UNZ/2                   # -UNZ/2 FIRST ITERATION
                VXSC            PDVL                    # EXCHANGE -UNFVZ/2 UNZ/2 FOR UNY/2
                                UNFVZ/2                 # MUST BE SMALL
                VXSC            BVSU                    # YIELDS -UNFVY/2 UNY/2-UNFVZ/2 UNZ/2
                                UNFVY/2                 # MUST BE SMALL
                VSL1            VAD
                                UNX/2
                UNIT                                    # TOTALLY ELIMINATES THRUST POINTING ERROR
                STORE           UNX/2                   # UNX/2
                VXV             VSL1
                                UNZ/2                   # -UNZ/2 WAS STORED HERE REMEMBER
                STORE           UNY/2                   # UNY/2
                VCOMP           VXV
                                UNX/2
                VSL1
                STORE           UNZ/2                   # UNZ/2

## Page 905
# COMPUTE THE REQUIRED GIMBAL ANGLES

                CALL
                                NB2CDUSP                # YIELDS THE RQD GIMBAL ANGLES, 2'S, PI
                EXIT

# BIAS OUTER GIMBAL ANGLE

                CA              OGABIAS
                ADS             MPAC

# LIMIT THE MIDDLE GIMBAL ANGLE & COMPUTE THE UNLIMITED GIMBAL ANGLE CHGS

                CA              MPAC            +2      # LIMIT THE MGA
                TS              L                       # CAN'T LXCH: NEED UNLIMITED MGA FOR ALARM
                CA              CDUZDLIM
                TC              LIMITSUB                # YIELDS LIMITED MGA. 1 BIT ERROR POSSIBLE
                XCH             MPAC            +2      #      BECAUSE USING 2'S COMP. WHO CARES?
                EXTEND
                MSU             MPAC            +2      # THIS BETTER YIELD ZERO
                EXTEND
                BZF             +2
                TCF             ALARMMGA

MGARET          INHINT                                  # RELINT AT TC INTPRET AFTER TCQCDUW

                ZL
                CA              TWO
DELGMBLP        TS              TEM2

                CA              L                       # TO PREVENT FALSE STARTS ABOUT X, ZERO
                EXTEND                                  #      FLAGOODW IF DELGMBZ OR Y TOO BIG.
                SQUARE
                AD              HI5                     # WITHIN 1 BIT OF -(45 DEG SQUARED)
                EXTEND
                BZMF            +3
                CA              ZERO
                TS              FLAGOODW

                INDEX           TEM2
                CA              MPAC
                INDEX           TEM2
                TS              CPHI                    # OUTPUTS TO NOUN22
                EXTEND
                INDEX           TEM2
                MSU             CDUXD                   # NO MATTER THAT THESE SLIGHTLY DIFFERENT
                COM                                     #      FROM WHEN WE INITIALLY FETCHED THEM
                INDEX           TEM2
                TS              -DELGMB                 # -UNLIMITED GIMBAL ANGLE CHGS, 1'S, PI
                TS              L                       # FOR PRECEDING TEST ON NEXT LOOP PASS
## Page 906
                CCS             TEM2
                TCF             DELGMBLP

## Page 907
# BRANCHES TO NOATTCNT

                CCS             FLPAUTNO
                TCF             NOATTCNT        +2      # NOT PNGCS AUTO

                CA              FLAGWRD5
                MASK            ENGONBIT
                EXTEND
                BZF             NOATTCNT        +2      # ENGINE NOT ON

## Page 908
# LIMIT THE ATTITUDE ANGLE CHANGES

# THIS SECTION LIMITS THE ATTITUDE ANGLE CHANGES ABOUT A SET OF ORTHOGONAL VEHICLE AXES X,YPRIME,ZPRIME.
# THESE AXES COINCIDE WITH THE COMMANDED VEHICLE AXES IF AND ONLY IF CDUXD IS ZERO.  THE PRIME SYSTEM IS
# THE COMMANDED VEHICLE SYSTEM ROTATED ABOUT THE X AXIS TO BRING THE Z AXIS INTO ALINEMENT WITH THE MIDDLE GIMBAL
# AXIS.  ATTITUDE ANGLE CHANGES IN THE PRIME SYSTEM ARE RELATED TO SMALL GIMBAL ANGLE CHANGES BY:

# * -DELATTX      *   * 1  SIN(CDUZD)  0 * * -DELGMBX *
# *               *   *                  * *          *
# * -DELATTYPRIME * = * 0  COS(CDUZD)  0 * * -DELGMBY *
# *               *   *                  * *          *
# * -DELATTZPRIME *   * 0  0           1 * * -DELGMBZ *

                LXCH            -DELGMB         +2      # SAME AS -DELATTZPRIME UNLIMITED
                INDEX           NDXCDUW
                CA              DAZMAX
                TC              LIMITSUB
                TS              -DELGMB         +2      # -DELGMBZ

                CA              -DELGMB         +1
                EXTEND
                MP              COSCDUZ                 # YIELDS -DELATTYPRIME/2 UNLIMITED
                TS              L
                INDEX           NDXCDUW
                CA              DAY/2MAX
                TC              LIMITSUB
                EXTEND
                DV              COSCDUZ
                XCH             -DELGMB         +1      # -DELGMBY, FETCHING UNLIMITED VALUE

                EXTEND
                MP              SINCDUZ
                DDOUBL
                COM
                EXTEND                                  # YIELDS +DELATTX UNLIMITD, MAG < 180 DEG,
                MSU             -DELGMB                 #      BASED ON UNLIMITED DELGMBY.
                TS              L                       #      ONE BIT ERROR IF OPERANDS IN MSU
                INDEX           NDXCDUW                 #      OF MIXED SIGNS.  WHO CARES?
                CA              DAXMAX
                TC              LIMITSUB
                TS              -DELGMB                 # SAVE LIMITED +DELATTX
                CCS             FLAGOODW
                CS              -DELGMB                 # FETCH IT BACK CHGING SIGN IF WINDOW GOOD
                TS              -DELGMB                 # OTHERWISE USE ZERO FOR -DELATTX
                CS              -DELGMB         +1
                EXTEND
                MP              SINCDUZ
                DDOUBL                                  # YIELDS -CNTRIB TO -DELATTX FROM -DELGMBY
                ADS             -DELGMB                 # -DELGMBX.  NO OVERFLOW SINCE LIMITED TO
                                                        # 20DEG(1+SIN(70DEG)/COS(70DEG)) < 180DEG

## Page 909
# COMPUTE COMMANDED ATTITUDE RATES

# * OMEGAPD *   * -2  -4 SINCDUZ          +0         * * -DELGMBX *
# *         *   *                                    * *          *
# * OMEGAQD * = * +0  -8 COSCDUZ COSCDUX  -4 SINCDUX * * -DELGMBY *
# *         *   *                                    * *          *
# * OMEGARD *   * +0  +8 COSCDUZ SINCDUX  -4 COSCDUX * * -DELGMBZ *

# ATTITUDE ANGLE RATES IN UNITS OF PI/4 RAD/SEC = K TRIG FCNS IN UNITS OF 2 X GIMBAL ANGLE RATES IN UNITS OF
# PI/2 RAD/SEC.  THE CONSTANTS ARE BASED ON DELGMB BEING THE GIMBAL ANGLE CHANGES IN UNITS OF PI RADIANS,
# AND 2 SECONDS BEING THE COMPUTATION PERIOD (THE PERIOD BETWEEN SUCCESSIVE PASSES THRU FINDCDUW).

                CS              -DELGMB
                TS              OMEGAPD
                CS              -DELGMB         +1
                EXTEND
                MP              SINCDUZ
                DDOUBL
                ADS             OMEGAPD
                ADS             OMEGAPD

                CS              -DELGMB         +1
                EXTEND
                MP              COSCDUX
                DDOUBL
                EXTEND
                MP              COSCDUZ
                TS              OMEGAQD
                CS              -DELGMB         +2
                EXTEND
                MP              SINCDUX
                ADS             OMEGAQD
                ADS             OMEGAQD
                ADS             OMEGAQD

                CA              -DELGMB         +1
                EXTEND
                MP              SINCDUX
                DDOUBL
                EXTEND
                MP              COSCDUZ
                TS              OMEGARD
                CS              -DELGMB         +2
                EXTEND
                MP              COSCDUX
                ADS             OMEGARD
                ADS             OMEGARD
                ADS             OMEGARD

## Page 910
# FINAL TRANSFER

                CA              TWO
CDUWXFR         TS              TEM2
                INDEX           TEM2
                CA              -DELGMB
                EXTEND
                MP              DT/DELT                 # RATIO OF DAP INTERVAL TO CDUW INTERVAL
                TC              ONESTO2S
                INDEX           TEM2
                TS              DELCDUX                 # ANGLE INTERFACE

                INDEX           TEM2
                CCS             OMEGAPD
                AD              ONE
                TCF             +2
                AD              ONE
                EXTEND                                  # WE NOW HAVE ABS(OMEGAPD,QD,RD)
                INDEX           TEM2
                MP              OMEGAPD
                EXTEND
                MP              BIT11                   # 1/16
                EXTEND
                INDEX           TEM2                    #                   2
                DV              1JACC                   # UNITS PI/4 RAD/SEC
                TS              L
                CA              DELERLIM
                TC              LIMITSUB
                INDEX           TEM2
                TS              DELPEROR                # LAG ANGLE = OMEGA ABS(OMEGA)/2 ACCEL
                CCS             TEM2
                TCF             CDUWXFR

# HAUSKEEPING AND RETURN

TCQCDUW         CA              ECDUWUSR
                TS              EBANK                   # RETURN USER'S EBANK

                TC              INTPRET
                SETPD           GOTO
                                0
                                QCDUWUSR                # NORMAL AND ABNORMAL RETURN TO USER

## Page 911
# THRUST VECTOR FILTER SUBROUTINE

FLTRSUB         EXTEND
                QXCH            TEM2
                TS              TEM3                    # SAVE ORIGINAL OFFSET
                COM                                     # ONE MCT, NO WDS, CAN BE SAVED IF NEG OF
                AD              L                       #      ORIG OFFSET ARRIVES IN A, BUT IT'S
                EXTEND                                  #      NOT WORTH THE INCREASED OBSCURITY.
                INDEX           NDXCDUW
                MP              GAINFLTR
                TS              L                       # INCR TO OFFSET, UNLIMITED
                CA              DUNFVLIM                # SAME LIMIT FOR Y AND Z
                TC              LIMITSUB                # YIELDS INCR TO OFFSET, LIMITED
                AD              TEM3                    # ORIGINAL OFFSET
                TS              L                       # TOTAL OFFSET, UNLIMITED
                CA              UNFVLIM                 # SAME LIMIT FOR Y AND Z
                TC              LIMITSUB                # YIELDS TOTAL OFFSET, LIMITED
                TC              TEM2

# SUBR TO TEST THE ANGLE BETWEEN THE PROPOSED WINDOW AND THRUST CMD VCTS

UNWCTEST        DOT             DSQ
                                UNX/2
                DSU             BMN
                                DOTSWFMX
                                DCMCL
                SSP             RVQ                     # RVQ FOR ALT CHOICE IF DOT MAGN TOO LARGE
                                FLAGOODW                #      ZEROING WINDOW GOOD FLAG
                                0

## Page 912
# NB2CDUSP RETURNS THE 2'S COMPLEMENT, PI, SP CDU ANGLES X,Y,Z IN MPAC,+1,+2 GIVEN THE MATRIX WHOSE ROW VECTORS
# ARE THE SEMI-UNIT NAV BASE VECTORS X,Y,Z EXPRESSED IN STABLE MEMBER COORDINATES, LOCATED AT 0 IN THE PUSH LIST.

# NB2CDUSP USES ARCTRGSP WHICH HAS A MAXIMUM ERROR OF +-4 BITS.

NB2CDUSP        DLOAD           DSQ
                                2
                BDSU            BPL
                                DP1/4TH
                                +3
                DLOAD
                                ZEROVECS                # IN CASE SIN WAS SLIGHTLY > 1/2
                SQRT            EXIT                    # YIELDS COS(CDUZ) IN UNITS OF 2

                EXTEND
                DCA             MPAC
                DDOUBL
                TS              TEM5
                TCF             +3
                CA              POSMAX                  # OVERFLOW. FETCH POSMAX, MPAC ALWAYS POS
                TS              TEM5                    # COS(CDUZ) IN TEM5, UNITS 1

                INDEX           FIXLOC
                CA              2
                LXCH            MPAC
                TC              ARCTRGSP
                TS              MPAC            +2      # CDUZ

                CA              ZERO
                TC              DVBYCOSM
                CA              FOUR
                TC              DVBYCOSM
                CS              TEM1
                TC              ARCTRGSP
                TS              MPAC            +1      # CDUY

                CA              BIT4
                TC              DVBYCOSM
                CA              16OCT
                TC              DVBYCOSM
                CS              TEM1
                TC              ARCTRGSP
                TS              MPAC                    # CDUX

                TC              INTPRET
                RVQ

16OCT           OCT             16

## Page 913
# THE ELEMENTS OF THE NAV BASE MATRIX WHICH WE MUST DIVIDE BY COS(MGA)
# ALREADY CONTAIN COS(MGA)/2 AS A FACTOR.  THEREFORE THE QUOTIENT SHOULD
# ORDINARILY NEVER EXCEED 1/2 IN MAGNITUDE.  BUT IF THE MGA IS NEAR PI/2
# THEN COS(MGA) IS NEAR ZERO, AND THERE MAY BE SOME CHAFF IN THE OTHER
# ELEMENTS OF THE MATRIX WHICH WOULD PRODUCE CHAOS UNDER DIVISION.
# BEFORE DIVIDING WE MAKE SURE COS(MGA) IS AT LEAST ONE BIT LARGER
# THAN THE MAGNITUDE OF THE HIGH ORDER PART OF THE OPERAND.

# IF ONE OR MORE DIVIDES CANNOT BE PERFORMED, THIS MEANS THAT THE
# REQUIRED MGA IS VERY NEARLY +-PI/2 AND THEREFORE THE OTHER GIMBAL
# ANGLES ARE INDETERMINATE.  THE INNER AND OUTER GIMBAL ANGLES RETURNED
# IN THIS CASE WILL BE RANDOM MULTIPLES OF PI/2.

DVBYCOSM        AD              FIXLOC
                TS              ADDRWD                  # ADRES OF OPERAND

                INDEX           ADDRWD                  # FETCH NEG ABS OF OPERAND, AD TEM5, AND
                CA              0                       #     SKIP DIVIDE IF RESULT NEG OR ZERO
                EXTEND
                BZMF            +2
                COM
                AD              TEM5                    # C(A) ZERO OR NEG, C(TEM5) ZERO OR POS
                EXTEND
                BZMF            TSL&TCQ                 # DIFFERENCE ALWAYS SMALL IF BRANCH

                EXTEND                                  # TEM5 EXCEEDS ABS HIGH ORDER PART OF
                INDEX           ADDRWD                  #      OPERAND BY AT LEAST ONE BIT.
                DCA             0                       #      THEREFORE IT EXCEEDS THE DP OPERAND
                EXTEND                                  #      AND DIVISION WILL ALWAYS SUCCEED.
                DV              TEM5
TSL&TCQ         TS              L
                LXCH            TEM1
                TC              Q

## Page 914
# ARCTRGSP RETURNS THE 2'S COMPLEMENT, PI, SP ANGLE IN THE A REGISTER GIVEN ITS SINE IN A AND ITS COSINE IN L IN
# UNITS OF 2.  THE RESULT IS AN UNAMBIGUOUS ANGLE ANYWHERE IN THE CIRCLE, WITH A MAXIMUM ERROR OF +-4 BITS.
# THE ERROR IS PRODUCED BY THE SUBROUTINE SPARCSIN WHICH IS USED ONLY IN THE REGION +-45 DEGREES.

ARCTRGSP        EXTEND
                BZF             SINZERO                 # TO AVOID DIVIDING BY ZERO

                EXTEND
                QXCH            TEM4
                TS              TEM2
                CA              L
                TS              TEM3
                CA              ZERO
                EXTEND
                DV              TEM2
                EXTEND
                BZF             USECOS

                CCS             TEM3                    # SIN IS SMALLER OR EQUAL
                CA              ZERO
                TCF             +4
                CS              TEM2                    # IF COS NEG, REVERSE SIGN OF SIN,
                TS              TEM2                    #      ANGLE = PI-ARCSIN(SIN)
                CA              NEGMAX                  # PICK UP PI, 2'S COMPLEMENT
                TS              TEM3                    # WE NO LONGER NEED COS
                CA              TEM2
                TC              SPARCSIN        -1
                TC              ONESTO2S
                EXTEND
                MSU             TEM3
1TO2&TCQ        TC              ONESTO2S
                TC              TEM4

USECOS          CS              TEM3                    # COS IS SMALLER
                TC              SPARCSIN        -1      # ANGLE = SIGN(SIN)(PI/2-ARCSIN(COS))
                AD              HALF
                TS              TEM3                    # WE NO LONGER NEED COS
                CCS             TEM2
                CA              TEM3
                TCF             1TO2&TCQ
                CS              TEM3
                TCF             1TO2&TCQ

SINZERO         CCS             L
                CA              ZERO
                TC              Q
                CA              NEGMAX                  # PI, 2'S COMP
                TC              Q

## Page 915
# SPARCSIN TAKES AN ARGUMENT SCALED UNITY IN A AND RETURNS AN ANGLE SCALED
# 180 DEGREES IN A.  IT HAS BEEN UNIT TESTED IN THE REGION +-.94 (+- 70
# DEGREES) AND THE MAXIMUM ERROR IS +-5 BITS WITH AN AVERAGE TIME OF
# 450 MICROSECONDS.  SPARCSIN -1 TAKES THE ARGUMENT SCALED TWO.(BOB CRISP)

                DOUBLE
SPARCSIN        TS              SR
                TCF             +4
                INDEX           A
                CS              LIMITS
                TS              SR
                EXTEND
                MP              A
                TS              TEM1
                EXTEND
                MP              DPL9
                AD              DPL7
                EXTEND
                MP              TEM1
                AD              DPL5
                EXTEND
                MP              TEM1
                AD              DPL3
                EXTEND
                MP              TEM1
                AD              DPL1
                EXTEND
                MP              SR
                TC              Q
DPL1            DEC             10502
DPL3            DEC             432
DPL5            DEC             7300
DPL7            DEC             -11803
DPL9            DEC             8397

## Page 916
# LIMITSUB LIMITS THE MAGNITUDE OF THE POSITIVE OR NEGATIVE VARIABLE
# ARRIVING IN L TO THE POSITIVE LIMIT ARRIVING IN A.
# THE SIGNED LIMITED VARIABLE IS RETURNED IN A.

# VERSION COURTESY HUGH BLAIR-SMITH

LIMITSUB        TS              TEM1
                CA              ZERO
                EXTEND
                DV              TEM1
                CCS             A
                LXCH            TEM1
                TCF             +2
                TCF             +3
                CA              L
                TC              Q
                CS              TEM1
                TC              Q

# SUBROUTINE TO CONVERT 1'S COMP SP TO 2'S COMP

ONESTO2S        CCS             A
                AD              ONE
                TC              Q
                CS              A
                TC              Q

# NO ATTITUDE CONTROL

NOATTCNT        TC              ALARM
                OCT             00402                   # NO ATTITUDE CONTROL

 +2             INHINT                                  # COME HERE FOR NOATTCNT WITHOUT ALARM
                TC              IBNKCALL                # RELINT AT TC INTPRET AFTER TCQCDUW
                FCADR           STOPRATE
                TCF             TCQCDUW                 # RETURN TO USER SKIPPING AUTOPILOT CMDS

# MIDDLE GIMBAL ANGLE ALARM

ALARMMGA        TC              ALARM
                OCT             00401
                TCF             MGARET

## Page 917
# ************************************************************************
# CONSTANTS
# ************************************************************************

# ADDRESS CONSTANTS

ECDUWL          ECADR           ECDUW
#
# THRUST DIRECTION FILTER CONSTANTS

GAINFLTR        DEC             .2                      # GAIN FILTER SANS CSM
                DEC             .1                      # GAIN FILTER WITH CSM

DUNFVLIM        DEC             .007            B-1     # 7 MR MAX CHG IN F DIR IN VEH IN 2 SECS.
                                                        # THIS DOES NOT ALLOW FOR S/C ROT RATE.

UNFVLIM         DEC             .129            B-1     # 129 MR MAX THRUST OFFSET. 105 MR TRAVEL
                                                        # +10MR DEFL+5MR MECH MOUNT+9MR ABLATION.
#
# CONSTANTS RELATED TO GIMBAL ANGLE COMPUTATIONS

DOTSWFMX        DEC             .93302          B-4     # LIM COLNRTY OF UNWC/2 & UNFC/2 TO 85 DEG
                                                        # LOWER PART COMES FROM NEXT CONSTANT

DAXMAX          DEC             .11111111111            # DELATTX LIM TO 20 DEG IN 2 SECS, 1'S, PI
                DEC             .0111111111             # 2 DEG WHEN CSM DOCKED

DAY/2MAX        DEC             .05555555555            # LIKEWISE FOR DELATTY
                DEC             .0055555555

DAZMAX          =               DAXMAX                  # LIKEWISE FOR DELATTZ

CDUZDLIM        DEC             .3888888888             # 70 DEG LIMIT FOR MGA, 1'S, PI
#
# CONSTANTS FOR DATA TRANSFER

DT/DELT         DEC             .05                     # .1 SEC/2 SEC WHICH IS THE AUTOPILOT
                                                        # CONTROL SAMPLE PERIOD/COMPUTATION PERIOD

DELERLIM        =               DAY/2MAX                # 10 DEG LIMIT FOR LAG ANGLES, 1'S, PI
#
