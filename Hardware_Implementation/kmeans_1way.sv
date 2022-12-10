////////////////////////////////////////////////////////////////////////
//                                                                    //
//                  K-Means Clustering in Hardware                    //
//                               By:                                  //
//  Peter Hevrdejs, Joseph Plata, Nam Ho Koh, Charles Ziegenbein Jr.  //
//    (hevrdejs)     (joeplata)   (namhokoh)        (cbzjr)           //
//                                                                    //
////////////////////////////////////////////////////////////////////////


/* Input Vector Breakdown:
Features:
----------------------  DECIMAL
AGE         -   [3:0]   MAX:15
EDU         -   [6:4]   MAX:6
ETHNC       -   [9:7]   MAX:5
RACE        -   [12:10] MAX:7
GENDER      -   [14:13] MAX:3
SPHSERVICE  -   [15]    MAX:2
CMPSERVICE  -   [16]    MAX:2
OPISERVICE  -   [17]    MAX:2
RTCSERVICE  -   [18]    MAX:2
IJSSERVICE  -   [19]    MAX:2
MARSTAT     -   [26,24] MAX:5
SAP         -   [28,27] MAX:3
EMPLOY      -   [31,29] MAX:6
DETNLF      -   [34,32] MAX:6
VETERAN     -   [36,35] MAX:3
LIVARAG     -   [38,37] MAX:4

Labels (for training):
----------------------
MH1         -   [23,20]

So when you look at an element coming in, it is represented as:
39'b{LIVARAG,VETERAN,DETNLF,EMPLOY,...,GENDER,RACE,ETHNIC,EDU,AGE}


*/


