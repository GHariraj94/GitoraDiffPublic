CREATE OR REPLACE NONEDITIONABLE PACKAGE "PKGRETURNCURSOR" 

    is

    Function fncReturnCursor
        (   XMLParam in GConst.gXMLType%Type)
        Return GConst.DataCursor;

    Function fncGetDescription
        (   PickKeyValue in number,
            DescriptionType in number)
        Return varchar2;



FUNCTION fncgethumanreadablefilesize (p_size IN NUMBER) 
RETURN VARCHAR2;
    Function fncRollover
        (   dealnumber in varchar2,
            ReturnType in number)
        Return number;


     function fncDealProfile(DealNumber varchar2)
         return number ;

--    Function fncMTMRate
--    (   DealNumber  in varchar2,
--        DealType in number,
--        MTMType in number,
--        AskRate in number := 0,
--        BidRate in number := 0,
--        WashRate in number := 0)
--    return number;


    Procedure prcGetDictionary
        (   ParamData   in  Gconst.gClobType%Type,
            ErrorData   out NoCopy Gconst.gClobType%Type,
            ProcessData out NoCopy Gconst.gClobType%Type,
            GenCursor   out Gconst.DataCursor,
            NextCursor  out Gconst.DataCursor);

    function fncGetDescriptionMulti
       (   pickkeyvalue in varchar2,
           descriptiontype in number) return varchar2;    

    function fncReturnCursorgetdescriptionMulti
       (   pickkeyvalue in varchar2,
           descriptiontypeofPickVal in number,
           descriptiontypeofDescrip in number) return varchar2; 

    Procedure prcReturnCursor
        (   ParamData   in  Gconst.gClobType%Type,
            ErrorData   out NoCopy Gconst.gClobType%Type,
            ProcessData out NoCopy  Gconst.gClobType%Type,
            GenCursor   out Gconst.DataCursor);

            function fncgetShortcutNumber
     (ShortCut in number,
      ShortCutKey in number)
      return number;
function fncUserLoginCheck
      (UserID in Varchar2, 
       UserPassword in varchar2) 
       return varchar2;
function fncGetMenuPath(MenuID in number)
  return varchar2;       
function fncGenerateMenu
    (userid in varchar2)
    return number;

    BASEAMOUNT                      CONSTANT number(1) := 1;
    EXCHANGERATE                    CONSTANT number(1) := 2;
    OTHERAMOUNT                     CONSTANT number(1) := 3;
    LOCALRATE                       CONSTANT number(1) := 4;
    AMOUNTLOCAL                     CONSTANT number(1) := 5;

    --  Ref Cursor Types returned
    REFPICKUPLIST                   CONSTANT number(4) := 1001;
    REFPICKUPFORM                   CONSTANT number(4) := 1004;
    REFXMLFIELDS                    CONSTANT number(4) := 1005;
    REFMENUITEMS                    CONSTANT number(4) := 1006;
    REFRELATION                     CONSTANT number(4) := 1009;
    REFACCESSGROUP                  CONSTANT number(4) := 1015;
    REFLOGININFO                    CONSTANT number(4) := 1016;
    REFALLUSERS                     CONSTANT number(4) := 1050;
    REFSECURITYPOLICY               CONSTANT number(4) := 1051;
    REFRISKDETAILS                  Constant number(4) := 1055;
    REFREPORTMENU                   constant number(4) := 1056;
     -- Modified by by Manjunath Reddy on 05/03/2008 For Geting Risk Params
    REFRISKPARAM                    Constant number(4) := 1057;
    REFTRADEDEALS                   CONSTANT number(4) := 1060;
    REFREPORTGROUPS                 CONSTANT number(4) := 1067;
    REFREPORTCODES                  CONSTANT number(4) := 1068;
    REFDEALS                        CONSTANT number(4) := 1080;
    REFPARTICULARDEAL               CONSTANT number(4) := 1082;
    REFMATURITYDATECALC             CONSTANT number(4) := 1088;
    REFRATES                        CONSTANT number(4) := 1099;
    REFKEYGROUP                     CONSTANT number(4) := 1104;
    REFHEDGEDEALS                   CONSTANT number(4) := 1135;
    REFHEDGESPECIFIC                CONSTANT number(4) := 1136;
    REFPICKENTITY                   CONSTANT number(4) := 1137; --added by supriya
    REFGETENTITYRELATION            CONSTANT number(4) := 1138; --added by supriya
    REFOPTIONDEALS                   CONSTANT number(4) := 1139;
    REFGETRELATIONTYPE              CONSTANT number(4) := 4002; --added by supriya
    REFGETMAINENTITY                CONSTANT number(4) := 4005; --added by supriya
    REFORDERLINKING                 CONSTANT number(4) := 3043;
    REFDEALLINKING                  CONSTANT number(4) := 1145;
    REFFORWARDLINKING               CONSTANT number(4) := 1146;
    REFOPTIONLINKING                CONSTANT number(4) := 1147;
    REFTRADELINKING                 CONSTANT number(4) := 1148;
    REFCUSTOMRATEIMP                CONSTANT NUMBER(4) := 1155; -- added by ishwarachandra
    REFCURRENCYLABEL                CONSTANT number(4) := 1170;
    REFPRODUCTDETAILS               CONSTANT number(4) := 1203;
    REFCUSTOMERDETAILS              CONSTANT number(4) := 1106;
