`default_nettype none

module regs(
    input  wire       clk,
    input  wire       rst_n,

    // write request from SPI (toggle-based)
    input  wire       wr_toggle,
    input  wire [5:0] wr_addr,
    input  wire [7:0] wr_data,

    // read address from SPI
    input  wire [5:0] rd_addr,
    output reg  [7:0] rd_data,

    // live signals out
    output reg  [7:0] period,
    output reg        counter_en,
    output reg  [7:0] compare1,
    output reg  [7:0] compare2,
    output reg  [7:0] prescale,
    output reg        upnotdown,
    output reg        pwm_en,
    output reg  [1:0] functions,
    output reg        soft_reset_pulse,

    // live signal in
    input  wire [7:0] counter_val
);

    // Address map (must match TB)
    localparam [5:0] REG_PERIOD        = 6'h00;
    localparam [5:0] REG_COUNTER_EN    = 6'h02;
    localparam [5:0] REG_COMPARE1      = 6'h03;
    localparam [5:0] REG_COMPARE2      = 6'h05;
    localparam [5:0] REG_COUNTER_RESET = 6'h07;
    localparam [5:0] REG_COUNTER_VAL   = 6'h08;
    localparam [5:0] REG_PRESCALE      = 6'h0A;
    localparam [5:0] REG_UPNOTDOWN     = 6'h0B;
    localparam [5:0] REG_PWM_EN        = 6'h0C;
    localparam [5:0] REG_FUNCTIONS     = 6'h0D;

    // Sync toggle to clk domain
    reg wr_tog_q1, wr_tog_q2;
    reg wr_tog_seen;

    wire wr_event = (wr_tog_q2 ^ wr_tog_seen);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_tog_q1   <= 1'b0;
            wr_tog_q2   <= 1'b0;
            wr_tog_seen <= 1'b0;
        end else begin
            wr_tog_q1 <= wr_toggle;
            wr_tog_q2 <= wr_tog_q1;
            if (wr_event)
                wr_tog_seen <= wr_tog_q2;
        end
    end

    // Register writes + soft reset pulse
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period           <= 8'd0;
            counter_en       <= 1'b0;
            compare1         <= 8'd0;
            compare2         <= 8'd0;
            prescale         <= 8'd0;
            upnotdown        <= 1'b1; // default: up
            pwm_en           <= 1'b0;
            functions        <= 2'b00;
            soft_reset_pulse <= 1'b0;
        end else begin
            soft_reset_pulse <= 1'b0;

            if (wr_event) begin
                case (wr_addr)
                    REG_PERIOD:        period     <= wr_data;
                    REG_COUNTER_EN:    counter_en <= wr_data[0];
                    REG_COMPARE1:      compare1   <= wr_data;
                    REG_COMPARE2:      compare2   <= wr_data;
                    REG_PRESCALE:      prescale   <= wr_data;
                    REG_UPNOTDOWN:     upnotdown  <= wr_data[0];
                    REG_PWM_EN:        pwm_en     <= wr_data[0];
                    REG_FUNCTIONS:     functions  <= wr_data[1:0];
                    REG_COUNTER_RESET: begin
                        if (wr_data[0])
                            soft_reset_pulse <= 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

    // Register reads (combinational)
    always @* begin
        case (rd_addr)
            REG_PERIOD:        rd_data = period;
            REG_COUNTER_EN:    rd_data = {7'b0, counter_en};
            REG_COMPARE1:      rd_data = compare1;
            REG_COMPARE2:      rd_data = compare2;
            REG_COUNTER_RESET: rd_data = 8'h00;
            REG_COUNTER_VAL:   rd_data = counter_val;
            REG_PRESCALE:      rd_data = prescale;
            REG_UPNOTDOWN:     rd_data = {7'b0, upnotdown};
            REG_PWM_EN:        rd_data = {7'b0, pwm_en};
            REG_FUNCTIONS:     rd_data = {6'b0, functions};
            default:           rd_data = 8'h00;
        endcase
    end

endmodule

`default_nettype wire

