
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter bit [6:0] I2C_SLAVE_ADDRESS = 7'h22;

typedef enum bit {
    I2C_WRITE=0,
    I2C_READ=1
} i2c_op_t;

string  map_op_name [ i2c_op_t ] = '{
    I2C_READ    : "READ",
    I2C_WRITE   : "WRITE"
};
