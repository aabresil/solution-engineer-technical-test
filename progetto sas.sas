/* ----------------------------------------
Codice esportato da SAS Enterprise Guide
DATA: domenica 9 febbraio 2020     ORA: 12:37:24
PROGETTO: progetto sas
PERCORSO PROGETTO: \\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp
---------------------------------------- */

/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* Build where clauses from stored process parameters */
%macro _eg_WhereParam( COLUMN, PARM, OPERATOR, TYPE=S, MATCHALL=_ALL_VALUES_, MATCHALL_CLAUSE=1, MAX= , IS_EXPLICIT=0, MATCH_CASE=1);

  %local q1 q2 sq1 sq2;
  %local isEmpty;
  %local isEqual isNotEqual;
  %local isIn isNotIn;
  %local isString;
  %local isBetween;

  %let isEqual = ("%QUPCASE(&OPERATOR)" = "EQ" OR "&OPERATOR" = "=");
  %let isNotEqual = ("%QUPCASE(&OPERATOR)" = "NE" OR "&OPERATOR" = "<>");
  %let isIn = ("%QUPCASE(&OPERATOR)" = "IN");
  %let isNotIn = ("%QUPCASE(&OPERATOR)" = "NOT IN");
  %let isString = (%QUPCASE(&TYPE) eq S or %QUPCASE(&TYPE) eq STRING );
  %if &isString %then
  %do;
	%if "&MATCH_CASE" eq "0" %then %do;
		%let COLUMN = %str(UPPER%(&COLUMN%));
	%end;
	%let q1=%str(%");
	%let q2=%str(%");
	%let sq1=%str(%'); 
	%let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq D or %QUPCASE(&TYPE) eq DATE %then 
  %do;
    %let q1=%str(%");
    %let q2=%str(%"d);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq T or %QUPCASE(&TYPE) eq TIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"t);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq DT or %QUPCASE(&TYPE) eq DATETIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"dt);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else
  %do;
    %let q1=;
    %let q2=;
	%let sq1=;
    %let sq2=;
  %end;
  
  %if "&PARM" = "" %then %let PARM=&COLUMN;

  %let isBetween = ("%QUPCASE(&OPERATOR)"="BETWEEN" or "%QUPCASE(&OPERATOR)"="NOT BETWEEN");

  %if "&MAX" = "" %then %do;
    %let MAX = &parm._MAX;
    %if &isBetween %then %let PARM = &parm._MIN;
  %end;

  %if not %symexist(&PARM) or (&isBetween and not %symexist(&MAX)) %then %do;
    %if &IS_EXPLICIT=0 %then %do;
		not &MATCHALL_CLAUSE
	%end;
	%else %do;
	    not 1=1
	%end;
  %end;
  %else %if "%qupcase(&&&PARM)" = "%qupcase(&MATCHALL)" %then %do;
    %if &IS_EXPLICIT=0 %then %do;
	    &MATCHALL_CLAUSE
	%end;
	%else %do;
	    1=1
	%end;	
  %end;
  %else %if (not %symexist(&PARM._count)) or &isBetween %then %do;
    %let isEmpty = ("&&&PARM" = "");
    %if (&isEqual AND &isEmpty AND &isString) %then
       &COLUMN is null;
    %else %if (&isNotEqual AND &isEmpty AND &isString) %then
       &COLUMN is not null;
    %else %do;
	   %if &IS_EXPLICIT=0 %then %do;
           &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2)
			%end;
			%else %do;
				%unquote(&q1)&&&PARM%unquote(&q2)
			%end;
	   %end;
	   %else %do;
	       &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2))
			%end;
	   %end;
       %if &isBetween %then 
          AND %unquote(&q1)&&&MAX%unquote(&q2);
    %end;
  %end;
  %else 
  %do;
	%local emptyList;
  	%let emptyList = %symexist(&PARM._count);
  	%if &emptyList %then %let emptyList = &&&PARM._count = 0;
	%if (&emptyList) %then
	%do;
		%if (&isNotin) %then
		   1;
		%else
			0;
	%end;
	%else %if (&&&PARM._count = 1) %then 
    %do;
      %let isEmpty = ("&&&PARM" = "");
      %if (&isIn AND &isEmpty AND &isString) %then
        &COLUMN is null;
      %else %if (&isNotin AND &isEmpty AND &isString) %then
        &COLUMN is not null;
      %else %do;
	    %if &IS_EXPLICIT=0 %then %do;
			%if "&MATCH_CASE" eq "0" %then %do;
				&COLUMN &OPERATOR (%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2))
			%end;
			%else %do;
				&COLUMN &OPERATOR (%unquote(&q1)&&&PARM%unquote(&q2))
			%end;
	    %end;
		%else %do;
		    &COLUMN &OPERATOR (
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2)))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2)))
			%end;
		%end;
	  %end;
    %end;
    %else 
    %do;
       %local addIsNull addIsNotNull addComma;
       %let addIsNull = %eval(0);
       %let addIsNotNull = %eval(0);
       %let addComma = %eval(0);
       (&COLUMN &OPERATOR ( 
       %do i=1 %to &&&PARM._count; 
          %let isEmpty = ("&&&PARM&i" = "");
          %if (&isString AND &isEmpty AND (&isIn OR &isNotIn)) %then
          %do;
             %if (&isIn) %then %let addIsNull = 1;
             %else %let addIsNotNull = 1;
          %end;
          %else
          %do;		     
            %if &addComma %then %do;,%end;
			%if &IS_EXPLICIT=0 %then %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(&q1)%QUPCASE(&&&PARM&i)%unquote(&q2)
				%end;
				%else %do;
					%unquote(&q1)&&&PARM&i%unquote(&q2)
				%end;
			%end;
			%else %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM&i)%unquote(%nrstr(&sq2))
				%end;
				%else %do;
					%unquote(%nrstr(&sq1))&&&PARM&i%unquote(%nrstr(&sq2))
				%end; 
			%end;
            %let addComma = %eval(1);
          %end;
       %end;) 
       %if &addIsNull %then OR &COLUMN is null;
       %else %if &addIsNotNull %then AND &COLUMN is not null;
       %do;)
       %end;
    %end;
  %end;
%mend _eg_WhereParam;


