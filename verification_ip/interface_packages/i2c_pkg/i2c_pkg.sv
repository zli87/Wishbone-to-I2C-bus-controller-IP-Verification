package i2c_pkg;

  import ncsu_pkg::*;
  import my_pkg::*;
  `include "ncsu_macros.svh"
  `include "i2c_macros.svh"

  `include "src/i2c_type.svh"
  `include "src/i2c_transaction.svh"
   `include "src/i2c_transaction_rand.svh"
  `include "src/i2c_configuration.svh"
  `include "src/i2c_driver.svh"
  `include "src/i2c_monitor.svh"
  `include "src/i2c_agent.svh"

endpackage
