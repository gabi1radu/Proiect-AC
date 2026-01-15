`default_nettype none

module spi_bridge(
    input  wire       rst_n,
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi_in,
    output reg        miso_out,

    // register file interface
    output reg  [5:0] rd_addr,
    input  wire [7:0] rd_data,

    output reg  [5:0] wr_addr,
    output reg  [7:0] wr_data,
    output reg        wr_toggle
);

    // transaction state (SCLK domain)
    reg [2:0] bit_cnt;
    reg [1:0] byte_cnt;
    reg [7:0] sh_in;
    reg [7:0] sh_out;

    // helpers (module-scope for Verilog-2001 compatibility)
    reg [7:0] next_byte;
    reg [7:0] so;

    reg       cmd_is_write;
    reg       cmd_is_valid;
    reg [5:0] cmd_addr;
    reg       load_read_data;

    // Note: an explicit decoder module exists (instr_dcd), but the bridge
    // keeps decoding inline to stay lightweight.

    // Reset/transaction start
    always @(negedge rst_n or negedge cs_n) begin
        if (!rst_n) begin
            bit_cnt        <= 3'd0;
            byte_cnt       <= 2'd0;
            sh_in          <= 8'h00;
            sh_out         <= 8'h00;
            miso_out       <= 1'b0;

            cmd_is_write   <= 1'b0;
            cmd_is_valid   <= 1'b0;
            cmd_addr       <= 6'h00;
            rd_addr        <= 6'h00;
            wr_addr        <= 6'h00;
            wr_data        <= 8'h00;
            wr_toggle      <= 1'b0;
            load_read_data <= 1'b0;
        end else begin
            // CS asserted: begin a new 2-byte frame
            bit_cnt        <= 3'd0;
            byte_cnt       <= 2'd0;
            sh_in          <= 8'h00;
            sh_out         <= 8'h00;
            miso_out       <= 1'b0;
            cmd_is_write   <= 1'b0;
            cmd_is_valid   <= 1'b0;
            cmd_addr       <= 6'h00;
            rd_addr        <= 6'h00;
            load_read_data <= 1'b0;
        end
    end

    // Shift MOSI in on rising edges
    always @(negedge rst_n or posedge sclk) begin
        if (!rst_n) begin
            sh_in    <= 8'h00;
            bit_cnt  <= 3'd0;
            byte_cnt <= 2'd0;

            cmd_is_write   <= 1'b0;
            cmd_is_valid   <= 1'b0;
            cmd_addr       <= 6'h00;
            rd_addr        <= 6'h00;
            load_read_data <= 1'b0;
        end else if (!cs_n) begin
            // build the byte MSB-first
            sh_in <= {sh_in[6:0], mosi_in};

            if (bit_cnt == 3'd7) begin
                // full byte received
                // (sh_in updates at end of the timestep, so reconstruct explicitly)
                next_byte = {sh_in[6:0], mosi_in};

                if (byte_cnt == 2'd0) begin
                    // command byte
                    cmd_is_write   <= next_byte[7];
                    cmd_is_valid   <= next_byte[6];
                    cmd_addr       <= next_byte[5:0];
                    rd_addr        <= next_byte[5:0];
                    load_read_data <= (~next_byte[7]) & next_byte[6];

                    byte_cnt <= 2'd1;
                end else begin
                    // data byte
                    if (cmd_is_valid && cmd_is_write) begin
                        wr_addr   <= cmd_addr;
                        wr_data   <= next_byte;
                        wr_toggle <= ~wr_toggle;
                    end
                    byte_cnt <= 2'd0;
                end

                bit_cnt <= 3'd0;
                sh_in   <= 8'h00;
            end else begin
                bit_cnt <= bit_cnt + 3'd1;
            end
        end
    end

    // Drive MISO on falling edges (mode 0)
    always @(negedge rst_n or negedge sclk) begin
        if (!rst_n) begin
            sh_out   <= 8'h00;
            miso_out <= 1'b0;
        end else if (!cs_n) begin
            // Only meaningful during second byte of a READ transaction
            if ((byte_cnt == 2'd1) && cmd_is_valid && !cmd_is_write) begin
                // load read data at start of the second byte
                if (load_read_data && (bit_cnt == 3'd0)) begin
                    so             = rd_data;
                    load_read_data <= 1'b0;
                end else begin
                    so = sh_out;
                end

                miso_out <= so[7];
                sh_out   <= {so[6:0], 1'b0};
            end else begin
                miso_out <= 1'b0;
                sh_out   <= sh_out;
            end
        end else begin
            miso_out <= 1'b0;
        end
    end

endmodule

`default_nettype wire


