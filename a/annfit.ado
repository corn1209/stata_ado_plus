*! Neural networks approximation; v. 1.3
* version 1.0: random search
* version 1.1: confirm new variable _out*; option delete
* version 1.2: added: if in, predict
* version 1.3: added: seed
program define annfit, rclass
    version 6
    #delimit ;
    syntax
          varname [if] [in],
          Neural(varlist numeric min=1)
          [Units(integer 1) RANDom Repeat(integer 100) NOCons DEBug DELete
          PRedict Linear(varlist numeric min=1) SEED(integer 1000)] ;
    #delimit cr
    * ��樨:
    * varname    -- ����ᨬ�� ��६�����
    * Linear     -- ��६����, �室�騥 � �������� ����
    * Neural     -- ��㬥��� ���஭��� ����⮢
    * Units      -- ������⢮ ���஭��� ����⮢
    * RANDom     -- ������ ���᪠
    * Repeat     -- ᪮�쪮 �������
    * DELete     -- 㭨�⮦��� ����訥�� _out*
    * PRedict    -- �ண����஢��� ���஭�� output �� ����祭��� ������
    * SEED       -- ���樠����஢��� ������� ��砩��� �ᥫ
    local LHS "`varlist'"
    local un=1
    capture confirm new variable _predict
    if _rc==110 {
      if "`delete'"=="" {
       di in red "_predict already defined"
       exit
      }
      else {
       qui drop _predict
      }
    }
    if "`seed'" ~= "" {
       set seed `seed'
    }
    while `un'<=`units' {
       capture confirm new variable _out`un'
       if _rc==110 {
        if "`delete'"=="" {
         di in red "_out`un' already defined"
         exit
        }
        else {
         qui drop _out`un'
        }
       }
       local un=`un'+1
    }
    if "`debug'"~="" {
       local debug 1
    }
    else {
       local debug 0
    }
    local debugg 0
    if `debug' {
       di in blue "Dependent variable: `LHS'"
       di in blue "Linear part:        `linear'"
       di in blue "Neural network ins: `neural'"
       di in blue "Neural units:       " `units'
       di in blue "Repeat times:       " `repeat'
    }
    macro shift
    * ⥯��� � varlist ᮤ�ঠ��� ⮫쪮 ������ᨬ� ��६����
    * �ந��樠�����㥬 �����:
    local un 1
    tokenize `neural', parse(" ")
    while `un'<=`units' {
        if `debug' {
           di in blue "Now working with unit " `un'
        }
        local a`un'_0=0
        local var 1
        while "``var''"~="" {
           if `debug' {
               di in blue "  Now working with variable no. " `var'
           }
           local a`un'_`var' = 0
           local var = `var'+1
        }
        if `debug' {
           di in blue "Finished var cycle; output of cell " `un' ":"
        }
        tempvar _out`un'
        qui gen double `_out`un''=0 `if' `in'
        if `debug' {
           sum `_out`un''
        }
        local un= `un'+1
    }
    tempname _r2
    scalar `_r2'=0
    if `debug' {
       di _n in blue "Initialization completed"
    }
    * ��, �ந��樠����஢���; ⥯��� ����� 横� �� ���-�� ����஢
    local count 1
    tempvar _s
    qui gen double `_s'=0 `if' `in'
    while `count'<=`repeat' {
        local un 1
        while `un'<=`units' {
            local var 1
            local shift`un'=invnorm(uniform())
            * �� �㤥� ��㬥�� �������᪮� �㭪樨
            qui replace `_s'=`shift`un'' `if' `in'
            while "``var''"~="" {
               local b`un'_`var'=invnorm(uniform())
               qui replace `_s'=`_s'+`b`un'_`var''*``var'' `if' `in'
               if `debugg' {
                 di in blue "Step " `count' "; unit no. " `un' "; variable no." `var'
                 sum `_s'
               }
               local var= `var'+1
            } * 横� �� var -- ���� �祥�
            qui replace `_out`un''=1/(1+exp(`_s')) `if' `in'
            if `debug' {
              di in blue "Output of cell " `un' " and it linear part:"
              sum `_out`un'' `_s'
            }
            local un=`un'+1
        } * 横� �� un -- ���� �祥�
        if `debug' {
            di in blue "Step no. " `count'
            local un 1
            while `un'<=`units' {
              di in blue _n "Coefficients in unit " `un'
              di in blue "  Shift " _c
              local var =1
              while "``var''"~="" {
                local colno =`var'*8+8
                di in blue "``var''" _col(`colno') _c
                local var=`var'+1
              }
              di in blue _n %8.5f `shift' _c
              local var =1
              while "``var''"~="" {
                di in blue %8.5f `b`un'_`var'' "  " _c
                local var=`var'+1
              }
              local un=`un'+1
            }
        } * if debug
        if `debug' {
          reg `LHS' `linear' `_out1'-`_out`units'' `if' `in'
        }
        else {
           qui reg `LHS' `linear' `_out1'-`_out`units'' `if' `in'
        }
        local _r2cur=_result(7)
        if `_r2cur'>`_r2' { * ���� �������� ���祭��
            if `debug' {
              di in blue "Updating maximum values"
            }
            scalar `_r2'=`_r2cur'
            local un=1
            while `un'<=`units' {
               local a`un'_0=`shift`un''
               local var=1
               while "``var''"~="" {
                 local a`un'_`var'=`b`un'_`var''
                 local var=`var'+1
               }
               local un=`un'+1
            }
        } * if ���� ���ᨬ� ������
        local count=`count'+1
    } * 横� �� count
    * ��, ⥯��� �뢮��� १�����
    di in green "OLS with neural cells repeated " `repeat' " times"
    local un 1
    while `un'<=`units' {
        di in green _n "Parameters of the cell no. " `un' _n
        di in green "  Shift" _c
        local var 1
        while "``var''"~="" {
          local colno =`var'*10
          di in green %10s "``var''" _c
          local var = `var' + 1
        }
        di in green _n _d(`colno') "-" _d(8) "-"
        di in yellow %8.5f `a`un'_0' _d(2) " " _c
        return scalar a`un'_0 = `a`un'_0'
        local var 1
        while "``var''"~="" {
          di in yellow %8.5f `a`un'_`var'' _d(2) " " _c
          return scalar a`un'_`var'=`a`un'_`var''
          local var = `var' + 1
        }
        di _n
        * �� �㤥� ��㬥�� �������᪮� �㭪樨
        local var 1
        qui replace `_s'=`a`un'_0'
        while "``var''"~="" {
           qui replace `_s'=`_s'+`a`un'_`var''*``var''
           local var= `var'+1
        } * 横� �� var -- ���� �祥�
        qui gen _out`un'=1/(1+exp(`_s')) `if' `in'
        if "`predict'"~="" {
           qui replace _out`un'=1/(1+exp(`_s'))
        }
        qui lab var _out`un' "Output of neural cell no. `un'"
        local un=`un'+1
    } * 横� �� un -- ���� �祥�
    return local linear="`linear'"
    return local neural="`neural'"
    return local units ="`units'"
    reg `LHS' `linear' _out1-_out`units' `if' `in'
    if "`predict'"~="" {
         qui predict _predict, xb
    }
end