/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=PNG;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HtmlBlue
    STYLESHEET=(URL="file:///C:/Program%20Files%20(x86)/SASHome/x86/SASEnterpriseGuide/7.1/Styles/HtmlBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   INIZIO NODO: Importa dati (Kensu_DATA.csv)   */
%LET _CLIENTTASKLABEL='Importa dati (Kensu_DATA.csv)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
/* --------------------------------------------------------------------
   Codice generato da un processo SAS
   
   Generato in data domenica 9 febbraio 2020 alle ore 12:36:04
   Dal processo:     procedura guidata Importa dati
   
   File di origine: \\LAPTOP-
   CASA\Users\B&B\Documents\Andrea\Andrea\Kensu_DATA.csv
   Server:      File system locale
   
   Dati di output: WORK.Kensu_DATA
   Server:      Local
   -------------------------------------------------------------------- */

/* --------------------------------------------------------------------
   Questo passo di DATA legge i valori dei dati dalle DATALINES
   all'interno del codice SAS. I valori all'interno delle DATALINES
   sono stati estratti dal file di origine di testo dalla procedura
   guidata Importa dati.
   -------------------------------------------------------------------- */

DATA WORK.Kensu_DATA;
    LENGTH
        Company          $ 13
        first_name       $ 13
        last_name        $ 13
        email            $ 37
        gender           $ 6
        Phone            $ 12
        City             $ 29
        Country          $ 2
        Payment_Method   $ 25 ;
    FORMAT
        Company          $CHAR13.
        first_name       $CHAR13.
        last_name        $CHAR13.
        email            $CHAR37.
        gender           $CHAR6.
        Phone            $CHAR12.
        City             $CHAR29.
        Country          $CHAR2.
        Payment_Method   $CHAR25. ;
    INFORMAT
        Company          $CHAR13.
        first_name       $CHAR13.
        last_name        $CHAR13.
        email            $CHAR37.
        gender           $CHAR6.
        Phone            $CHAR12.
        City             $CHAR29.
        Country          $CHAR2.
        Payment_Method   $CHAR25. ;
    INFILE DATALINES4
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        Company          : $CHAR13.
        first_name       : $CHAR13.
        last_name        : $CHAR13.
        email            : $CHAR37.
        gender           : $CHAR6.
        Phone            : $CHAR12.
        City             : $CHAR29.
        Country          : $CHAR2.
        Payment_Method   : $CHAR25. ;
DATALINES4;
MeezzyAdelindWolfindaleawolfindale0@google.nlFemale650-808-8725PacchaPEjcb
RoomboTedraMunseytmunsey1@comsenz.comFemale524-166-9189WangjiapingCNjcb
BabbleopiaLewJaycocksljaycocks2@feedburner.comMale445-108-0167BarunyBYjcb
BrowseblabDarbeeGottharddgotthard3@hud.govMale528-204-4437AdamantinaBRjcb
TopicblabDoralynneAlgeodalgeo4@hibu.comFemale247-686-8523SauramaPEjcb
LajoGerekNeilgneil5@jigsy.comMale307-756-1932SivaRUdiners-club-enroute
OyopeHilaryRoderhroder6@xinhuanet.comFemale265-378-3374PinskBYvisa
SkyvuKelleyMcLesekmclese7@state.govFemale422-288-0443MangarinePHchina-unionpay
LivefishKaylynDominicikdominici8@tuttocitta.itFemale949-230-4831AzoguesECjcb
TwitterbridgeXeverChallicombexchallicombe9@a8.netMale795-712-8084LampihungIDjcb
PlambeeValleHazelgrovevhazelgrovea@techcrunch.comMale538-760-3314ConcepcionPHjcb
OozzSaxRicketsricketb@fc2.comMale585-468-1645RochesterUSmaestro
DivavuTabbieBarlastbarlasc@simplemachines.orgFemale577-548-5511MachingaMWsolo
EayoAddiChauveyachauveyd@1und1.deFemale980-515-4525BalbalanPHjcb
ThoughtsphereEditaAykroydeaykroyde@mozilla.orgFemale260-976-9996KoszarawaPLjcb
LazzyPrentKelsellpkelsellf@ovh.netMale674-328-0243JankovecMKdiners-club-us-ca
JabbertypeJesseMarnsjmarnsg@kickstarter.comFemale864-455-3827HanchangCNjcb
BlogXSFlssRubertellifrubertellih@webeden.co.ukFemale262-904-6553UseviaTZjcb
ThoughtbridgePauletteKlugel Female949-483-0421CermeeIDjcb
EaboxElliDosedaleedosedalej@dedecms.comFemale551-634-0742KutyUAamericanexpress
YoufeedMartieCreaseymcreaseyk@shinystat.comMale116-915-3730CajamarcaCOjcb
RealmixTylerRoseboroughtroseboroughl@ow.lyMale554-887-1394DongshangguanCNinstapayment
RealcubeHelainaKillner Female930-659-0125Bang LenTHjcb
BabbleopiaNicholeQuinneynquinneyn@nationalgeographic.comMale828-148-9390JiaokuiCNamericanexpress
VitzTeddiGabalatgabalao@comcast.netFemale402-284-3780LincolnUSlaser
 JewelSherlandjsherlandp@reference.comFemale700-303-4548NardaranAZjcb
TagopiaMindyAshleymashleyq@amazonaws.comFemale966-897-3575OranjestadAWswitch
KareHelaineGrigshgrigsr@unc.eduFemale713-651-9892PanguCNjcb
ThoughtmixDamonSteagalldsteagalls@smugmug.comMale303-930-0170VårgårdaSEchina-unionpay
GigazoomAllanStelljes Male134-315-7059 HNjcb
YotzBerkPentelobpentelou@cdbaby.comMale600-361-6765La FranciaARvisa
TagpadPatricRobroeprobroev@github.comMale416-995-9099Gavinhos de BaixoPTmastercard
MinyxVictorLukacsvlukacsw@webeden.co.ukMale681-351-1847Krasnotur’inskRUdiners-club-enroute
RealfireAmabelVarianavarianx@dagondesign.comFemale194-557-4424XingquanCNjcb
ChatterbridgeWinfredJaouenwjaoueny@usda.govMale177-758-9917Lázně KynžvartCZdiners-club-us-ca
YaceroMartynneHornungmhornungz@buzzfeed.comFemale139-355-7619PangpangPHchina-unionpay
JumpXSBrannonMccaullbmccaull10@utexas.eduMale601-614-2631JacksonUSjcb
YouopiaJustinianWellerjweller11@sina.com.cnMale612-654-5116MinneapolisUSjcb
EazzyShannahGoforthsgoforth12@nasa.govFemale582-237-4724ShuichaCNjcb
SkippadDoreneMitchenerdmitchener13@forbes.comFemale951-771-8856GikongoroRWjcb
KwimbeeClaibornLaceyclacey14@dagondesign.comMale271-203-0641GuérandeFRjcb
MynteRoscoeScalerarscalera15@blogger.comMale504-540-0159New OrleansUSmaestro
ZoomzoneFeyTrenholmftrenholm16@webs.comFemale399-787-3381FarkaždinRSjcb
JazzyShepMawbysmawby17@patch.comMale505-831-1447JinshanCNjcb
AilaneChandalClemencecclemence18@booking.comFemale670-666-6263KlichawBYvisa-electron
EayoHedyBodham Female894-107-8043MarčeljiHRinstapayment
EdgeclubDonaltPosselwhitedposselwhite1a@xrea.comMale418-134-9169BokkosNGmastercard
MeemmPhipRailtonprailton1b@yandex.ruMale436-884-0264LinjiangCNdiners-club-carte-blanche
BrowsedriveGuilbertRosegrose1c@vistaprint.comMale972-818-1313IbungPHmastercard
MymmSophieKeyserskeyser1d@sun.comFemale240-412-9841HuoluCNmastercard
TazzJoanVezeyjvezey1e@imgur.comFemale587-884-4780ZaozhuangCNjcb
ObaEsmeEdgintoneedginton1f@digg.comMale836-623-6597San AntonioARinstapayment
QuambaJaquelinDoggartjdoggart1g@flavors.meFemale370-240-5461Le Grand-QuevillyFRbankcard
EadelWhitneyBernaldezwbernaldez1h@baidu.comFemale589-856-9586 BRjcb
EimbeeFernandeSalasar Female282-811-2414MalianaTLmaestro
PhotolistRonnieChoulesrchoules1j@naver.comFemale144-993-8996BelloCOmastercard
AimboLeilahO'Moylanlomoylan1k@who.intFemale627-925-8241YuanlingCNjcb
BluezoomMoiraSpaxmanmspaxman1l@symantec.comFemale238-426-9191MakabeJPjcb
CentidelElvynEwenseewens1m@blog.comMale927-299-1592PanineunganIDlaser
YoufeedIrwinDarrigrandidarrigrand1n@hibu.comMale201-402-8617Villefranche-sur-MerFRmastercard
ObaCariottaBransbycbransby1o@quantcast.comFemale227-909-0184GasaBTjcb
DabvineCoriSowtecsowte1p@jimdo.comFemale995-496-4943NovoselëALvisa
MinyxCecillaElacoate Female128-971-3480 IDamericanexpress
FlipopiaMarielHethronmhethron1r@acquirethisname.comFemale475-134-9552Tembayangan BaratIDmaestro
BrightdogFosterCassiefcassie1s@nhs.ukMale510-927-4659General GalarzaARamericanexpress
JumpXSHerthaPaganhpagan1t@indiegogo.comFemale637-658-5032ChengmagangCNswitch
MeezzyGarrekRyegrye1u@fema.govMale805-284-5973San MiguelPYbankcard
WordtuneCarloMithoncmithon1v@ucla.eduMale787-718-3851Al FarwānīyahKWbankcard
KwinuGiustinaErdely Female392-813-0741TandouCNjcb
PhotobeanJeraleeHuton Female969-812-3346LudvikaSEbankcard
MibooCaterinaDiamondcdiamond1y@house.govFemale932-611-2538BilaoPHjcb
KwinuGlennCholmondeleygcholmondeley1z@mozilla.comMale390-158-4205AbomsaETchina-unionpay
ThoughtbeatJehuSargejsarge20@ox.ac.ukMale859-597-7625São Julião do TojalPTbankcard
ZooveoReevaClementerclemente21@ow.lyFemale465-147-0258KasakhAMjcb
DabfeedMaudMacRitchiemmacritchie22@purevolume.comFemale592-489-7075RyazanskayaRUvisa
 MichaellaFernsmferns23@hexun.comFemale197-141-1012KvasiceCZdiners-club-enroute
JamiaRaynaWhinrayrwhinray24@virginia.eduFemale444-580-1791NaguaDOjcb
SkipstormMalachiMatyashevmmatyashev25@hostgator.comMale639-567-3376JajawaiIDjcb
OzuJocelynDeavesjdeaves26@spiegel.deFemale292-638-6589LommeFRvisa
BuzzsterCliffordSteercsteer27@ibm.comMale513-149-0492BitamGAbankcard
ZoomboxClaytonHewertsonchewertson28@china.com.cnMale534-457-7743 ARvisa
 EmmyRomaineromain29@so-net.ne.jpMale825-981-8706KojageteIDdiners-club-enroute
FlashsetPhebeMarsterspmarsters2a@diigo.comFemale804-599-8251SalamancaESjcb
MeedooConBalderstoncbalderston2b@addthis.comFemale569-578-2651Rostov-na-DonuRUdiners-club-carte-blanche
MeembeeCoreyNorquaycnorquay2c@qq.comMale427-272-8514Jayaraga KalerIDsolo
SkidooBertieMattosoff Male784-400-2785BordeauxFRbankcard
AinyxTallyBladertblader2e@google.co.jpMale770-958-6977BunolPHbankcard
CentidelLammondConstantinelconstantine2f@nationalgeographic.comMale707-259-0375KaminaCDjcb
SkabooCelestinaMcFatercmcfater2g@theguardian.comFemale537-769-4446BaozibaCNamericanexpress
AiveeHertaBoanashboanas2h@vimeo.comFemale772-335-7785LapuanPHdiners-club-enroute
TrupeKarlottePellewkpellew2i@github.comFemale878-825-4414RecifeBRchina-unionpay
TrupeIsadoreConersiconers2j@dot.govMale334-719-2638VitartePEdiners-club-us-ca
EidelKlausCourceykcourcey2k@domainmarket.comMale128-648-5947GöteborgSEmastercard
OodooCharleyJakubiakcjakubiak2l@hatena.ne.jpMale127-320-2559BabicePLvisa
DemiveeGeorgiePerkinsgperkins2m@yolasite.comMale513-758-1530Horní LidečCZjcb
ZooxoDerkPillmandpillman2n@nydailynews.comMale108-804-1754Bakung UtaraIDvisa-electron
KimiaLurlineMayalllmayall2o@deviantart.comFemale747-686-5207Zamoskvorech’yeRUjcb
OyolooCindelynRittercritter2p@gov.ukFemale934-373-7422ChłapowoPLmaestro
ZoomloungeRancellTollmachertollmache2q@ucoz.ruMale336-545-1601MarmandeFRlaser
VinteMarthenaScholemschole2r@yellowbook.comFemale802-598-5698OrléansFRjcb
ShuffletagConniHacketchacket2s@sakura.ne.jpFemale476-432-1541LunenburgCAdiners-club-enroute
YozioFlorisEardfeard2t@gmpg.orgFemale472-675-3164CaikoujiCNjcb
TrilithTerenceRobinettrobinet2u@bluehost.comMale235-478-4426KloleIDmaestro
EireJechoGrumleyjgrumley2v@google.com.brMale609-206-4026PomahanIDswitch
VoolithIngemarPinnigeripinniger2w@naver.comMale935-719-8877KalinovoRUvisa-electron
DevpulseGarrekBergingbergin2x@php.netMale113-790-8448CaledonZAswitch
VinteDurwardDiversddivers2y@cdbaby.comMale919-893-1259HuichangCNjcb
CentizuDoreyDelcastelddelcastel2z@globo.comMale681-365-8486DubininoRUjcb
TeklistChannaDantercdanter30@europa.euFemale970-686-2674ShapingCNjcb
RhynyxHunterHolberryhholberry31@wikipedia.orgMale877-150-0006Pointe-à-PitreGPmaestro
TagchatTorryScrimshawtscrimshaw32@jalbum.netMale813-247-5951MercedesARjcb
DivavuValeStavevstave33@google.nlMale492-256-3132San MarcosSVchina-unionpay
GigaclubLiliaSheahanlsheahan34@ask.comFemale575-400-7366JangkungkusumoIDdiners-club-enroute
OlooRadGonzalezrgonzalez35@auda.org.auMale728-304-6950TexíguatHNvisa-electron
FlipstormVirginaCleland Female158-617-7669CikaungIDjcb
JabbersphereSunnyAinsworthsainsworth37@1688.comMale480-422-9481GentBEjcb
VoonderCorieWalsh Female346-598-1071Velká BítešCZjcb
OlooTyValintinetvalintine39@scribd.comMale363-768-4058GaoMLvisa-electron
RhynyxClairWalklingcwalkling3a@about.meFemale135-545-1244ChacapalpaPEjcb
SkinderMoisheBearfootmbearfoot3b@umich.eduMale788-962-9019Bay RobertsCAjcb
FeedmixShirMedcalfsmedcalf3c@so-net.ne.jpFemale213-534-7810CiseuseupanIDswitch
DabjamKelleyBridellkbridell3d@tinypic.comMale572-504-4502Novo-PeredelkinoRUjcb
 ShaylynnBatesonsbateson3e@over-blog.comFemale457-983-9719Krajan KarangsariIDjcb
JanyxFayreGillibrandfgillibrand3f@chronoengine.comFemale308-430-3577ChangmaolingCNlaser
WikivuLouieKyngdon Male178-765-1685SakuraJPjcb
YoutagsMickyBenedettimbenedetti3h@princeton.eduMale971-830-5138PortlandUSdiners-club-carte-blanche
JabbertypeMarioMcGillacoellmmcgillacoell3i@cornell.eduMale203-121-9893LahishynBYmaestro
SkiboxBernardYousonbyouson3j@rambler.ruMale290-344-4109La GuadalupeMXjcb
 OralieVlachovlach3k@berkeley.eduFemale559-976-5629WuyangCNswitch
KwinuCoreneBrosekecbroseke3l@w3.orgFemale431-426-2068GajrugIDjcb
TazzYumaLinsleyylinsley3m@marriott.comMale701-815-6509MajagualCOmastercard
DabZFalitoCrocumbefcrocumbe3n@behance.netMale611-795-2636MurçaPTmastercard
JaxbeanDaelBanvilledbanville3o@unesco.orgFemale995-339-4314XiaolongCNdiners-club-international
SkajoNancieWagerfieldnwagerfield3p@mysql.comFemale389-622-8414VanadjouKMswitch
QuimmAdoreePesapes3q@whitehouse.govFemale555-205-3947KuzhupingCNlaser
KwinuChaddyRowecrowe3r@ted.comMale845-193-1873KipiniKEswitch
GabtypeSukeyMcKinnsmckinn3s@ed.govFemale855-444-0447MuromRUjcb
 RinaSeilerrseiler3t@friendfeed.comFemale560-198-1729TroitskRUjcb
PhotobeanDruVittetdvittet3u@bbc.co.ukMale395-202-3093QuimbayaCOdiners-club-international
PhotospaceIvettIpwelliipwell3v@columbia.eduFemale259-439-7601ChornukhyneUAamericanexpress
FanoodleCaciliaFerronicferroni3w@uol.com.brFemale477-799-4429FuttsuJPjcb
JaxworksFlorianSilvesterfsilvester3x@paypal.comMale628-658-1466DadukouCNjcb
FlashpointLucineBulgen Female215-387-9934BururiBIjcb
ZooxoMyNeubiginmneubigin3z@google.caMale849-173-6129IndangPHjcb
YoubridgeViolanteBirkwood Female187-640-6810SharjahAEjcb
SkiveeAstridBlumablum41@yellowpages.comFemale347-656-9822DunkerqueFRjcb
FlashdogDennisHeephy Male613-367-3643BaligródPLjcb
FlipbugSofiaGookeysgookey43@nps.govFemale314-991-6155Miastków KościelnyPLswitch
LinklinksPammiCarranepcarrane44@dailymail.co.ukFemale218-603-4499KhóraGRjcb
PixonyxCurrSwitsurcswitsur45@photobucket.comMale128-356-8197PanjakentTJjcb
OyopeYaleElesyeles46@studiopress.comMale323-520-7984San Antonio SuchitepéquezGTjcb
GigazoomHyBuryhbury47@shop-pro.jpMale432-793-6483OdessaUSjcb
RooxoBevinBlakelockbblakelock48@usa.govMale458-318-2421Joubb JannîneLBjcb
OyonduEwenWallickerewallicker49@amazon.co.ukMale563-150-0517JiangchuanCNjcb
AvambaVinniePetrollivpetrolli4a@army.milMale568-170-2746AranitasALjcb
EamiaCassyArsnellcarsnell4b@mit.eduFemale723-789-9714AlikaliaSLjcb
TrudeoMimiFatkinmfatkin4c@live.comFemale154-844-7926Fale old settlementTKchina-unionpay
 KymSteanyngksteanyng4d@noaa.govFemale416-796-1753MondragonPHmastercard
DevpointHansonVaughnhvaughn4e@prlog.orgMale603-817-0192Puerto ParraCOjcb
TwinteElwoodRops Male261-696-9671ZielonkiPLinstapayment
LinkbridgeDannaClemsondclemson4g@latimes.comFemale349-618-0357RajhradCZjcb
TagpadEdgardoHallstoneehallstone4h@yellowbook.comMale573-492-4414QārahSYvisa-electron
BrowsezoomVincentyFishly Male423-294-3030BangunsariIDvisa-electron
TagchatHarrisonSwinehswine4j@state.govMale604-715-2846Rancho NuevoMXmaestro
VoommMarenaGerrettmgerrett4k@meetup.comFemale649-263-9696NaprawaPLswitch
ZooxoBonifaceFiellerbfieller4l@posterous.comMale651-959-5185MadridESvisa-electron
FeedmixCrawfordScoblecscoble4m@ocn.ne.jpMale253-874-4368MuhezaTZjcb
BuzzshareShaeCorkishscorkish4n@sourceforge.netMale661-452-4559El ReténCOamericanexpress
KazioRawleyGeraldinirgeraldini4o@blogger.comMale990-960-9487Francisco VillaMXjcb
LayoLedaCamellilcamelli4p@cdc.govFemale824-323-3386UlcinjMEjcb
TavuAntoniusDunkerkadunkerk4q@nhs.ukMale700-509-1411KavalerovoRUamericanexpress
TwitterworksWaltLoachheadwloachhead4r@tinyurl.comMale424-983-8842KruševacRSmastercard
BrainloungeWestbrookChatewchate4s@microsoft.comMale866-667-7189Stony PlainCAsolo
TagfeedIorgoMcGrawimcgraw4t@amazonaws.comMale279-540-8273BudapestHUjcb
RealcubeMunroeBenmben4u@ehow.comMale391-693-8366Al MadānYEjcb
BrainsphereBrokOllier Male824-581-9515 ECswitch
LinkbridgeTimmiLottetlotte4w@theatlantic.comFemale820-656-7691KlobukyCZjcb
FliptuneJacoboWalkdenjwalkden4x@arizona.eduMale121-929-0501ZaindainxoiCNjcb
SkipfireLeontyneBuckleslbuckles4y@bluehost.comFemale436-682-2266WanmaoCNdiners-club-enroute
MyworksSimmondsMannocksmannock4z@theglobeandmail.comMale526-865-8023QiaozhuangCNswitch
ZoomdogAubrieTichelaaratichelaar50@360.cnFemale866-766-9586TitiakarIDamericanexpress
MuxoNahumScutchingsnscutchings51@youku.comMale546-450-1205BlaMLbankcard
KatzConstantaLomath Female230-848-8366Cravo NorteCOdiners-club-enroute
InnoZShaunSpriginssprigin53@ed.govFemale600-984-5560PañgobilianPHmastercard
ZazioKandaceStrongmankstrongman54@1und1.deFemale823-391-2012KaborIDjcb
TwitterbridgeWynFugglewfuggle55@stanford.eduMale282-481-2570DomampotPHdiners-club-enroute
InnojamSalomoCrowterscrowter56@bing.comMale712-363-1432CimuncangIDjcb
YadelOrinPeltzeropeltzer57@nydailynews.comMale160-226-2885AgraPTswitch
JamiaChrysaEldonceldon58@forbes.comFemale312-383-3251AcchaPEswitch
LivetubeWinnifredStorrarwstorrar59@unesco.orgFemale473-559-6591PóvoaPTswitch
FeedfishNolanaMealhamnmealham5a@google.com.brFemale798-329-0178Quận NămVNjcb
OodooLonnieClapsonlclapson5b@e-recht24.deMale620-286-4238Banjar BeratanIDmastercard
 LydonFoulislfoulis5c@jiathis.comMale133-109-9163CarapicuíbaBRdiners-club-enroute
LeentiFeliksHaningtonfhanington5d@amazon.co.ukMale484-751-0048ObrytePLjcb
FlashpointDerrikDenziloeddenziloe5e@ezinearticles.comMale861-531-8993São Miguel do Rio TortoPTjcb
 LiviaVynolllvynoll5f@vk.comFemale902-203-3260AcoPEdiners-club-international
RoodelAvictorCosbeyacosbey5g@chronoengine.comMale551-238-9532ŠestajoviceCZbankcard
TwitterbridgeLanceMacDonoghlmacdonogh5h@elegantthemes.comMale300-881-1430La CoipaPEjcb
OmbaPearceMurfillpmurfill5i@sourceforge.netMale967-401-0448BangonayPHjcb
LazzyHillieYerlett Male905-841-5319NýdekCZdiners-club-international
GigashotsTerriCransontcranson5k@state.tx.usFemale414-899-3250MazyrBYjcb
FivebridgeFloryDi Carlofdicarlo5l@cbslocal.comMale521-875-0849XiakouCNvisa
QuimbaBabDuckitbduckit5m@dyndns.orgFemale949-742-7101YongfengCNdiners-club-enroute
KwideoJeremiasCharlejcharle5n@shareasale.comMale810-276-7717MuḩambalSYswitch
GigashotsMalaWingarmwingar5o@shinystat.comFemale885-732-7170NymburkCZmaestro
SkipstormOlivieroWhetland Male486-658-8709KøbenhavnDKmastercard
BubblemixBrentGracebgrace5q@ning.comMale440-416-3929RuseBGchina-unionpay
ThoughtbridgeLydaHaslehurstlhaslehurst5r@artisteer.comFemale699-308-0918MadagaliNGvisa-electron
OyoyoRozelleDestouche Female816-435-9289HuaishuCNjcb
BabbleopiaMerrileeBarthrupmbarthrup5t@edublogs.orgFemale498-290-2381UstupoPAamericanexpress
MeeveoMarioFotheringhammfotheringham5u@lulu.comMale234-117-4314RomnyRUmastercard
TanoodleFayetteHamsteadfhamstead5v@buzzfeed.comFemale118-420-9677DoibangIDjcb
DevcastTaliaFerrarintferrarin5w@seattletimes.comFemale251-789-1459Colonia Mauricio José TrochePYjcb
DabtypeAmiNozzoliianozzolii5x@yahoo.co.jpFemale274-396-0503Kuz’minskiye OtverzhkiRUjcb
ShuffletagDerrikGuthersondgutherson5y@a8.netMale477-151-1567WojaIDamericanexpress
JatriErminiaStentestent5z@cpanel.netFemale907-454-4825LongshanCNvisa-electron
EamiaOrionMawmanomawman60@hhs.govMale433-413-5075YuzaJPjcb
DabZFarleyYakovlivfyakovliv61@moonfruit.comMale413-316-7729At SamatTHdiners-club-enroute
FlashspanAllardNeashamaneasham62@sakura.ne.jpMale685-255-5603DashirenCNbankcard
EdgepulseRafaItzchaki Female426-195-1313Omuo-EkitiNGjcb
JumpXSWhitbyWhereatwwhereat64@123-reg.co.ukMale798-795-7997Leskovec pri KrškemSIvisa-electron
KayveoShaunaPurdonspurdon65@scribd.comFemale881-273-4722RūdiškėsLTjcb
KanoodleKalieMcChesney Female934-370-8095FloreştiMDjcb
SkipfireGoranRizzardinigrizzardini67@artisteer.comMale837-683-0165Kafr TakhārīmSYjcb
ZoomcastGarekBoundygboundy68@engadget.comMale762-907-0750NiederwaldkirchenATvisa
TagopiaHowieMonsonhmonson69@salon.comMale630-267-3155VoznesenskayaRUjcb
EaboxMonroMcConigalmmcconigal6a@yelp.comMale378-132-0422GoúrnesGRdiners-club-enroute
VoommNormyPoynzer Male741-136-6858LaoxialuCNamericanexpress
CogilithIveHubbuckihubbuck6c@guardian.co.ukMale685-149-0275PalmiraCOvisa
TagtuneFerrisPeyesfpeyes6d@geocities.jpMale524-986-0096 PHmastercard
TopiczoomGerrieCoweygcowey6e@dyndns.orgFemale566-105-3042AngoulêmeFRjcb
OlooLeviWillbournelwillbourne6f@jalbum.netMale913-737-1540BamendaCMvisa
TriliaJerromeChatwoodjchatwood6g@hibu.comMale380-719-3313RixiCNinstapayment
DevcastAnna-dianeCrosonacroson6h@webs.comFemale826-231-4343ObudovacBAjcb
CentizuReinholdInglesringles6i@soundcloud.comMale787-988-7970ZhaojiaCNamericanexpress
GigaboxRoselleDavenhillrdavenhill6j@skyrock.comFemale604-682-2379Paso de CarrascoUYjcb
MidelHendrickOldred Male400-257-5584MaracaiboVEmaestro
FeedspanSidSalewayssaleway6l@nationalgeographic.comMale666-653-2870CambanayPHmastercard
JabberbeanDalAylmoredaylmore6m@ow.lyMale486-177-6699Vila Pouca da BeiraPTdiners-club-enroute
YoutagsWilhelmBullinghamwbullingham6n@topsy.comMale819-598-3075SuishanCNmaestro
AiveeKlaraFaillkfaill6o@who.intFemale130-544-3368Velikiy UstyugRUjcb
ShuffledriveEmyleeWorsameworsam6p@4shared.comFemale816-771-2504 LVjcb
MymmDitaLunadluna6q@un.orgFemale127-398-1324LichingaMZbankcard
AbataCarlinRobertazzicrobertazzi6r@networksolutions.comFemale615-120-9849PetongIDjcb
EdgepulseSigfridStoakleysstoakley6s@google.com.hkMale821-900-0170PellegriniARjcb
SkiveeBaseHamsharbhamshar6t@hatena.ne.jpMale613-638-3578KourouGFjcb
SkiptubeCaseySiemonscsiemons6u@scribd.comFemale827-352-9357João CâmaraBRjcb
OyopeVannieDe Gregario Female776-919-5201KlayusiwalanIDjcb
KaymboEvenKrierekrier6w@360.cnMale402-449-1435LincolnUSjcb
MudoRupertoDaouserdaouse6x@mail.ruMale826-223-5023Nueva HelveciaUYjcb
MeejoImmanuelManterfieldimanterfield6y@myspace.comMale112-293-8809AzeitãoPTjcb
ThoughtbridgeGiustoOrdergorder6z@whitehouse.govMale297-505-8080Las PalmasMXjcb
TriliaBonneeDabinettbdabinett70@is.gdFemale573-888-2039Jefferson CityUSjcb
TagopiaHermiaMairshmairs71@examiner.comFemale616-362-9368TlučnáCZvisa-electron
FlipbugVanyaKevis Male339-175-3815Koh KongKHlaser
MeezzyMarisaPuckinghornempuckinghorne73@guardian.co.ukFemale968-366-0596DamaturuNGjcb
FeedfishWilekWhitenwwhiten74@icio.usMale241-587-3739Huarong ChengguanzhenCNmaestro
TagpadAdolphoMcGurnamcgurn75@moonfruit.comMale338-942-2610GuaíraBRvisa-electron
DynaboxTeodoorDukelowtdukelow76@europa.euMale358-744-5099TembauIDvisa-electron
EdgeifyDougieNevilledneville77@i2i.jpMale954-271-0688KhokhryakiRUbankcard
TrudooJaquenettaMugridgejmugridge78@stumbleupon.comFemale611-448-2070PoncokusumoIDmaestro
AinyxFaustineRheltonfrhelton79@topsy.comFemale549-310-1930ChengyangCNdiners-club-enroute
JaxnationAarenShaldersashalders7a@abc.net.auFemale650-851-1163OaklandUSjcb
TwitterbeatRayeEsposita Female197-934-7112ÚštěkCZmastercard
SkiveeMelMoyler Female879-191-3243ShalangCNvisa-electron
MycatLiukaBeestonlbeeston7d@nature.comFemale789-578-7534KozovaUAamericanexpress
VooliaEadmundGianneschiegianneschi7e@un.orgMale179-556-5572KariyaJPjcb
GebaThaliaFowlstfowls7f@mlb.comFemale913-590-2068São Caetano do SulBRchina-unionpay
TanoodleCraggyTrevanctrevan7g@tamu.eduMale147-238-2628EbetsuJPjcb
DivapeRoddieDorinrdorin7h@uol.com.brMale233-559-0794GentBEjcb
TagopiaGalvenKarimgkarim7i@csmonitor.comMale512-131-4260AustinUSmaestro
MitaTravusRaddentradden7j@zdnet.comMale129-406-5058SelatIDdiners-club-enroute
InnoZWesleyDel Montewdelmonte7k@nhs.ukMale501-654-2268Little RockUSjcb
ZoomcastCrossDudderidgecdudderidge7l@mac.comMale628-828-5101BolderajaLVdiners-club-carte-blanche
VoonyxKaileyRableaukrableau7m@etsy.comFemale360-387-2749HuaccanaPEvisa
YoveoCharityGribbencgribben7n@ning.comFemale582-255-0661KaranggintungIDswitch
JabberbeanUdaleTrowillutrowill7o@cnbc.comMale881-608-9553RiyomNGbankcard
OyoyoKonstanceAbbskabbs7p@sitemeter.comFemale926-280-5702RouenFRmastercard
NpathGustaBummfrey Female612-305-0781BaiimaSLchina-unionpay
NpathRoanaStrongmanrstrongman7r@cisco.comFemale892-439-6278KathuZAjcb
MudoEltonPleasantsepleasants7s@npr.orgMale836-177-0140 ALvisa-electron
LeentiEthelChappleechapple7t@alibaba.comFemale410-361-6379WadungIDdiners-club-enroute
JalooElliVaneschievaneschi7u@wikimedia.orgFemale951-876-5040XinleCNswitch
QuambaFranciskusScarlanfscarlan7v@wufoo.comMale463-227-7411Sapareva BanyaBGbankcard
ZooxoFidelMellings Male907-945-6390BressuireFRmastercard
BrowsecatAmiEskrietaeskriet7x@mit.eduFemale147-739-5519LaozhuangCNvisa
FlashspanShaniePerazzosperazzo7y@home.plFemale895-709-5270SinamarPHjcb
FanoodleAbbyParkinaparkin7z@liveinternet.ruFemale279-512-1595LeuwidamarIDjcb
ThoughtbeatCarNorthage Male780-874-3201KamyshevatskayaRUchina-unionpay
ThoughtblabGlenOakdengoakden81@unesco.orgFemale624-961-4697KoninPLvisa
MuxoAnissaZukiermanazukierman82@jiathis.comFemale752-392-9182Port MariaJMjcb
MeetzWhitbyBarwiswbarwis83@ihg.comMale852-810-2819EiradoPTjcb
ZooveoSidonnieDe Ruggerosderuggero84@over-blog.comFemale214-961-7994GémeosPTswitch
CamimboErinnMableson Female636-475-3102DuobagouCNvisa-electron
WikivuBevvyBurrisbburris86@fastcompany.comFemale382-390-1017RancabungurIDamericanexpress
JabbersphereHadleyTincombehtincombe87@ask.comMale868-775-7664EstreitoBRjcb
TrilithBennGarrochbgarroch88@bigcartel.comMale687-198-3107Cantuk KidulIDdiners-club-enroute
IzioOdeCyplesocyples89@salon.comMale307-549-8944SidzinaPLsolo
VoolithFranklinGavrielfgavriel8a@w3.orgMale805-677-8701NambalanPHjcb
RealbridgeWildenYvewyve8b@google.plMale507-820-5116CampokIDamericanexpress
DazzlesphereCliffLagenclagen8c@gmpg.orgMale583-497-0666 CRjcb
CogilithRaffaelloGiacobillorgiacobillo8d@soup.ioMale586-282-0751DonetskUAjcb
AilaneBankWoodersonbwooderson8e@arizona.eduMale884-439-8563MassarandubaBRjcb
GabvineLorneCarlisilcarlisi8f@a8.netFemale819-979-6408DiaofengCNjcb
FeedfireMadelineJelkmjelk8g@yellowpages.comFemale404-523-6959KembangIDamericanexpress
TalaneStefaMimmacksmimmack8h@rediff.comFemale849-319-6536Otan AiyegbajuNGjcb
WordwareRandyDe Matteirdemattei8i@last.fmFemale312-411-2847BaklashiRUvisa-electron
KaymboTateO' Scallantoscallan8j@umich.eduFemale170-918-0703MosquéeMAmaestro
InnotypePetLaityplaity8k@ox.ac.ukFemale728-842-7005WielichowoPLjcb
YouopiaFaustinePackingtonfpackington8l@printfriendly.comFemale898-660-3685Sidi BousberMAjcb
TwinderNikoClearienclearie8m@wikimedia.orgMale329-454-0487HoupingCNmaestro
AbataAlinaOwenaowen8n@topsy.comFemale733-849-4564KuantanMYmaestro
OobaSaulDahlborgsdahlborg8o@baidu.comMale588-348-0069KitenBGamericanexpress
LeentiBertMc Elory Female652-854-7473‘Ayn al ‘ArabSYjcb
TazzyNickolasYarnellnyarnell8q@jimdo.comMale577-289-8705 CNjcb
YouspanConstantinaGarredcgarred8r@yellowpages.comFemale326-858-4414StockholmSEmastercard
YouspanMiraAvisonmavison8s@psu.eduFemale786-408-8533SlemanIDjcb
FivespanRickardEasthopereasthope8t@1und1.deMale226-106-4161SallinsIEswitch
MeemmZoranaDwirezdwire8u@examiner.comFemale846-271-4820BoychinovtsiBGdiners-club-us-ca
ZooxoBerkleyWhiffinbwhiffin8v@home.plMale723-571-3190LubangoAOjcb
AinyxFanyaMoorey Female806-633-3111ProvidenciaPEjcb
KambaTerri-joRoytroy8x@chronoengine.comFemale409-454-8418 PLjcb
DynaboxClaysonCaineyccainey8y@whitehouse.govMale945-945-2341 KRmastercard
ZoomzonePaviaBelton Female997-847-7676BarisālBDvisa
LivepathGiustinoHavileghavile90@so-net.ne.jpMale788-689-2763NatoPHjcb
FlashdogBenediktaPassbybpassby91@simplemachines.orgFemale977-139-0425CruzeiroPTjcb
BrainsphereAdelaideMereweather Female366-381-8864Youxi ChengguanzhenCNinstapayment
EazzyRockieFaulconerrfaulconer93@amazon.co.ukMale843-522-4849ZhenshanCNjcb
FiveclubErinOlvereolver94@digg.comMale594-114-1401TucuranPHjcb
YaboxSheffyDoegsdoeg95@icio.usMale643-162-2056MaruNGjcb
 MillardTourotmtourot96@e-recht24.deMale870-269-2644ZiyangCNbankcard
FatzMernaPellingmpelling97@freewebs.comFemale154-804-9225FengyiCNjcb
BrightdogAlexioLadburyaladbury98@forbes.comMale661-622-2261WedangtemuIDjcb
MynteJeraldCarljcarl99@csmonitor.comMale795-324-3730Anren ChengguanzhenCNjcb
FivespanPerlaJebbpjebb9a@disqus.comFemale350-307-0849BallinteerIEjcb
AvaveoLyndsayDavsleyldavsley9b@wix.comFemale465-376-6540DrahovoUAjcb
MeeveeTashaPottagetpottage9c@foxnews.comFemale483-209-0292SindangIDmastercard
TagchatKevanBramsenkbramsen9d@google.ruMale627-577-9182 IDjcb
GabtuneEbertoRisbrougherisbrough9e@usatoday.comMale207-273-6391HeiiyugouCNjcb
SkippadPrentOswell Male760-482-8869 PHbankcard
SkiptubeJustinianCloneyjcloney9g@reuters.comMale169-231-4084DikhilDJamericanexpress
GigaboxGlenineBrodeaugbrodeau9h@biglobe.ne.jpFemale535-633-3510LongheCNswitch
 GaelShiltongshilton9i@japanpost.jpMale617-619-4230ViganPHjcb
MeeveeSloanWilcinskisswilcinskis9j@toplist.czMale270-515-9737MoroniKMmastercard
BuzzbeanFernandePatriefpatrie9k@mac.comFemale189-874-0805VrbovecCZdiners-club-enroute
CogiboxClaudianusFalkuscfalkus9l@goodreads.comMale754-955-2339Qian’anCNjcb
LinktypeAmaraLonglandsalonglands9m@opensource.orgFemale131-227-0696RafaḩEGjcb
RealblabBairdFinnimorebfinnimore9n@bluehost.comMale994-660-9222Puerto VarasCLjcb
AvambaEwardQuarryequarry9o@psu.eduMale389-248-1168BarengkokIDjcb
MibooLorinBowerslbowers9p@fastcompany.comMale789-996-3189SumberdadiIDdiners-club-carte-blanche
ZoombeatOllyTatteshallotatteshall9q@nsw.gov.auMale806-373-1890AuroraPHvisa-electron
OmbaDanyaBourgesdbourges9r@drupal.orgMale419-978-1316AndovorantoMGlaser
ZoonderUlrichWellbeloved Male397-241-1803Mas‘adahSYjcb
 AugustCrinsonacrinson9t@google.deMale286-510-7021KangarMYjcb
FeedfireMerissaJehaesmjehaes9u@netlog.comFemale568-674-4932DamnicaPLjcb
CentimiaEsteleTappetapp9v@comcast.netFemale913-272-5721XinningCNjcb
MeezzyTabbithaAldritttaldritt9w@sourceforge.netFemale789-664-4490MātliPKmaestro
RealbridgeTerrySpeirtspeir9x@xrea.comFemale460-939-1792SantongIDamericanexpress
WordifyMarkVanstonemvanstone9y@360.cnMale456-313-3658ParizhRUamericanexpress
EaboxMuhammadAttymatty9z@tumblr.comMale378-185-1763WumaCNjcb
OozzCasseyTwidalectwidalea0@nature.comFemale921-534-1197KrahësALjcb
BrowsecatGoddardMacKowle Male951-640-4916SedlarevoMKmaestro
MymmKristenFeldbaukfeldbaua2@mysql.comFemale278-821-8342 MXjcb
QuambaSabineBrickettsbricketta3@flickr.comFemale410-460-0287Nevel’RUlaser
SkipstormWallaceHapswhapsa4@4shared.comMale596-738-1891KøbenhavnDKjcb
TrunyxMalvinaPicklessmpicklessa5@163.comFemale486-467-3975JelsaHRvisa
ZooxoKerianneLegueyklegueya6@dion.ne.jpFemale548-951-3721Vila do BispoPTjcb
YotzCandidaDunguycdunguya7@mozilla.comFemale418-972-8808MarstonGBdiners-club-international
EimbeeMaloryLattymlattya8@sakura.ne.jpFemale294-859-8663VingåkerSElaser
QuambaMerrileFenlonmfenlona9@friendfeed.comFemale788-799-4040GameleiraBRjcb
BrowsebugPearlineConiampconiamaa@networksolutions.comFemale367-326-3340AstorgaBRswitch
 AinslieReayareayab@japanpost.jpFemale345-599-3551BagarmossenSEdiners-club-carte-blanche
GabspotDeloriaRubinowitzdrubinowitzac@wired.comFemale333-314-4327YanjiaoCNjcb
MeeveeRosamondFairlam Female660-140-7099KatakwiUGinstapayment
ZooveoGertieLearmouthglearmouthae@paginegialle.itFemale959-863-6569‘Arab ar RashāydahPSvisa
DevpulseBernicePughebpugheaf@freewebs.comFemale841-700-3330Al ‘ĀqirYEbankcard
MidelClarineBunnercbunnerag@51.laFemale377-239-1245LinjiangCNsolo
TwitterworksAlberikPettyapettyah@cnet.comMale121-685-5549Heřmanův MěstecCZjcb
RiffpathDarnallManntschkedmanntschkeai@craigslist.orgMale295-367-7211TierpSEmastercard
LinkbridgeSandroBoundssboundsaj@bigcartel.comMale889-425-3832KulasePHdiners-club-enroute
QuatzFerrisSesonfsesonak@w3.orgMale539-314-8025SindangsariIDbankcard
PhotofeedTimotheePietersentpietersenal@census.govMale295-418-7332FatukanutuIDdiners-club-carte-blanche
YamiaPerrenChickpchickam@feedburner.comMale104-614-6437AzovoRUjcb
FivechatDollieKaretdkaretan@wufoo.comFemale384-447-8027GuaynaboPRswitch
TopicloungeBrannonMcCriskenbmccriskenao@ow.lyMale230-207-7209NovokizhinginskRUmastercard
BlogXSQuentDe Clairmontqdeclairmontap@goo.glMale170-817-8235FarasānSAjcb
JamiaIgnazO'Dugganiodugganaq@wikipedia.orgMale372-993-0991OliveiraPTjcb
MudoElsworthTemplemanetemplemanar@tumblr.comMale741-863-2720Miān ChannūnPKmaestro
LeentiShelleyCotelardscotelardas@gov.ukFemale532-740-9089ParaísoPAjcb
MeeveeDurwardBoissieuxdboissieuxat@seesaa.netMale607-667-4702TakaniniNZjcb
TazzNickoMengonmengoau@nationalgeographic.comMale851-103-4788Centar ŽupaMKmastercard
FeedspanNorbieWetherellnwetherellav@usatoday.comMale753-391-8022Saint-Louis du SudHTjcb
QuireEvonneBrekonridgeebrekonridgeaw@ehow.comFemale327-190-1583Sergiyev PosadRUdiners-club-carte-blanche
YoutagsArielaBowditchabowditchax@nyu.eduFemale201-124-0840CuijiaqiaoCNchina-unionpay
MeedooIngunnaLovartilovartay@cocolog-nifty.comFemale423-887-8431MabiniPHmaestro
JaxnationYolandeHuburnyhuburnaz@addtoany.comFemale617-435-1477MuruniIDdiners-club-enroute
YouspanRockeyHanselmanrhanselmanb0@rambler.ruMale245-445-4203Cihideung SatuIDvisa-electron
AbatzConsuelaDickincdickinb1@altervista.orgFemale813-891-2621HexiCNjcb
GigaboxFelicdadChilderleyfchilderleyb2@surveymonkey.comFemale673-192-4694LiufuCNdiners-club-carte-blanche
AimbuSteveFraginosfraginob3@digg.comMale424-773-5125PanjingCNvisa
ZoomboxIngramFulgerifulgerb4@nsw.gov.auMale204-785-2258MandōlAFjcb
LinkbridgeGalinaBeargbearb5@xinhuanet.comFemale745-725-6839Santa Cruz do SulBRlaser
RhyboxXerxesMaddiexmaddieb6@cdbaby.comMale493-928-2930ZhonghualuCNjcb
TalaneHertaMerryweather Female441-821-3303MazhaCNjcb
FeedfishCarlingSeldnercseldnerb8@simplemachines.orgMale567-809-5845RawasanIDjcb
TwitterbeatWoodrowBasillwbasillb9@archive.orgMale862-947-4638Morioka-shiJPjcb
MibooMearaRawesmrawesba@elegantthemes.comFemale542-947-3829La SaludCUjcb
MyworksGallagherKubugkububb@ucoz.ruMale762-125-2927KommunisticheskiyRUjcb
FatzAntoninDossitadossitbc@youtube.comMale102-520-1926La EsperanzaMXjcb
CentizuStirlingEdmeadessedmeadesbd@sciencedirect.comMale952-374-4571Saint PaulUSvisa-electron
ThoughtbridgeEwanMallindineemallindinebe@zimbio.comMale808-494-8938HaBTamericanexpress
DivapeDurRawlesdrawlesbf@meetup.comMale892-661-3096Alejo LedesmaARjcb
NloungeCobFellscfellsbg@ocn.ne.jpMale584-882-2805KýmiGRmastercard
MeezzyDuranteBalwindbalwinbh@drupal.orgMale238-509-5044MontagueCAmastercard
RhynyxMercieDememdemebi@trellian.comFemale237-803-3426ChavãoPTjcb
TanoodleBurgWorshambworshambj@cafepress.comMale416-627-3330Orahovica DonjaBAmaestro
YoubridgeNickyTunnyntunnybk@unicef.orgFemale817-218-6475SukomulyoIDvisa
VipeTommiSteinsontsteinsonbl@unesco.orgFemale817-524-8151GuojiabaCNswitch
CentizuAngeliqueCubberley Female563-586-1964Besuki DuaIDvisa-electron
CentizuFreddieRichel Male912-996-5194BánovCZjcb
KareEvvieMaltbyemaltbybo@biglobe.ne.jpFemale753-832-3057VelizhRUdiners-club-international
MeeveoZachariahMacPhail Male365-517-1211DobdobanPHlaser
InnoZGilburtDunbletongdunbletonbq@howstuffworks.comMale108-303-4087LeiguanCNbankcard
JetwireBevanDobrovolnybdobrovolnybr@latimes.comMale150-601-5355DalheimLUbankcard
JetwireShellGrisewoodsgrisewoodbs@fotki.comFemale118-699-6543AkankpaNGlaser
YozioSansonFranchyonoksfranchyonokbt@twitpic.comMale975-468-0264UrjalaFIbankcard
JayoBessyReightleybreightleybu@furl.netFemale540-866-3351MuritibaBRjcb
TwinderRouvinClamprclampbv@epa.govMale189-786-7459BarreirinhasBRmaestro
QuatzToinetteFluckertfluckerbw@buzzfeed.comFemale105-185-8422KolchikónGRmastercard
BabbleblabCorriePortwainecportwainebx@booking.comMale762-669-7748MrgavanAMamericanexpress
WordifyHarriettaPfeiferhpfeiferby@51.laFemale692-405-0345DengmuCNjcb
DablistWarrenIvankovicwivankovicbz@tripod.comMale564-295-4868LiugeCNamericanexpress
QuambaLaurenceWilkin Male824-359-1041BomomaniIDjcb
BrainverseCaleJacobowits Male877-373-3690ItamiJPmastercard
AgimbaErnstDewingedewingc2@w3.orgMale899-778-6083Dukuh KalerIDjcb
IzioParkArkcoll Male171-958-9488RudkaPLmaestro
LayoUlbertoLyosikulyosikc4@squarespace.comMale167-228-2284OsórioBRjcb
RhyzioWebsterSnodinwsnodinc5@weibo.comMale751-701-4170IperuNGjcb
 CasperDesbrowcdesbrowc6@cargocollective.comMale689-993-1264ChipataZMswitch
OozzGerrieFitzsymonsgfitzsymonsc7@studiopress.comMale249-750-3534DounianiKMjcb
CogilithBibbyeFroudbfroudc8@google.nlFemale721-286-1038HauhenaIDdiners-club-us-ca
QuatzEmanueleFrauloefrauloc9@reverbnation.comMale409-478-6129TawauMYjcb
 OsmondLorraineolorraineca@globo.comMale994-406-4434QuimperléFRdiners-club-us-ca
BubbletubeChaddIncognacincognacb@bravesites.comMale516-495-7908GaltekIDjcb
DemimbuGiustinaImlackegimlackecc@princeton.eduFemale541-688-8276AmparafaravolaMGjcb
BubbletubeJaimieFominovjfominovcd@bbb.orgMale776-175-1999KaloyanovoBGjcb
DivanoodleAnastasiaO'Codihieaocodihiece@symantec.comFemale621-864-4247AsarumSEjcb
QuinuTarrahGetleytgetleycf@ucsd.eduFemale615-427-3560FengyuanTWmaestro
BubbletubeDenisLaffoley-Lanedlaffoleylanecg@ft.comMale749-354-0889Kayu AgungIDswitch
LivepathKrishnaAmbrogiolikambrogiolich@kickstarter.comMale202-269-1119WashingtonUSvisa-electron
EamiaLydaVentomlventomci@chicagotribune.comFemale143-732-7317Ban Talat NuaTHjcb
VoommAftonLabuschagnealabuschagnecj@bizjournals.comFemale888-926-3291GomelBYjcb
OyonduDomenicBastimandbastimanck@msu.eduMale184-848-1514SritanjungIDjcb
MybuzzLaunceBignall Male340-328-9947ShuanglongCNjcb
BrainverseJacquelynnDunkerlyjdunkerlycm@engadget.comFemale329-662-3916DelgadoSVvisa
ZoozzyNilBlaisenblaisecn@illinois.eduMale971-264-0033PortlandUSmastercard
 ChaddyLillyclillyco@ucsd.eduMale205-444-3032MundukIDjcb
RhynoodleNeroSweedland Male297-269-4238DenglongCNvisa
 MariannBottingmbottingcq@ustream.tvFemale623-542-5980Santa Helena de GoiásBRvisa
DemimbuGaraldTyergtyercr@seattletimes.comMale615-345-4471West KelownaCAswitch
BuzzbeanLynseyRumplrumpcs@blogspot.comFemale415-168-2248Santa Vitória do PalmarBRjcb
TwimboKaleenaHeeney Female738-404-2345TuatetaIDjcb
TazzyAntoniaBlouetablouetcu@ucoz.comFemale556-452-3516BanyulegiIDdiners-club-enroute
AgivuArmanBalsdonabalsdoncv@phpbb.comMale410-614-0228QianweiCNjcb
TanoodleLettyEillesleillescw@prlog.orgFemale245-544-5216ClizaBOamericanexpress
WordifyDewainAmbrogiodambrogiocx@yandex.ruMale163-331-4372NantesFRdiners-club-international
CentimiaBeliaMenloebmenloecy@gnu.orgFemale638-338-2132TibatiCMswitch
YoufeedHillelLogghloggcz@google.itMale869-312-9142GómfoiGRswitch
PixobooCosettePeacecpeaced0@parallels.comFemale759-680-4832Taen TengahIDbankcard
JaxnationBernyHaversonbhaversond1@etsy.comMale554-721-9529TaoxiCNmastercard
BrainverseBerneteKlosgesbklosgesd2@nytimes.comFemale467-832-6032KarlstadSEswitch
YakitriEphremRathboneerathboned3@google.com.hkMale647-389-4367Nueva FuerzaPHjcb
EamiaDollieWynesdwynesd4@webs.comFemale546-349-6589MlanggengIDjcb
RiffpediaNicholasTerbruggennterbruggend5@com.comMale401-774-7079ConcepcionPHvisa-electron
YouspanReubeMellishrmellishd6@icio.usMale179-160-6651ArshaluysAMjcb
TagcatMinorSlossmslossd7@toplist.czMale278-330-4776DijonFRvisa
MymmHarleyBalsellie Male502-965-9123CataguasesBRbankcard
BrightbeanEvangelinaBruneauebruneaud9@altervista.orgFemale359-136-3231GolugCNjcb
EazzyPrinzPlainpplainda@t.coMale508-475-6954LiugongCNswitch
TrudooAudyOrtsmannaortsmanndb@wisc.eduFemale667-451-8967Cabannungan SecondPHlaser
OyobaMarylinListonemlistonedc@amazon.co.ukFemale483-762-8371Thị Trấn Yên PhúVNjcb
SkiptubeAllixHeamsaheamsdd@sciencedirect.comFemale938-910-5621PatosBRjcb
ThoughtworksErickAdaireadairde@bizjournals.comMale246-151-3001TëployeRUjcb
TagcatElvisGuillemeguillemdf@com.comMale766-982-5309LongxingCNjcb
KazioOlivePaniman Female664-105-3632ChinozUZmaestro
SkimiaSebastienIlchuksilchukdh@csmonitor.comMale936-595-4966ZhoujiCNamericanexpress
TopicblabJocelinElijahujelijahudi@bandcamp.comFemale237-699-6291IleboCDamericanexpress
TanoodleJolynnDunnjdunndj@naver.comFemale757-244-4226Fengyang FuchengzhenCNjcb
VivaMikeyBuxcymbuxcydk@theatlantic.comMale706-115-5344JianchangCNdiners-club-carte-blanche
OozzNickolaiBooknbookdl@xing.comMale425-319-1235CiusulIDswitch
SkinteVanyaBurvillvburvilldm@paginegialle.itFemale112-460-5106AngaoCNjcb
WikiboxDelmerAmiabledamiabledn@ted.comMale435-476-5476Salt Lake CityUSchina-unionpay
GigashotsTatianiaEusticeteusticedo@chicagotribune.comFemale771-378-9921NíkaiaGRmaestro
RiffpediaSebastianoKunzlerskunzlerdp@state.tx.usMale209-926-2224KenzheRUjcb
ZoomloungeKerLabba Male832-536-5338Monkey HillKNmaestro
GigashotsObieLulham Male217-741-8914TríkeriGRjcb
BlogtagsChaseYacob Male953-760-0645SmilteneLVswitch
ZooveoOgdenCobdenocobdendt@berkeley.eduMale514-465-8367BaichengCNjcb
JaxworksFrederiqueGlencorsefglencorsedu@npr.orgFemale501-789-5236Ciguha TengahIDjcb
SkipfireMorgunEldenmeldendv@fema.govMale448-262-2110EkouCNjcb
FeedspanEliaFarnsworthefarnsworthdw@upenn.eduMale476-155-7144GryfinoPLjcb
TwitterbridgeFidelioMcLanachanfmclanachandx@i2i.jpMale220-907-6363El ViejoNIjcb
BuzzshareEleenKlimmekeklimmekdy@parallels.comFemale526-180-8108DuraznopampaPEbankcard
BlogspanLyonSorrilllsorrilldz@opera.comMale152-698-3053Khu KhanTHvisa
ZoomdogDeeDunbar Female745-536-9101DzhetygaraKZjcb
InnotypeNeritaTomasinontomasinoe1@technorati.comFemale950-927-0788KalahangIDmaestro
RiffpathGennaStanislawgstanislawe2@newsvine.comFemale621-518-4036BurgosPHjcb
AinyxChrystelDobbinsoncdobbinsone3@vk.comFemale239-452-5668San MartínCOmastercard
GeveeBilliePasqualebpasqualee4@devhub.comMale184-573-3130LiugouCNmastercard
SkimiaBondonMartyntsevbmartyntseve5@state.govMale458-860-9359SangzhouCNjcb
DemiveeMehetabelDroghanmdroghane6@ezinearticles.comFemale602-670-7370PhoenixUSjcb
SkimiaDidoLagdedlagdee7@craigslist.orgFemale887-141-2722OmutninskRUswitch
DynazzyHilarioDwyrhdwyre8@t-online.deMale199-501-5077WucunCNjcb
 AriellaRevellarevelle9@elegantthemes.comFemale583-135-0404Alejandro RocaARdiners-club-carte-blanche
LeentiDoreneBortolazzidbortolazziea@fda.govFemale843-874-5268OlocuiltaSVdiners-club-enroute
YouopiaTamraFewstertfewstereb@sogou.comFemale545-177-9945 RUjcb
TwinderElseyMcAlisteremcalisterec@oracle.comFemale428-165-7866PasireurihIDjcb
MymmBerthaWildblood Female663-972-8196KubangkondangIDswitch
TagfeedGiraldoSpurdengspurdenee@canalblog.comMale966-855-4375TartaroPHchina-unionpay
TwimboLucilleBeamondlbeamondef@bbb.orgFemale768-273-5324PostřekovCZmastercard
EimbeeBryceGraberbgrabereg@jugem.jpMale580-613-5221PengshiCNmaestro
SkinixMohandisHoultmhoulteh@livejournal.comMale989-520-0277KelinCNjcb
QuaxoAkimCollocottacollocottei@xinhuanet.comMale278-305-3111Tây HồVNjcb
TwitterbeatAshlaNeathwayaneathwayej@deliciousdays.comFemale755-476-2267ChernoyerkovskayaRUvisa
DabshotsBurchVasilevichbvasilevichek@issuu.comMale571-668-5741AlzamayRUjcb
TalaneLettieEvinslevinsel@google.deFemale954-141-5013Fort LauderdaleUSbankcard
WikizzXavieraMalitrottxmalitrottem@nymag.comFemale393-388-3702BarajalanIDchina-unionpay
LivetubeAllySherrumasherrumen@mapquest.comFemale648-644-6094La Chapelle-sur-ErdreFRjcb
DivanoodleNoreneLeverettenleveretteeo@cam.ac.ukFemale401-442-0499VranishtALswitch
 ByrannKoberabkoberaep@shinystat.comMale708-385-4446LishuCNmastercard
DabjamLeonanieReicherz Female233-642-9419Saint-BrieucFRswitch
NtagsKassandraVernerkvernerer@jigsy.comFemale698-336-7053ZdibyCZjcb
DemimbuQueridaMcCook Female849-156-2722North BayCAjcb
AilaneTaniaOveriltoverilet@fastcompany.comFemale339-364-2894BatangafoCFdiners-club-enroute
CentizuRodolfoScadrscadeu@sogou.comMale232-104-9661BururiBIjcb
LazzyTammieSchurichttschurichtev@wordpress.comMale642-294-4397OrongIDmaestro
YaboxAntoniTromansatromansew@cbc.caMale791-814-2174ĀsmārAFamericanexpress
GabtuneTitosKnightstknightsex@census.govMale615-223-9686Malko TŭrnovoBGjcb
DevpulseCordieGolagleycgolagleyey@geocities.jpFemale776-632-9662PleshanovoRUmastercard
MudoBrockieCunneybcunneyez@loc.govMale842-885-2323KøbenhavnDKinstapayment
YoutagsBettiTonbyebtonbyef0@spotify.comFemale192-937-1194IturamaBRjcb
RealmixFlorenceFavill Female105-862-9391CabanoCAbankcard
ZoozzyKailaSabbinksabbinf2@newyorker.comFemale390-577-7034SasykoliRUmaestro
FanoodleMargieNegrimnegrif3@imgur.comFemale729-895-6643BokinoRUmaestro
RhynyxJanetaBoyall Female509-449-9375Rakiv LisUAjcb
FlipopiaThebaultLaycocktlaycockf5@xing.comMale467-140-7182La PalmaMXjcb
OyoyoElbertinePenniellepenniellf6@webmd.comFemale251-208-3206DazuCNjcb
TopicwareLyssaRosendalllrosendallf7@constantcontact.comFemale225-295-7226SukabumiIDmastercard
RhylooGianniBryangbryanf8@gravatar.comMale455-181-2981TabukPHvisa-electron
AvammArdellaCaldeyroux Female210-434-5433DalsjöforsSEdiners-club-us-ca
LivepathBarbabraGreenlybgreenlyfa@reuters.comFemale374-765-5786ZargarānAFbankcard
CamidoGodivaVanelligvanellifb@cam.ac.ukFemale731-884-2813BangoloCIjcb
SkinixTobiasDaddtdaddfc@com.comMale195-853-8554МогилаMKdiners-club-international
MudoElonoreFriedankefriedankfd@blogspot.comFemale180-224-6095NamanganUZdiners-club-enroute
ZoomdogJeradArboinjarboinfe@bravesites.comMale200-937-7939SparwoodCAjcb
EdgeblabWinslowReolfowreolfoff@domainmarket.comMale655-414-4316BalingasagPHdiners-club-enroute
JabberbeanBerkeRabbattsbrabbattsfg@ow.lyMale933-367-5452RansangPHjcb
FivespanCasperPichecpichefh@prweb.comMale324-248-2165LidunCNjcb
QuambaDaronPotterildpotterilfi@unc.eduMale385-909-1110Le MansFRjcb
 BevonCasper Male636-565-7967PukouCNchina-unionpay
ZoomboxZakBordiszbordisfk@phoca.czMale249-120-7850LillehammerNOjcb
KambaChristophorusKliementckliementfl@berkeley.eduMale852-120-3503PetroúpolisGRdiners-club-us-ca
ThoughtstormKathrineDugankduganfm@ox.ac.ukFemale256-705-0686Qukës-SkënderbeALvisa-electron
RhyboxNorrieRaftnraftfn@slashdot.orgMale743-800-9126ChazónARjcb
DigitubeFayinaSchiefersten Female916-159-2455XishapingCNjcb
RhynoodleCaryJanotacjanotafp@netscape.comFemale191-432-1080BalibagoPHjcb
BuzzsterEllwoodLamborneelambornefq@cnbc.comMale406-770-6951SikurIDmaestro
YouspanWernherSherrellwsherrellfr@toplist.czMale173-120-9170BūrabayKZjcb
VoommKennithPinchbeckkpinchbeckfs@digg.comMale999-244-0567Ad DawḩahPSdiners-club-international
SkipfireJosiahDockrelljdockrellft@facebook.comMale475-855-8270Thành Phố Bà RịaVNbankcard
AiveeDeboraIzatdizatfu@ehow.comFemale449-312-5346MarinićiHRjcb
JaxworksItchTidmanitidmanfv@utexas.eduMale814-294-8873AntonyFRjcb
EireRoseliaDaytonrdaytonfw@guardian.co.ukFemale716-633-0052Clermont-FerrandFRvisa-electron
MidelSeamusMacMaykin Male774-939-2972MacArthurPHmaestro
RiffwireEarleCroall Male272-239-1641RudziczkaPLjcb
BubblemixCorbetCasleyccasleyfz@arstechnica.comMale757-497-7291LiushuiCNjcb
BrainverseClariceWonham Female939-961-8059ZelenečCZjcb
QuimbaLynetteHartzogslhartzogsg1@va.govFemale547-527-5229KenzheRUinstapayment
BlogpadDaveWinspiredwinspireg2@people.com.cnMale294-672-4265BeškaRSmaestro
AiveeOlivetteWiggamowiggamg3@bluehost.comFemale118-327-0807MosrentgenRUjcb
DynaboxJodyCorsorjcorsorg4@usatoday.comMale128-746-4882LuponPHjcb
OozzMerrelHeinishmheinishg5@google.com.auMale910-358-4954SukamanahIDjcb
BabblestormZuzanaClaworthzclaworthg6@adobe.comFemale441-974-6111La MesaMXdiners-club-carte-blanche
AgimbaValeneSchafer Female490-620-0988ChosicaPEsolo
GigashotsRhiannaPoolrpoolg8@un.orgFemale254-227-6576KanoyaJPlaser
RhynoodleKelleyTremellierktremellierg9@xrea.comMale273-942-1813YstadSEjcb
JabbersphereBarbaraRankingbrankingga@yandex.ruFemale242-677-9454LužeCZvisa
RoodelInesitaDrewsidrewsgb@aol.comFemale972-953-6734 CRbankcard
 AllieByatt Male621-346-3821NamballePEdiners-club-carte-blanche
FeedmixCaesarTaylourctaylourgd@ask.comMale446-275-3019RongguiCNjcb
YombuVanessaCoulingvcoulingge@japanpost.jpFemale730-965-8990LyonFRjcb
JaxbeanJemimaBarffordjbarffordgf@de.vuFemale976-445-5154BalallyIEdiners-club-carte-blanche
ShuffletagJaneneCowpjcowpgg@loc.govFemale616-262-3712Samut SakhonTHjcb
TagpadJoyousMonseyjmonseygh@amazon.co.ukFemale422-129-8715KleszczewoPLdiners-club-enroute
PhotobeanDaleOrreydorreygi@bbb.orgMale596-644-9834KarangpariIDjcb
CamimboDerrekOvendondovendongj@bravesites.comMale371-152-0891OrléansFRbankcard
RoodelAlbertAronsohnaaronsohngk@intel.comMale943-496-7385NiceFRjcb
LazzyFlorentiaHansill Female452-851-8998HebianCNjcb
JabbertypeIvieGroverigrovergm@webs.comFemale949-186-0356 UGjcb
JanyxMoeLaurentinmlaurentingn@google.plMale422-531-5941Bayt SīrāPSbankcard
YakitriAbagailHanleyahanleygo@globo.comFemale659-238-6077HezuoCNvisa-electron
 JessalinColnettjcolnettgp@discuz.netFemale393-646-6437GuruafinIDdiners-club-enroute
FliptuneJaneneDallemore Female305-342-4834 UAjcb
BrowsedriveBanTreamaynebtreamaynegr@jigsy.comMale221-290-4971Puerto BelloPHmaestro
VivaLorenzoWhatlinglwhatlinggs@slideshare.netMale679-717-3666HenggangCNjcb
KazioBroderickJoplinbjoplingt@opera.comMale423-256-1931PortumnaIEswitch
 MickieKenworthey Male519-391-7804JhumraPKswitch
WordtuneBunniJodlkowski Female287-648-3709Villa del CarmenUYjcb
FlashsetJermaineChicchettojchicchettogw@opensource.orgMale642-560-3326YaozhuangCNjcb
ZoovuRobertoMacMarcuisrmacmarcuisgx@google.com.brMale106-158-9917Dĩ AnVNjcb
ThoughtbridgeJoaneLinnelljlinnellgy@rakuten.co.jpFemale537-390-0181Vel’skRUswitch
FeedbugXymenesBrenstuhlxbrenstuhlgz@ucoz.ruMale871-242-6881BurauenPHjcb
AvammWaringAddeycottwaddeycotth0@hostgator.comMale914-364-8554Ribeira SecaPTjcb
SkilithLindseyHuburnlhuburnh1@ustream.tvMale990-773-6315CabindaAOjcb
LatzBabbieLanyonblanyonh2@usda.govFemale947-189-0663HelveciaARinstapayment
TwitterbeatCoriCraskeccraskeh3@google.com.hkMale932-116-5053OxelösundSEjcb
PixonyxBlondyBlunsombblunsomh4@biglobe.ne.jpFemale995-443-2924NiortFRmastercard
MitaStefaFoortsfoorth5@harvard.eduFemale314-567-0365FujiokaJPmaestro
YozioOdiliaHancke Female681-477-2239Tabuc PontevedraPHjcb
BuzzsterBartHeismanbheismanh7@unicef.orgMale941-516-3978Balpyk BīKZswitch
LinkbridgeVerenaGallahuevgallahueh8@digg.comFemale540-226-9817Bang RakamTHjcb
BabblestormTuckieFlewett Male281-863-0954HecunCNjcb
RealpointConstantaCrudenccrudenha@cornell.eduFemale631-927-2813 CUjcb
KwimbeeVerileGrousevgrousehb@abc.net.auFemale606-342-7259XiaoheCNamericanexpress
PlajoLilahHalesworthlhalesworthhc@chron.comFemale785-581-5725Krajan KeboromoIDswitch
BubbleboxArriCouchman Male723-248-8779ShahbāSYdiners-club-carte-blanche
VoonderBradenVlasovbvlasovhe@friendfeed.comMale563-847-1580Várzea de SintraPTvisa
BubblemixSimTixallstixallhf@google.deMale581-657-8543North BayCAdiners-club-enroute
VooliaBeatricePettecrewbpettecrewhg@kickstarter.comFemale561-875-9222HetangCNjcb
QuireMeaganStrathearn Female489-282-4376YangpingCNswitch
TagfeedJobeyVilesjvileshi@artisteer.comFemale283-303-0984MorelosMXjcb
RealblabHirschElnaughhelnaughhj@weebly.comMale997-414-0584BangshipuCNjcb
PhotospaceMozesTrotmanmtrotmanhk@mapy.czMale730-440-8458ShunheCNmaestro
ShufflebeatArchibaldoDavidescoadavidescohl@github.comMale585-707-9589RochesterUSchina-unionpay
ZoombeatItchNealeinealehm@odnoklassniki.ruMale322-820-1983ShilongCNlaser
DabvineMaxwellLesauniermlesaunierhn@canalblog.comMale308-516-5165La LimaHNdiners-club-enroute
TwitterlistFiannaBlastockfblastockho@chron.comFemale577-353-8466AmbohitrolomahitsyMGjcb
KatzVladamirTrewhelavtrewhelahp@163.comMale639-524-9018LameiroPTdiners-club-carte-blanche
ZooveoLaurettePattendenlpattendenhq@ycombinator.comFemale136-474-9315NiebylecPLmastercard
TrudeoElisabetTrainoretrainorhr@discovery.comFemale248-748-8980 PEvisa-electron
 WalshPendreighwpendreighhs@furl.netMale298-714-4556YanglinshiCNswitch
TwiyoEboneeMoralasemoralasht@yelp.comFemale546-212-0910RendianCNinstapayment
TanoodleKristoforoDuftonkduftonhu@google.esMale690-816-2616TiranaALmastercard
RhylooShandyBridgemansbridgemanhv@quantcast.comFemale930-227-2548Habana del EsteCUjcb
 ZacherieWilsezwilsehw@intel.comMale458-284-2771FryazinoRUjcb
BrainboxJeannaHubbackjhubbackhx@ftc.govFemale373-209-2497ZaragozaMXvisa-electron
PhotobeanMerlaBonehammbonehamhy@bandcamp.comFemale248-301-0017HeshanCNvisa-electron
WikivuBerniCarlickbcarlickhz@squidoo.comFemale632-903-7437VillanovaITjcb
DablistWardMulvanywmulvanyi0@washingtonpost.comMale408-258-0206KamnicaSIjcb
EdgeclubOsborneScattergoodoscattergoodi1@independent.co.ukMale487-724-6336MorazánGTamericanexpress
SkidooLayneySkeen Female315-693-7733SimRUamericanexpress
MeembeeKariaHundy Female663-690-2540PabeanIDjcb
YakijoMalachiBortolomeimbortolomeii4@ihg.comMale423-574-9116ZhizeCNmaestro
LeexoRobinettaFaierrfaieri5@princeton.eduFemale538-111-7012Jenang SelatanIDdiners-club-us-ca
PlajoDellyAndress Female314-783-8471SlavgorodRUdiners-club-enroute
TrunyxAlainLargenalargeni7@japanpost.jpMale210-104-5485HejiadongCNdiners-club-carte-blanche
SkiveeBurlSwettbswetti8@about.comMale308-313-6639 MNlaser
GabtypeTonySconcetsconcei9@hubpages.comFemale251-441-2541San Jose del MontePHmaestro
KwilithPennyMillettpmillettia@infoseek.co.jpMale931-350-2050LyckseleSEjcb
RhynoodleKlementChominskikchominskiib@army.milMale122-961-2077BaihuaCNjcb
GigaclubRadcliffeBrattyrbrattyic@twitter.comMale723-395-5799QuebradasPTbankcard
 NadyBoothmannboothmanid@businessinsider.comFemale103-620-4720Hacienda La CaleraCLswitch
AbatzWestleighChaggwchaggie@go.comMale479-639-0818MiraPTinstapayment
FlipopiaIngebergPergensipergensif@sohu.comFemale832-355-5199FarstaSEsolo
OobaMaybelleAlsteadmalsteadig@rakuten.co.jpFemale268-325-4979HuangliCNjcb
LinkbuzzTateJamestjamesih@amazon.comMale397-682-1052PakemitanIDswitch
DazzlesphereCarinBurnipcburnipii@tinyurl.comFemale473-395-2422PengchangCNvisa-electron
TagcatMelodyEarlmearlij@tripod.comFemale590-897-7382KokofataMLjcb
FlashdogCamillaIvaincivainik@usnews.comFemale890-180-4993Barra VelhaBRdiners-club-enroute
YaceroBradleySunnersbsunnersil@gmpg.orgMale193-147-0005SongbaiCNjcb
SkiveeLeonelleSloyanlsloyanim@sphinn.comFemale624-447-2929SpångaSEbankcard
LazzJaneenRimesjrimesin@hugedomains.comFemale600-279-9271SukawarisIDjcb
OyoyoFletchPercyfpercyio@newsvine.comMale953-962-0170Jasper Park LodgeCAjcb
JayoAllxKhidrakhidrip@npr.orgFemale593-667-2190 TJdiners-club-international
BrowsecatCazzieBurgesscburgessiq@elpais.comMale316-731-4360CigunaIDjcb
ZoonderMosheBrobakmbrobakir@netlog.comMale419-737-8828WisłaPLinstapayment
MeembeeEmaBriseebriseis@furl.netFemale706-762-3342Su’aoCNmastercard
YodoKristelRhydderchkrhydderchit@nsw.gov.auFemale326-226-6263KedatuanIDsolo
JetpulseMikaelaKlischmklischiu@wisc.eduFemale987-371-8306Głogów MałopolskiPLdiners-club-international
WikidoKakalinaBerns Female554-853-7292ChangshanCNjcb
FlashspanFaricaGilffillandfgilffillandiw@topsy.comFemale503-452-8289BuenavistaPHjcb
QuimbaMeyerBoynemboyneix@icio.usMale561-328-2140JiangcunCNjcb
InnoZLindyMcGirrlmcgirriy@github.comFemale703-470-7434‘IbwaynPSamericanexpress
TrudeoCasseyAntonietticantoniettiiz@is.gdFemale414-126-5485ShazhuangCNjcb
TagopiaCarolynGoddingcgoddingj0@creativecommons.orgFemale437-576-5942TuojiangCNjcb
CamidoMaddalenaStandingfordmstandingfordj1@arstechnica.comFemale648-631-9618CimaraIDjcb
VoonyxSamueleTchirstchirj2@imageshack.usMale689-628-8060HeshangCNjcb
YodelEmmottChason Male221-169-6990 RUmaestro
AvaveoEmmalynnHornbuckleehornbucklej4@shutterfly.comFemale450-837-0013WolinPLvisa
TopicshotsRitaZoephelrzoephelj5@sphinn.comFemale360-731-3085KarpinskRUinstapayment
SkiptubeCassandraOldacrescoldacresj6@yolasite.comFemale375-256-7901CapandananPHjcb
BrowseblabFinIpsgravefipsgravej7@opera.comMale721-968-4259CabinteelyIEamericanexpress
JetwireHyacinthiaWidmorehwidmorej8@goodreads.comFemale748-463-9388NangerangIDjcb
FeednationLennardVerdenlverdenj9@nyu.eduMale383-828-3822SolokIDmaestro
LazzBessAndrysbandrysja@state.tx.usFemale312-357-5905ChicagoUSjcb
TrudooFanyaMillgate Female736-827-8180La PalmaPAlaser
GabtypeFilippoBrassfbrassjc@amazon.co.ukMale576-291-2576JabongaPHjcb
FivechatDonettaDufferddufferjd@miibeian.gov.cnFemale926-907-7769IniöFIvisa-electron
TwitterworksNanetteMacbeth Female987-654-8182NekrasovkaRUjcb
BlogtagKinnieWhitterkwhitterjf@bloglovin.comMale359-315-1895TallaghtIEswitch
MeetzColleenSnozzwellcsnozzwelljg@oaic.gov.auFemale109-520-2353XiaolongmenCNjcb
FeedfishLineaArchbaldlarchbaldjh@utexas.eduFemale985-935-2817La PazARjcb
SkynoodleGannyWestfieldgwestfieldji@over-blog.comMale770-510-2602MhlambanyatsiSZjcb
MuxoGroverIversgiversjj@mashable.comMale507-584-0500KalepasanIDdiners-club-carte-blanche
TrudooSelenaSimenot Female376-987-2011BerlinDEmaestro
PhotolistArchambaultRalestonaralestonjl@shutterfly.comMale909-633-4965BarticaGYmastercard
VoommCulleyHutchesonchutchesonjm@yolasite.comMale917-630-9656MayqayyngKZjcb
YotzPippyRestonprestonjn@tripod.comFemale278-682-6919NārangPKdiners-club-enroute
TopicblabRaffertyNobbsrnobbsjo@comcast.netMale598-535-7499Il’kaRUvisa
JetpulseAndeeWroughtonawroughtonjp@hugedomains.comFemale936-629-0613ŠenčurSImastercard
TrudooJabezKohnjkohnjq@weather.comMale234-430-6885BuanPHjcb
OyoyoUrsolaGeraldougeraldojr@printfriendly.comFemale900-710-5940KilSEinstapayment
PixobooAllinaKatzmann Female582-526-1167BuđanovciRSchina-unionpay
NpathJanelleIncejincejt@smh.com.auFemale882-331-4972JianghuCNchina-unionpay
TopicloungeSidoneyMaypothersmaypotherju@purevolume.comFemale967-403-8076KuantanMYjcb
EdgetagEstevanMcAulayemcaulayjv@virginia.eduMale785-956-3801CurpahuasiPEjcb
TwitternationAshlaWoodgerawoodgerjw@about.comFemale101-279-1874CabaPHjcb
IzioAgrethaPitceathlyapitceathlyjx@yandex.ruFemale221-472-3900SalcedoDObankcard
JayoGrisGirvanggirvanjy@seattletimes.comMale605-172-6431YangyingCNmaestro
MeeveeDallisPaskins Male355-750-8833BizanaZAdiners-club-carte-blanche
KareGregorPetti Male170-795-1023BeopwonKRjcb
TagcatNorinaMcVronenmcvronek1@abc.net.auFemale179-678-3588ShijiaCNdiners-club-us-ca
GigazoomGenevieveDawdrygdawdryk2@cbslocal.comFemale769-951-3674MeixianCNjcb
GabspotGabbieIredalegiredalek3@bbb.orgFemale394-124-1184Wang NoiTHjcb
SkimiaKoryNorvelknorvelk4@stanford.eduMale644-959-5931ShanxiaCNdiners-club-carte-blanche
GabcubeTheresitaFrancklintfrancklink5@arstechnica.comFemale303-754-0061XialiCNmaestro
TwimmBennettMcTaguebmctaguek6@sbwire.comMale929-925-1994DongfengCNbankcard
DynazzyFransIvamyfivamyk7@state.govMale489-744-2365ChantillyFRswitch
MeemmDarillSabatesdsabatesk8@devhub.comMale404-162-9628Mūsa Khel BāzārPKjcb
VoonixSybilleLeggensleggenk9@digg.comFemale255-999-3381TörebodaSEbankcard
LazzyNappieZealandernzealanderka@theguardian.comMale205-618-0886BorkowicePLdiners-club-carte-blanche
GigashotsKalaClibberykclibberykb@ocn.ne.jpFemale806-484-9064 PGinstapayment
BlogspanLowranceMessengerlmessengerkc@gizmodo.comMale653-812-2080 IDbankcard
SkiboxKylieBakewell Male229-965-8588Song’aoCNbankcard
TriliaAlfonseDemeltademeltke@tiny.ccMale816-704-8362PuricayPHjcb
KazuJensSantinojsantinokf@china.com.cnMale671-952-6196 MXmastercard
FeedfireAlisterRayworth Male942-111-1375LianpengCNchina-unionpay
LivetubeArelO' Molanaomolankh@yellowbook.comMale166-197-1437GulaiCNdiners-club-enroute
FlipopiaSybillaPringellspringellki@lycos.comFemale882-534-8535 MNinstapayment
QuinuForbesGildingfgildingkj@360.cnMale996-129-0180Korolëv StanBYjcb
LinkbuzzCayeScoltscscoltskk@ovh.netFemale314-925-3717GujiadianCNjcb
 JermaineSpekejspekekl@senate.govMale617-255-1235El DoncelloCOvisa
ShufflebeatLeeClaillclailkm@miibeian.gov.cnFemale257-183-2506ŌnojōJPmaestro
GabtypeEmlenMcEntegart Male832-148-1247JiangpanCNjcb
BuzzshareRobbieAlderwickralderwickko@arizona.eduFemale583-844-7420FuchengCNjcb
MeeveoHewettKuschahkuschakp@wp.comMale235-610-1327RakitovoBGmastercard
CentidelEvonneRuthveneruthvenkq@businesswire.comFemale493-823-4956PoddębicePLswitch
DabshotsBerkGradonbgradonkr@washingtonpost.comMale283-901-7505Byala SlatinaBGdiners-club-enroute
TrudeoAnitaAmsden Female234-311-3536LorientFRjcb
MinyxReggieWraxallrwraxallkt@patch.comFemale879-387-8185Gotse DelchevBGjcb
EdgeifyOberonGotliffeogotliffeku@craigslist.orgMale921-885-4276Bento GonçalvesBRvisa-electron
DevifyGeorgianneDewisgdewiskv@narod.ruFemale504-924-0801SlavutaUAlaser
YakidooQuentFessierqfessierkw@wunderground.comMale200-346-6339ChocianówPLmaestro
PhotobeanEarlieKeemerekeemerkx@google.comMale571-461-4864Villa FranciscaDOjcb
WikizzKandyDarkerkdarkerky@de.vuFemale830-742-5757Ban PhaiTHvisa-electron
MidelAmoryCouvertacouvertkz@japanpost.jpMale129-445-9900Buqei‘aILjcb
QuireCoryDomesdaycdomesdayl0@constantcontact.comFemale692-188-2347CabogPHlaser
 DarynMooredmoorel1@narod.ruFemale741-629-2929CuritibanosBRjcb
SkidooColinApfelcapfell2@indiatimes.comMale236-405-7971XishaqiaoCNbankcard
GebaFrancklynIorizzifiorizzil3@webmd.comMale761-841-1805BoketuCNvisa
JanyxAngilBroschkeabroschkel4@dyndns.orgFemale965-486-4928NanjiaoCNdiners-club-international
EayoLinnellMonroelmonroel5@wix.comFemale139-520-5062ProletarskRUamericanexpress
SkynduDiandraBrazerdbrazerl6@artisteer.comFemale675-424-5523DaqianCNmaestro
BabbleblabNikitaDychendychel7@mit.eduMale991-769-7335PershotravneveUAvisa-electron
VoommMitchelPepismpepisl8@free.frMale519-518-1559LepoglavaHRvisa-electron
OyopeDorrieVedenyapindvedenyapinl9@bravesites.comFemale460-188-0530ShilingCNchina-unionpay
RealfireSashaHatfullshatfullla@mit.eduFemale394-775-1326San VicentePHjcb
AilaneKurtisShuttellkshuttelllb@washington.eduMale414-922-1180Santo Amaro da ImperatrizBRvisa
AvaveoOrinBrunstanobrunstanlc@csmonitor.comMale600-908-9031AnibareNRvisa
BlogtagAllixRoughanaroughanld@devhub.comFemale886-186-5759HebuCNmastercard
MibooHewetSlosshslossle@irs.govMale152-108-6786GrazATinstapayment
BabbleopiaWildenLepperwlepperlf@istockphoto.comMale199-853-5325Thành Phố Thái BìnhVNamericanexpress
CogilithWilburtOndrousekwondrouseklg@imgur.comMale328-402-1338LukavecCZjcb
ZazioSuzanneAndrisssandrisslh@blinklist.comFemale711-497-1891VšerubyCZmastercard
 CornyGilleoncgilleonli@nasa.govFemale259-550-9727La CejaCOjcb
 NanciBoudnboudlj@time.comFemale635-388-7736ŻółkiewkaPLjcb
FivebridgeCheslieBrynscbrynslk@addtoany.comFemale774-394-5957Ostrožská LhotaCZamericanexpress
SnaptagsSimonneMacCallsmaccallll@is.gdFemale440-390-3945WojcieszkówPLlaser
AbataArmanCufflinacufflinlm@answers.comMale568-442-5031KleszczewoPLjcb
ShuffletagPercyGrimmolbypgrimmolbyln@google.ruMale311-832-9313BritsZAinstapayment
CentimiaTabbyHaymesthaymeslo@ftc.govFemale747-404-5429 LAvisa-electron
MeemmRavidSimminsrsimminslp@yolasite.comMale118-102-6798WuyingCNdiners-club-enroute
KimiaSallieIckovicz Female797-799-5108CangshanCNmaestro
 MarietteRidingmridinglr@ebay.co.ukFemale485-668-0756KalininaulRUchina-unionpay
BrowsezoomBaronMcCasterbmccasterls@altervista.orgMale440-976-7381PoigarIDjcb
ZoomcastNeilAchurchnachurchlt@moonfruit.comMale974-355-3666KostakioíGRjcb
RealmixCaroleeBarkleycbarkleylu@npr.orgFemale282-241-0474HatsukaichiJPmaestro
SkabooSukiGoadbiesgoadbielv@princeton.eduFemale389-727-3933UyoNGjcb
LeentiCarminaWinspare Female852-106-6081KarlovoBGmastercard
BluezoomMeredithBerfootmberfootlx@dropbox.comFemale947-610-2159ZalewoPLjcb
MeejoMarilynFranzolinimfranzolinily@ustream.tvFemale883-954-1303IgcocoloPHchina-unionpay
YoutagsCarineHeiblcheibllz@constantcontact.comFemale452-203-3018KhurriānwālaPKjcb
LinkbuzzAgnetaBenteabentem0@aboutads.infoFemale538-247-6816Bandar-e LengehIRdiners-club-carte-blanche
TanoodleMortenGillianmgillianm1@unesco.orgMale617-146-0368Krasnaya PolyanaRUjcb
DabshotsThomasTortoisettortoisem2@xinhuanet.comMale787-970-2685JīmaETmastercard
DabtypeSachaStaffordsstaffordm3@upenn.eduFemale863-958-6339InayauanPHvisa
JabbercubeBuddieCatherybcatherym4@desdev.cnMale805-405-7137SandakanMYjcb
JetwireHubieMacourekhmacourekm5@ezinearticles.comMale827-529-8578QuettaPKjcb
MibooAmandaRickertsenarickertsenm6@spiegel.deFemale643-440-7429TagbinaPHjcb
KareStormVasilischevsvasilischevm7@nasa.govFemale150-793-4604LimmaredSEchina-unionpay
BrightbeanStanislawHawkswellshawkswellm8@1688.comMale449-631-8937SkuodasLTdiners-club-carte-blanche
KatzBradanSakerbsakerm9@pbs.orgMale178-857-2663LillooetCAmastercard
YozioEllsworthFullicks Male629-873-1224Nha TrangVNmastercard
TambeeWiattEliesweliesmb@umich.eduMale795-680-4874SzczecinekPLjcb
TopdriveBearMulcockbmulcockmc@soundcloud.comMale103-799-7611Sainte-Marthe-sur-le-LacCAvisa
FlipopiaFeliceHampsonfhampsonmd@microsoft.comMale562-429-2419PojokIDsolo
ZooveoKerrillEateskeatesme@cisco.comFemale132-456-2160RostockDEvisa-electron
AinyxMallorieVedyaevmvedyaevmf@army.milFemale848-891-0357SogatiIDamericanexpress
FeedfireMignonFishpoolemfishpoolemg@ucla.eduFemale782-521-7082XipuCNjcb
TagfeedBetteanneMachenbmachenmh@mtv.comFemale738-232-9694ChifengCNlaser
BrowsecatLarisaZuppalzuppami@harvard.eduFemale709-563-0652HuazhaiCNbankcard
DablistAmaletaVidgenavidgenmj@discovery.comFemale198-123-9033Grande PrairieCAmaestro
RealfireIlkaAmbroixiambroixmk@senate.govFemale826-256-1712FortiosPTvisa-electron
IzioFrazierSladerfsladerml@columbia.eduMale296-180-3895MenconIDjcb
MyworksEdwinGowansonegowansonmm@illinois.eduMale710-779-9723MostyPLjcb
ZoomzoneReebaPreshousrpreshousmn@moonfruit.comFemale150-387-2937AnluCNdiners-club-enroute
TopicloungeRafaelaBattellerbattellemo@wufoo.comFemale679-405-3683Paris 02FRjcb
 CarlAireycaireymp@state.tx.usMale640-647-0551MendiPGvisa-electron
PhotojamRalphSemkenrsemkenmq@spotify.comMale523-174-3407QingzhouCNjcb
OyonderRhettDaskiewiczrdaskiewiczmr@imgur.comMale751-401-5342GaliGEamericanexpress
QuinuKennettCavillekcavillems@census.govMale895-372-4292WutanCNmastercard
PhotofeedLaurentMulqueenylmulqueenymt@google.nlMale755-511-7937MhamidMAsolo
KazuDarwinTownsenddtownsendmu@ask.comMale642-258-6007SoachaCOchina-unionpay
TwitterlistAlieBarnewilleabarnewillemv@upenn.eduFemale914-261-8568MeijiaheCNdiners-club-enroute
ShufflesterRodrigoSwarbriggrswarbriggmw@canalblog.comMale838-763-7925GhātLYmastercard
ZoomloungeDelKolczynskidkolczynskimx@google.frMale129-850-8511San PatricioPYsolo
GabtypeEddyBentsenebentsenmy@livejournal.comMale746-738-6278San PedroBOmastercard
QuireAlysiaFullwoodafullwoodmz@alexa.comFemale213-885-5696Los AngelesUSjcb
BubbleboxViviyanMacFaulvmacfauln0@telegraph.co.ukFemale800-526-6360StockholmSEdiners-club-us-ca
TwitterlistAbraMakepeaceamakepeacen1@stanford.eduFemale394-230-1831PasacaoPHswitch
SkybaHershMcLagainhmclagainn2@soup.ioMale121-159-8113Licheń StaryPLjcb
PodcatDeeThurbydthurbyn3@ycombinator.comFemale130-301-6398MengxingzhuangCNdiners-club-international
KwilithTeadorCoraini Male902-192-1512MetsovoGRvisa-electron
AvaveeThaddeusGerrelstgerrelsn5@discuz.netMale379-697-3103RokycanyCZjcb
ZoozzyUrsaRussamurussamn6@addtoany.comFemale582-285-9680OrikhivUAchina-unionpay
TwitternationHolmesDeelayhdeelayn7@storify.comMale992-901-1731DuisburgDEbankcard
ThoughtstormJoseitoDerilljderilln8@phoca.czMale284-820-9237HuanghuatanCNswitch
VoonixElbertineVaudreevaudren9@youku.comFemale516-198-9463Khon BuriTHjcb
EireBuddBennbbennna@linkedin.comMale317-835-1341IndianapolisUSdiners-club-carte-blanche
TopicloungeKirsteniArrigokarrigonb@accuweather.comFemale917-995-9088CaliCOjcb
YamiaButchLafflinablafflinanc@vinaora.comMale383-473-5769BahuangCNmaestro
DynavaGillesBellsham Male350-962-9523DafengCNjcb
RealfireLeelaDuberylduberyne@jigsy.comFemale713-379-3826GuangshunCNjcb
GebaDaltMaunselldmaunsellnf@hud.govMale754-368-7303Banatsko Veliko SeloRSjcb
OyoyoCharinMacCollomcmaccollomng@so-net.ne.jpFemale662-495-5561RizómataGRsolo
FiveclubClementiusAsplecasplenh@i2i.jpMale519-642-6076ZaozerneUAchina-unionpay
BluejamMaritsaMuzzinimmuzzinini@ted.comFemale255-224-7692RajadesaIDjcb
TopicwareIrwinBeebeibeebenj@reverbnation.comMale865-590-1825Stará Ves nad OndřejnicíCZchina-unionpay
YoutagsChariotThomasoncthomasonnk@zimbio.comMale625-763-4366Kota KinabaluMYjcb
ShuffletagCooperPetrushkacpetrushkanl@about.meMale123-250-9854MabiniPHjcb
BabblestormHadCardinalhcardinalnm@msu.eduMale418-402-8953Lago da PedraBRswitch
BuzzshareKarleeChurchillkchurchillnn@canalblog.comFemale828-241-4837Swan HillsCAvisa-electron
JabbersphereClerkclaudeKippieckippieno@123-reg.co.ukMale490-582-1078Al MayādīnSYjcb
NpathWilfridBrechewbrechenp@admin.chMale202-581-9347PancolPHswitch
OyobaGregoorShellumgshellumnq@whitehouse.govMale634-941-2498BaiheCNjcb
PhotobugSabraElgarselgarnr@mapy.czFemale581-990-9405ChangqingCNjcb
RealmixAlexandrinaOrrillaorrillns@liveinternet.ruFemale356-134-0950PortelaPTvisa
YakitriDedeWalch Female860-604-3733HartfordUSvisa-electron
 MarthaParmleymparmleynu@dagondesign.comFemale786-690-5053MiamiUSjcb
LayoHerculieSulterhsulternv@smugmug.comMale834-257-4149DingchengCNmastercard
PixonyxHanaOlenikov Female550-721-2236San CarlosCOjcb
InnoZDanieleFlisherdflishernx@mtv.comFemale664-970-0500CarayaóPYmastercard
ThoughtstormHyacinthieGuynemerhguynemerny@imdb.comFemale575-323-2337SułkowicePLjcb
MybuzzUptonMuirheadumuirheadnz@exblog.jpMale344-410-1521LichengdaoCNmaestro
LinktypeDwayneApplebeedapplebeeo0@g.coMale604-488-4083NikkiBJjcb
TeklistLeonidasBaulklbaulko1@cpanel.netMale667-886-0431FärgelandaSEjcb
WikivuEugenChmarny Male643-799-9078UppsalaSEdiners-club-carte-blanche
TrudooGriffinKlosser Male154-706-2426ZaliztsiUAmastercard
WikivuReinaldoBottomerrbottomero4@sourceforge.netMale822-719-4884ChrysoúpolisGRdiners-club-carte-blanche
FlipbugFrediFlemmich Female585-657-2837RochesterUSmastercard
 ValeTotarovtotaroo6@etsy.comFemale991-113-0190YulinCNjcb
YouopiaVictoriaWeatherburnvweatherburno7@abc.net.auFemale942-568-3105LilleFRjcb
DevbugChloetteKorfckorfo8@blogger.comFemale222-211-1089SocaUYjcb
BrowseblabRenardLilburne Male912-208-8824Samut SakhonTHjcb
TagfeedPatenSemanpsemanoa@dailymail.co.ukMale767-925-5915MtwangoTZinstapayment
BrainverseGertrudisAttwatergattwaterob@dailymail.co.ukFemale975-743-6781YaroslavlRUjcb
MeeveeGwenoraBlackburnegblackburneoc@epa.govFemale133-217-3312TbilisskayaRUmaestro
EdgewireKatrinkaSellyksellyod@harvard.eduFemale809-287-1125 PTjcb
EayoGussBehnkegbehnkeoe@etsy.comMale840-795-1123MuromRUmaestro
YoveoMaxyViscovimviscoviof@seattletimes.comFemale512-137-4204Nor GyughAMjcb
TopicshotsJoellenIglesiazjiglesiazog@unicef.orgFemale249-378-4591MönsteråsSEvisa
EdgeclubJonellBarnetjbarnetoh@yellowbook.comFemale191-162-0755 MYjcb
MymmBeaForgan Female279-924-2566KøbenhavnDKdiners-club-enroute
TwiyoIolantheIpslyiipslyoj@earthlink.netFemale129-781-3263 GRbankcard
FlipstormMitchRudlandmrudlandok@europa.euMale150-435-1094TegalgedeIDjcb
ThoughtsphereDaleJehandjehanol@bigcartel.comFemale183-640-9695BaizhangCNinstapayment
AimbuSheffyKlimentyev Male494-246-9633XunzhongCNmaestro
JalooOrelieMonahanomonahanon@purevolume.comFemale996-274-8084ItaperunaBRjcb
PhotobeanSonjaPollakspollakoo@admin.chFemale129-697-8706KibitiTZvisa-electron
OyonduGardenerShanngshannop@uiuc.eduMale813-714-6842TampaUSvisa-electron
DabvineWendelBirchwoodwbirchwoodoq@zdnet.comMale584-809-2887IlihanPHjcb
AimboChloetteKauscherckauscheror@toplist.czFemale767-308-3609PatzicíaGTmastercard
LeentiHyMargriehmargrieos@seesaa.netMale205-443-6216KalmarSEamericanexpress
DabfeedHugoGiraldonhgiraldonot@bing.comMale629-479-5929‘IrbīnSYjcb
DevifyPerkinForwardpforwardou@techcrunch.comMale164-423-9901SanyangCNjcb
FeedspanPhillisMacCaig Female936-423-1961GorzyczkiPLjcb
EdgeifyBarthelLewsyblewsyow@tamu.eduMale110-792-3725TwardawaPLjcb
OzuJeraldViantjviantox@google.frMale204-760-3908KurihashiJPmaestro
DynavaNertieCrouxncrouxoy@opera.comFemale252-287-1694El CapulinMXdiners-club-carte-blanche
YamiaMorlyBrobyn Male356-858-0887ParapatIDmastercard
 JaquelynEspositojespositop0@tiny.ccFemale828-940-4785CigembongIDdiners-club-enroute
RealpointGinniferGriffittggriffittp1@google.plFemale895-553-0290ChmielnoPLjcb
BrainversePincasTinklerptinklerp2@prlog.orgMale593-540-3957AninIDjcb
YoveoAnastasieSpringtorpaspringtorpp3@opensource.orgFemale147-645-4077TaunanIDvisa
JaxworksIleaneKnaptoniknaptonp4@twitpic.comFemale767-867-4619Marcq-en-BarœulFRvisa-electron
ThoughtworksSansoneComello Male127-737-4995ExamíliaGRdiners-club-us-ca
BlognationWaldenSteaningwsteaningp6@bbb.orgMale974-569-9638OstrogozhskRUjcb
TopicshotsRobertoOffin Male700-259-1011BanghaiCNchina-unionpay
YotzAnnabelaNorthenanorthenp8@over-blog.comFemale758-508-0101Paris 01FRjcb
EdgeblabBarbyBinchbbinchp9@cisco.comFemale360-261-1227Koni-DjodjoKMjcb
PhotobugMartyBaldrickmbaldrickpa@printfriendly.comFemale311-248-2622HuangsangkouCNjcb
FeedfireHortIdneyhidneypb@reference.comMale129-523-2035NgandanganIDjcb
DabZPhedraWawerpwawerpc@home.plFemale848-355-1796Al ‘AzīzīyahLYchina-unionpay
FatzStephenieBuckbysbuckbypd@businessinsider.comFemale669-274-3762 RUswitch
TwitterlistLaurenaFyfieldlfyfieldpe@webnode.comFemale374-273-8365GensiCNjcb
MidelDonnieErdelyderdelypf@ca.govFemale449-178-5855BlahodatneUAdiners-club-carte-blanche
ZoonoodleCorettaCherrisonccherrisonpg@nyu.eduFemale505-342-8905JinjiaheCNjcb
AinyxBarneyAitkenheadbaitkenheadph@reddit.comMale197-497-4458MíthymnaGRjcb
WordtuneLynseyArentlarentpi@moonfruit.comFemale889-251-0500LiulinCNsolo
RooxoBaxyBertenshawbbertenshawpj@joomla.orgMale432-680-8104SödertäljeSEchina-unionpay
SkybleAileneBalaisonabalaisonpk@woothemes.comFemale279-732-4937RancabuayaIDvisa-electron
CogilithDaryaFrantzenidfrantzenipl@plala.or.jpFemale734-722-1984TaozhuangCNjcb
TekflyShananShilvocksshilvockpm@typepad.comMale405-760-6010KrinichnayaUAchina-unionpay
RhyzioRedHartfieldrhartfieldpn@fotki.comMale437-550-2028Paris 01FRbankcard
YouspanBironMartinatbmartinatpo@blog.comMale320-601-7054PenjaCMsolo
MidelJillMalmarjmalmarpp@accuweather.comFemale248-189-8011Rio NegrinhoBRjcb
ZavaShantaHamnershamnerpq@tuttocitta.itFemale913-448-0189AgarsinCNdiners-club-us-ca
MymmAlisanderMallabaramallabarpr@tuttocitta.itMale464-168-0047HushanCNjcb
RoodelDarrylBaisedbaiseps@wordpress.orgFemale255-121-1540Bangan-OdaPHchina-unionpay
GabtuneIngmarLampkinilampkinpt@ihg.comMale914-504-2078TajerouineTNbankcard
JaxnationHaraldTurvillehturvillepu@constantcontact.comMale704-167-5351CharlotteUSlaser
QuatzOctaviaBaynesobaynespv@thetimes.co.ukFemale465-287-8274CilongkrangIDjcb
 ColeenPetericpeteripw@altervista.orgFemale614-430-5745SuisanKRjcb
TwitterworksRobinetteKevernrkevernpx@kickstarter.comFemale903-488-8217VinhaPTjcb
ZavaLaurianneFihellylfihellypy@simplemachines.orgFemale472-217-6545ShuangyangCNbankcard
AvammLodovicoFrugierlfrugierpz@buzzfeed.comMale593-729-8483ParfinoRUvisa
BubbletubeSydelleMarusyaksmarusyakq0@fema.govFemale740-548-6974MalesínaGRjcb
VinteGertyBilslandgbilslandq1@oaic.gov.auFemale241-292-2645ÉtampesFRmastercard
VooliaLichaMechilmechiq2@bbc.co.ukFemale649-135-5754DujuumaSOjcb
EimbeePavelWalklottpwalklottq3@netlog.comMale569-426-4663ShangyangCNsolo
RealmixPetrinaJessopppjessoppq4@aol.comFemale268-562-9612AnápolisBRjcb
TagchatCorreyPauercpauerq5@samsung.comMale708-184-4858JalālābādAFjcb
MeedooRenellBlasoni Female398-258-1043KievUAlaser
LinklinksConstantinKilianckilianq7@bizjournals.comMale972-274-9588AntanifotsyMGdiners-club-international
TwitterbridgeHershGuilliatthguilliattq8@php.netMale626-429-9441XinglinCNjcb
SkimiaGarfieldPhilippeauxgphilippeauxq9@youtube.comMale797-606-6249ValeGEmaestro
DynazzyBertrandoCarabinebcarabineqa@github.comMale485-147-7033 PLdiners-club-carte-blanche
TopicstormLeandraAmerylameryqb@canalblog.comFemale640-395-6999ZouilaTNjcb
WikidoAmbroseMacClintonamacclintonqc@usatoday.comMale414-632-1679Coronel FabricianoBRjcb
PhotospaceViBadrockvbadrockqd@homestead.comFemale282-430-9157NantesFRmaestro
ThoughtsphereRebeckaDonativo Female557-278-4738DonggaocunCNlaser
BluejamFrancesPiggenfpiggenqf@usgs.govFemale949-539-0563BeloeilCAjcb
OobaMelisendaGudgenmgudgenqg@reverbnation.comFemale820-537-8927DaqiaoCNamericanexpress
NtagsTuckiePasslertpasslerqh@hostgator.comMale833-417-7193São FilipeCVamericanexpress
LivepathKalliWittleton Female686-953-8810KrzczonówPLchina-unionpay
CogilithBasiliusBlankenshipbblankenshipqj@chron.comMale304-547-5865SantiagoPYamericanexpress
GigashotsNolanReadynreadyqk@loc.govMale666-262-9712RungisFRchina-unionpay
KatzNevsaBatynbatyql@columbia.eduFemale734-160-6367CianorteBRjcb
KazioJeanSambalsjsambalsqm@mayoclinic.comFemale204-895-2517HengfengCNamericanexpress
JayoEmRegis Female500-721-1095AksuKZjcb
OobaLaughtonFancourtlfancourtqo@quantcast.comMale195-650-9742BejaPTmastercard
FivespanSharonBlaisdalesblaisdaleqp@dell.comFemale945-211-4514 THjcb
TambeeMajorReinermreinerqq@admin.chMale805-158-6373DezhouCNmaestro
GabvineMattieSpatarimspatariqr@berkeley.eduFemale964-952-8493PhonsavanLAamericanexpress
AbataKassieLathleiffure Female676-376-7693LiujiCNjcb
GabspotLorenLightewoodllightewoodqt@wordpress.comMale661-881-3086Mülheim an der RuhrDEbankcard
MitaStanfordDodridgesdodridgequ@cornell.eduMale234-373-1065SonghuCNinstapayment
AimbuPattonMorvillepmorvilleqv@imgur.comMale147-883-9845QingheCNdiners-club-carte-blanche
ZoomzoneDarwinMartynovdmartynovqw@weibo.comMale683-640-3372ObihiroJPmaestro
SkynoodleArnySchimmangaschimmangqx@plala.or.jpMale936-908-9288MiyangCNmastercard
EadelTreyMoresidetmoresideqy@chicagotribune.comMale901-795-8021MoralesCObankcard
PixobooNatanielKitcatnkitcatqz@columbia.eduMale201-407-1918AguilaresARvisa-electron
BrowsecatThomasinWindridgetwindridger0@pcworld.comFemale410-103-5185BaltimoreUSlaser
OmbaEddiPennigar Female773-122-7898Cantuk KidulIDjcb
RoomboCristyCossentineccossentiner2@mashable.comFemale268-228-1446RaszczycePLjcb
OlooAbbottKnowleraknowlerr3@europa.euMale617-151-8591ShitangCNjcb
JabberbeanNoemiGouldbournngouldbournr4@posterous.comFemale828-213-4904IkedaJPjcb
JabberstormDallasWatmoredwatmorer5@ed.govFemale480-611-8479OliveiraPTjcb
GabtypeColettaJewiscjewisr6@dropbox.comFemale546-912-0630Governor’s HarbourBSdiners-club-enroute
OodooOwenHullettohullettr7@storify.comMale874-333-4811ZdiceCZjcb
AvaveeRoxyThickettrthickettr8@marketwatch.comFemale274-582-9317Kuala LumpurMYjcb
QuaxoMorganaInottminottr9@tripod.comFemale617-145-1823Tyret’ PervayaRUbankcard
ThoughtworksTamraPanting Female404-273-6967GuojiaCNjcb
EimbeeBertheJoslingbjoslingrb@noaa.govFemale856-302-6139VideiraBRjcb
DabvineIvarStranaghanistranaghanrc@sciencedirect.comMale114-241-4100YisuheCNvisa
RiffpathClariceBrantoncbrantonrd@ow.lyFemale136-139-4138Dos QuebradasCOdiners-club-carte-blanche
SkipfireMintaDanamdanare@mysql.comFemale431-754-5892Nizhniy UfaleyRUjcb
BrainloungeKaterinaGoorkgoorrf@163.comFemale788-438-1601Kuczbork-OsadaPLmastercard
ZavaJoellyBromejbromerg@upenn.eduFemale652-188-3861PhitsanulokTHjcb
JabberspherePeterusBenediktpbenediktrh@mit.eduMale929-869-5404CikaduIDmastercard
OyoyoEmeldaKelbermanekelbermanri@stanford.eduFemale510-125-6033AlamedaMXlaser
MeeveeShaynePettspettrj@google.com.auFemale587-398-2311OxelösundSEdiners-club-carte-blanche
DevpulseVergeMarianvmarianrk@odnoklassniki.ruMale778-456-4488Pilar do SulBRmastercard
JabberstormMackenzieFennermfennerrl@stanford.eduMale556-380-0492ZhongxinCNjcb
PhotobugSibelleBletsorsbletsorrm@skype.comFemale581-529-2130St. Anton an der JeßnitzATjcb
YaceroBarbiDomekbdomekrn@mozilla.comFemale963-393-1680SanjiaCNjcb
SkynoodleAndonisDelleradellerro@opensource.orgMale948-592-8969ZharkovskiyRUjcb
SkinderPhoebeHoneyghanphoneyghanrp@zimbio.comFemale914-598-6007MegionRUjcb
JumpXSAmelitaMapesamapesrq@skype.comFemale453-973-5573ParanhoPTjcb
CentidelShepherdLindbladslindbladrr@buzzfeed.comMale158-742-1683Thị Trấn Việt QuangVNmastercard
;;;;



GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query   */
%LET _CLIENTTASKLABEL='Costruttore di query';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA AS 
   SELECT t1.Company, 
          t1.first_name, 
          t1.last_name, 
          t1.email, 
          t1.gender, 
          t1.Phone, 
          t1.City, 
          t1.Country, 
          t1.Payment_Method, 
          /* conta */
            (1) FORMAT=BESTX12. LABEL="conta" AS conta, 
          /* mailvuote */
            (case when t1.email is null  then 1 
                    else 0
            end) FORMAT=BESTX12. LABEL="mailvuote" AS mailvuote, 
          /* companivuota */
            (case when t1.company is null  then 1 
                    else 0
            end) FORMAT=BESTX12. LABEL="companivuota" AS companivuota
      FROM WORK.KENSU_DATA t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: step1   */
%LET _CLIENTTASKLABEL='step1';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0000);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0000 AS 
   SELECT t1.Country, 
          /* Calcolo */
            (SUM(t1.conta)) FORMAT=BESTX12. AS Calcolo
      FROM WORK.QUERY_FOR_KENSU_DATA t1
      GROUP BY t1.Country;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Filtro e ordinamento   */