module toplevel(
    input logic clk, reset, training, valid,
    input logic [38:0] element_in,
    output logic [`K-1:0][34:0] formatted_centroids,
    output logic [38:0] element_from_memory,
    output logic finished, update_centroids,recalculate_centroids
    
);
// ECD Wires 
logic [`K-1:0][38:0] centroid_from_crf;

// DC Wires
logic ecd2dc_valid;
logic [38:0] ecd2dc_element;
logic [`K-1:0][38:0] ecd2dc_distances; 

//CECAU Wires
logic dc2cecau_valid;
logic [38:0] dc2cecau_element; 
logic [`Klen-1:0] closest_index;
logic [`K-1:0][38:0] centroid_from_cecau;



logic [38:0] element_source;
logic valid_source, valid_from_memory;

assign element_source = update_centroids? element_from_memory:element_in;
assign valid_source = update_centroids? valid_from_memory:valid;

////////////////////////////////////////////////////////////////////////////////
centroid_rf crf(.clk(clk),.reset(reset),.update(update_centroids),.centroids_in(centroid_from_cecau),.centroids_out(centroid_from_crf));


e2cd ecd(.clk(clk),.reset(reset),.valid_in(valid_source),.element(element_source),
    .centroid(centroid_from_crf),.distance(ecd2dc_distances),.valid_out(ecd2dc_valid),.element_out(ecd2dc_element));

dc   dc1(.clk(clk),.reset(reset),.valid_in(ecd2dc_valid),.element_in(ecd2dc_element),.distance(ecd2dc_distances),
    .label_idx(closest_index),.updated_element(dc2cecau_element),.valid_out(dc2cecau_valid));


cecau ca1(.clk(clk),.reset(reset),.training_mode(training),.recalculate_centroids(recalculate_centroids),.update_centroids(update_centroids),
          .element(dc2cecau_element),.index(closest_index),.valid(dc2cecau_valid),.adjusted_centroids(centroid_from_cecau),.centroids_in(centroid_from_crf));

pc  counter(.clk(clk),.reset(reset),.valid(dc2cecau_valid),.eol(finished),.training(training),.update(recalculate_centroids));

temp_mem mem(.reset(reset),.clk(clk),.valid_in(dc2cecau_valid), .Din(dc2cecau_element), .Dout(element_from_memory),.valid_out(valid_from_memory));
////////////////////////////////////////////////////////////////////////////////


always_comb begin
    for (int i = 0; i<`K; i++) begin
            formatted_centroids[i]  = {centroid_from_crf[i][38:24],centroid_from_crf[i][19:0]};
        end
end

endmodule



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////
//                                           //
//          Centroid Register File           // 
//                                           //
///////////////////////////////////////////////


module centroid_rf(
    input logic update, clk, reset,
    input logic [`K-1:0][38:0] centroids_in,
    output logic [`K-1:0][38:0] centroids_out
);

// trigger memory on reset or update
always_ff @(posedge clk) begin
    // on initialization, load randomly generated points (aside from label hook) for the centroid values
    if(reset)begin             
        centroids_out[0]    <= #1 39'b010110110110100000110101100000010111000;
        centroids_out[1]    <= #1 39'b111001101001000001110010011010011000111;
        centroids_out[2]    <= #1 39'b001000101101100010010100101000000100000;
        centroids_out[3]    <= #1 39'b110000101000010011111001100110001000011;
        centroids_out[4]    <= #1 39'b010010000000010100110101100101000001000;
        centroids_out[5]    <= #1 39'b001010000001100101010110001010110011110;
        centroids_out[6]    <= #1 39'b100100010100010110100100011000010111000;
        centroids_out[7]    <= #1 39'b110010101101010111010011010000110100111;
        centroids_out[8]    <= #1 39'b000110010010101000100000000010001011011;
        centroids_out[9]    <= #1 39'b111010101100001001000101101000001001001;
        centroids_out[10]   <= #1 39'b001010101001001010011111000110001001110;
        centroids_out[11]   <= #1 39'b000010000000011011001010010000110110100;
        centroids_out[12]   <= #1 39'b110000100100001100010100100000000010000;
        centroids_out[13]   <= #1 39'b010100100010011101100101010000010001010;
    end

    // if an update has been detected, move the new centroid values in
    else if(update) begin
        for (int i = 0; i<`K; i++) begin
            centroids_out[i]  <= #1 centroids_in[i];
        end
    end

    // else keep values static
    else begin
        for (int i = 0; i<`K; i++) begin
            centroids_out[i]  <= #1 centroids_out[i];
        end
    end
end

endmodule



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////
//                                           //
// Element to Centorid Distance Calculation  // 
//                                           //
///////////////////////////////////////////////

/* 
Description:
Latency: 2-cycles 
Throughput: K-distances from an element
*/

module e2cd(
    input logic clk, reset, valid_in,
    input logic [38:0] element,
    input logic [`K-1:0][38:0] centroid,
    output logic [`K-1:0][38:0] distance,
    output logic valid_out,
    output logic [38:0] element_out
);

logic [`K-1:0][38:0] next_distance; 

// to account for underflow, will need to map to a larger, signed logic

//wires
logic signed [`K-1:0][4:0] next_AGE;
logic signed [`K-1:0][3:0] next_EDU, next_ETHNC, next_RACE, next_MARSTAT, next_EMPLOY, next_DETNLF;
logic signed [`K-1:0][2:0] next_GENDER, next_SAP, next_VETERAN, next_LIVARAG;
logic        [`K-1:0]      next_SPHSERVICE,next_CMPSERVICE,next_OPISERVICE, next_RTCSERVICE, next_IJSSERVICE;

//registers
logic signed [`K-1:0][4:0] AGE;
logic signed [`K-1:0][3:0] EDU, ETHNC, RACE, MARSTAT, EMPLOY, DETNLF;
logic signed [`K-1:0][2:0] GENDER, SAP, VETERAN, LIVARAG;
logic        [`K-1:0]      SPHSERVICE,CMPSERVICE,OPISERVICE, RTCSERVICE, IJSSERVICE;

//wires @@@ Removed sign from top 3 and decremented storage by 1, check if getting wrong inputs
logic  [`K-1:0][3:0] AGE_w;
logic  [`K-1:0][2:0] EDU_w, ETHNC_w, RACE_w, MARSTAT_w, EMPLOY_w, DETNLF_w;
logic  [`K-1:0][1:0] GENDER_w, SAP_w, VETERAN_w, LIVARAG_w;
logic  [`K-1:0]      SPHSERVICE_w,CMPSERVICE_w,OPISERVICE_w, RTCSERVICE_w, IJSSERVICE_w;

Delay2 ed1(.reset(reset),.clk(clk),.valid_in(valid_in),.Din(element),.Dout(element_out),.valid_out(valid_out)); // TODO

always_comb begin

    // next_X: stores subtraction or XOR result in register
    // X: register storing feature distance (Non ABS)
    // X_w: Wire from register X that has ABS(X)

    for (int i = 0; i<`K; i++) begin

        // First Stage (Gather Differences)

        // 3bits
        next_AGE[i]      = element[3:0]      - centroid[i][3:0];
        next_EDU[i]      = element[6:4]      - centroid[i][6:4];
        next_ETHNC[i]    = element[9:7]      - centroid[i][9:7];
        next_RACE[i]     = element[12:10]    - centroid[i][12:10];
        next_MARSTAT[i]  = element[26:24]    - centroid[i][26:24];
        next_EMPLOY[i]   = element[31:29]    - centroid[i][31:29];
        next_DETNLF[i]   = element[34:32]    - centroid[i][34:32];

        // 2bits
        next_GENDER[i]   = element[14:13]    - centroid[i][14:13];
        next_SAP[i]      = element[28:27]    - centroid[i][28:27];
        next_VETERAN[i]  = element[36:35]    - centroid[i][36:35];
        next_LIVARAG[i]  = element[38:37]    - centroid[i][38:37];
        
        // 1bit - XOR to find distance
        next_SPHSERVICE[i] = element[15] ^ centroid[i][15];
        next_CMPSERVICE[i] = element[16] ^ centroid[i][16];
        next_OPISERVICE[i] = element[17] ^ centroid[i][17];
        next_RTCSERVICE[i] = element[18] ^ centroid[i][18];
        next_IJSSERVICE[i] = element[19] ^ centroid[i][19];


        //////////////////////////////////////////////////
        // ABS Logic
        //////////////////////////////////////////////////

        //TODO - go back and make this a module

        //AGE
        if(AGE[i][3]==1'b1) begin
            AGE_w[i] = -AGE[i];
        end
        else begin
            AGE_w[i] = AGE[i];
        end
        
        //EDU
        if(EDU[i][3]==1'b1) begin
            EDU_w[i] = -EDU[i];
        end
        else begin
            EDU_w[i] = EDU[i];
        end

        //ETHNC
        if(ETHNC[i][3]==1'b1) begin
            ETHNC_w[i] = -ETHNC[i];
        end
        else begin
            ETHNC_w[i] = ETHNC[i];
        end

        //RACE
        if(RACE[i][3]==1'b1) begin
            RACE_w[i] = -RACE[i];
        end
        else begin
            RACE_w[i] = RACE[i];
        end

        //MARSTAT
        if(MARSTAT[i][3]==1'b1) begin
            MARSTAT_w[i] = -MARSTAT[i];
        end
        else begin
            MARSTAT_w[i] = MARSTAT[i];
        end

        //EMPLOY
        if(EMPLOY[i][3]==1'b1) begin
            EMPLOY_w[i] = -EMPLOY[i];
        end
        else begin
            EMPLOY_w[i] = EMPLOY[i];
        end

        //DETNLF
        if(DETNLF[i][3]==1'b1) begin
            DETNLF_w[i] = -DETNLF[i];
        end
        else begin
            DETNLF_w[i] = DETNLF[i];
        end
        //////////////////////////////////////////////////
        
        //GENDER
        if(GENDER[i][2]==1'b1) begin
            GENDER_w[i] = -GENDER[i];
        end
        else begin
            GENDER_w[i] = GENDER[i];
        end

        //SAP
        if(SAP[i][2]==1'b1) begin
            SAP_w[i] = -SAP[i];
        end
        else begin
            SAP_w[i] = SAP[i];
        end

        //VETERAN
        if(VETERAN[i][2]==1'b1) begin
            VETERAN_w[i] = -VETERAN[i];
        end
        else begin
            VETERAN_w[i] = VETERAN[i];
        end

        //LIVARAG
        if(LIVARAG[i][2]==1'b1) begin
            LIVARAG_w[i] = -LIVARAG[i];
        end
        else begin
            LIVARAG_w[i] = LIVARAG[i];
        end

        //pass through
        SPHSERVICE_w[i] = SPHSERVICE[i];
        CMPSERVICE_w[i] = CMPSERVICE[i];
        OPISERVICE_w[i] = OPISERVICE[i];
        RTCSERVICE_w[i] = RTCSERVICE[i];
        IJSSERVICE_w[i] = IJSSERVICE[i];

        //////////////////////////////////////////////////

        next_distance[i] = (AGE_w[i] + EDU_w[i] + ETHNC_w[i] + RACE_w[i]
                            + MARSTAT_w[i] + EMPLOY_w[i] + DETNLF_w[i]
                            + GENDER_w[i]  + SAP_w[i] + VETERAN_w[i] + LIVARAG_w[i]
                            + SPHSERVICE_w[i] + CMPSERVICE_w[i] + OPISERVICE_w[i] + RTCSERVICE_w[i]
                            + IJSSERVICE_w[i]);
    end
end

always_ff @(posedge clk) begin
    if(reset) begin
        for (int i = 0; i<`K; i++) begin
            AGE[i]         <= #1 0;
            EDU[i]         <= #1 0;
            ETHNC[i]       <= #1 0;
            RACE[i]        <= #1 0;
            MARSTAT[i]     <= #1 0;
            EMPLOY[i]      <= #1 0;
            DETNLF[i]      <= #1 0;
            GENDER[i]      <= #1 0;
            SAP[i]         <= #1 0;
            VETERAN[i]     <= #1 0;
            LIVARAG[i]     <= #1 0;
            SPHSERVICE[i]  <= #1 0;
            CMPSERVICE[i]  <= #1 0;
            OPISERVICE[i]  <= #1 0;
            RTCSERVICE[i]  <= #1 0;
            IJSSERVICE[i]  <= #1 0;
            distance[i]    <= #1 0;
        end
    end
    else begin
        for (int i = 0; i<`K; i++) begin
            AGE[i]         <= #1 next_AGE[i];
            EDU[i]         <= #1 next_EDU[i];
            ETHNC[i]       <= #1 next_ETHNC[i];
            RACE[i]        <= #1 next_RACE[i];
            MARSTAT[i]     <= #1 next_MARSTAT[i];
            EMPLOY[i]      <= #1 next_EMPLOY[i];
            DETNLF[i]      <= #1 next_DETNLF[i];
            GENDER[i]      <= #1 next_GENDER[i];
            SAP[i]         <= #1 next_SAP[i];
            VETERAN[i]     <= #1 next_VETERAN[i];
            LIVARAG[i]     <= #1 next_LIVARAG[i];
            SPHSERVICE[i]  <= #1 next_SPHSERVICE[i];
            CMPSERVICE[i]  <= #1 next_CMPSERVICE[i];
            OPISERVICE[i]  <= #1 next_OPISERVICE[i];
            RTCSERVICE[i]  <= #1 next_RTCSERVICE[i];
            IJSSERVICE[i]  <= #1 next_IJSSERVICE[i];
            distance[i]    <= #1 next_distance[i]; //2-cycle latency
        end
    end
end

endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
//                                           //
//            Distance Comparator            // 
//                                           //
///////////////////////////////////////////////
module dc(
    input logic clk, reset, valid_in,
    input logic [38:0] element_in,
    input logic [`K-1:0][38:0] distance,
    output logic [`Klen-1:0]label_idx,
    output logic [38:0] updated_element,
    output logic valid_out
);

logic [38:0] da_01,da_23,da_45,da_67,da_89,da_1011,da_1213;
logic [`Klen-1:0] ta_01,ta_23,ta_45,ta_67,ta_89,ta_1011,ta_1213;

logic [38:0] db_03,db_47,db_811,db_1213;
logic [`Klen-1:0] tb_03,tb_47,tb_811,tb_1213;

logic [38:0] dc_07,dc_813;
logic [`Klen-1:0] tc_07,tc_813;

logic [38:0] dd_013; //burner wire - just need the label index

logic [38:0] temp_element;

// carry element through
Delay4 elementdelay(.reset(reset),.clk(clk),.Din(element_in),.valid_in(valid_in),.Dout(temp_element),.valid_out(valid_out));

// FIRST STAGE (a)

cbuff cb1a(.clk(clk),.reset(reset),.Din1(distance[0]),.Din2(distance[1]),.Tin1(4'd0),.Tin2(4'd1),.Dout(da_01),.Tout(ta_01));
cbuff cb2a(.clk(clk),.reset(reset),.Din1(distance[2]),.Din2(distance[3]),.Tin1(4'd2),.Tin2(4'd3),.Dout(da_23),.Tout(ta_23));
cbuff cb3a(.clk(clk),.reset(reset),.Din1(distance[4]),.Din2(distance[5]),.Tin1(4'd4),.Tin2(4'd5),.Dout(da_45),.Tout(ta_45));
cbuff cb4a(.clk(clk),.reset(reset),.Din1(distance[6]),.Din2(distance[7]),.Tin1(4'd6),.Tin2(4'd7),.Dout(da_67),.Tout(ta_67));
cbuff cb5a(.clk(clk),.reset(reset),.Din1(distance[8]),.Din2(distance[9]),.Tin1(4'd8),.Tin2(4'd9),.Dout(da_89),.Tout(ta_89));
cbuff cb6a(.clk(clk),.reset(reset),.Din1(distance[10]),.Din2(distance[11]),.Tin1(4'd10),.Tin2(4'd11),.Dout(da_1011),.Tout(ta_1011));
cbuff cb7a(.clk(clk),.reset(reset),.Din1(distance[12]),.Din2(distance[13]),.Tin1(4'd12),.Tin2(4'd13),.Dout(da_1213),.Tout(ta_1213));

// SECOND STAGE (b)

cbuff cb1b(.clk(clk),.reset(reset),.Din1(da_01),.Din2(da_23),.Tin1(ta_01),.Tin2(ta_23),.Dout(db_03),.Tout(tb_03));
cbuff cb2b(.clk(clk),.reset(reset),.Din1(da_45),.Din2(da_67),.Tin1(ta_45),.Tin2(ta_67),.Dout(db_47),.Tout(tb_47));
cbuff cb3b(.clk(clk),.reset(reset),.Din1(da_89),.Din2(da_1011),.Tin1(ta_89),.Tin2(ta_1011),.Dout(db_811),.Tout(tb_811));
Delay1 d1b(.clk(clk),.reset(reset),.Din(da_1213),.Tin(ta_1213),.Dout(db_1213),.Tout(tb_1213));


// THIRD STAGE (c)
cbuff cb1c(.clk(clk),.reset(reset),.Din1(db_03),.Din2(db_47),.Tin1(tb_03),.Tin2(tb_47),.Dout(dc_07),.Tout(tc_07));
cbuff cb2c(.clk(clk),.reset(reset),.Din1(db_811),.Din2(db_1213),.Tin1(tb_811),.Tin2(tb_1213),.Dout(dc_813),.Tout(tc_813));

// FOURTH STAGE (d)
cbuff cb1d(.clk(clk),.reset(reset),.Din1(dc_07),.Din2(dc_813),.Tin1(tc_07),.Tin2(tc_813),.Dout(dd_013),.Tout(label_idx));

assign updated_element = {temp_element[38:24], label_idx, temp_element[19:0]};

endmodule 

module cbuff(
    input logic clk, reset,
    input logic [38:0] Din1, Din2,
    input logic [`Klen-1:0] Tin1,Tin2,
    output logic [38:0] Dout,
    output logic [`Klen-1:0] Tout
);
logic [38:0] Dw;
logic [`Klen-1:0] Tw;

always_comb begin
    if(Din1 >= Din2) begin
        Dw = Din1;
        Tw = Tin1;
    end
    else begin
        Dw = Din2;
        Tw = Tin2;
    end
end

always_ff @(posedge clk)begin
    if(reset)begin
        Dout <= #1 0;
        Tout <= #1 0;
    end
    else begin
        Dout <= #1 Dw;
        Tout <= #1 Tw;
    end
end

endmodule

module Delay1(
input   logic reset,clk,
input   logic [38:0] Din,
input   logic [`Klen-1:0] Tin,
output  logic [38:0] Dout,
output  logic [`Klen-1:0] Tout
);

always @(posedge clk) begin
    if(reset) begin
        Dout <= #1 0;
        Tout <= #1 0;
    end
    else begin
        Dout <= #1 Din;
        Tout <= #1 Tin;
    end
end

endmodule


module Delay2(
input   logic reset,clk,valid_in,
input   logic [38:0] Din,
output  logic [38:0] Dout,
output  logic valid_out
);

logic [1:0][38:0] shift_storage;
logic [1:0] shift_storage_valid;

assign Dout = shift_storage[1];
assign valid_out = shift_storage_valid[1];

always @(posedge clk) begin
    if(reset) begin
        for (int i = 1; i>=0; i=i-1) begin 
            shift_storage[i] <= #1 0;
            shift_storage_valid[i] <= #1 0;
        end
    end
    else begin
        shift_storage[0] <= #1 Din;
        shift_storage_valid[0] <= #1 valid_in;
        for (int i = 1; i>=1; i=i-1) begin 
            shift_storage[i] <= #1 shift_storage[i-1];
            shift_storage_valid[i] <= #1 shift_storage_valid[i-1];
        end
    end
end

endmodule

module Delay4(
input   logic reset,clk,valid_in,
input   logic [38:0] Din,
output  logic [38:0] Dout,
output  logic valid_out
);

logic [3:0][38:0] shift_storage;
logic [3:0] shift_storage_valid;

assign Dout = shift_storage[3];
assign valid_out = shift_storage_valid[3];

always @(posedge clk) begin
    if(reset) begin
        for (int i = 3; i>=0; i=i-1) begin 
            shift_storage[i] <= #1 0;
            shift_storage_valid[i] <= #1 0;
        end
    end
    else begin
        shift_storage[0] <= #1 Din;
        shift_storage_valid[0] <= #1 valid_in;
        for (int i = 3; i>=1; i=i-1) begin 
            shift_storage[i] <= #1 shift_storage[i-1];
            shift_storage_valid[i] <= #1 shift_storage_valid[i-1];
        end
    end
end
endmodule


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////
//                                                      //
//   Centorid Element Counting and Adjustment Unit      // 
//                                                      //
//////////////////////////////////////////////////////////


//keeps track of the sum correctly


module cecau(
    input logic clk, reset, training_mode, valid, recalculate_centroids,
    input logic [38:0] element,
    input logic [`Klen-1:0] index,
    input logic [`K-1:0][38:0] centroids_in,
    output logic [`K-1:0][38:0] adjusted_centroids,
    output logic update_centroids
);
// if working with larger data sets, need to increase register size to prevent overflow
logic [`K-1:0][`n-1:0] element_count,next_element_count; //number of elements in a given centroid
logic temp_update_centroids;
logic [`K-1:0][3:0] charlie;

logic [`K-1:0][22:0] AGE;
logic [`K-1:0][21:0] EDU, ETHNC, RACE, MARSTAT, EMPLOY, DETNLF;
logic [`K-1:0][21:0] GENDER, SAP, VETERAN, LIVARAG;
logic [`K-1:0][21:0] SPHSERVICE,CMPSERVICE,OPISERVICE, RTCSERVICE, IJSSERVICE;

logic [`K-1:0][22:0] next_AGE;
logic [`K-1:0][21:0] next_EDU, next_ETHNC, next_RACE, next_MARSTAT, next_EMPLOY, next_DETNLF;
logic [`K-1:0][21:0] next_GENDER, next_SAP, next_VETERAN, next_LIVARAG;
logic [`K-1:0][21:0] next_SPHSERVICE,next_CMPSERVICE,next_OPISERVICE, next_RTCSERVICE, next_IJSSERVICE;


logic  [`K-1:0][3:0] new_AGE;
logic  [`K-1:0][2:0] new_EDU, new_ETHNC, new_RACE, new_MARSTAT, new_EMPLOY, new_DETNLF;
logic  [`K-1:0][1:0] new_GENDER, new_SAP, new_VETERAN, new_LIVARAG;
logic  [`K-1:0][1:0] new_SPHSERVICE,new_CMPSERVICE,new_OPISERVICE, new_RTCSERVICE, new_IJSSERVICE;

logic  [`K-1:0][3:0] next_new_AGE;
logic  [`K-1:0][2:0] next_new_EDU, next_new_ETHNC, next_new_RACE, next_new_MARSTAT, next_new_EMPLOY, next_new_DETNLF;
logic  [`K-1:0][1:0] next_new_GENDER, next_new_SAP, next_new_VETERAN, next_new_LIVARAG;
logic  [`K-1:0][1:0] next_new_SPHSERVICE,next_new_CMPSERVICE,next_new_OPISERVICE, next_new_RTCSERVICE, next_new_IJSSERVICE;

logic  [`K-1:0]      SPHSERVICE_w,CMPSERVICE_w,OPISERVICE_w, RTCSERVICE_w, IJSSERVICE_w;

assign charlie[0] = 4'd0;
assign charlie[1] = 4'd1;
assign charlie[2] = 4'd2;
assign charlie[3] = 4'd3;
assign charlie[4] = 4'd4;
assign charlie[5] = 4'd5;
assign charlie[6] = 4'd6;
assign charlie[7] = 4'd7;
assign charlie[8] = 4'd8;
assign charlie[9] = 4'd9;
assign charlie[10] = 4'd10;
assign charlie[11] = 4'd11;
assign charlie[12] = 4'd12;
assign charlie[13] = 4'd13;



always_comb begin
    for (int i = 0; i<`K; i++) begin
            next_element_count[i]  = element_count[i];
            next_AGE[i]         = AGE[i];  
            next_EDU[i]         = EDU[i];
            next_ETHNC[i]       = ETHNC[i];
            next_RACE[i]        = RACE[i];
            next_MARSTAT[i]     = MARSTAT[i];
            next_EMPLOY[i]      = EMPLOY[i];
            next_DETNLF[i]      = DETNLF[i];
            next_GENDER[i]      = GENDER[i];
            next_SAP[i]         = SAP[i];
            next_VETERAN[i]     = VETERAN[i];
            next_LIVARAG[i]     = LIVARAG[i];
            next_SPHSERVICE[i]  = SPHSERVICE[i];
            next_CMPSERVICE[i]  = CMPSERVICE[i];
            next_OPISERVICE[i]  = OPISERVICE[i];
            next_RTCSERVICE[i]  = RTCSERVICE[i];
            next_IJSSERVICE[i]  = IJSSERVICE[i];
    end
    if(valid)begin
        casez(index)
        4'd0:
            begin
                next_element_count[0] = element_count[0]+ 1;
                next_AGE[0]           = AGE[0]          + element[3:0];  
                next_EDU[0]           = EDU[0]          + element[6:4];
                next_ETHNC[0]         = ETHNC[0]        + element[9:7];
                next_RACE[0]          = RACE[0]         + element[12:10];
                next_MARSTAT[0]       = MARSTAT[0]      + element[26:24];
                next_EMPLOY[0]        = EMPLOY[0]       + element[31:29];
                next_DETNLF[0]        = DETNLF[0]       + element[34:32];
                next_GENDER[0]        = GENDER[0]       + element[14:13];
                next_SAP[0]           = SAP[0]          + element[28:27];
                next_VETERAN[0]       = VETERAN[0]      + element[36:35];
                next_LIVARAG[0]       = LIVARAG[0]      + element[38:37];
                next_SPHSERVICE[0]    = SPHSERVICE[0]   + element[15];
                next_CMPSERVICE[0]    = CMPSERVICE[0]   + element[16];
                next_OPISERVICE[0]    = OPISERVICE[0]   + element[17];
                next_RTCSERVICE[0]    = RTCSERVICE[0]   + element[18];
                next_IJSSERVICE[0]    = IJSSERVICE[0]   + element[19];
            end
        
        4'd1:
            begin
                next_element_count[1] = element_count[1]+ 1;
                next_AGE[1]           = AGE[1]          + element[3:0];  
                next_EDU[1]           = EDU[1]          + element[6:4];
                next_ETHNC[1]         = ETHNC[1]        + element[9:7];
                next_RACE[1]          = RACE[1]         + element[12:10];
                next_MARSTAT[1]       = MARSTAT[1]      + element[26:24];
                next_EMPLOY[1]        = EMPLOY[1]       + element[31:29];
                next_DETNLF[1]        = DETNLF[1]       + element[34:32];
                next_GENDER[1]        = GENDER[1]       + element[14:13];
                next_SAP[1]           = SAP[1]          + element[28:27];
                next_VETERAN[1]       = VETERAN[1]      + element[36:35];
                next_LIVARAG[1]       = LIVARAG[1]      + element[38:37];
                next_SPHSERVICE[1]    = SPHSERVICE[1]   + element[15];
                next_CMPSERVICE[1]    = CMPSERVICE[1]   + element[16];
                next_OPISERVICE[1]    = OPISERVICE[1]   + element[17];
                next_RTCSERVICE[1]    = RTCSERVICE[1]   + element[18];
                next_IJSSERVICE[1]    = IJSSERVICE[1]   + element[19];
            end

        4'd2:
            begin
                next_element_count[2] = element_count[2]+ 1;
                next_AGE[2]           = AGE[2]          + element[3:0];  
                next_EDU[2]           = EDU[2]          + element[6:4];
                next_ETHNC[2]         = ETHNC[2]        + element[9:7];
                next_RACE[2]          = RACE[2]         + element[12:10];
                next_MARSTAT[2]       = MARSTAT[2]      + element[26:24];
                next_EMPLOY[2]        = EMPLOY[2]       + element[31:29];
                next_DETNLF[2]        = DETNLF[2]       + element[34:32];
                next_GENDER[2]        = GENDER[2]       + element[14:13];
                next_SAP[2]           = SAP[2]          + element[28:27];
                next_VETERAN[2]       = VETERAN[2]      + element[36:35];
                next_LIVARAG[2]       = LIVARAG[2]      + element[38:37];
                next_SPHSERVICE[2]    = SPHSERVICE[2]   + element[15];
                next_CMPSERVICE[2]    = CMPSERVICE[2]   + element[16];
                next_OPISERVICE[2]    = OPISERVICE[2]   + element[17];
                next_RTCSERVICE[2]    = RTCSERVICE[2]   + element[18];
                next_IJSSERVICE[2]    = IJSSERVICE[2]   + element[19];
            end
        4'd3:
            begin
                next_element_count[3] = element_count[3]+ 1;
                next_AGE[3]           = AGE[3]          + element[3:0];  
                next_EDU[3]           = EDU[3]          + element[6:4];
                next_ETHNC[3]         = ETHNC[3]        + element[9:7];
                next_RACE[3]          = RACE[3]         + element[12:10];
                next_MARSTAT[3]       = MARSTAT[3]      + element[26:24];
                next_EMPLOY[3]        = EMPLOY[3]       + element[31:29];
                next_DETNLF[3]        = DETNLF[3]       + element[34:32];
                next_GENDER[3]        = GENDER[3]       + element[14:13];
                next_SAP[3]           = SAP[3]          + element[28:27];
                next_VETERAN[3]       = VETERAN[3]      + element[36:35];
                next_LIVARAG[3]       = LIVARAG[3]      + element[38:37];
                next_SPHSERVICE[3]    = SPHSERVICE[3]   + element[15];
                next_CMPSERVICE[3]    = CMPSERVICE[3]   + element[16];
                next_OPISERVICE[3]    = OPISERVICE[3]   + element[17];
                next_RTCSERVICE[3]    = RTCSERVICE[3]   + element[18];
                next_IJSSERVICE[3]    = IJSSERVICE[3]   + element[19];
            end
        4'd4:
            begin
                next_element_count[4] = element_count[4]+ 1;
                next_AGE[4]           = AGE[4]          + element[3:0];  
                next_EDU[4]           = EDU[4]          + element[6:4];
                next_ETHNC[4]         = ETHNC[4]        + element[9:7];
                next_RACE[4]          = RACE[4]         + element[12:10];
                next_MARSTAT[4]       = MARSTAT[4]      + element[26:24];
                next_EMPLOY[4]        = EMPLOY[4]       + element[31:29];
                next_DETNLF[4]        = DETNLF[4]       + element[34:32];
                next_GENDER[4]        = GENDER[4]       + element[14:13];
                next_SAP[4]           = SAP[4]          + element[28:27];
                next_VETERAN[4]       = VETERAN[4]      + element[36:35];
                next_LIVARAG[4]       = LIVARAG[4]      + element[38:37];
                next_SPHSERVICE[4]    = SPHSERVICE[4]   + element[15];
                next_CMPSERVICE[4]    = CMPSERVICE[4]   + element[16];
                next_OPISERVICE[4]    = OPISERVICE[4]   + element[17];
                next_RTCSERVICE[4]    = RTCSERVICE[4]   + element[18];
                next_IJSSERVICE[4]    = IJSSERVICE[4]   + element[19];
            end
        4'd5:
            begin
                next_element_count[5] = element_count[5]+ 1;
                next_AGE[5]           = AGE[5]          + element[3:0];  
                next_EDU[5]           = EDU[5]          + element[6:4];
                next_ETHNC[5]         = ETHNC[5]        + element[9:7];
                next_RACE[5]          = RACE[5]         + element[12:10];
                next_MARSTAT[5]       = MARSTAT[5]      + element[26:24];
                next_EMPLOY[5]        = EMPLOY[5]       + element[31:29];
                next_DETNLF[5]        = DETNLF[5]       + element[34:32];
                next_GENDER[5]        = GENDER[5]       + element[14:13];
                next_SAP[5]           = SAP[5]          + element[28:27];
                next_VETERAN[5]       = VETERAN[5]      + element[36:35];
                next_LIVARAG[5]       = LIVARAG[5]      + element[38:37];
                next_SPHSERVICE[5]    = SPHSERVICE[5]   + element[15];
                next_CMPSERVICE[5]    = CMPSERVICE[5]   + element[16];
                next_OPISERVICE[5]    = OPISERVICE[5]   + element[17];
                next_RTCSERVICE[5]    = RTCSERVICE[5]   + element[18];
                next_IJSSERVICE[5]    = IJSSERVICE[5]   + element[19];
            end
        4'd6:
            begin
                next_element_count[6] = element_count[6]+ 1;
                next_AGE[6]           = AGE[6]          + element[3:0];  
                next_EDU[6]           = EDU[6]          + element[6:4];
                next_ETHNC[6]         = ETHNC[6]        + element[9:7];
                next_RACE[6]          = RACE[6]         + element[12:10];
                next_MARSTAT[6]       = MARSTAT[6]      + element[26:24];
                next_EMPLOY[6]        = EMPLOY[6]       + element[31:29];
                next_DETNLF[6]        = DETNLF[6]       + element[34:32];
                next_GENDER[6]        = GENDER[6]       + element[14:13];
                next_SAP[6]           = SAP[6]          + element[28:27];
                next_VETERAN[6]       = VETERAN[6]      + element[36:35];
                next_LIVARAG[6]       = LIVARAG[6]      + element[38:37];
                next_SPHSERVICE[6]    = SPHSERVICE[6]   + element[15];
                next_CMPSERVICE[6]    = CMPSERVICE[6]   + element[16];
                next_OPISERVICE[6]    = OPISERVICE[6]   + element[17];
                next_RTCSERVICE[6]    = RTCSERVICE[6]   + element[18];
                next_IJSSERVICE[6]    = IJSSERVICE[6]   + element[19];
            end
        4'd7:
            begin
                next_element_count[7] = element_count[7]+ 1;
                next_AGE[7]           = AGE[7]          + element[3:0];  
                next_EDU[7]           = EDU[7]          + element[6:4];
                next_ETHNC[7]         = ETHNC[7]        + element[9:7];
                next_RACE[7]          = RACE[7]         + element[12:10];
                next_MARSTAT[7]       = MARSTAT[7]      + element[26:24];
                next_EMPLOY[7]        = EMPLOY[7]       + element[31:29];
                next_DETNLF[7]        = DETNLF[7]       + element[34:32];
                next_GENDER[7]        = GENDER[7]       + element[14:13];
                next_SAP[7]           = SAP[7]          + element[28:27];
                next_VETERAN[7]       = VETERAN[7]      + element[36:35];
                next_LIVARAG[7]       = LIVARAG[7]      + element[38:37];
                next_SPHSERVICE[7]    = SPHSERVICE[7]   + element[15];
                next_CMPSERVICE[7]    = CMPSERVICE[7]   + element[16];
                next_OPISERVICE[7]    = OPISERVICE[7]   + element[17];
                next_RTCSERVICE[7]    = RTCSERVICE[7]   + element[18];
                next_IJSSERVICE[7]    = IJSSERVICE[7]   + element[19];
            end
        4'd8:
            begin
                next_element_count[8] = element_count[8]+ 1;
                next_AGE[8]           = AGE[8]          + element[3:0];  
                next_EDU[8]           = EDU[8]          + element[6:4];
                next_ETHNC[8]         = ETHNC[8]        + element[9:7];
                next_RACE[8]          = RACE[8]         + element[12:10];
                next_MARSTAT[8]       = MARSTAT[8]      + element[26:24];
                next_EMPLOY[8]        = EMPLOY[8]       + element[31:29];
                next_DETNLF[8]        = DETNLF[8]       + element[34:32];
                next_GENDER[8]        = GENDER[8]       + element[14:13];
                next_SAP[8]           = SAP[8]          + element[28:27];
                next_VETERAN[8]       = VETERAN[8]      + element[36:35];
                next_LIVARAG[8]       = LIVARAG[8]      + element[38:37];
                next_SPHSERVICE[8]    = SPHSERVICE[8]   + element[15];
                next_CMPSERVICE[8]    = CMPSERVICE[8]   + element[16];
                next_OPISERVICE[8]    = OPISERVICE[8]   + element[17];
                next_RTCSERVICE[8]    = RTCSERVICE[8]   + element[18];
                next_IJSSERVICE[8]    = IJSSERVICE[8]   + element[19];
            end
        4'd9:
            begin
                next_element_count[9] = element_count[9]+ 1;
                next_AGE[9]           = AGE[9]          + element[3:0];  
                next_EDU[9]           = EDU[9]          + element[6:4];
                next_ETHNC[9]         = ETHNC[9]        + element[9:7];
                next_RACE[9]          = RACE[9]         + element[12:10];
                next_MARSTAT[9]       = MARSTAT[9]      + element[26:24];
                next_EMPLOY[9]        = EMPLOY[9]       + element[31:29];
                next_DETNLF[9]        = DETNLF[9]       + element[34:32];
                next_GENDER[9]        = GENDER[9]       + element[14:13];
                next_SAP[9]           = SAP[9]          + element[28:27];
                next_VETERAN[9]       = VETERAN[9]      + element[36:35];
                next_LIVARAG[9]       = LIVARAG[9]      + element[38:37];
                next_SPHSERVICE[9]    = SPHSERVICE[9]   + element[15];
                next_CMPSERVICE[9]    = CMPSERVICE[9]   + element[16];
                next_OPISERVICE[9]    = OPISERVICE[9]   + element[17];
                next_RTCSERVICE[9]    = RTCSERVICE[9]   + element[18];
                next_IJSSERVICE[9]    = IJSSERVICE[9]   + element[19];
            end
        4'd10:
            begin
                next_element_count[10] = element_count[10]+ 1;
                next_AGE[10]           = AGE[10]          + element[3:0];  
                next_EDU[10]           = EDU[10]          + element[6:4];
                next_ETHNC[10]         = ETHNC[10]        + element[9:7];
                next_RACE[10]          = RACE[10]         + element[12:10];
                next_MARSTAT[10]       = MARSTAT[10]      + element[26:24];
                next_EMPLOY[10]        = EMPLOY[10]       + element[31:29];
                next_DETNLF[10]        = DETNLF[10]       + element[34:32];
                next_GENDER[10]        = GENDER[10]       + element[14:13];
                next_SAP[10]           = SAP[10]          + element[28:27];
                next_VETERAN[10]       = VETERAN[10]      + element[36:35];
                next_LIVARAG[10]       = LIVARAG[10]      + element[38:37];
                next_SPHSERVICE[10]    = SPHSERVICE[10]   + element[15];
                next_CMPSERVICE[10]    = CMPSERVICE[10]   + element[16];
                next_OPISERVICE[10]    = OPISERVICE[10]   + element[17];
                next_RTCSERVICE[10]    = RTCSERVICE[10]   + element[18];
                next_IJSSERVICE[10]    = IJSSERVICE[10]   + element[19];
            end
        4'd11:
            begin
                next_element_count[11] = element_count[11]+ 1;
                next_AGE[11]           = AGE[11]          + element[3:0];  
                next_EDU[11]           = EDU[11]          + element[6:4];
                next_ETHNC[11]         = ETHNC[11]        + element[9:7];
                next_RACE[11]          = RACE[11]         + element[12:10];
                next_MARSTAT[11]       = MARSTAT[11]      + element[26:24];
                next_EMPLOY[11]        = EMPLOY[11]       + element[31:29];
                next_DETNLF[11]        = DETNLF[11]       + element[34:32];
                next_GENDER[11]        = GENDER[11]       + element[14:13];
                next_SAP[11]           = SAP[11]          + element[28:27];
                next_VETERAN[11]       = VETERAN[11]      + element[36:35];
                next_LIVARAG[11]       = LIVARAG[11]      + element[38:37];
                next_SPHSERVICE[11]    = SPHSERVICE[11]   + element[15];
                next_CMPSERVICE[11]    = CMPSERVICE[11]   + element[16];
                next_OPISERVICE[11]    = OPISERVICE[11]   + element[17];
                next_RTCSERVICE[11]    = RTCSERVICE[11]   + element[18];
                next_IJSSERVICE[11]    = IJSSERVICE[11]   + element[19];
            end
        4'd12:
            begin
                next_element_count[12] = element_count[12]+ 1;
                next_AGE[12]           = AGE[12]          + element[3:0];  
                next_EDU[12]           = EDU[12]          + element[6:4];
                next_ETHNC[12]         = ETHNC[12]        + element[9:7];
                next_RACE[12]          = RACE[12]         + element[12:10];
                next_MARSTAT[12]       = MARSTAT[12]      + element[26:24];
                next_EMPLOY[12]        = EMPLOY[12]       + element[31:29];
                next_DETNLF[12]        = DETNLF[12]       + element[34:32];
                next_GENDER[12]        = GENDER[12]       + element[14:13];
                next_SAP[12]           = SAP[12]          + element[28:27];
                next_VETERAN[12]       = VETERAN[12]      + element[36:35];
                next_LIVARAG[12]       = LIVARAG[12]      + element[38:37];
                next_SPHSERVICE[12]    = SPHSERVICE[12]   + element[15];
                next_CMPSERVICE[12]    = CMPSERVICE[12]   + element[16];
                next_OPISERVICE[12]    = OPISERVICE[12]   + element[17];
                next_RTCSERVICE[12]    = RTCSERVICE[12]   + element[18];
                next_IJSSERVICE[12]    = IJSSERVICE[12]   + element[19];
            end
        4'd13:
            begin
                next_element_count[13] = element_count[13]+ 1;
                next_AGE[13]           = AGE[13]          + element[3:0];  
                next_EDU[13]           = EDU[13]          + element[6:4];
                next_ETHNC[13]         = ETHNC[13]        + element[9:7];
                next_RACE[13]          = RACE[13]         + element[12:10];
                next_MARSTAT[13]       = MARSTAT[13]      + element[26:24];
                next_EMPLOY[13]        = EMPLOY[13]       + element[31:29];
                next_DETNLF[13]        = DETNLF[13]       + element[34:32];
                next_GENDER[13]        = GENDER[13]       + element[14:13];
                next_SAP[13]           = SAP[13]          + element[28:27];
                next_VETERAN[13]       = VETERAN[13]      + element[36:35];
                next_LIVARAG[13]       = LIVARAG[13]      + element[38:37];
                next_SPHSERVICE[13]    = SPHSERVICE[13]   + element[15];
                next_CMPSERVICE[13]    = CMPSERVICE[13]   + element[16];
                next_OPISERVICE[13]    = OPISERVICE[13]   + element[17];
                next_RTCSERVICE[13]    = RTCSERVICE[13]   + element[18];
                next_IJSSERVICE[13]    = IJSSERVICE[13]   + element[19];
            end

        endcase
    end
end



always_ff @(posedge clk) begin
    if(reset) begin
        for (int i = 0; i<`K; i++) begin
            element_count[i]        <= #1 0;
            AGE[i]                  <= #1 0;
            EDU[i]                  <= #1 0;
            ETHNC[i]                <= #1 0;
            RACE[i]                 <= #1 0;
            MARSTAT[i]              <= #1 0;
            EMPLOY[i]               <= #1 0;
            DETNLF[i]               <= #1 0;
            GENDER[i]               <= #1 0;
            SAP[i]                  <= #1 0;
            VETERAN[i]              <= #1 0;
            LIVARAG[i]              <= #1 0;
            SPHSERVICE[i]           <= #1 0;
            CMPSERVICE[i]           <= #1 0;
            OPISERVICE[i]           <= #1 0;
            RTCSERVICE[i]           <= #1 0;
            IJSSERVICE[i]           <= #1 0;
        end
    end
    else begin
        for (int i = 0; i<`K; i++) begin
            element_count[i]<= #1 next_element_count[i];
            AGE[i]          <= #1 next_AGE[i];
            EDU[i]          <= #1 next_EDU[i];
            ETHNC[i]        <= #1 next_ETHNC[i];
            RACE[i]         <= #1 next_RACE[i];
            MARSTAT[i]      <= #1 next_MARSTAT[i];
            EMPLOY[i]       <= #1 next_EMPLOY[i];
            DETNLF[i]       <= #1 next_DETNLF[i];
            GENDER[i]       <= #1 next_GENDER[i];
            SAP[i]          <= #1 next_SAP[i];
            VETERAN[i]      <= #1 next_VETERAN[i];
            LIVARAG[i]      <= #1 next_LIVARAG[i];
            SPHSERVICE[i]   <= #1 next_SPHSERVICE[i];
            CMPSERVICE[i]   <= #1 next_CMPSERVICE[i];
            OPISERVICE[i]   <= #1 next_OPISERVICE[i];
            RTCSERVICE[i]   <= #1 next_RTCSERVICE[i];
            IJSSERVICE[i]   <= #1 next_IJSSERVICE[i];
        end
    end
end

always_comb begin
    temp_update_centroids = 0;//@@@ update_centroids;
    for(int i = 0; i<`K; i++)begin
        next_new_AGE[i]         = new_AGE[i];  
        next_new_EDU[i]         = new_EDU[i];
        next_new_ETHNC[i]       = new_ETHNC[i];
        next_new_RACE[i]        = new_RACE[i];
        next_new_MARSTAT[i]     = new_MARSTAT[i];
        next_new_EMPLOY[i]      = new_EMPLOY[i];
        next_new_DETNLF[i]      = new_DETNLF[i];
        next_new_GENDER[i]      = new_GENDER[i];
        next_new_SAP[i]         = new_SAP[i];
        next_new_VETERAN[i]     = new_VETERAN[i];
        next_new_LIVARAG[i]     = new_LIVARAG[i];
        next_new_SPHSERVICE[i]  = new_SPHSERVICE[i];
        next_new_CMPSERVICE[i]  = new_CMPSERVICE[i];
        next_new_OPISERVICE[i]  = new_OPISERVICE[i];
        next_new_RTCSERVICE[i]  = new_RTCSERVICE[i];
        next_new_IJSSERVICE[i]  = new_IJSSERVICE[i];
    end

    if(recalculate_centroids) begin
        temp_update_centroids = 1;
        for(int i = 0; i<`K; i++)begin
            next_new_AGE[i]         =  element_count[i] ? AGE[i]/element_count[i]:centroids_in[i];
            next_new_EDU[i]         =  element_count[i] ? EDU[i]/element_count[i]:centroids_in[i];
            next_new_ETHNC[i]       =  element_count[i] ? ETHNC[i]/element_count[i]:centroids_in[i];
            next_new_RACE[i]        =  element_count[i] ? RACE[i]/element_count[i]:centroids_in[i];
            next_new_MARSTAT[i]     =  element_count[i] ? MARSTAT[i]/element_count[i]:centroids_in[i];
            next_new_EMPLOY[i]      =  element_count[i] ? EMPLOY[i]/element_count[i]:centroids_in[i];
            next_new_DETNLF[i]      =  element_count[i] ? DETNLF[i]/element_count[i]:centroids_in[i];
            next_new_GENDER[i]      =  element_count[i] ? GENDER[i]/element_count[i]:centroids_in[i];
            next_new_SAP[i]         =  element_count[i] ? SAP[i]/element_count[i]:centroids_in[i];
            next_new_VETERAN[i]     =  element_count[i] ? VETERAN[i]/element_count[i]:centroids_in[i];
            next_new_LIVARAG[i]     =  element_count[i] ? LIVARAG[i]/element_count[i]:centroids_in[i];
            next_new_SPHSERVICE[i]  =  element_count[i] ? (SPHSERVICE[i]<<1)/element_count[i]:centroids_in[i];
            next_new_CMPSERVICE[i]  =  element_count[i] ? (CMPSERVICE[i]<<1)/element_count[i]:centroids_in[i];
            next_new_OPISERVICE[i]  =  element_count[i] ? (OPISERVICE[i]<<1)/element_count[i]:centroids_in[i];
            next_new_RTCSERVICE[i]  =  element_count[i] ? (SPHSERVICE[i]<<1)/element_count[i]:centroids_in[i];
            next_new_IJSSERVICE[i]  =  element_count[i] ? (SPHSERVICE[i]<<1)/element_count[i]:centroids_in[i];
        end
    end
    for(int i = 0; i<`K; i++)begin

        SPHSERVICE_w[i] = new_SPHSERVICE[i][1];
        CMPSERVICE_w[i] = new_CMPSERVICE[i][1];  
        OPISERVICE_w[i] = new_OPISERVICE[i][1];
        RTCSERVICE_w[i] = new_RTCSERVICE[i][1];  
        IJSSERVICE_w[i] = new_IJSSERVICE[i][1];

        
        adjusted_centroids[i] = {new_LIVARAG[i],new_VETERAN[i],new_DETNLF[i],
                                 new_EMPLOY[i],new_SAP[i],new_MARSTAT[i],charlie[i],
                                 new_IJSSERVICE[i],new_RTCSERVICE[i],new_OPISERVICE[i],
                                 new_CMPSERVICE[i],new_SPHSERVICE[i],new_GENDER[i],
                                 new_RACE[i],new_ETHNC[i],new_EDU[i],new_AGE[i]};   
            
    end
end

always_ff @(posedge clk) begin
    if(reset) begin
        update_centroids <= #1 0;
        for(int i = 0; i<`K; i++) begin
            new_AGE[i]         <= #1 0;
            new_EDU[i]         <= #1 0;
            new_ETHNC[i]       <= #1 0;
            new_RACE[i]        <= #1 0;
            new_MARSTAT[i]     <= #1 0;
            new_EMPLOY[i]      <= #1 0;
            new_DETNLF[i]      <= #1 0;
            new_GENDER[i]      <= #1 0;
            new_SAP[i]         <= #1 0;
            new_VETERAN[i]     <= #1 0;
            new_LIVARAG[i]     <= #1 0;
            new_SPHSERVICE[i]  <= #1 0;
            new_CMPSERVICE[i]  <= #1 0;
            new_OPISERVICE[i]  <= #1 0;
            new_RTCSERVICE[i]  <= #1 0;
            new_IJSSERVICE[i]  <= #1 0;
        end
    end
    else begin
        update_centroids <= #1 temp_update_centroids;
        for(int i = 0; i<`K; i++) begin
            new_AGE[i]         = next_new_AGE[i];  
            new_EDU[i]         = next_new_EDU[i];
            new_ETHNC[i]       = next_new_ETHNC[i];
            new_RACE[i]        = next_new_RACE[i];
            new_MARSTAT[i]     = next_new_MARSTAT[i];
            new_EMPLOY[i]      = next_new_EMPLOY[i];
            new_DETNLF[i]      = next_new_DETNLF[i];
            new_GENDER[i]      = next_new_GENDER[i];
            new_SAP[i]         = next_new_SAP[i];
            new_VETERAN[i]     = next_new_VETERAN[i];
            new_LIVARAG[i]     = next_new_LIVARAG[i];
            new_SPHSERVICE[i]  = next_new_SPHSERVICE[i];
            new_CMPSERVICE[i]  = next_new_CMPSERVICE[i];
            new_OPISERVICE[i]  = next_new_OPISERVICE[i];
            new_RTCSERVICE[i]  = next_new_RTCSERVICE[i];
            new_IJSSERVICE[i]  = next_new_IJSSERVICE[i];
        end
    end
end

endmodule


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


module pc(
    input logic clk,reset,valid,training,
    output logic update, eol
);
logic [8:0] count, temp_count;
logic [6:0] elements_processed, temp_ep; //19
logic temp_update, temp_eol;

always_comb begin;
    temp_ep = elements_processed;
    temp_update = 0; //@@@
    temp_count = count;
    temp_eol = eol;

    if(valid) begin
        temp_ep = elements_processed + 1;
    end

    if(temp_ep == 20'd127) begin
        if(training) begin
            temp_update = 1;
            temp_count = count + 1;
        end
    end
    
    if(temp_count == 9'd300)begin
        temp_eol = 1;
    end

end

always_ff @(posedge clk) begin
    if(reset)begin
        elements_processed <= #1 0;
        update             <= #1 0;
        count              <= #1 0;
        eol                <= #1 0;
    end
    else begin
        elements_processed <= #1 temp_ep;
        update             <= #1 temp_update;
        count              <= #1 temp_count;
        eol                <= #1 temp_eol;
    end
end

endmodule

// represents external memory

module temp_mem(
input   logic reset,clk,valid_in,
input   logic [38:0] Din,
output  logic [38:0] Dout,
output  logic valid_out
);
//524287
logic [127:0][38:0] shift_storage;
logic [127:0] shift_storage_valid;

assign Dout = shift_storage[127];
assign valid_out = shift_storage_valid[127];

always @(posedge clk) begin
    if(reset) begin
        for (int i = 127; i>=0; i=i-1) begin 
            shift_storage[i] <= #1 0;
            shift_storage_valid[i] <= #1 0;
        end
    end
    else begin
        shift_storage[0] <= #1 Din;
        shift_storage_valid[0] <= #1 valid_in;
        for (int i = 127; i>=1; i=i-1) begin 
            shift_storage[i] <= #1 shift_storage[i-1];
            shift_storage_valid[i] <= #1 shift_storage_valid[i-1];
        end
    end
end
endmodule