-----Currency Futures-------------------------------------------------------------
    REFFUTUREOUTSTANDING            CONSTANT number(4) := 1402;    
    REFPATICULAREFUTDEAL            CONSTANT number(4) := 4006;
----- Derivatives Module----------------------------------------------------------
    REFOPTIONTRADES                 CONSTANT number(4) := 1501;
    REFOPTIONLEGS                   CONSTANT number(4) := 1503;
    REFOPTIONSPL                    CONSTANT number(4) := 1504;  
    Refinflowoutflowdetails         Constant Number(4) := 1530;
    Refretreivedeals                Constant Number(4) := 1531;
    --Added by Supriya for Option Valuation
    REFVALUATIONRESULT              CONSTANT NUMBER(4) := 1539;
    REFOptionCalculator             CONSTANT NUMBER(4) := 1541;
    RefMarketFxRates                CONSTANT NUMBER(4) := 1540;
    RefMarketInterest               constant number(4) := 1543;    
    RefMarketVols                   constant number(4) := 4003;   
    RefMarketSmileCurved            constant number(4) := 4004;    
   -- refGetMTMData           CONSTANT NUMBER(4) := 1542;   
    refGetCurrencyPairDetails            CONSTANT NUMBER(4) := 1545;
    refGetDirectIndirect            Constant number(4) := 1546;

    REFDEALSVIEW                    CONSTANT NUMBER(4) := 1601;
    REFBLOOMBERG                    CONSTANT number(4) := 1602;
    REFBLOOMBERG1                   CONSTANT number(4) := 1603;
    -- Forward Rollover
    REFROLLOVERDELETE               CONSTANT NUMBER(4) := 1535;
    REFROLLOVERFORWARD              CONSTANT NUMBER(4) := 1536;

    Refstresspnlcurrency            Constant Number(8) := 1616;
    REFSTRESSPNLCOMPANY             CONSTANT NUMBER(8) := 1617;
    Refstresspnlrate                Constant Number(8) := 1618;
    Refstresspnledit                Constant Number(8) := 1619;
    REFSTRESSPNLCURRENCYDETAILED    Constant Number(8) := 1620;

    -- Forward Rollover
    -- Future Rollover
    REFROLLOVERFUTUREDEALS          CONSTANT NUMBER(4):=1537;
    ---------
    refMaturityPopulate             CONSTANT NUMBER(4) := 1764;  
    refGetExposure                  CONSTANT NUMBER(4) := 1769;
    refdealername                   CONSTANT NUMBER(4) := 1765;  
    refGetForward                   CONSTANT NUMBER(4) := 1770;
    refFrowardBatchno               CONSTANT NUMBER(4) := 1771;
    refExposureLinkDelete           CONSTANT NUMBER(4) := 1772;
    Refdeallinkdelete               Constant Number(4) := 1773;
    --------data uplaod------------------------------------------
    REFGETSYNONYMNAME               CONSTANT NUMBER(4) := 1774;
    refgetmasterdataCloud           CONSTANT NUMBER(4) := 1750; 
    refgetxmlfieldcloud             CONSTANT NUMBER(4) := 1751;
    refgetfileuploaddetailscloud    CONSTANT NUMBER(4) := 1752;
    refgetfiledetailscloud          CONSTANT NUMBER(4) := 1753;
    refgetsynonymdetailscloud       CONSTANT NUMBER(4) := 1754;
    ----------------------------------------------------------------
    refGetForwardCross              constant number(4) := 1801;
    refDealLinkDeletecross          constant number(4) := 1802;
    refDashboardPosition            constant number(4) := 3003;
    refDashboardPosition_detail     constant number(4) := 3004;
    REFPOSITIONGAPVIEWNEW           CONSTANT number(4) := 3001;
    REFPOSITIONGAPVIEWGRIDNEW       CONSTANT NUMBER(4) := 3002;
    RefNOPDashBoard                 CONSTANT NUMBER(4) := 3006;

    REFNOPDashBoardCurrenypairWise      CONSTANT NUMBER(4) := 3007;
    REFNOPDashBoardCurrenypairConsolidate CONSTANT number(4):=3008;

    REFIMAGESCANNING                CONSTANT NUMBER(4) := 3010;
    REFIMAGEGRIDDATA                CONSTANT NUMBER(4) := 3011; 
    REFHEDGESTATUS                  CONSTANT NUMBER(4) := 3012;
    REFFXSETTLEMENT                 CONSTANT NUMBER(4) := 3013;
    refGENPICKUP                    CONSTANT NUMBER(4) := 3000;
    REFLIMITDASHBOARD               CONSTANT NUMBER(4) := 3016;
    --REFLIMITDRILL                   CONSTANT NUMBER(4)  :=3017;
    REFBANWISELIMIT                 CONSTANT NUMBER(4) := 3018;    
    REFSTOPLOSS                     CONSTANT NUMBER(4) := 3019;
    --RefNOPDashBoard_Details         CONSTANT NUMBER(4)  :=3020;
    REFGRIDSCHEMA                   CONSTANT number(4) := 3021;
    refDashboardBudget              CONSTANT number(4) := 3022;
    refDashboardPortfolio           CONSTANT number(4) := 3023;
    refDashboardDealer              CONSTANT number(4) := 3024;
    --refDashboardCurrency            CONSTANT number(4):=3025;
    refRiskMonitoring               constant number(4) := 3025;
    refRiskMonitoring_detail        constant number(4) := 3026;
    refUserDataFormat               CONSTANT number(4) := 3035;
    refEntityTABList                Constant number(4) := 3028;
            -- added by manjunath reddy on 02/04/2019 to take care other than add data 
    REFGETLOADDATA                  Constant number(4) := 3027;
    REFPROGRAMUNITVALIDATION        CONSTANT NUMBER(4) := 3029;
    REFFXSUMMARYLOCWISE             CONSTANT number(4) := 3031;
    REFFXSUMMARYFWDOPT              CONSTANT number(4) := 3032;
    REFUSERALERTS                   CONSTANT NUMBER(4) := 3034;
    --CURSORGRIDTEST                  CONSTANT NUMBER(4)  := 3038;
    --REFMONTHLYSETTLEMENT            CONSTANT NUMBER(4)  := 3040;
    REFFXSETTLEMENTNEW              CONSTANT NUMBER(4) := 3041;
    REFUSERALERTS_Details           CONSTANT NUMBER(4) := 3042;
    refDeliveryBatchNo              CONSTANT NUMBER(4) := 3044;
    RefGetSynonymsList              CONSTANT NUMBER(4) := 3045;
    RefGetSynonymScreenData         CONSTANT NUMBER(4) := 3046;
    REFDMSSYNONYMS                  CONSTANT NUMBER(4) := 3047;
    REFDMSDETAILS                   CONSTANT NUMBER(4) := 3048;
    REFHOLIDAYCHECK                 Constant number(4) := 3049;
    REFEMAILCONFIG                  Constant number(4) := 3050;
    REFPASSWORDSTATUS               Constant number(4) := 3051;
    REFUSERVALIDATE                 CONSTANT number(4) := 3052;
    refxmlfieldsBrowser             Constant number(4) := 3053;
    REFLICENSEUSERS                 CONSTANT NUMBER(4) := 3054;
    REFLICENSEMODULES               CONSTANT NUMBER(4) := 3055;
    REFGETREPORTCOLUMNS             CONSTANT NUMBER(4) := 3056;
    REFGETREPORTAGGREGATES          CONSTANT NUMBER(4) := 3057;
    REFCHECKEMAILEXISTS             CONSTANT NUMBER(4) := 3060;
    REFGETAUDITTRAIL                CONSTANT NUMBER(4) := 3065;
    REFSCREENSAUDIT                 CONSTANT NUMBER(4) := 3064;
    REFGETOPTIONPRODUCT             CONSTANT NUMBER(4) := 3066;
    REFLOADCASHFAIRHEDGE            constant number(4) := 3067;
    REFLOADVIEWCASHFLOW             constant number(4) := 3068;
    REFLOADCASHFAIRHEDGEDETAILS     constant number(4) := 3069;
    REFGETFORWARDOPTIONSBOOKING     constant number(4) := 3070;
    REFGETFORWARDOPTIONSCANCEL      constant number(4) := 3071;
    REFLOADFORWARDOPTIONSDELETET    constant number(4) := 3072;
    REFLINKREFERENCE                constant number(4) := 3073;
    REFLoggedUser                   constant number(4) := 3074;
    REFGETSYNONYMDATA               constant number(4) := 3075;
    REFGETXMLFIELDDATA              constant number(4) := 3076;  
    REFGETSYNONYMS                  constant number(4) := 3077;  
    REGGETDISPLAYBUTTONS            CONSTANT number(4) := 3078;


    REFRATESTICKER                  constant number(4) := 4001; 
    REFGETFUTUREPRODUCT             CONSTANT NUMBER(4) := 4007;  
    REFGETCASHFLOWCATEGORIES        CONSTANT NUMBER(4) := 4008; 
    REFGETBANKBRANCHDETAILS         CONSTANT NUMBER(4) := 4009; 
    REFCASHFLOWBUDGETDETAILS        CONSTANT NUMBER(4) := 4010; 
    RefGetEntityDetails             CONSTANT NUMBER(4) := 4012; 
    REFGETCASHINHANDDETAILS         CONSTANT NUMBER(4) := 4011; 
    REFGETCASHPOOLDETAILS           CONSTANT NUMBER(4) := 4013; 
    REFGETCASHINHANDREFERENCE       CONSTANT NUMBER(4) := 4014; 
    REFGETCASHINHANDVIEW            CONSTANT NUMBER(4) := 4015;
    REFCASHPOSITIONDASHBOARD        CONSTANT NUMBER(4) := 4016;
    REFDAILYCASHFLOWDETAILS         CONSTANT NUMBER(4) := 4017;
    REFGETPOLICYGROUP               CONSTANT NUMBER(4) := 4018;
    REFMONTHLYCASHFLOWDETAILS       CONSTANT NUMBER(4) := 4019;
    REFFILTERDAILYCASHFLOW          CONSTANT NUMBER(4) := 4020;
    REFFILTERMONTHLYCASHFLOW        CONSTANT NUMBER(4) := 4021;
    REFGETCASHINHANDASONDATE        CONSTANT NUMBER(4) := 4022;
    REFGETRECIEPTANDPAYMENTDETAILS  CONSTANT NUMBER(4) := 4023;
    REFGETFUNDREQUIREMENT           CONSTANT NUMBER(4) := 4024;
    REFGETMATURITYSCHEDULE          CONSTANT NUMBER(4) := 4025;
    REFGETSWAPDETAILSIRS            CONSTANT NUMBER(4) := 4026;
    REFGETIRSSETTLEMENTDETAILS      CONSTANT NUMBER(4) := 4027;
    REFGETIRSREFERENCESETTLEMENT    CONSTANT NUMBER(4) := 4028;
    refIRSHolidayList               CONSTANT NUMBER(4) := 4029;
    REFGETSWAPREFERENCEDETAILS      CONSTANT NUMBER(4) := 4030;
    REFGETPRINCIPALSCHEDULEIRS      CONSTANT NUMBER(4) := 4031;
    REFGETSETTLEMENTSCHEDULEDETS    CONSTANT NUMBER(4) := 4032;
    REFGETMAXSETTLEMENTDATE         CONSTANT NUMBER(4) := 4033;
    REFGETSYNONYMWITHID             CONSTANT NUMBER(4) := 4034;
    REFGETFORWARDDATA               CONSTANT NUMBER(4) := 4035;  
    REFGETPRINCIPALSCHEDULECSS      CONSTANT NUMBER(4) := 4036;
    REFGETSYNONYMCOLUMN             CONSTANT NUMBER(4) := 4037;  
    REFGETCONFIRMREMARKS            CONSTANT NUMBER(4) := 4038;

    REFVARANALYSISMAIN              CONSTANT number(4) := 4039;
    REFVARANALYSISSUBPRODUCTWISE    CONSTANT number(4) := 4040;
    REFVARANALYSISPRODUCTWISE       CONSTANT number(4) := 4041;
    REFVARANALYSISCURRENCYWISE      CONSTANT number(4) := 4042;
    REFVARANALYSISDEALER            CONSTANT number(4) := 4043;
    REFGETDATES                     CONSTANT number(4) := 4044;
    REFGETMENUS                     CONSTANT number(4) := 4045;
    REFGETCURSORDATES               CONSTANT number(4) := 4046;  
    REFGETPICKCODES                 CONSTANT number(4) := 4047;  
    REFGETLABELTEXT                 CONSTANT number(4) := 4048;  
    REFGETALERTCODE                 CONSTANT number(4) := 4049;  
    REFGETREPORTLIST                CONSTANT number(4) := 4050;  
    REFGETDATANAMES                 CONSTANT number(4) := 4051; 
    REFGETDATADETAILS               CONSTANT number(4) := 4052; 
    REFGETDATAUPLOAD                CONSTANT number(4) := 4053; 
    REFGETDEALERSDRILLDOWN          CONSTANT number(4) := 4054;
    REFGETDEALERSDRILLDOWNPNL       CONSTANT number(4) := 4055; 
    REFGETREQUESTID                 CONSTANT number(4) := 4056; 
    REFGETFXSUMMARYDRILLDOWN        CONSTANT number(4) := 4057;
    REFGETOPTIONTYPECONFIG          CONSTANT number(4) := 4058;
    REFGETALLOWEDUSERCOUNT          CONSTANT number(4) := 4059;
    REFGETOPTIONTYPE                CONSTANT number(4) := 4060;
    REFGETLEGSCONFIG                CONSTANT number(4) := 4061;
    REFGETLICENSESTATUS             CONSTANT number(4) := 4062;
    REFGETUSERPREFERENCE            CONSTANT number(4) := 4063;
    REFGETINFLOWMARGINRATE          CONSTANT number(4) := 4064;
    REFGETOUTFLOWMARGINRATE         CONSTANT number(4) := 4065;
    REFGETCOLUMNNAMES               CONSTANT number(4) := 4066;
    REFGETHEDGEDATA                 CONSTANT number(4) := 4067;
    REFGETPREFERENCEFORUSER         CONSTANT number(4) := 4068;
    REFGETCASHINHANDFORCASHPOOL     CONSTANT number(4) := 4069;
    REFGETCASHANALYSISDATA          CONSTANT number(4) := 4070;
    REFGETCATEGORY                  CONSTANT number(4) := 4071;
    REFPICKKEYVALUES                CONSTANT number(4) := 4072;
    REFGETRATES                     CONSTANT number(4) := 4073;
    REFGLOBALCASHPOSITION           CONSTANT number(4) := 4074;
    REFLOCALCASHPOSITION            CONSTANT number(4) := 4075;
    REFGETBUDGETDETAILS             CONSTANT number(4) := 4076;
    REFGETDATANAME                  CONSTANT number(4) := 4077;
    REFMAPCASHFLOWACTUALS           CONSTANT NUMBER(4) := 4078;
    REFGETNOTMAPPEDACTUALS          CONSTANT NUMBER(4) := 4079;
    REFGETFUNDREQUIREMENTDETAILS    CONSTANT NUMBER(4) := 4080;
    REFACCESSGROUPDELETE            CONSTANT NUMBER(4) := 4081;
    REFGETFUNDREQUIREDVIEW          CONSTANT NUMBER(4) := 4082;
    REFNOTMAPPEDACTUALSDATERANGE    CONSTANT NUMBER(4) := 4083;
    REFCASHINHANDDASHBOARD          CONSTANT NUMBER(4) := 4084;
    REFGENPICKUPPARAMETER           CONSTANT NUMBER(4) := 4085;
    REFGETDAILYRATES                CONSTANT NUMBER(4) := 4086;
    REFCHECKACCOUNTEXISTS           CONSTANT NUMBER(4) := 4087;
    REFCHECKCATEGORYEXISTS          CONSTANT NUMBER(4) := 4088;
    REFGETDEFAULTDASHBOARD          CONSTANT NUMBER(4) := 4089;
    REFCURRENCYFORCASHPOSITION      CONSTANT NUMBER(4) := 4090;
    REFGETCURWISEBRANCHDETAILS      CONSTANT NUMBER(4) := 4091;
    REFCHECKERPEXISTS               CONSTANT NUMBER(4) := 4092;
    REFGETCURRENCYPAIR              CONSTANT NUMBER(4) := 4093;
    REFGETFUNRPTCURRPAIR            CONSTANT NUMBER(4) := 4094;
    REFGETSYNONYMSPICKCODES         CONSTANT NUMBER(4) := 4095;
    REFGETBUDGETREFERENCE           CONSTANT NUMBER(4) := 4096;
    REFFUNCTIONALCURRENCYFORCFB     CONSTANT NUMBER(4) := 4097;
    REFRELATIONTYPE                 CONSTANT NUMBER(4) := 4098;
    REFMAINENTITY                   CONSTANT NUMBER(4) := 4099;
    REFRELATIONENTITY               CONSTANT NUMBER(4) := 4100;
    REFRELATIONTABLEVALID           CONSTANT NUMBER(4) := 4101;
    REFGETDATAUPLOADSYNONYMS        CONSTANT NUMBER(4) := 4102;
    REFCHECKGRIDUSERCONFIGEXISTS    CONSTANT NUMBER(4) := 4103;
    REFCHECKENTITYUSERCONFIGEXISTS  CONSTANT NUMBER(4) := 4104;
    REFGETCURRENCYPAIRS             CONSTANT NUMBER(4) := 4105;
    REFGETVARLIMIT                  CONSTANT NUMBER(4) := 4106;
    REFGETCURRENCYDETAILS           CONSTANT NUMBER(4) := 4107;
    REFGETCOMPANYLOCATION           CONSTANT NUMBER(4) := 4108;
    REFGETSPOTDATE                  CONSTANT NUMBER(4) := 4109;
    REFGETLETTERDETAILS             CONSTANT NUMBER(4) := 4110;
    REFGETLETTERLOADTYPE            CONSTANT NUMBER(4) := 4111;
    REFBANKCHARGEABLES              CONSTANT NUMBER(4) := 4112;
    REFBANKACCOUNTNUMBER            CONSTANT NUMBER(4) := 4113;
    REFBANKCHARGELINKENTITY         CONSTANT NUMBER(4) := 4114;
    REFGETENTITYCOLUMNS             CONSTANT NUMBER(4) := 4115;
    REFGETFILTERPARAMS              CONSTANT NUMBER(4) := 4116;
    REFGETCASCADEDETAILS            CONSTANT NUMBER(4) := 4117;
    REFGETMATCHINGPASSWORDKEYS      CONSTANT NUMBER(4) := 4118;
    REFGETDEALWRITINGIN             CONSTANT NUMBER(4) := 4119;
    REFGETCOLUMNSFORDROPBOX         CONSTANT NUMBER(4) := 4120;
    REFGETFILTEREDCURRENCYPAIRS     CONSTANT NUMBER(4) := 4121;
    REFGETAMOUNTINLABEL             CONSTANT NUMBER(4) := 4122;
    REFGETDATATYPEFORMATS           CONSTANT NUMBER(4) := 4123;
    REFGETBUYSELL                   CONSTANT NUMBER(4) := 4124;
    REFGETPRODUCTCATEGORYDETAIL     CONSTANT NUMBER(4) := 4125;
    REFGETCURRENCY                  CONSTANT NUMBER(4) := 4126;
    REFGETMTMDATA                   CONSTANT NUMBER(4) := 4127;
    REFGETPERIODOPEN                CONSTANT NUMBER(4) := 4128;
    REFGETPERIODOPENDATES           CONSTANT NUMBER(4) := 4129;
    REFCHECKPERIODOPEN              CONSTANT NUMBER(4) := 4130;
    REFGETPARAMETERVALUES           CONSTANT NUMBER(4) := 4131;
    REFGETDAYSTATUS                 CONSTANT NUMBER(4) := 4132;
    REFVALIDATEHOLIDAY              CONSTANT NUMBER(4) := 4133;
    REFGETALLOWEDFILETYPES          CONSTANT NUMBER(4) := 4134;
    REFGETMATCHINGFILEPREFIXES      CONSTANT NUMBER(4) := 4135;
    REFGETBRANCHACCOUNTDETAILS      CONSTANT NUMBER(4) := 4136;
    REFGETCASHFLOWFORECAST          CONSTANT NUMBER(4) := 4137;
    REFGETEXPOSURESFORREVERSAL      constant number(4) := 4138;
    REFGETBANKCHARGEINITIALDATA     CONSTANT NUMBER(4) := 4151;
    refGetLetterDoc                 constant number(4) := 4153;

    refGetLettersList               constant number(4) := 4152;
    refGetLetterFields              constant number(4) := 4154;
    refGetLettersParameter          constant number(4) := 4157;

    REFGETBANKCHARGECONFIG          CONSTANT NUMBER(4) := 4155;
    REFGETBNKCHRCONFFORSYNONYM      CONSTANT NUMBER(4) := 4156;
    REFGETFORWARDDEALDATA           CONSTANT NUMBER(4) := 4159;
    REFGETDATALOADDETAILS           CONSTANT NUMBER(4) := 4160;
    REFVALIDATEBNKCHRCONFIG         CONSTANT NUMBER(4) := 4158;
    REFGETACCESSGROUPUSERS          CONSTANT NUMBER(4) := 4161;
    REFGETMASTERTOCONFIG            CONSTANT NUMBER(4) := 4162;
    REFGETALERT                     CONSTANT NUMBER(4) := 4163;
    REFCOPYOVERMASTERKEY            CONSTANT number(4) := 4164;
    REFCOPYOVERMASTERDATA           CONSTANT number(4) := 4165;
    REFGETINTERESTREVALUATIONDATA   CONSTANT number(4) := 4166;
    REFGETPICKKEYVALUES             CONSTANT NUMBER(4) := 4168;
    REFGETVOUCHERDISPLAYDATA        CONSTANT NUMBER(4) := 4167;
    REFGETACCOUNTNUMBERS            CONSTANT NUMBER(4) := 4169;
    REFGETREPORTGRIDDETAILS         CONSTANT NUMBER(4) := 4170;
    REFGETSWAPDETAILSCCS            CONSTANT NUMBER(4) := 4171;
    REFGETUSERSCREENCONFIGDETAILS   CONSTANT NUMBER(4) := 4172;
    REFCHECKUSERSCREENCONFIGEXISTS  CONSTANT NUMBER(4) := 4173;
    REFCURRENTACCOUNT               CONSTANT number(4) := 4174;
    REFFGETALLLETTERS               CONSTANT number(4) := 4175;
    REFGETDEALINTEGRATIONDETAILS    CONSTANT number(4) := 4176;
    REFGETGRIDCONFIGDETAILS         CONSTANT number(4) := 4177;
    REFGETVOUCHERS                  CONSTANT NUMBER(4) := 4178;
    REFGETEXPOSURERTYPES            CONSTANT number(4) := 4179;
    REFGETBANKFORBROKER             CONSTANT number(4) := 4180;
    REFGETJOBSTATUS                 CONSTANT number(4) := 4182;
    REFGETJOBSTATUSDETAILS          CONSTANT number(4) := 4183;
    REFJOBRUN                       CONSTANT number(4) := 4184;
    REFGETPICKGROUPDATA             CONSTANT number(4) := 4185;
    REFGETBUDGETCOMPARISION         CONSTANT number(4) := 4186;    
    REFGETSYNONYMKEYDATA            CONSTANT number(4) := 4187;
    REFPARTICULAREXPOSURES          CONSTANT number(4) := 4188;
 --   REFGETEMAILTYPEDATA             CONSTANT number(4) := 4189;
    REFEXPOSURES                    CONSTANT number(4) := 4190;
    REFGETSYNONYMKEYSPARENT         CONSTANT number(4) := 4191;
    REFGETSYNONYMKEYSPROGUNIT       CONSTANT number(4) := 4192;
    REFGETFORWARDDEALAMOUNT         CONSTANT number(4) := 4193;
    REFCHECKCASHFLOWCOMPANYEXISTS   CONSTANT number(4) := 4194;
    REFBUDGETVSPROJECTIONS          CONSTANT number(4) := 4195;
    REFGETIMPORANDEXPORT            CONSTANT number(4) := 4196;
    REFGETGROUPBYREMITTANCES        CONSTANT number(4) := 4197;
    REFGETDATACONFIGCOLUMNMODEL     CONSTANT number(4) := 4198;
    REFGETLETTERNAME                CONSTANT number(4) := 4199;
    REFGETVOUCHERFORREFERENCE       CONSTANT NUMBER(4) := 4200;
    REFGETVOUCHERSUMMARY            CONSTANT NUMBER(4) := 4201;
    REFGETVOUCHERFORDATE            CONSTANT NUMBER(4) := 4202;
