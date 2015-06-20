//-----------------------------------------------------------------
// TOP
//-----------------------------------------------------------------
module top
(
    // 50MHz clock
    input           clk,

    // LED
    output [7:0]    leds,

    // SDRAM
    inout           udqm,
    inout           sdram_clk,
    inout           cke,
    inout           bs1,
    inout           bs0,
    inout           sdram_csn,
    inout           rasn,
    inout           casn,
    inout           wen,
    inout           ldqm,
    inout [12:0]    a,
    inout [15:0]    d,

    // FTDI
    inout           ftdi_rxf,
    inout           ftdi_txe,
    inout           ftdi_siwua,
    inout           ftdi_wr,
    inout           ftdi_rd,
    inout [7:0]     ftdi_d
);

//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
parameter       CLK_KHZ             = 100000;

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
wire        clk100;

reg         reset           = 1'b1;
reg         rst_next        = 1'b1;

wire[31:0]  ftdi_address_w;
wire[31:0]  ftdi_data_w;
wire[31:0]  ftdi_data_r;
wire[3:0]   ftdi_sel_w;
wire        ftdi_we_w;
wire        ftdi_stb_w;
wire        ftdi_cyc_w;
wire        ftdi_stall_w;
wire        ftdi_ack_w;

wire [7:0]  ftdi_gpio_w;

//-----------------------------------------------------------------
// Implementation
//-----------------------------------------------------------------
generate 
if (CLK_KHZ > 50000)
begin
    clk_50_100 u_dcm
    (
        .CLK_IN(clk),
        .CLK_OUT(clk100)
    );
end
else
begin
    assign clk100 = clk;
end
endgenerate

always @(posedge clk100) 
if (rst_next == 1'b0)
    reset       <= 1'b0;
else 
    rst_next    <= 1'b0;

//-----------------------------------------------------------------
// FTDI
//-----------------------------------------------------------------
ftdi_if
u_ftdi
(
    .clk_i(clk100),
    .rst_i(reset),

    // FTDI (async FIFO interface)
    .ftdi_rxf_i(ftdi_rxf),
    .ftdi_txe_i(ftdi_txe),
    .ftdi_siwua_o(ftdi_siwua),
    .ftdi_wr_o(ftdi_wr),
    .ftdi_rd_o(ftdi_rd),
    .ftdi_d_io(ftdi_d),

    .gp_o(ftdi_gpio_w),
    .gp_i(8'b0),

    // Wishbone
    .mem_addr_o(ftdi_address_w),
    .mem_data_o(ftdi_data_w),
    .mem_data_i(ftdi_data_r),
    .mem_sel_o(ftdi_sel_w),
    .mem_we_o(ftdi_we_w),
    .mem_stb_o(ftdi_stb_w),
    .mem_cyc_o(ftdi_cyc_w),
    .mem_ack_i(ftdi_ack_w),
    .mem_stall_i(ftdi_stall_w)
);

//-----------------------------------------------------------------
// SDRAM Controller
//-----------------------------------------------------------------
sdram
#(
    .SDRAM_MHZ(CLK_KHZ / 1000),
    .SDRAM_READ_LATENCY((CLK_KHZ == 50000) ? 2 : 3)
)
u_dram
(
    .clk_i(clk100),
    .rst_i(reset),

    // Wishbone Interface
    .stb_i(ftdi_stb_w),
    .we_i(ftdi_we_w),
    .sel_i(ftdi_sel_w),
    .addr_i(ftdi_address_w),
    .data_i(ftdi_data_w),
    .data_o(ftdi_data_r),
    .cyc_i(ftdi_cyc_w),
    .stall_o(ftdi_stall_w),
    .ack_o(ftdi_ack_w),

    // SDRAM Interface
    .sdram_clk_o(sdram_clk),
    .sdram_cke_o(cke),
    .sdram_cs_o(sdram_csn),
    .sdram_ras_o(rasn),
    .sdram_cas_o(casn),
    .sdram_we_o(wen),
    .sdram_dqm_o({udqm, ldqm}),
    .sdram_addr_o(a),
    .sdram_ba_o({bs1, bs0}),
    .sdram_data_io(d)
);

assign leds = ftdi_gpio_w;

endmodule
