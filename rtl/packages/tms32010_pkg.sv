`default_nettype none

package tms32010_pkg;
  typedef enum logic [3:0] {
    OP_LACK,
    OP_NOP,
    OP_ZAC,
    OP_ROVM,
    OP_SOVM,
    OP_LARK,
    OP_LARP,
    OP_LDPK
  } tms32010_operation_t;
endpackage

`default_nettype wire
