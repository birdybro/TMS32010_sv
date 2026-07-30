`default_nettype none

package tms32010_pkg;
  typedef enum logic [3:0] {
    OP_LACK = 4'd0,
    OP_NOP  = 4'd1,
    OP_ZAC  = 4'd2,
    OP_ROVM = 4'd3,
    OP_SOVM = 4'd4,
    OP_LARK = 4'd5,
    OP_LARP = 4'd6,
    OP_LDPK = 4'd7,
    OP_LAC  = 4'd8,
    OP_SACL = 4'd9,
    OP_SACH = 4'd10
  } tms32010_operation_t;
endpackage

`default_nettype wire
