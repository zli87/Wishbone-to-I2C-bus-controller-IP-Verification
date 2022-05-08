add testbrowser ./*.ucdb
xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
vcover merge -stats=none -strip 0 -totals i2cmb_test_plan.ucdb ./*.ucdb
add testbrowser ./i2cmb_test_plan.ucdb
#vsim -viewcov ./i2cmb_test_plan.ucdb
