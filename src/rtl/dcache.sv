////////////
// Filename: dcache.sv
// Author: Christopher Tinker, Keefe Johnson, Joseph Callenes
// Date: 2023/03/02
// 
// 4KB Direct-mapped L1 data cache
// Organization: 256 x 128b
// Implements a sorta AXI-lite interface with some signals omitted - 
// 32 bit AXI-lite slave for core-cache interface and 128 bit AXI-lite
// master for cache-memory interface.
//
// Cache cannot accept simultaneous read and write transactions, but will
// always prioritize reads
////////////

`include "defs.svh"
`include "memory_interfaces.svh"

module dcache (
    input                 clk_i, 
    input                 rst_i,
    axi_bus_rw.device     core,
    axi_bus_rw.controller mem
);

    logic [`LINE_LEN-1:0] dmem_rd_data;
    logic [`LINE_LEN-1:0] dmem_wr_data;
    
    //cache_req_t active_req;
    cache_req_t core_req;
    cache_req_t core_req_r;
    cache_req_t mem_req;
    cache_req_t cache_ctrl;

    cache_tag_t wr_tag;
    cache_tag_t core_wr_tag;
    cache_tag_t mem_wr_tag;
    cache_tag_t rd_tag, rd_tag_r;

    logic        cache_hit;
    logic        core_axi_valid;
    logic        core_rvalid_d;
    logic        core_bvalid_d;
    logic [31:0] core_req_addr;
    logic [31:0] core_req_addr_r;

    typedef enum {COMPARE_TAG, ALLOCATE, WRITEBACK} cache_state_e;
    cache_state_e state_r, next_state;

    // Decode core AXI-lite signals into cache control
    assign core_req_addr         = core.read_addr_valid ? core.read_addr : core.write_addr; // double check this
    assign core_req.index        = core_req_addr[11:4];
    assign core_req.wr_en        = core.write_addr_valid && cache_hit; // double check -- does this logic work?
    assign core_req.byte_en      = core.strobe;
    assign core_req.block_offset = core_req_addr[3:2];
    assign core_req.from_ram     = 1'b0;
    
    // Cache control signals for cache read from main memory
    assign mem_req.index        = core_req_addr_r[11:4];
    assign mem_req.wr_en        = (mem.read_addr_valid && mem.read_data_valid); // review
    assign mem_req.byte_en      = '0; // do not care
    assign mem_req.block_offset = '0; // do not care
    assign mem_req.from_ram     = 1'b1;

    // Update tag memory on core write to cache
    assign core_wr_tag.tag   = core_req_addr[`TAG_MSB:`TAG_LSB];
    assign core_wr_tag.dirty = 1'b1;
    assign core_wr_tag.valid = 1'b1;

    // Update tag memory on cache read from main memory  
    assign mem_wr_tag.tag   = core_req_addr_r[`TAG_MSB:`TAG_LSB]; // Same as mem.read_addr
    assign mem_wr_tag.dirty = 1'b0;
    assign mem_wr_tag.valid = 1'b1;

    // Cache write data mux
    assign dmem_wr_data = (core_req.from_ram) ? {96'b0, core.write_data} : {96'b0, mem.read_data};

    tag_mem l1_tag_mem (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .cache_req_i (cache_ctrl), // WRONG
        .wr_tag_i    (wr_tag),
        .rd_tag_o    (rd_tag)
    ); 

    data_mem l1_data_mem (
        .clk_i       (clk_i),
        .cache_req_i (cache_ctrl),  // WRONG
        .wr_data_i   (dmem_wr_data),
        .rd_data_o   (dmem_rd_data)
    );  
    
    // Compare tags and determine cache hit
    // TODO: check this use of core_req_addr - we're either doing hit from address on AXI bus, or 
    // buffered core_req_addr_r if we've just resolved a cache miss
    assign cache_hit      = (rd_tag.tag == core_req_addr[`TAG_MSB:`TAG_LSB]) && rd_tag.valid;
    assign core_axi_valid = core.write_addr_valid || core.read_addr_valid;
    
    // Register a core request when it is accepted by cache
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            core_req_r      <= '0;
            core_req_addr_r <= '0;
            rd_tag_r        <= '0;
        end else if ((core.read_addr_valid && core.read_addr_ready) ||
            (core.write_addr_valid && core.write_addr_ready)) begin
            core_req_r      <= core_req;
            core_req_addr_r <= core_req_addr[31:0];
            rd_tag_r        <= rd_tag;
        end
    end

    // Cache Controller FSM
    always_ff @(posedge clk_i) begin
        if (rst_i)
            state_r <= COMPARE_TAG;
        else state_r <= next_state; 

        core.read_data_valid  <= core_rvalid_d;
        core.write_resp_valid <= core_bvalid_d;
    end

    always_comb begin
        core.read_addr_ready  = 1'b0;
        core.write_addr_ready = 1'b0;
        core_rvalid_d         = 1'b0;
        core_bvalid_d         = 1'b0;
        mem.read_addr_valid   = 1'b0;
        mem.write_addr_valid  = 1'b0;
        wr_tag                = '0;
        cache_ctrl            = '0;
        
        case (state_r)

            COMPARE_TAG: begin
                core.read_addr_ready  = 1'b1;
                core.write_addr_ready = 1'b1;
                cache_ctrl            = core_req;
                wr_tag                = core_wr_tag;

                // Technically a bug, but this cache just ignores a write request if the
                // core makes an AXI read and a write request at the same time
                if (core.read_addr_valid && cache_hit) begin
                    core_rvalid_d = 1'b1;
                    next_state    = COMPARE_TAG;
                end else if (core.write_addr_valid && cache_hit) begin
                    core_bvalid_d = 1'b1;
                    next_state    = COMPARE_TAG;
                end else if (core_axi_valid && !cache_hit && rd_tag.dirty) begin
                    next_state = WRITEBACK;
                end else if (core_axi_valid && !cache_hit && !rd_tag.dirty) begin
                    next_state = ALLOCATE;   
                end else begin
                    next_state = COMPARE_TAG;
                end
            end

            WRITEBACK: begin
                mem.write_addr_valid = 1'b1;

                // Why doesn't memory have a write_resp_valid signal? 
                if (mem.write_addr_ready) next_state = ALLOCATE;
                else next_state = WRITEBACK;
            end

            ALLOCATE: begin
                // AXI violation in FSM - no combinational paths between input and output!
                mem.read_addr_valid = 1'b1;
                cache_ctrl          = mem_req;
                wr_tag              = mem_wr_tag;

                if (mem.read_data_valid) begin
                    next_state = COMPARE_TAG;
                end else begin
                    //mem.read_addr_valid = 1'b1;
                    next_state = ALLOCATE;
                end
            end
        endcase
    end
    
    // Memory 128 bit AXI-lite bus
    assign mem.read_addr  = {core_req_addr_r[31:4], 4'b0}; // double check
    assign mem.write_addr = {rd_tag_r.tag, core_req_r.index, 4'b0}; // double check
    assign mem.write_data = dmem_rd_data;
    assign mem.strobe     = core_req_r.byte_en; 
    assign mem.size       = '0; // What does this signal even do?
    assign mem.lu         = '0; // Same for you, wtf    

    // Core 32-bit AXI-lite bus
    assign core.read_data = dmem_rd_data[core_req_r.block_offset*32+:32]; // am I being too clever? check in sim

`ifdef VERILATOR
    _unused = &{1'b0};
`endif


endmodule
