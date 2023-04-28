parameter int WB_ADDR = 2;
parameter bit [WB_ADDR-1:0] CSR = 2'b00;
parameter bit [WB_ADDR-1:0] DPR = 2'b01;
parameter bit [WB_ADDR-1:0] CMDR = 2'b10;
parameter bit [WB_ADDR-1:0] FSMR = 2'b11;
parameter int WB_SLAVE_ADDR_SIZE = 7;
parameter int WB_BYTE_SIZE = 8;
parameter int NUM_I2C_SLAVES = 2;
parameter int WB_DATA = 8;
parameter int BUS_NUM = 0;
parameter bit [WB_DATA-1:0] SLAVE_ADDRESS = 8'h22;

parameter bit [WB_DATA-1:0] CSR_RESET_VAL = 8'h00;
parameter bit [WB_DATA-1:0] DPR_RESET_VAL = 8'h00;
parameter bit [WB_DATA-1:0] CMDR_RESET_VAL = 8'h80;
parameter bit [WB_DATA-1:0] FSMR_RESET_VAL = 8'h00;

enum bit [WB_DATA-1:0] {
SET_BUS_CONFG 		= 8'b00000110,
READ_ACK_CONFG 		= 8'b00000010,
READ_NAK_CONFG		= 8'b00000011,
START_CONFG		= 8'b00000100,
STOP_CONFG		= 8'b00000101,
WRITE_CONFG		= 8'b00000001
} wb_cmd_t;

typedef enum int {
	FSM_START,
	FSM_ADDRESS,
	FSM_DATA
} wb_enum;
