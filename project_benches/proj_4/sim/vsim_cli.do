set NoQuitOnFinish 1;
coverage exclude -scope /top/DUT/iicmb_m_inst0/mbit_inst0
run -all;
coverage save $1.$Sv_Seed.ucdb ;
quit -f;
