`ifndef __SYS_DEFS_VH__
`define __SYS_DEFS_VH__


//`define VECTOR_SIZE 39
`define K 14 //number of labels = number of clusters
`define Klen $clog2(`K)
`define m 524288 // number of rows of data to be analyzed
`define n $clog2(`m) // number of elements to a cluster 
`define dpw 32 //datapath width

//bits needed to not overflow
/*
`define s_age 23
`define s_educ 22
`define s_ethnic 22
`define s_race 22
`define s_gender 21
`define s_service 20
`define s_marstat 22
`define s_sap 21
`define s_employ 22
`define s_detnlf 22
`define s_veteran 21
`define s_livarag 21
*/

`endif // __SYS_DEFS_VH__