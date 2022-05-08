// Enum: ncsu_verbosity
//
// Defines standard verbosity levels for reports.
//
//  NCSU_NONE   - Report is always printed. Verbosity level setting can not
//               disable it.
//  NCSU_LOW    - Report is issued if configured verbosity is set to UVM_LOW
//               or above.
//  NCSU_MEDIUM - Report is issued if configured verbosity is set to UVM_MEDIUM
//               or above.
//  NCSU_HIGH   - Report is issued if configured verbosity is set to UVM_HIGH
//               or above.
//  NCSU_FULL   - Report is issued if configured verbosity is set to UVM_FULL
//               or above.

typedef enum
{
  NCSU_NONE   = 0,
  NCSU_LOW    = 100,
  NCSU_MEDIUM = 200,
  NCSU_HIGH   = 300,
  NCSU_FULL   = 400,
  NCSU_DEBUG  = 500
} ncsu_verbosity_e;
