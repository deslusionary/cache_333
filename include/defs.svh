////////////
// Filename: defs.svh
// Author: Christopher Tinker
// Date: 2023/03/02
// 
// preprocessor defines and data types for cache
////////////

`ifndef DEFS
`define DEFS

`define TAG_MSB 31
`define TAG_LSB 12
`define LINE_LEN 128

`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define WORD_WIDTH 32
`define WORD_SIZE `DATA_WIDTH / 8
`define MMIO_START_ADDR 'h11000000\
`define BLOCK_SIZE 16
`define BLOCK_WIDTH `BLOCK_SIZE * 8
`define WORD_ADDR_LSB $clog2(`WORD_SIZE)
`define BLOCK_ADDR_LSB $clog2(BLOCK_SIZE)


typedef struct packed{
    logic valid;
    logic dirty;
    logic [`TAG_MSB:`TAG_LSB] tag;
} cache_tag_t;

typedef struct {
    logic [7:0] index;
    logic       wr_en;
    // Signals needed only for L1_cache_data
    logic [3:0] byte_en; //byte enable from ADDR_WIDTH
    logic [1:0] block_offset;
    logic       from_ram;
    
} cache_req_t;

// package cache_def;

// parameter int TAG_MSB = 31;
// parameter int TAG_LSB = 12;

// typedef struct packed{
//     logic valid;
//     logic dirty;
//     logic [TAG_MSB:TAG_LSB] tag;
// } cache_tag_t;

// typedef struct {
//     logic [7:0] index;
//     logic we;
//     // Signals needed only for L1_cache_data
//     logic [3:0] be; //byte enable from ADDR_WIDTH
//     logic [1:0] block_offset;
//     logic from_ram;
    
// } cache_req_t;

// //128-bit cache line
// typedef logic [127:0] cache_data_type;

// endpackage


// package memory_bus_sizes;
// // user-defined
// parameter ADDR_WIDTH = 32;  // bits
// parameter DATA_WIDTH = 32;  // bits
// parameter WORD_WIDTH = 32;
// parameter WORD_SIZE = DATA_WIDTH / 8;  //bytes  /STRB -strobe
// parameter MMIO_START_ADDR = 'h11000000;
// //for blocked memory
// parameter BLOCK_SIZE =16;   //bytes, power of 2
// parameter BLOCK_WIDTH = BLOCK_SIZE * 8;
// parameter WORD_ADDR_LSB = $clog2(WORD_SIZE);
// parameter BLOCK_ADDR_LSB = $clog2(BLOCK_SIZE);
// endpackage
// import memory_bus_sizes::*;

`endif

