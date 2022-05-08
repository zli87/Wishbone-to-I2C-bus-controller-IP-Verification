`timescale 1ns / 10ps
interface i2c_if       #(
    int I2C_ADDR_WIDTH = 7,
    int I2C_DATA_WIDTH = 8,
    int SLAVE_ADDRESS = 7'h22
)(
    // Slave signals
    input           scl_s,
    inout   triand  sda_s
);
    //typedef enum bit { I2C_READ=1,I2C_WRITE=0} i2c_op_t;
    import i2c_pkg::*;

    // global signals
    logic sda_ack       = 0;
    logic ack_drive     = 0;
    assign sda_s = sda_ack ? ack_drive : 'bz;

    // variable for task wait_for_i2c_transfer, provide_read_data
    bit     flg_start_1 = 0;
    bit     flg_stop_1  = 0;
    bit     flg_data_1  = 0;
    // variable for task monitor
    bit     flg_start_2 = 0;
    bit     flg_stop_2  = 0;
    bit     flg_data_2  = 0;

    task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
        automatic bit [I2C_DATA_WIDTH-1:0]      data_packed;
        automatic bit [I2C_ADDR_WIDTH-1:0]      addr_packed;
        automatic bit [I2C_DATA_WIDTH-1:0]      data_packet_buffer [$];
        automatic bit correct = 0;

        WaitStart( flg_start_1 );
        GetAddr( op, correct, addr_packed );
        assert( correct ) begin end else $fatal("[info][%t] WRONG I2C slave address!!!",$time);
        Ack( correct );
        if(!correct) begin
            WaitStop( flg_stop_1 );
        end else if( op == I2C_WRITE ) begin
            @(negedge scl_s) sda_ack =0;
            GetDataPacket( data_packed );
            data_packet_buffer.push_back( data_packed );
            Ack( correct );
            @(negedge scl_s) sda_ack =0;
            do begin
                flg_data_1 = 0;
                fork    :   fork_in_driver
                    begin   WaitStart( flg_start_1 );       flg_start_1 = 1;    end
                    begin   WaitStop( flg_stop_1 );                             end
                    begin   GetDataPacket( data_packed );
                            data_packet_buffer.push_back( data_packed );
                            flg_data_1 = 1;
                            Ack( correct );
                            @(negedge scl_s) sda_ack =0;
                    end
                join_any
                disable fork;
            end while( flg_data_1 );

            write_data = new [ data_packet_buffer.size() ];
            write_data = {>>{data_packet_buffer}};
        end // end if op == OP_WRITE

    endtask

    task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
        automatic bit ack =0; // 0: Acknowledge, 1: Non Acknowledge
        foreach( read_data[i] ) begin
            DriveDataPacket( read_data[i] );
            @(negedge scl_s) sda_ack <=0;
            @(posedge scl_s) ack = !sda_s;
            if( !ack ) begin // if No Acknowledge from I2C master, stop transfer
                fork
                    begin WaitStart( flg_start_1 ); flg_start_1 =1; end
                    begin WaitStop( flg_stop_1 ); end
                join_any
                disable fork;
                break;
            end // end if No ack
        end // end foreach
        // if Acknowledge, transfer incomplete, else if Non Acknowledge, transfer complete
        transfer_complete = !ack;
    endtask

    task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
        automatic bit [I2C_DATA_WIDTH-1:0] data_packed;
        automatic bit [I2C_DATA_WIDTH-1:0] data_packet_buffer [$];
        automatic bit correct = 0;
        automatic bit ack = 0;

        WaitStart( flg_start_2 );
        GetAddr( op, correct, addr );
        @(posedge scl_s);
        if(!correct) begin
            WaitStop( flg_stop_2 );
        end else begin
            automatic bit stall = 0;
            do begin
                flg_data_2 = 0;
                fork : fork_in_monitor
                    begin   wait(stall); WaitStart( flg_start_2 ); flg_start_2 = 1; end
                    begin   wait(stall); WaitStop( flg_stop_2 ); end
                    begin   GetDataPacket( data_packed );
                            data_packet_buffer.push_back( data_packed );
                            @(posedge scl_s);
                            flg_data_2 = 1;
                    end
                join_any
                disable fork_in_monitor;
                stall = 1;
            end while( flg_data_2 );
        end // end if-else-!correct
        data = new [ data_packet_buffer.size() ];
        data = {>>{data_packet_buffer}};
    endtask

    task automatic WaitStart( ref bit _flg_start_ );
        while( !_flg_start_ ) @(negedge sda_s) if(scl_s) _flg_start_ = 1'b1;
        _flg_start_ = 1'b0;
    endtask

     task automatic WaitStop( ref bit _flg_stop_ );
        while( !_flg_stop_ ) @(posedge sda_s) if(scl_s) _flg_stop_ = 1'b1;
        _flg_stop_ = 1'b0;
    endtask

     task automatic GetAddr( output i2c_op_t op1, output bit _correct_ , output bit [I2C_ADDR_WIDTH-1:0] _addr_packed_ );
        automatic bit buffer[$];
        repeat(I2C_ADDR_WIDTH) @(posedge scl_s) begin buffer.push_back(sda_s); end
        _addr_packed_ = {>>{buffer}};
        @(posedge scl_s) op1 = i2c_op_t'(sda_s);
        // asusme we connect multiple i2c slave to i2c bus, we can accept any slave address.
        // _correct_ = ( SLAVE_ADDRESS == _addr_packed_ );
        _correct_ = 1'b1;
    endtask

     task automatic GetDataPacket( output bit [I2C_DATA_WIDTH-1:0] _data_packed_ );
        automatic bit buffer[$];
        repeat(I2C_DATA_WIDTH) @(posedge scl_s) begin buffer.push_back(sda_s); end
        _data_packed_ = {>>{buffer}};
    endtask

     task automatic Ack( input bit _correct_ );
        @(negedge scl_s) begin sda_ack <=_correct_; ack_drive <=0; end
        @(posedge scl_s);
    endtask

     task automatic DriveDataPacket( input bit [I2C_DATA_WIDTH-1:0] _read_data_ );
        foreach( _read_data_[j] ) begin
            @(negedge scl_s) sda_ack <=1; ack_drive <= _read_data_[j];
        end
    endtask

    task automatic arb_lost_during_restart();
        automatic bit _op_;
        automatic bit _correct_;
        automatic bit _stall_ =0;
        automatic bit [I2C_ADDR_WIDTH-1:0]      _addr_packed_;
        automatic bit [I2C_DATA_WIDTH-1:0]      _data_packed_;

            WaitStart( flg_start_1 );
            GetAddr( _op_, _correct_, _addr_packed_ );
            assert( _correct_ ) begin end else $fatal("[info][%t] WRONG I2C slave address!!!",$time);
            Ack( _correct_ );
            if(!_correct_) begin
                WaitStop( flg_stop_1 );
            end else if( _op_ == I2C_WRITE ) begin
                @(negedge scl_s) sda_ack =0;

                GetDataPacket( _data_packed_ );
                Ack( _correct_ );
                @(negedge scl_s) //sda_ack =0;
                sda_ack =1;
                ack_drive<=0;
                flg_data_1 = 0;

            end // end if op == I2C_WRITE
    endtask

    task arb_lost_during_write();
        automatic bit correct = 0;
        automatic bit stall = 0;
        automatic bit illegal_start_flg = 0;
        automatic bit op;
        automatic bit [I2C_DATA_WIDTH-1:0]      data_packed;
        automatic bit [I2C_ADDR_WIDTH-1:0]      addr_packed;
        automatic bit [I2C_DATA_WIDTH-1:0]      data_packet_buffer [$];

            WaitStart( flg_start_1 );

            repeat(I2C_ADDR_WIDTH) @(posedge scl_s) begin
                if(sda_s==1)begin // i2c slave dont care about i2c master, always pull down sda_s
                    sda_ack <=1;
                    ack_drive <=0;
                    break;
                end
            end
            //#1000 sda_ack <=0;
    endtask

    task arb_lost_during_read();
        automatic i2c_op_t _op_ ;
        automatic bit [I2C_DATA_WIDTH-1:0] dontcare_data [];
        wait_for_i2c_transfer ( _op_, dontcare_data );
        // i2c slave dont care about i2c master, always pull down sda_s
        @(negedge scl_s) sda_ack <=1; ack_drive<=0;
    endtask

    task reset();
        sda_ack <=0;
        flg_start_1<=0;
    endtask

endinterface

// hold_data = {>>{data with [0:blk_len-1]}};
