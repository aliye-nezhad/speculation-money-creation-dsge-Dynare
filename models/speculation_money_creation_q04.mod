/*=============================================================================
  DSGE MODEL: SPECULATION AND BANK MONEY CREATION
  Calibration case: q = 0.4

  Source: Aliye Nezhad's master's-thesis model and related research note.
  Purpose: Study how speculative-return and technology shocks transmit
           through bank money creation, inflation, and real activity.

  This repository version preserves the original model equations,
  scenario-specific calibration, shock standard deviations, and simulation
  length. Edits are limited to comments, formatting, explicit simulation
  defaults, a fixed random seed, and portable file organization.
=============================================================================*/

/*=============================================================================
  1. ENDOGENOUS VARIABLES
=============================================================================*/
var
    A       /* Technology */
    K       /* Capital */
    N       /* Labor */
    M       /* Money / liquidity measure */
    PPI     /* Inflation */
    W       /* Wage */
    C       /* Consumption */
    R       /* Return on capital */
    P       /* Price level */
    Y       /* Output */
    IS      /* Speculative return */
    IL      /* Loan interest rate */
    O       /* Leisure */
    T       /* Transfers */
    IIP     /* Nominal interest rate */
    II      /* Investment */
    IP      /* Gross nominal interest */
    B       /* Bonds */
    G       /* Government spending */
    IT;     /* Deposit interest rate */
/*=============================================================================
  2. EXOGENOUS SHOCKS
=============================================================================*/
varexo
    EEPSILONA   /* Technology shock innovation */
    EEPSILONIS; /* Speculative-return shock innovation */
/*=============================================================================
  3. PARAMETERS
=============================================================================*/
parameters
    qq          /* Productive loan-allocation share: q */
    aalpha      /* Capital elasticity */
    rhois       /* Speculative-return shock persistence */
    bbeta       /* Discount factor */
    ggama       /* Loan/liquidity elasticity in production */
    aix         /* Banking-sector labor share */
    rhoa        /* Technology shock persistence */
    mmo         /* Time-deposit real-equivalent parameter */
    ddelta      /* Demand-deposit real-equivalent parameter */
    rrt         /* Reserve requirement on time deposits */
    rrd         /* Reserve requirement on demand deposits */
    bbi         /* Time-deposit share */
    aa          /* Demand-deposit share */
    ddelta2     /* Capital depreciation rate */
    eeta        /* Consumption weight in utility */
    PPISS       /* Steady-state gross inflation */
    KSS         /* Steady-state capital */
    ILSS        /* Steady-state loan interest rate */
    TSS         /* Steady-state transfers */
    GSS         /* Steady-state government spending */
    IPSS        /* Steady-state gross nominal interest */
    IIPSS       /* Steady-state nominal interest rate */
    BSS         /* Steady-state bonds */
    PSS         /* Steady-state price level */
    aalpha2     /* Auxiliary calibration parameter */
    MSS         /* Steady-state money */
    CSS         /* Steady-state consumption */
    IISS        /* Steady-state investment */
    RSS         /* Steady-state return on capital */
    NSS         /* Steady-state labor */
    OSS         /* Steady-state leisure */
    ISSS        /* Steady-state speculative return */
    YSS         /* Steady-state output */
    WSS         /* Steady-state wage */
    ASS         /* Steady-state technology */
    ITSS        /* Steady-state deposit interest rate */
    zz;         /* Banking-sector capital share */
