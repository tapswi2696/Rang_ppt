   /*****************************************************************************/
  /**                  RESET EVERYHING                                      ****/
 /*****************************************************************************/

 dm log 'clear';
 dm output 'clear'; 
 dm odsresults 'clear';
 
 proc datasets memtype=catalog;
 delete formats;
 run;
 quit; 

 proc datasets lib=work memtype=data kill nodetails nolist;
 run;
 quit; 
 
 title1;
 footnote1;
 
   /*****************************************************************************/
  /**                  IMPORT AND READ GITHUB                               ****/
 /*****************************************************************************/

/* Fetch the file from the web site */

filename raw_ct temp;
proc http
 url="https://raw.githubusercontent.com/tapswi2696/Rang_ppt/master/RAW_CSV.csv"
 method="GET" 
 out=raw_ct;
run;

options validvarname=any;
 
/* import to a SAS data set */

proc import
  file=raw_ct
  out=work.raw_ct_db replace dbms=csv;delimiter=',';guessingrows=3000;
run;

proc sort data=raw_ct_db;
  by sr_num;
run;

/** EDIT CHECK ****/ 

proc freq data=raw_ct_db  noprint;
   table level * ct_code * sdtm_variable * raw_value /out=basic (drop=percent count);
run;

   /*****************************************************************************/
  /**                  BASIC LEVEL                                          ****/
 /*****************************************************************************/

/** LET'S WARM UP **/ 

proc sort data=raw_ct_db out=basic; 
   by sr_num;
   where level eq upcase('BASIC'); /* LEVEL variable : I'VE INCLUDED FOR LEARNING PURPOSE ****/
run;

proc freq data=basic  noprint;
   table level * ct_code * sdtm_variable * raw_value /out=basic (drop=percent count);
   /** LEVEL * ALL UNIQUE CONTROL TERM CODE * SDTM VAR * RAW VAL ***/
run;

/** APPLY CONTROL TERMINOLOGY ****/ 

proc format;

   invalue levnum
     
   "BASIC"=1
   "INTERMIDATE"=2
   "ADVANCE"=3
   ;
   
   value $basic
   
   "feeMale","F"="F"
   "MaLe","male"="M"
   "N"="N"
   "Na","NA"="NA"
   "NO","No","nO"="N"
   "YES","Yes","y"="Y"
   other="CT Is Not Applied For The Value, Please Find Or Use Extensible Value"
    ; 
   
run;
     

data basic;
  retain ct_code raw_value sdtm_value;
  length sdtm_value $100.;
  set basic; 
 
   sdtm_value=put(strip(raw_value),$basic.);
   levnum=input(level,levnum.);
run;

   /*****************************************************************************/
  /**                  INTERMIDATE LEVEL                                    ****/
 /*****************************************************************************/

/** NOW LET'S STRECH YOUR SELF ***/ 

proc sort data=raw_ct_db out=interm; 
   by sr_num;
   where level eq upcase('INTERMIDATE');
run;

proc freq data=interm  noprint;
   table level * ct_code * sdtm_variable * raw_value /out=interm (drop=percent count);
run;

/** APPLY CONTROL TERMINOLOGY ****/ 

proc format;

   value $interm
   
   "Alcohol"="Ethanol"
   "Inconculsive"="INDETERMINATE"
   "Neg"="NEGATIVE"
   "Preg test"="Choriogonadotropin Beta"/** LBTESTCD = HCG **/
   "leuKocytes"="Leukocytes" /**LBTESTCD = WBC **/
   "positive"="POSITIVE"
   other="CT Is Not Applied For The Value, Please Find Or Use Extensible Value"
     ; 

run;

data interm;
  retain ct_code raw_value sdtm_value;
  length sdtm_value $100.;
  set interm; 
 
  sdtm_value=put(strip(raw_value),$interm.);
  levnum=input(level,levnum.);
run;

   /*****************************************************************************/
  /**                  ADVANCE LEVEL                                        ****/
 /*****************************************************************************/

/** NOW TEST YOUR SELF **/ 

proc sort data=raw_ct_db out=advance; 
   by sr_num;
   where level eq upcase('ADVANCE');
run;

proc freq data=advance  noprint;
   table level * ct_code * sdtm_variable * raw_value /out=advance (drop=percent count);
run;

/** APPLY CONTROL TERMINOLOGY ****/ 

proc format;

   value $advance
   
   "ABNORMAL","AbNORMAL,CLI. SIGNIFIC .","Abnormal","Abnormal, Changed from baseline","Abnormal, Clinically significant"="ABNORMAL"
   "NORMAL"="NORMAL"
   "10*12/Lit"="10^12/L"
   "Breaths per Minute"="breaths/min" 
   "Percent"="%"
   "Thou/L"="10^3/L"
   "hpf"="/HPF"
   other="CT Is Not Applied For The Value, Please Find Or Use Extensible Value"
   ;

run;

data advance;
    retain ct_code raw_value sdtm_value;
    length sdtm_value $100.;
    set advance; 
    sdtm_value=put(strip(raw_value),$advance.);
    levnum=input(level,levnum.);
 run;

   /*****************************************************************************/
  /**                  FINAL OUTPUT                                         ****/
 /*****************************************************************************/

/** SORT IT **/ 

proc sort data=basic;
   by levnum ct_code sdtm_value raw_value;
run;

proc sort data=interm;
   by levnum ct_code sdtm_value raw_value;
run;

proc sort data=advance;
   by levnum ct_code sdtm_value raw_value;
run;

   /*****************************************************************************/
  /**                  ORGANIZE IT                                          ****/
 /*****************************************************************************/

/** SET TO GETHER ***/ 

data final ;
  retain levenum level ct_code sdtm_value raw_value;
  set basic interm advance;
  by levnum ct_code sdtm_value raw_value;
run;

   /*****************************************************************************/
  /**                  OUTPUT                                               ****/
 /*****************************************************************************/

/** PRINT IT ***/

proc sort data=final;
   by levnum sdtm_value;
run;

proc print data=final noobs;
  var level ct_code sdtm_variable sdtm_value raw_value ;
run;




