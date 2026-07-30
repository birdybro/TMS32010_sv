`default_nettype none

package tms32010_pkg;
  typedef enum logic [2:0] {
    OP_LACK,
    OP_NOP,
    OP_ZAC,
    OP_ROVM,
    OP_SOVM
  } tms32010_operation_t;
endpackage

`default_nettype wire