--    REFGETEDITLETTER                CONSTANT NUMBER(4) := 4203;
    REFGETMTMACCOUNTS                CONSTANT NUMBER(4) := 4204;
    REFGETMTMACCOUNTSFORREFERENCE   CONSTANT NUMBER(4) := 4205;
    REFGETMTMACCOUNTDETAIL          CONSTANT NUMBER(4) := 4206;
    REFGETPERIODOPENLIST            CONSTANT NUMBER(4) := 4207;    
    REFGETPERIODCLOSELIST           CONSTANT NUMBER(4) := 4208;   
    REFCHECKUSEREXISTS              CONSTANT NUMBER(4) := 4209;  
    REFGETPICKUPCODES               CONSTANT NUMBER(4) := 4210; 
    REFGETAPISTATUSDETAILS          CONSTANT NUMBER(4) := 4211; 
    REFGETDOCSUPLOADED              CONSTANT NUMBER(4) := 4212;
    REFGETDOCIMAGE                  CONSTANT NUMBER(4) := 4213;
    REFGETDOCCOLUMNDATA             CONSTANT NUMBER(4) := 4214;
    REFGETUSERPICKKEYGROUPS         CONSTANT NUMBER(4) := 4215;
    REFGETDOCXMLFIELDDATA           CONSTANT NUMBER(4) := 4216;
    REFGETALLUSERS                  CONSTANT NUMBER(4) := 4217;
    REFCHECKAPIUSEREXISTS           CONSTANT NUMBER(4) := 4218;
    REFGETENCRYPTDECRYPTDETAILS     CONSTANT NUMBER(4) := 4219;
    REFGETDATASOURCETYPE            CONSTANT NUMBER(4) := 4220;
    REFGETEMAILTEMPLATE             CONSTANT NUMBER(4) := 4221;
    REFGETXMLFIELDTEMPLATEDATA      CONSTANT NUMBER(4) := 4222;
    REFGETSYNONYMDATAFORTEMPLATE    CONSTANT number(4) := 4223;
    REFGETFXHEDGEANALYSISDATA       CONSTANT number(4) := 4224;
    RefEffectivenessProsp           CONSTANT number(4) := 4225;
    RefEffectivenessRetro           CONSTANT number(4) := 4226;
    RefDollarWorking                CONSTANT number(4) := 4227;
    RefDollarSummary                CONSTANT number(4) := 4228;
    RefNOPCURRENCYPAIRCONSOLIDATE   CONSTANT number(4) := 4229;
    REFGETVOUCHERFORDATESUMMARY     CONSTANT NUMBER(4) := 4230;
    REFGETVOUCHERNUMBERS            CONSTANT NUMBER(4) := 4231;
    refHedgePosition                CONSTANT number(4) := 4232;
    REFHedgePortfolio               CONSTANT number(4) := 4233;
    RefHedgePositionPivot           CONSTANT number(4) := 4234;    
    RefDollarOffsetWorking          CONSTANT number(4) := 4235;
    REFGETHEDGEPOSITIONDRILLDOWN    CONSTANT number(4) := 4236;
    REFGETFNCGETDESCRIPTIONMULTI    CONSTANT number(4) := 4237;
    REFGETPREMAMORTIZATIONDETAIL    CONSTANT NUMBER(4) := 4238;
    REFGETLETTERIMAGES              CONSTANT NUMBER(4) := 4239;
    REFGETCURRENTFINANCIALYEAR      CONSTANT NUMBER(4) := 4240;
    REFHEDGEPOSITIONCURRBUYSELL     CONSTANT NUMBER(4) := 4241;
    REFLOGUSERS                     CONSTANT NUMBER(4) := 4242;
    REFLOGUSERMENUS                 CONSTANT NUMBER(4) := 4243;
    REFGETUSERLOGMENU               CONSTANT NUMBER(4) := 4244;
    REFGETUSERLOGTRACE              CONSTANT NUMBER(4) := 4245;
    REFGETLOGREQUESTRESPONSE        CONSTANT NUMBER(4) := 4246;
    REFGETDOCUMENT                  CONSTANT number(4) := 4249; 
    REFGETAUTOLINKINGDATA           CONSTANT NUMBER(4) := 4250;

    REFGETLICENSEDCOMPANIES         CONSTANT number(4) := 4145;
    REFGETERRORLOGTRACE             CONSTANT number(4) := 4144;
    REFGETERRORLOG                  CONSTANT number(4) := 4143;
    REFGETLOGDETAILS                CONSTANT number(4) := 4141;
    REFGETLOGTRACEREQUEST           CONSTANT number(4) := 4140;
    REFGETERRORRESPONSE             CONSTANT number(4) := 4149;
    REFGETTRANCTIONBULKCONFIRM      CONSTANT number(4) := 4150;
    REFGETTRANCTIONBULKCONFIRMLIST  CONSTANT number(4) := 4247;
    REFGETSCREENXMLLIST             CONSTANT number(4) := 4248;
   -- REFGETDOCUMENT                  CONSTANT number(4) := 4249;
    REFGETDATANAMELOAD              CONSTANT number(4) := 4251;
    REFGETRISKLIMITDATA             CONSTANT number(4) := 4252;
    REFGETEMAILPICKCODE             CONSTANT number(4) := 4253;
    REFGETMAPPENDINGDOCUMENT        CONSTANT number(4) := 4254;
    REFGETRISKCALCULATION           CONSTANT number(4) := 4255;
    REFGETRISKTRANSDETAIL           CONSTANT number(4) := 4256;
