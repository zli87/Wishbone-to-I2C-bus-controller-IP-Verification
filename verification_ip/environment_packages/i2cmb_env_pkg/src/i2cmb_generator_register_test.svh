class i2cmb_generator_register_test extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_register_test)

bit [7:0] reset_value[iicmb_reg_ofst_t];
bit [7:0] mask_value[iicmb_reg_ofst_t]; // access permission of each register

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);

	reset_value[CSR] = 8'h00;
	reset_value[DPR] = 8'h00;
	reset_value[CMDR] = 8'h80;
	reset_value[FSMR] = 8'h00;
	// access permission of each register
	mask_value[CSR] = 8'hc0;
	mask_value[DPR] = 8'h00; // !!! refer to description in line 52
	mask_value[CMDR] = 8'h17;
	// write 8'h07 to CMDR will assert error bit( bit offset 4).
	// Thus I add error bit into CMDR mask to simplify testing logic.
	mask_value[FSMR] = 8'h00;

endfunction

virtual task run();

    // Control/Status Register (CSR)
    //      address offset  0x00
    //      bit offset      |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
    //      meaning         |  E | IE | BB | BC |       Bus ID      |
    //      permission      | RW | RW | RO | RO | RO | RO | RO | RO |
    //      reset value     |  0 |  0 |  0 |  0 |       4'b0000     |

    // Control/Status Register (DPR)
    //      address offset  0x01
    //      bit offset      |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
    //      meaning         |Data/parameter for a byte-level command|
    //      permission      |                   RW                  |
    //      reset value     |              8'b00000000              |
    //      !!! Suspectul Bug !!!
    //          According to specification, it defined "Reading DPR register returns last byte received via I2C bus.",
    //      if we didnt send CMDR a READ command before we read DPR register,
    //      iicmb returns 0. This means the access permission of DPR is "WO" in most of time.

    // Control/Status Register (CMDR)
    //      address offset  0x02
    //      bit offset      |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
    //      meaning         | DON| NAK| AL | ERR|  R |      CMD     |
    //      permission      | RO | RO | RO | RO | RO | RW | RW | RW |
    //      reset value     |  0 |  0 |  0 |  0 |  0 |      3'b0000 |

    // Control/Status Register (FSMR)
    //      address offset  0x03
    //      bit offset      |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
    //      meaning         |      Byte FSM     |      Bit FSM      |
    //      permission      | RO | RO | RO | RO | RO | RO | RO | RO |
    //      reset value     |       4'b0000     |       4'b0000     |

    $display("--------------------------------------------------------");
    $display("       TEST PLAN 1: REGISTER BLOCK TEST START          ");
    $display("--------------------------------------------------------");

    // Test Plan 1.1: Register System Reset Test
    //      refer to case 1.TEST REGISTER RESET VALUE AFTER SYSTEM RESET (before enable core)

    // Test Plan 1.2: Register Core Reset Test
    //      refer to case 2.TEST REGISTER RESET VALUE AFTER ENABLE CORE

    // Test Plan 1.3: Register Default Value
    //      refer to case 1.TEST REGISTER RESET VALUE AFTER SYSTEM RESET (before enable core)
    //      refer to case 2.TEST REGISTER RESET VALUE AFTER ENABLE CORE

    // Test Plan 1.4: Register Address
    //      refer to all TEST cases

    // Test Plan 1.5: Register Access Permission
    //      refer to case 3.TEST REGISTER ACCESS PERMISSION AFTER RESET CORE
    //      refer to case 4.TEST REGISTER ACCESS PERMISSION AFTER ENABLE CORE

    // Test Plan 1.6: Register Aliasing
    //      refer to case 5.TEST REGISTER ALIASING AFTER ENABLE CORE

    // test purpose: register should be reset value AFTER SYSTEM RESET (rst signal)
    $display("_____________CASE 1.TEST REGISTER RESET VALUE AFTER SYSTEM RESET_________________");

    // test order: FSMR(3) -> CMDR(2) -> DPR(1)-> CSR(0)
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
    	else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
    end

    // enable core
    void'(trans_w[CSR].set_data( CSR_E | CSR_IE));
	super.wb_agt0.bl_put_ref(trans_w[CSR]);


    // test purpose: CMDR, DPR, FSMR registers should be reset value after enable
    $display("_____________CASE 2.TEST REGISTER RESET VALUE AFTER ENABLE CORE_________________");

    // test order: FSMR(3) -> CMDR(2) -> DPR(1)-> CSR(0)
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        if(addr_ofst == CSR)begin
            assert(trans_r[addr_ofst].wb_data == mask_value[CSR] )  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} INCORRECT :%b", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)],trans_r[addr_ofst].wb_data);
        end else begin
            assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)],trans_r[addr_ofst].wb_data);
        end
    end

    // test purpose: all register except CSR should not be able to be written "AFTER RESET CORE, before enable core!"
    // access permission of CSR should follow specification.
    $display("_____________CASE 3.TEST REGISTER ACCESS PERMISSION AFTER RESET CORE_________________");

    // reset core
    void'(trans_w[CSR].set_data( (~CSR_E) & (~CSR_IE) ));
    super.wb_agt0.bl_put_ref(trans_w[CSR]);

    // test order: FSMR(3) -> CMDR(2) -> DPR(1)-> CSR(0)
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        void'(trans_w[addr_ofst].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst]);

        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        if(addr_ofst == CSR)begin
            assert(trans_r[addr_ofst].wb_data == mask_value[CSR] )  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
        end else begin
            assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
        end
    end

    // test purpose: test access permission AFTER ENABLE CORE
    // access permission of DPR, FSMR should follow specification.
    $display("_____________CASE 4.TEST REGISTER ACCESS PERMISSION AFTER ENABLE CORE_________________");

    // enable core
    void'(trans_w[CSR].set_data( CSR_E | CSR_IE));
    super.wb_agt0.bl_put_ref(trans_w[CSR]);

    // test order: FSMR(3) -> CMDR(2) -> DPR(1)-> CSR(0)
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        void'(trans_w[addr_ofst].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst]);

        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        assert(trans_r[addr_ofst].wb_data == mask_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
        else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
    end
    // test purpose: test register aliasing
    // writing to 1 register should not affect other registers
    $display("_____________CASE 5.TEST REGISTER ALIASING AFTER ENABLE CORE_________________");

    // test order: CSR(0) -> DPR(1) -> CMDR(2) -> FSMR(3)
    for(int i=0; i<4 ;i++)begin
        automatic iicmb_reg_ofst_t addr_ofst_1 = iicmb_reg_ofst_t'(i);
        automatic iicmb_reg_ofst_t addr_ofst_2;

        void'(trans_w[addr_ofst_1].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst_1]);
        // test order: CSR(0) -> DPR(1) -> CMDR(2) -> FSMR(3)
        for(int k=0; k<4 ;k++)begin
            if( k == i ) continue;
            addr_ofst_2 = iicmb_reg_ofst_t'(k);
            assert(trans_r[addr_ofst_2].wb_data == mask_value[addr_ofst_2])  $display("{%s UNCHANGED WHEN WRITING TO %s} PASSED ", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
            else $fatal("{%s ALIASED WHEN WRITING TO %s} FAILED ", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
        end
    end
    $display("--------------------------------------------------------");
    $display("       TEST PLAN 1: REGISTER BLOCK TEST PASS          ");
    $display("--------------------------------------------------------");

 endtask

endclass
