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
    input cache_req_t  cache_req_i,
    input cache_tag_t  wr_tag_i,
    output cache_tag_t rd_tag_o
);
    cache_tag_t mem [0:TAG_MEM_SIZE-1];

    // Synchronous write
    always_ff @(posedge clk_i) begin
        if (cache_req_i.wr_en)
            mem[cache_req_i.index] <= wr_tag_i;
    end

    // Asynchronous read
    assign rd_tag_o = mem[cache_req_i.index];

endmodule