/*=============================================================================
  4. CALIBRATION
=============================================================================*/
qq      = 0.4;
zz      = 0.0202830062;
aalpha  = 0.414;
bbeta   = 0.965;
ggama   = 0.09351;
aix     = 0.0193370166;
rhoa    = 0.764;
mmo     = 0.0021722644;
ddelta  = 0.0021722644;
rrt     = 0.1216693017;
rrd     = 0.1190081099;
bbi     = 0.6634227136;
aa      = 0.1606872842;
ddelta2 = 0.02;
eeta    = 0.95;
PPISS   = 1;
PSS     = 1;
aalpha2 = 0.1233135453;
MSS     = 0.05407787993;
CSS     = 0.3192834582;
IISS    = 0.148;
RSS     = 0.0562694301;
NSS     = 0.583;
OSS     = 0.417;
ISSS    = 1.948540193;
YSS     = 0.0954086821;
WSS     = 0.0805966069;
ASS     = 0.02330282698;
ITSS    = 0.008471524590;
KSS     = 7.4;
ILSS    = 0.03725956339;
TSS     = 0.2652055783;
IPSS    = 1.0362624301;
BSS     = -17.48529743;
IIPSS   = 0.036264301;
GSS     = 0.3689761929;
rhois   = -0.125333333;
/*=============================================================================
  5. PREDETERMINED VARIABLES
=============================================================================*/
predetermined_variables M K;
/*=============================================================================
  6. MODEL
=============================================================================*/
model(linear);
    /*-------------------------------------------------------------------------
      Interest-rate relationship
      Preserved from the original code:
          IP*IPSS = IIP*IIPSS
    -------------------------------------------------------------------------*/
    IP*IPSS = IIP*IIPSS;
    /*-------------------------------------------------------------------------
      Government budget constraint
    -------------------------------------------------------------------------*/
    (MSS/PSS)*PPISS*(M(+1) + PPI(+1) - P(+1))
    + (BSS/PSS)*PPISS*(B(+1) + PPI(+1) - P(+1))
    = (BSS/PSS)*IPSS*(B - P + IP)
    + (MSS/PSS)*(M - P)
    + (TSS/PSS)*(T - P)
    + (GSS/PSS)*(G - P);
    /*-------------------------------------------------------------------------
      Inflation definition
    -------------------------------------------------------------------------*/
    PPISS*PPI = P - P(-1);
    /*-------------------------------------------------------------------------
      Leisure-labor relation
    -------------------------------------------------------------------------*/
    O*OSS = -N*NSS;
    /*-------------------------------------------------------------------------
      Capital accumulation
    -------------------------------------------------------------------------*/
    KSS*K(+1) = KSS*K*(1 - ddelta2) + IISS*II;
    /*-------------------------------------------------------------------------
      Production function
    -------------------------------------------------------------------------*/
    Y = A
    + aalpha*K
    + ggama*(M - P)
    + (1 - aalpha - ggama)*N;
    /*-------------------------------------------------------------------------
      Return on capital
    -------------------------------------------------------------------------*/
    R = A
    + (aalpha - 1)*K
    + ggama*(M - P)
    + (1 - aalpha - ggama)*N;
    /*-------------------------------------------------------------------------
      Wage equation
    -------------------------------------------------------------------------*/
    W = A
    + aalpha*K
    + (-aalpha - ggama)*N
    + ggama*(M - P);
    /*-------------------------------------------------------------------------
      Loan interest equation
    -------------------------------------------------------------------------*/
    IL = A
    + aalpha*K
    + (ggama - 1)*(M - P)
    + N*(1 - aalpha - ggama);
    /*-------------------------------------------------------------------------
      Technology shock process
    -------------------------------------------------------------------------*/
    A = rhoa*A(-1) + EEPSILONA;
    /*-------------------------------------------------------------------------
      Speculative-return shock process
    -------------------------------------------------------------------------*/
    IS = rhois*IS(-1) + EEPSILONIS;
    /*-------------------------------------------------------------------------
      Consumption-leisure condition
    -------------------------------------------------------------------------*/
    CSS*C = OSS*WSS*(W + O);
    /*-------------------------------------------------------------------------
      Cash-in-advance constraint
    -------------------------------------------------------------------------*/
    (MSS/PSS)*(M - P)
    + (TSS/PSS)*(T - P)
    = CSS*C;
    /*-------------------------------------------------------------------------
      Banking condition
    -------------------------------------------------------------------------*/
    ((bbi/(mmo + rrt)) + (aa/(ddelta + rrd)) - bbi - aa)
    *ILSS*(MSS/PSS)*(M + IL - P)
    = aix*(WSS*NSS*(W + N))
    + zz*(RSS*KSS*(R + K))
    + ITSS*(MSS/PSS)*(M - P + IT)*(bbi/mmo + rrt);
    /*-------------------------------------------------------------------------
      Resource constraint
    -------------------------------------------------------------------------*/
    YSS*Y
    + (MSS/PSS)*ISSS*(M + IS - P)*(1 - qq)
    *((bbi/(mmo + rrt)) + (aa/(ddelta + rrd)) - bbi - aa)
    = (1 - aix)*(WSS*NSS*(W + N))
    + (1 - zz)*(RSS*KSS*(R + K))
    + ((bbi/(mmo + rrt)) + (aa/(ddelta + rrd)) - bbi - aa)
    *(MSS/PSS)*ILSS*(M + IL - P);
    /*-------------------------------------------------------------------------
      Household budget constraint
    -------------------------------------------------------------------------*/
    WSS*NSS*(W + N)
    + KSS*K*(1 - ddelta2)
    + KSS*RSS*(K + R)
    + (TSS/PSS)*(T - P)
    + (MSS/PSS)*(M - P)
    + (MSS/PSS)*ITSS*(bbi/(mmo + rrt))*(M - P + IT)
    + (BSS/PSS)*IPSS*(B - P + IP)
    = (BSS/PSS)*PPISS*(B(+1) + PPI(+1) - P(+1))
    + KSS*K(+1)
    + CSS*C
    + (MSS/PSS)*PPISS*(M(+1) + PPI(+1) - P(+1))
    - ISSS*(MSS/PSS)*(M + IS - P)
    *((bbi/(mmo + rrt)) + (aa/(ddelta + rrd)) - bbi - aa)*(1 - qq)
    + ((bbi/(mmo + rrt)) + (aa/(ddelta + rrd)) - bbi - aa)
    *(MSS/PSS)*(M - P);
    /*-------------------------------------------------------------------------
      Euler equation for bonds
    -------------------------------------------------------------------------*/
    bbeta*IPSS*(IP(+1) + eeta*(C(+1) + O) + W)
    = PPISS*(PPI(+1) + W(+1) + eeta*(C + O(+1)));
    /*-------------------------------------------------------------------------
      Fisher equation
    -------------------------------------------------------------------------*/
    (1 - ddelta2)*PPISS*PPI
    + (R + PPI)*RSS*PPISS
    = IP*IPSS;
    /*-------------------------------------------------------------------------
      Euler equation for capital
    -------------------------------------------------------------------------*/
    W(+1) + eeta*O(+1) + eeta*C
    = bbeta*(1 - ddelta2)*(eeta*C(+1) + eeta*O + W)
    + bbeta*RSS*(W + R(+1) + eeta*C(+1) + eeta*O);
    /*-------------------------------------------------------------------------
      Money demand condition
    -------------------------------------------------------------------------*/
    (PPISS/bbeta)*PPI(+1)
    - (eeta/(1 - eeta))*WSS*
      (eeta*(C(+1) + O - C + O(+1)) + O(+1) - C(+1) + W)
    + (eeta*(C(+1) - C + O - O(+1)) - W(+1) + W)
    = (((bbi/(mmo + rrt)) + (aa/(ddelta + rrd)) - bbi - aa) - 1)
      *(eeta*(C(+1) - C + O - O(+1)) - W(+1) + W)
    - ((bbi/(mmo + rrt)) + (aa/(ddelta + rrd)) - bbi - aa)
      *(eeta*(C(+1) - C + O - O(+1)) - W(+1) + W + IS(+1))
      *(1 - qq)*ISSS
    - (bbi/(mmo + rrt))*ITSS*
      (eeta*(C(+1) - C + O - O(+1)) - W(+1) + W + IT(+1));
end;
/*=============================================================================
  7. INITIAL VALUES
=============================================================================*/
initval;
    A          = 0;
    K          = 0;
    N          = 0;
    M          = 0;
    PPI        = 0;
    W          = 0;
    C          = 0;
    R          = 0;
    Y          = 0;
    IS         = 0;
    IL         = 0;
    O          = 0;
    P          = 0;
    IP         = 0;
    B          = 0;
    IIP        = 0;
    G          = 0;
    EEPSILONA  = 0;
    EEPSILONIS = 0;
    IT         = 0;
    T          = 0;
end;
/*=============================================================================
  8. MODEL DIAGNOSTICS
=============================================================================*/
resid(1);
steady;
check;
/*=============================================================================
  9. SHOCKS
=============================================================================*/
shocks;
    var EEPSILONIS;
    stderr 0.01;
    var EEPSILONA;
    stderr 0.01;
end;
/*=============================================================================
  10. STOCHASTIC SIMULATION
=============================================================================*/
set_dynare_seed(12345);
stoch_simul(order=1, irf=40, periods=5000);
