`default_nettype none

module top(
    input  wire clk,
    input  wire rst_n,

    // SPI (naming follows the testbench wiring)
    input  wire sclk,
    input  wire cs_n,
    input  wire miso,      // TB drives this with its MOSI
    output wire mosi,      // TB reads this as MISO

    output wire pwm_out
);

    // SPI <-> regfile signals
    wire [5:0] rd_addr;
    wire [7:0] rd_data;
    wire [5:0] wr_addr;
    wire [7:0] wr_data;
    wire       wr_toggle;

    // Reg outputs
    wire [7:0] period;
    wire       counter_en;
    wire [7:0] compare1;
    wire [7:0] compare2;
    wire [7:0] prescale;
    wire       upnotdown;
    wire       pwm_en;
    wire [1:0] functions;
    wire       soft_reset_pulse;

    wire [7:0] counter_val;

    spi_bridge u_spi(
        .rst_n     (rst_n),
        .sclk      (sclk),
        .cs_n      (cs_n),
        .mosi_in   (miso),
        .miso_out  (mosi),
        .rd_addr   (rd_addr),
        .rd_data   (rd_data),
        .wr_addr   (wr_addr),
        .wr_data   (wr_data),
        .wr_toggle (wr_toggle)
    );

    regs u_regs(
        .clk              (clk),
        .rst_n            (rst_n),
        .wr_toggle        (wr_toggle),
        .wr_addr          (wr_addr),
        .wr_data          (wr_data),
        .rd_addr          (rd_addr),
        .rd_data          (rd_data),
        .period           (period),
        .counter_en       (counter_en),
        .compare1         (compare1),
        .compare2         (compare2),
        .prescale         (prescale),
        .upnotdown        (upnotdown),
        .pwm_en           (pwm_en),
        .functions        (functions),
        .soft_reset_pulse (soft_reset_pulse),
        .counter_val      (counter_val)
    );

    counter u_cnt(
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (counter_en),
        .period     (period),
        .prescale   (prescale),
        .upnotdown  (upnotdown),
        .soft_reset (soft_reset_pulse),
        .value      (counter_val)
    );

    pwm_gen u_pwm(
        .pwm_en      (pwm_en),
        .functions   (functions),
        .period      (period),
        .compare1    (compare1),
        .compare2    (compare2),
        .counter_val (counter_val),
        .pwm_out     (pwm_out)
    );

endmodule

`default_nettype wire

