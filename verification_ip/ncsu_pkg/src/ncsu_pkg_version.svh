`define NCSU_MAJOR_VERSION 1
`define NCSU_MINOR_VERSION 0
`define NCSU_LETTER_VERSION "a"

class ncsu_pkg_version;

  static bit b = print_version();
  static function bit print_version();

    $display("----------------------------------------------------------------");
    $display("//  NCSU Package ");
    $display("//  Version %0d.%0d%s" , `NCSU_MAJOR_VERSION , `NCSU_MINOR_VERSION, `NCSU_LETTER_VERSION);
    $display("----------------------------------------------------------------");
    $display("\n");
    return 1;
  endfunction

endclass