--    REFGETXMLFIELDTRANCONFIG         CONSTANT number(4) := 4257;
-------Above 6000 cursors  for Market Rates and Bank Statement    
--     REFGETMARKETRATES              CONSTANT number(4) := 6000;
--     REFGETMARKETRATELIST           CONSTANT number(4) := 6001;
--     REFGETRATESUPLOAD              CONSTANT number(4) := 6002;   
    REFGETCOPYOVERMASTER            CONSTANT number(4) := 6005;
    GC_ParamData gconst.gclobtype%type;
    GC_ErrorData gconst.gclobtype%type;
    TYPE GC_GenCursor IS REF CURSOR;
    --GC_GenCursor DataCursor IS REF CURSOR;
    GC_workdate date;
    GC_UserID varchar(50);
    GC_Action number(8);
    GC_UserAction number(8);
    GC_Entity varchar(50);
    GC_XMLDoc xmltype;
    GC_numerror number;
    GC_UserActionType number;
    GC_varoperation gconst.gvaroperation%type;
    GC_varmessage gconst.gvarmessage%type;
    GC_varerror gconst.gvarerror%type;
    procedure Process_Cursor
    ( numInfoType in number,
      ParamData in gconst.gclobtype%type,
      ErrorData out nocopy gconst.gclobtype%type,
      GenCursor out gconst.datacursor);
End; -- Package spec