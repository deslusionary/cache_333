////////////
// Filename: data_mem.sv
// Author: Christopher Tinker, Keefe Johnson, Joseph Callenes-Sloan
// Date: 2023/03/02
// 
// L1 direct mapped data cache data memory
////////////

`include "defs.svh"


module data_mem ( 
    input                        clk_i,
    input cache_req_t            cache_req_i,
    input        [`LINE_LEN-1:0] wr_data_i,
    output logic [`LINE_LEN-1:0] rd_data_o
);
    
    logic [`LINE_LEN-1:0] mem[0:255];
    
    initial begin
        for(int i=0; i<256; i++)
            mem[i]='0;
    end

    always_ff @(posedge clk_i) begin
        if(cache_req_i.wr_en) begin
            if (cache_req_i.from_ram) mem[cache_req_i.index] <= wr_data_i;

            else if (!cache_req_i.from_ram) begin
                for (int b = 0; b < `WORD_SIZE; b++) begin
                    if (cache_req_i.byte_en[b]) begin
                    // use this if word is moved into the correct location in wr_data_i
                    // mem[data_req.index][block_offset*WORD_WIDTH+b*8+:8] <= wr_data_i[block_offset*WORD_WIDTH+b*8+:8];

                    // use this if the data to write from the CPU starts at the lowest word
                        mem[cache_req_i.index][cache_req_i.block_offset*`WORD_WIDTH+b*8+:8] <= wr_data_i[b*8+:8];
                end
              end
            end
        end
            
        rd_data_o <= mem[cache_req_i.index];
    end
endmodule

