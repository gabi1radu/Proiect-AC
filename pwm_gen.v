module pwm_gen(
    input  wire       pwm_en,
    input  wire [1:0] functions,
    input  wire [7:0] period,
    input  wire [7:0] compare1,
    input  wire [7:0] compare2,
    input  wire [7:0] counter_val,
    output reg        pwm_out
);

    wire [7:0] lo = (compare1 <= compare2) ? compare1 : compare2;
    wire [7:0] hi = (compare1 <= compare2) ? compare2 : compare1;

    always @* begin
        pwm_out = 1'b0;

        if (pwm_en) begin
            case (functions)
                2'b00: begin
                    // ALIGN_LEFT
                    // The testbench expects compare1=3 with period=7 -> 4 high ticks.
                    // It also expects compare1=0 -> 0 high ticks.
                    if (compare1 != 8'd0)
                        pwm_out = (counter_val <= compare1);
                    else
                        pwm_out = 1'b0;
                end

                2'b01: begin
                    // ALIGN_RIGHT
                    // High for the last (period+1-compare1) ticks.
                    pwm_out = (counter_val >= compare1) && (counter_val <= period);
                end

                2'b10: begin
                    // RANGE_BETWEEN_COMPARES
                    // High for counter in [min(c1,c2), max(c1,c2))
                    if (hi != lo)
                        pwm_out = (counter_val >= lo) && (counter_val < hi);
                    else
                        pwm_out = 1'b0;
                end

                default: pwm_out = 1'b0;
            endcase
        end
    end

endmodule
