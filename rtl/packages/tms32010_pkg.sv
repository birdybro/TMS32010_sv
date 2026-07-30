`default_nettype none

package tms32010_pkg;
  typedef enum logic [4:0] {
    OP_LACK = 5'd0,
    OP_NOP  = 5'd1,
    OP_ZAC  = 5'd2,
    OP_ROVM = 5'd3,
    OP_SOVM = 5'd4,
    OP_LARK = 5'd5,
    OP_LARP = 5'd6,
    OP_LDPK = 5'd7,
    OP_LAC  = 5'd8,
    OP_SACL = 5'd9,
    OP_SACH = 5'd10,
    OP_ZALH = 5'd11,
    OP_ZALS = 5'd12,
    OP_ADDS = 5'd13,
    OP_XOR  = 5'd14,
    OP_AND  = 5'd15,
    OP_OR   = 5'd16,
    OP_ADD  = 5'd17,
    OP_SUB  = 5'd18,
    OP_SUBS = 5'd19,
    OP_LAR  = 5'd20,
    OP_SAR  = 5'd21
  } tms32010_operation_t;
endpackage

`default_nettype wire
