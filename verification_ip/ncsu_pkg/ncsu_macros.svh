`define ncsu_register_object(T) \
  typedef ncsu_object_registry #(T,`"T`") type_id;

// *****************************************
// Terminal Text Color      Code
// BRIGHT_RED"              91
// BRIGHT_GREEN"            92
// BRIGHT_YELLOW"           93
// BRIGHT_CYAN"             96
// *****************************************

`ifdef TERMINAL
    `define displayY(x) $display("\033[93m%s\033[0m",x);
`else
    `define displayY(x) $display("%s",x);
`endif