%LET _CLIENTTASKLABEL='Filtro e ordinamento';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.FILTER_FOR_QUERY_FOR_KENSU_DATA_);

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_QUERY_FOR_KENSU_DATA_ AS 
   SELECT t1.Country, 
          t1.Calcolo
      FROM WORK.QUERY_FOR_KENSU_DATA_0000 t1
      WHERE t1.Country = 'BE';
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: step2   */
%LET _CLIENTTASKLABEL='step2';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0001);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0001 AS 
   SELECT t1.Company, 
          t1.first_name, 
          t1.last_name, 
          t1.email, 
          t1.gender, 
          t1.Phone, 
          t1.City, 
          t1.Country, 
          t1.Payment_Method, 
          t1.conta, 
          t1.mailvuote, 
          t1.companivuota
      FROM WORK.QUERY_FOR_KENSU_DATA t1
      WHERE t1.gender = 'Male' AND t1.Country = 'IT';
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: step3   */
%LET _CLIENTTASKLABEL='step3';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0002);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0002 AS 
   SELECT t1.Company, 
          t1.first_name, 
          t1.last_name, 
          t1.email, 
          t1.gender, 
          t1.Phone, 
          t1.City, 
          t1.Country, 
          t1.Payment_Method, 
          t1.conta, 
          t1.mailvuote, 
          t1.companivuota
      FROM WORK.QUERY_FOR_KENSU_DATA t1
      WHERE t1.Country = 'CN';
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (2)   */
%LET _CLIENTTASKLABEL='Costruttore di query (2)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0003);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0003 AS 
   SELECT t1.Payment_Method, 
          /* COUNT_of_Payment_Method */
            (COUNT(t1.Payment_Method)) AS COUNT_of_Payment_Method
      FROM WORK.QUERY_FOR_KENSU_DATA_0002 t1
      GROUP BY t1.Payment_Method;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (3)   */
