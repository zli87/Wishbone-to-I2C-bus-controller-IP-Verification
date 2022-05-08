class ncsu_object extends ncsu_void;

  string name;
  ncsu_verbosity_e verbosity_level=NCSU_MEDIUM;
  static ncsu_verbosity_e global_verbosity_level=NCSU_MEDIUM;
  static int unsigned ncsu_warnings;
  static int unsigned ncsu_errors;
  static int unsigned ncsu_fatals;

  function new(string name="");
    super.new();
    this.name = name;
  endfunction

  function void set_verbosity(ncsu_verbosity_e new_verbosity);
    verbosity_level = new_verbosity;
  endfunction

  function void set_global_verbosity(ncsu_verbosity_e new_verbosity);
    global_verbosity_level = new_verbosity;
  endfunction

  function void ncsu_info(string id, string msg, ncsu_verbosity_e msg_verbosity);
  	if ((verbosity_level >= msg_verbosity) | (global_verbosity_level >= msg_verbosity))
      $display("NCSU_INFO:Time %t:%s: %s", $time, id, msg);
  endfunction

  function void ncsu_warning(string id, string msg);
  	$display("NCSU_WARNING:Time %t:%s: %s", $time, id, msg);
  	ncsu_warnings++;
  	$warning;
  endfunction

  function void ncsu_error(string id, string msg);
  	$display("NCSU_ERROR:Time %t:%s: %s", $time, id, msg);
  	ncsu_errors++;
  	$error;
  endfunction

  function void ncsu_fatal(string id, string msg);
  	$display("NCSU_FATAL:Time %t:%s: %s", $time, id, msg);
  	ncsu_fatals++;
  	$fatal;
  endfunction

  function void ncsu_test_report();
  	$display("NCSU_WARNINGS: %d", ncsu_warnings);
  	$display("NCSU_ERRORS:   %d", ncsu_errors);
  	$display("NCSU_FATALS:   %d", ncsu_fatals);
  endfunction

endclass
