////////////
// Filename: tag_mem.sv
// Author: Christopher Tinker
// Date: 2023/03/03
// 
// L1 direct mapped data cache tag memory
////////////

`include "defs.svh"

module tag_mem #(
    parameter int unsigned TAG_MEM_SIZE = 256
    ) (
    input logic        clk_i,
    input logic        rst_i,
    input cache_req_t  cache_req_i,
    input cache_tag_t  wr_tag_i,
    output cache_tag_t rd_tag_o
);
    cache_tag_t mem [0:TAG_MEM_SIZE-1];
    
    initial begin
        for (int i = 0; i < TAG_MEM_SIZE; i++) begin
            mem[i] = '0;
        end
    end

    // Synchronous write
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for (int i = 0; i < TAG_MEM_SIZE; i++) begin
                mem[i].valid <= 1'b0;
            end
        end else if (cache_req_i.wr_en) begin
            mem[cache_req_i.index] <= wr_tag_i;
        end
    end

    // Asynchronous read
    assign rd_tag_o = mem[cache_req_i.index];

endmodule