%LET _CLIENTTASKLABEL='Costruttore di query (3)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0004);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0004 AS 
   SELECT /* COUNT_of_Payment_Method */
            (COUNT(t1.Payment_Method)) AS COUNT_of_Payment_Method
      FROM WORK.QUERY_FOR_KENSU_DATA_0003 t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: step4   */
%LET _CLIENTTASKLABEL='step4';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0005);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0005 AS 
   SELECT t1.Payment_Method, 
          t1.COUNT_of_Payment_Method
      FROM WORK.QUERY_FOR_KENSU_DATA_0003 t1
      ORDER BY t1.COUNT_of_Payment_Method DESC;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (5)   */
%LET _CLIENTTASKLABEL='Costruttore di query (5)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0006);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0006 AS 
   SELECT /* MAX_of_COUNT_of_Payment_Method */
            (MAX(t1.COUNT_of_Payment_Method)) AS MAX_of_COUNT_of_Payment_Method
      FROM WORK.QUERY_FOR_KENSU_DATA_0005 t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (6)   */
%LET _CLIENTTASKLABEL='Costruttore di query (6)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0007);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0007 AS 
   SELECT t1.Payment_Method, 
          t1.COUNT_of_Payment_Method
      FROM WORK.QUERY_FOR_KENSU_DATA_0005 t1
           INNER JOIN WORK.QUERY_FOR_KENSU_DATA_0006 t2 ON (t1.COUNT_of_Payment_Method = 
          t2.MAX_of_COUNT_of_Payment_Method);
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: step5   */
%LET _CLIENTTASKLABEL='step5';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0008);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0008 AS 
   SELECT /* SUM_of_conta */
            (SUM(t1.conta)) FORMAT=BESTX12. AS SUM_of_conta, 
          /* SUM_of_mailvuote */
            (SUM(t1.mailvuote)) FORMAT=BESTX12. AS SUM_of_mailvuote
      FROM WORK.QUERY_FOR_KENSU_DATA t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (8)   */
