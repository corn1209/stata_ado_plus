*! version 1.0.1 19mar00 modified to work with Stata 6 & up -- pbe
*! version 1.0.0   07 February 1997   DEM

program define mvtest /* call: mvtest varlist [/varlist2 ...], options */
   version 5.0

   #delimit ;

   if ("$S_E_cmd" != "mvreg") {
      display in red "no mvreg results";
      error 301;
   };

   parse "`*'", parse(",");
   if ("`1'" == "" | "`1'" == ",") { error 100; };
   local vlists `1';
   macro shift;

   local options "Hyp Err m(string) Norm";
   parse "`*'";

   local ss : set log linesize;
   local ss = int( (`ss' - length("MULTIVARIATE TESTS OF SIGNIFICANCE")) / 2 );
   display "" _continue;
   display _col(`ss') "MULTIVARIATE TESTS OF SIGNIFICANCE" _newline;

   if ("`m'" != "") {
      matrix S_0 = (`m');
      local cols = rowsof(S_0);
      local i = 1;
      while (`i' <= `cols') {
         local names "`names' M`i'";
         local i = `i' + 1;
      };

      if ("`norm'" != "") {
         tempname mm mrow nm;
         local i 1;
         while `i' <= rowsof(S_0) {
            matrix `mrow' = S_0[`i',.];
            matrix `nm' = `mrow' * `mrow'';
            scalar `nm' = 1 / sqrt( el(`nm',1,1) );
            matrix `mrow' = `mrow' * `nm';
            matrix `mm' = `mm' \ `mrow';
            local i = `i' + 1;
         };
         matrix S_0 = `mm';
         display _newline
            "Normalized Matrix (S_0) Describing Transformed Variables";
         matrix colnames S_0 = $S_E_elis;
         matrix rownames S_0 = `names';
         matrix list S_0;
         display _newline(4);
      };
      matrix S_0 = S_0';
   };

   tempname sysm tempm B;
   parse "$S_E_elis",parse(" ");
   matrix `sysm' = get(_b);               /*   matrix list `sysm';*/
   local i = 1;
   while `i' <= $S_E_neq {
      matrix `tempm' = `sysm'[1,"``i'':"];
      matrix `B' = `B' \ `tempm';
      local i = `i' + 1;
   };
   matrix `B' = `B'';

   tempname XX BXXB YY;
   quietly matrix ac `XX' = $S_eqeq1;
   matrix `XX'    = `XX'[2...,2...];
   if ("`m'" != "") {
      quietly matrix ac `YY' = $S_E_elis, nocons;
      matrix `BXXB' = `B'' * `XX';
      matrix `BXXB' = `BXXB' * `B';
      matrix S_1    = `YY' - `BXXB';
      matrix S_1    = S_0' * S_1;
      matrix S_1    = S_1 * S_0;
      matrix colnames S_1 = `names';
      matrix rownames S_1 = `names';
   }; else {
      matrix S_1    =  e(Sigma);
      matrix S_1    = S_1 * $S_E_tdf; /* fixed code */
     /*  matrix S_1    = S_E_rcv * $S_E_tdf;  old code*/
   };

   matrix `XX'    = syminv(`XX');

   if ("`err'" != "") {
      display _newline "Error SS&CP Matrix (S_1)";
      if ("`m'" != "") {
         display "  (Variables M1 - Mn correspond to rows of"
                 " supplied transformation matrix)";
      };
      matrix list S_1;  display _newline(4);
   };

   parse "`vlists'", parse("/");
   while ("`1'" != "") {
      mvtest1 `1', `B', `XX', "`names'", "`m'", "`hyp'";
      macro shift;
   };

end;


program define mvtest1;     /* need: vars, B, XX, names, m, hyp */
   version 5.0;

   parse "`*'", parse(",");
   if ("`1'" == "/") { exit; };

   tempname B XX;
   local vlist0 `1';
   matrix `B'  = `3';
   matrix `XX' = `5';
   local names `7';
   local m `9';
   local hyp `11';

   parse "`1'", parse(" ");
   while ("`1'" != "") {
      if ("`1'" == "_cons") {
         local vlist1 `vlist1' _cons;
      }; else {
         unabbrev(`1');
         local vlist1 `vlist1' $S_1;
      };
      macro shift;
   };

   tempname sysm tempm L;
   quietly test `vlist1';
   matrix `sysm' = get(Rr);                  /*   matrix list `sysm';*/
   matrix `sysm' = `sysm'[.,1..$S_E_par];    /*   matrix list `sysm';*/
   matrix `L' = `sysm'[1,.];
   matrix `L' = diag(`L');
   local i = 2;
   while `i' <= rowsof(`sysm') {
      matrix `tempm' = `sysm'[`i',.];
      matrix `tempm' = diag(`tempm'); 
      matrix `L' = `L' + `tempm';
      local i = `i' + 1;
   };

   tempname LXXL LB TI;
   matrix `LXXL'  = `L' * `XX';
   matrix `LXXL'  = `LXXL' * `L'';
   matrix `LXXL'  = syminv(`LXXL');
   matrix `LB'    = `L' * `B';
   matrix `LXXL'  = `LB'' * `LXXL';
   matrix S_2    = `LXXL' * `LB';

   if ("`m'" != "") {
      matrix S_2    = S_0' * S_2;
      matrix S_2    = S_2 * S_0;
      matrix colnames S_2 = `names';
      matrix rownames S_2 = `names';
   }; else {
      matrix colnames S_2 = $S_E_elis;
      matrix rownames S_2 = $S_E_elis;
   };
   matrix `TI' = S_2 + S_1;

   tempname p q r tempv value df1 df2 F;

   scalar `p' = colsof(`TI');
   scalar `q' = rowsof(`sysm') / $S_E_neq;            /* sysm == Rr */
   scalar S_3 = scalar( min(`p',`q') );
   scalar S_4 = scalar( (abs(`p' - `q') - 1) / 2 );
   scalar S_5 = scalar( ($S_E_tdf - `p' - 1) / 2 );
           
   if ("`hyp'" != "") {
      display _newline "Hypothesis SS&CP Matrix (S_2) for " _quote
                           "`vlist1'" _quote;
      if ("`m'" != "") {
         display "  (Variables M1 - Mn correspond to rows of"
                 " supplied transformation matrix)";
      };
      matrix list S_2; display _newline(2); 
   };
   local ss : set log linesize;
   display _newline "Multivariate Test Criteria and Exact F Statistics for";
   display "the Hypothesis of no Overall " _quote "`vlist0'" _quote " Effect(s)"
   _newline; 
   local hs : display "S=" S_3 _skip(4) "M=" S_4 _skip(4) "N=" S_5;
   local ss = int( (`ss' - length("`hs'")) / 2 );
   display _col(`ss') "`hs'" _newline;
   display "Test" _col(31) "Value" _col(46) "F" _col(54) "Num DF" _col(65)
           "Den DF" _col(74) "Pr > F" _newline;

   scalar `r' = $S_E_tdf - ( scalar(`p'-`q'+1) / 2 );

   scalar `value' = det(S_1) / det(`TI');
   scalar `tempv' = scalar( `p'^2 + `q'^2 - 5 );
   if `tempv'>0 {
      scalar `tempv' = scalar( (`p'^2 * `q'^2 - 4) / `tempv' );
      scalar `tempv' = sqrt( scalar(`tempv') );
      scalar `df2' = scalar(`r'*`tempv' - ((`p'*`q' - 2) / 2) );
      scalar `tempv' = scalar( `value'^(1/`tempv') );
   }; else {
      scalar `df2' = scalar(`r' - ((`p'*`q' - 2) / 2) );
      scalar `tempv' = scalar( `value' );
   };
   scalar `df1' = scalar(`p'*`q');
   scalar `F'   = scalar( ((1 - `tempv') / `tempv') * (`df2' / `df1') );
   display "Wilks' Lambda          "
            %14.8f = `value'
            %11.4f = `F'
            %11.0f = `df1'
            %11.4f = `df2'
            %9.4f = fprob(`df1',`df2',`F');
   global S_1 = `value';
   global S_2 = `F';
   global S_3 = `df1';
   global S_4 = `df2';

   matrix `tempm' = syminv(`TI');
   matrix `tempm' = S_2 * `tempm';
   scalar `value' = trace(`tempm');
   scalar `df1' = scalar(2*S_4 + S_3 + 1);
   scalar `df2' = scalar(2*S_5 + S_3 + 1);
   scalar `F' = scalar( (`df2'*`value')/(`df1'*(S_3-`value')) );
   scalar `df1' = scalar( S_3 * `df1' );
   scalar `df2' = scalar( S_3 * `df2' );
   display "Pillai's Trace         "
            %14.8f = `value'
            %11.4f = `F'
            %11.0f = `df1'
            %11.4f = `df2'
            %9.4f = fprob(`df1',`df2',`F');
   global S_5 = `value';
   global S_6 = `F';
   global S_7 = `df1';
   global S_8 = `df2';

   matrix `tempm' = syminv(S_1);
   matrix `tempm' = `tempm' * S_2;
   scalar `value' = trace(`tempm');
   scalar `df2'   = scalar( 2*S_3*S_5 + 2 );
   scalar `F'     = scalar( (`df2'*`value')/ (S_3*`df1') );
   display "Hotelling-Lawley Trace "
            %14.8f = `value'
            %11.4f = `F'
            %11.0f = `df1'
            %11.4f = `df2'
            %9.4f = fprob(`df1',`df2',`F')
            _newline(4);
   global S_9 = `value';
   global S_10 = `F';
   global S_11 = `df1';
   global S_12 = `df2';
end;