%LET _CLIENTTASKLABEL='Costruttore di query (8)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_0009);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_0009 AS 
   SELECT /* %Vuotesutotale */
            ((t1.SUM_of_mailvuote/t1.SUM_of_conta) * 100) LABEL="%Vuotesutotale" AS '%Vuotesutotale'n
      FROM WORK.QUERY_FOR_KENSU_DATA_0008 t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: step6   */
%LET _CLIENTTASKLABEL='step6';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_000A);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_000A AS 
   SELECT t1.Country, 
          /* SUM_of_conta */
            (SUM(t1.conta)) FORMAT=BESTX12. AS SUM_of_conta, 
          /* SUM_of_companivuota */
            (SUM(t1.companivuota)) FORMAT=BESTX12. AS SUM_of_companivuota
      FROM WORK.QUERY_FOR_KENSU_DATA t1
      GROUP BY t1.Country;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (4)   */
%LET _CLIENTTASKLABEL='Costruttore di query (4)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_000A_0000);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_000A_0000 AS 
   SELECT t1.Country, 
          /* Calcolo */
            (t1.SUM_of_companivuota/t1.SUM_of_conta) AS Calcolo
      FROM WORK.QUERY_FOR_KENSU_DATA_000A t1
      ORDER BY Calcolo DESC;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (7)   */
%LET _CLIENTTASKLABEL='Costruttore di query (7)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_000A_0001);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_000A_0001 AS 
   SELECT /* MAX_of_Calcolo */
            (MAX(t1.Calcolo)) AS MAX_of_Calcolo
      FROM WORK.QUERY_FOR_KENSU_DATA_000A_0000 t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   INIZIO NODO: Costruttore di query (9)   */
%LET _CLIENTTASKLABEL='Costruttore di query (9)';
%LET _CLIENTPROCESSFLOWNAME='Flusso dei processi';
%LET _CLIENTPROJECTPATH='\\LAPTOP-CASA\Users\B&B\Documents\Andrea\Andrea\progetto sas.egp';
%LET _CLIENTPROJECTPATHHOST='CNS0937';
%LET _CLIENTPROJECTNAME='progetto sas.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_KENSU_DATA_000A_0002);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_KENSU_DATA_000A_0002 AS 
   SELECT t1.Country, 
          t1.Calcolo
      FROM WORK.QUERY_FOR_KENSU_DATA_000A_0000 t1
           INNER JOIN WORK.QUERY_FOR_KENSU_DATA_000A_0001 t2 ON (t1.Calcolo = t2.MAX_of_Calcolo);
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
