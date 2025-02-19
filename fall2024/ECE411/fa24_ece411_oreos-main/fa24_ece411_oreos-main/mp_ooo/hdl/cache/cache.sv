module cache 
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    stage_reg_t                 stage_reg; 
    stage_reg_t                 stage_next_reg;

    logic          [31:0]       input_addr;
    logic          [31:0]       dfp_addr_temp;
    logic          [3:0]        r_mask;
    logic          [3:0]        w_mask;
    logic          [31:0]       w_data;
    
    //logic                       csbo_data;
    logic                       web0_data[4];
    logic          [31:0]       wmask0_data[4];
    //logic          [3:0]        addr0_data;
    logic          [255:0]      din0_data[4];
    logic          [255:0]      dout0_data[4];

        
    //logic                       csbo_tag;
    logic                       web0_tag[4];
    //logic          [3:0]        addr0_tag;
    logic          [23:0]       din0_tag[4];
    logic          [23:0]       dout0_tag[4];

        
    //logic                       csbo_valid;
    logic                       web0_valid[4];
    //logic          [3:0]        addr0_valid;
    logic                       din0_valid[4];
    logic                       dout0_valid[4];

    logic                       csb0_lru;
    logic                       web0_lru;
    logic          [3:0]        addr0_lru;
    logic          [2:0]        din0_lru;
    logic          [2:0]        dout0_lru;

    logic                       csb1_lru;
    logic                       web1_lru;
    logic          [3:0]        addr1_lru;
    logic          [2:0]        din1_lru;
    logic          [2:0]        dout1_lru;

    logic                       csb0;
    logic          [3:0]        addr0;

    logic          [2:0]        choose_lru;      
    logic          [1:0]        choose_way;
    logic          [1:0]        hit_way;
    logic                       hit_flag; 

    logic          [7:0]        rdata_bits;
    logic          [31:0]       rdata_temp;

    logic          [4:0]        rdata_bits_hit;
    logic          [31:0]       rdata_temp_hit;

    logic          [3:0]        test;
    logic          [31:0]       test2;

    logic          [4:0]        wdata_bits_hit;
    logic          [255:0]       wdata_temp_hit;

    logic          [31:0]       wdata_previous;
    logic          [31:0]       ufp_wdata_temp;

    logic          [1:0]        way_var;     

    logic                       dirty_flag;
    logic                       cache_flag;
    logic                       writing;

    assign test = ufp_wmask;
    assign test2 = ufp_wdata;



    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (csb0),
            .web0       (web0_data[i]),
            .wmask0     (wmask0_data[i]),
            .addr0      (addr0),
            .din0       (din0_data[i]),
            .dout0      (dout0_data[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (csb0),
            .web0       (web0_tag[i]),
            .addr0      (addr0),
            .din0       (din0_tag[i]),
            .dout0      (dout0_tag[i])
        );

        valid_array valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (csb0),
            .web0       (web0_valid[i]),
            .addr0      (addr0),
            .din0       (din0_valid[i]),
            .dout0      (dout0_valid[i])
        );
    end endgenerate

    lru_array lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (csb0_lru),
        .web0       (web0_lru),
        .addr0      (addr0_lru),
        .din0       (din0_lru),
        .dout0      (dout0_lru),
        .csb1       (csb1_lru),
        .web1       (web1_lru),
        .addr1      (addr1_lru),
        .din1       (din1_lru),
        .dout1      (dout1_lru)
    );

    always_comb begin
        if ((dfp_read || dfp_write) || (stage_reg.write_flag) || (stage_reg.write_flag_ufp < 1 && stage_reg.ufp_wmask > 0))begin
            input_addr = stage_reg.addr;
            r_mask = stage_reg.ufp_rmask;
            w_mask = stage_reg.ufp_wmask;
            w_data = stage_reg.ufp_wdata;
        end else if (stage_reg.write_flag_ufp) begin
            input_addr = stage_reg.next_addr;
            r_mask = stage_reg.next_ufp_rmask;
            w_mask = stage_reg.next_ufp_wmask;
            w_data = stage_reg.next_ufp_wdata;
        end else begin
            input_addr = ufp_addr;
            r_mask = ufp_rmask;
            w_mask = ufp_wmask;
            w_data = ufp_wdata;
        end
    end

    always_comb begin
        way_var ='0;
        stage_next_reg.addr = input_addr;
        stage_next_reg.tag = input_addr[31:9];
        stage_next_reg.index = input_addr[8:5];
        stage_next_reg.offset = input_addr[4:0];
        stage_next_reg.ufp_rmask = r_mask;
        stage_next_reg.ufp_wmask = w_mask;
        stage_next_reg.ufp_wdata = w_data;
        
        stage_next_reg.next_addr = ufp_addr;
        stage_next_reg.next_tag = ufp_addr[31:9];
        stage_next_reg.next_index = ufp_addr[8:5];
        stage_next_reg.next_offset = ufp_addr[4:0];
        stage_next_reg.next_ufp_rmask = ufp_rmask;
        stage_next_reg.next_ufp_wmask = ufp_wmask;
        stage_next_reg.next_ufp_wdata = ufp_wdata;
        
        web0_data[0] = 1'b1;
        wmask0_data[0] = '0;
        din0_data[0] = '0;
        web0_tag[0] = 1'b1;
        din0_tag[0] = '0;
        web0_valid[0] = 1'b1;
        din0_valid[0] = '0;

        web0_data[1] = 1'b1;
        wmask0_data[1] = '0;
        din0_data[1] = '0;
        web0_tag[1] = 1'b1;
        din0_tag[1] = '0;
        web0_valid[1] = 1'b1;
        din0_valid[1] = '0;

        web0_data[2] = 1'b1;
        wmask0_data[2] = '0;
        din0_data[2] = '0;
        web0_tag[2] = 1'b1;
        din0_tag[2] = '0;
        web0_valid[2] = 1'b1;
        din0_valid[2] = '0;

        web0_data[3] = 1'b1;
        wmask0_data[3] = '0;
        din0_data[3] = '0;
        web0_tag[3] = 1'b1;
        din0_tag[3] = '0;
        web0_valid[3] = 1'b1;
        din0_valid[3] = '0;

        if (dfp_resp && (stage_reg.ufp_rmask > 0) && dfp_read) begin

            web0_data[choose_way] = 1'b0;
            wmask0_data[choose_way] = '1;
            din0_data[choose_way] = dfp_rdata;
      
            web0_tag[choose_way] = 1'b0;
            din0_tag[choose_way] = {1'b0,input_addr[31:9]};

            web0_valid[choose_way] = 1'b0;
            din0_valid[choose_way] = 1'b1;

            stage_next_reg.write_flag =  1'b1;

            // csb1_lru = 1'b0;
            // web1_lru = 1'b0;
            // addr1_lru = input_addr[8:5];
            // din1_lru = choose_lru;

            csb0_lru = 1'b1;
            web0_lru = 1'b1;
            addr0_lru = input_addr[8:5];
            din0_lru = '0;

            csb0 = 1'b0;
            addr0 = input_addr[8:5];
            wdata_bits_hit = '0;
            wdata_temp_hit = '0;
            stage_next_reg.write_flag_ufp = '0;
            stage_next_reg.dirty_flag = 1'b0;

        end else if (stage_reg.ufp_wmask > 0 && (~stage_reg.write_flag_ufp) && ((dfp_resp && dfp_read) || (hit_flag))) begin
            if (dfp_read) begin
                wdata_bits_hit = (stage_reg.offset / 5'b00100);
                wdata_temp_hit = dfp_rdata;
                way_var = choose_way;
                stage_next_reg.write_flag =  1'b1;

            end else begin
                wdata_bits_hit = (stage_reg.offset / 5'b00100);
                wdata_temp_hit = dout0_data[hit_way];
                way_var = hit_way;
                stage_next_reg.write_flag =  1'b0;
            end

            //stage_next_reg.write_flag =  1'b0;

            unique case (wdata_bits_hit)
                    0: wdata_previous = wdata_temp_hit[31:0];   
                    1: wdata_previous = wdata_temp_hit[63:32]; 
                    2: wdata_previous = wdata_temp_hit[95:64];  
                    3: wdata_previous = wdata_temp_hit[127:96]; 
                    4: wdata_previous = wdata_temp_hit[159:128];
                    5: wdata_previous = wdata_temp_hit[191:160];
                    6: wdata_previous = wdata_temp_hit[223:192];
                    7: wdata_previous = wdata_temp_hit[255:224];
                    default: wdata_previous = '0;      
                endcase

                
                if (stage_reg.ufp_wmask[3] == 1'b1) begin
                    ufp_wdata_temp[31:24] = stage_reg.ufp_wdata[31:24]; 
                end else begin
                    ufp_wdata_temp[31:24] = wdata_previous[31:24]; 
                end

                if (stage_reg.ufp_wmask[2] == 1'b1) begin
                    ufp_wdata_temp[23:16] = stage_reg.ufp_wdata[23:16]; 
                end else begin
                    ufp_wdata_temp[23:16] = wdata_previous[23:16]; 
                end

                if (stage_reg.ufp_wmask[1] == 1'b1) begin
                    ufp_wdata_temp[15:8] = stage_reg.ufp_wdata[15:8]; 
                end else begin
                    ufp_wdata_temp[15:8] = wdata_previous[15:8]; 
                end

                if (stage_reg.ufp_wmask[0] == 1'b1) begin
                    ufp_wdata_temp[7:0] = stage_reg.ufp_wdata[7:0]; 
                end else begin
                    ufp_wdata_temp[7:0] = wdata_previous[7:0]; 
                end 


                unique case (wdata_bits_hit)
                    0: wdata_temp_hit[31:0] = ufp_wdata_temp;   
                    1: wdata_temp_hit[63:32] = ufp_wdata_temp; 
                    2: wdata_temp_hit[95:64] = ufp_wdata_temp;  
                    3: wdata_temp_hit[127:96] = ufp_wdata_temp; 
                    4: wdata_temp_hit[159:128] = ufp_wdata_temp;
                    5: wdata_temp_hit[191:160] = ufp_wdata_temp;
                    6: wdata_temp_hit[223:192] = ufp_wdata_temp;
                    7: wdata_temp_hit[255:224] = ufp_wdata_temp;
                    default: wdata_temp_hit = '0;      
                endcase

            web0_data[way_var] = 1'b0;
            wmask0_data[way_var] = '1;
            din0_data[way_var] = wdata_temp_hit;
    
            web0_tag[way_var] = 1'b0;
            din0_tag[way_var] = {1'b1,input_addr[31:9]};

            web0_valid[way_var] = 1'b0;
            din0_valid[way_var] = 1'b1;

            stage_next_reg.write_flag_ufp = '1;
            //stage_next_reg.write_flag =  1'b0;

            csb0_lru = 1'b1;
            web0_lru = 1'b1;
            addr0_lru = input_addr[8:5];
            din0_lru = '0;

            csb0 = 1'b0;
            addr0 = input_addr[8:5];
            stage_next_reg.dirty_flag = 1'b0;

            
        end else if (dfp_write && dfp_resp)begin
            stage_next_reg.write_flag =  1'b0;
            stage_next_reg.write_flag_ufp = '0;
            wdata_bits_hit = '0;
            wdata_temp_hit = '0;

            csb0_lru = 1'b1;
            web0_lru = 1'b1;
            addr0_lru = input_addr[8:5];
            din0_lru = '0;

            stage_next_reg.dirty_flag = 1'b1;

            csb0 = 1'b0;
            addr0 = input_addr[8:5];
        end else begin
            stage_next_reg.dirty_flag = 1'b0;
            stage_next_reg.write_flag =  1'b0;
            stage_next_reg.write_flag_ufp = '0;
            wdata_bits_hit = '0;
            wdata_temp_hit = '0;
            
            web0_data[0] = 1'b1;
            wmask0_data[0] = '0;
            din0_data[0] = '0;
            web0_tag[0] = 1'b1;
            din0_tag[0] = '0;
            web0_valid[0] = 1'b1;
            din0_valid[0] = '0;

            web0_data[1] = 1'b1;
            wmask0_data[1] = '0;
            din0_data[1] = '0;
            web0_tag[1] = 1'b1;
            din0_tag[1] = '0;
            web0_valid[1] = 1'b1;
            din0_valid[1] = '0;

            web0_data[2] = 1'b1;
            wmask0_data[2] = '0;
            din0_data[2] = '0;
            web0_tag[2] = 1'b1;
            din0_tag[2] = '0;
            web0_valid[2] = 1'b1;
            din0_valid[2] = '0;

            web0_data[3] = 1'b1;
            wmask0_data[3] = '0;
            din0_data[3] = '0;
            web0_tag[3] = 1'b1;
            din0_tag[3] = '0;
            web0_valid[3] = 1'b1;
            din0_valid[3] = '0;

            csb0_lru = 1'b0;
            web0_lru = 1'b1;
            addr0_lru = input_addr[8:5];
            din0_lru = '0;

            // csb1_lru = 1'b1;
            // web1_lru = 1'b0;
            // addr1_lru = input_addr[8:5];
            // din1_lru = choose_lru;

            csb0 = 1'b0;
            addr0 = input_addr[8:5];

        

        end


    end

    
    
    always_ff @(posedge clk) begin
        if (rst) begin
            stage_reg <= '0;
        end
        else if ((~dfp_resp) && (dfp_read || dfp_write)) begin
            stage_reg <= stage_reg;
        end else begin
            stage_reg <= stage_next_reg;
        end
    end

    assign dirty_flag = (dout0_tag[choose_way][23] == 1'b1) && (dout0_valid[choose_way] == 1'b1);
    assign cache_flag = ((stage_reg.ufp_rmask != 4'b0000) || (stage_reg.ufp_wmask != 4'b0000));
    assign writing = !(stage_reg.dirty_flag || stage_reg.write_flag);
    always_comb begin

        if ((dout0_tag[0][22:0] == stage_reg.tag[22:0]) && (dout0_valid[0] == 1) && (stage_reg.ufp_rmask != 4'b0000 || stage_reg.ufp_wmask != 4'b0000)) begin
            hit_flag = 1'b1;
            hit_way = 2'd0;
            din1_lru[2] = dout0_lru[2];
            din1_lru[1] = '0;
            din1_lru[0] = '0;

            csb1_lru = 1'b0; 
        end else if ((dout0_tag[1][22:0] == stage_reg.tag[22:0]) && (dout0_valid[1] == 1) && (stage_reg.ufp_rmask != 4'b0000 || stage_reg.ufp_wmask != 4'b0000)) begin
            hit_flag = 1'b1;
            hit_way = 2'd1;
            din1_lru[2] = dout0_lru[2];
            din1_lru[1] = '1;
            din1_lru[0] = '0;

            csb1_lru = 1'b0; 
        end else if ((dout0_tag[2][22:0] == stage_reg.tag[22:0]) && (dout0_valid[2] == 1) && (stage_reg.ufp_rmask != 4'b0000 || stage_reg.ufp_wmask != 4'b0000)) begin
            hit_flag = 1'b1;
            hit_way = 2'd2;
            din1_lru[2] = '0;
            din1_lru[1] = dout0_lru[1];
            din1_lru[0] = '1;

            csb1_lru = 1'b0; 
        end else if ((dout0_tag[3][22:0] == stage_reg.tag[22:0]) && (dout0_valid[3] == 1) && (stage_reg.ufp_rmask != 4'b0000 || stage_reg.ufp_wmask != 4'b0000)) begin
            hit_flag = 1'b1;
            hit_way = 2'd3; 
            din1_lru[2] = '1;
            din1_lru[1] = dout0_lru[1];
            din1_lru[0] = '1;  

            csb1_lru = 1'b0;   
        end else begin
            din1_lru[2] = '0;
            din1_lru[1] = '0;
            din1_lru[0] = '0;  

            hit_flag = 1'b0;
            hit_way = 2'd0;

            csb1_lru = 1'b1;
        end

        //csb1_lru = 1'b1;
        web1_lru = 1'b0;
        addr1_lru = stage_reg.addr[8:5];

        ufp_resp = 1'b0;


        //choose_lru = '0;

        // dfp_read = 1'b0;
        // dfp_write = 1'b0;
        // dfp_addr = '0;
        // dfp_wdata = '0;
        // ufp_resp = 1'b0;
        // ufp_rdata = '0;
        if (!hit_flag) begin
            //ZERO OUT THESE LAST 5 BITS
            // dfp_addr = '0;
            // dfp_read = '0;
            // dfp_write = '0;
            // dfp_wdata = '0;
            // ufp_resp = '0;
            if (cache_flag) begin
                
                if (dout0_lru[0] == 1) begin
                    choose_way = {1'b0,~dout0_lru[1]};
                end else begin
                    choose_way = {1'b0,~dout0_lru[2]} + 2'b10;
                end

                if (dirty_flag && writing) begin
                    dfp_addr_temp = {dout0_tag[choose_way][22:0], stage_reg.index, 5'b00000};
                    dfp_addr_temp[4:0] = '0;
                    dfp_addr = dfp_addr_temp;
                
                    dfp_write = 1'b1;
                   
                    dfp_wdata = dout0_data[choose_way];

                    ufp_resp = 1'b0;
                    ufp_rdata = '0; 

                    dfp_read = 1'b0;

                    rdata_bits_hit = '0;
                    rdata_temp_hit = '0;
                   
                end else begin

                    dfp_addr_temp = stage_reg.addr;
                    dfp_addr_temp[4:0] = '0;
                    dfp_addr = dfp_addr_temp;

                    if (stage_reg.write_flag) begin
                        dfp_read = 1'b0;
                    end else begin 
                        dfp_read = 1'b1;
                    end

                    dfp_write = 1'b0;
                    dfp_wdata = '0;

                    ufp_resp = 1'b0;
                    ufp_rdata = '0; 

                    rdata_bits_hit = '0;
                    rdata_temp_hit = '0; 
                end

            end else begin
                dfp_addr = '0;
                dfp_read = '0;
                dfp_write = '0;
                dfp_wdata = '0;


                choose_way = '0;

                choose_lru = '0;

                rdata_bits_hit = '0;
                rdata_temp_hit = '0;

                ufp_resp = '0;
                ufp_rdata = '0;
            end


        end else begin
            if (stage_reg.ufp_wmask > 0) begin
                dfp_addr = '0;
                dfp_read = '0;
                dfp_write = '0;
                dfp_wdata = '0;


                choose_way = '0;

                choose_lru = '0;

                ufp_rdata = '0;
                if (stage_reg.write_flag_ufp) begin
                    ufp_resp = 1'b0;
                end else begin
                    ufp_resp = 1'b1;
                end

                rdata_bits_hit = '0;
            end else begin
                dfp_addr = '0;
                dfp_read = '0;
                dfp_write = '0;
                dfp_wdata = '0;

                if (hit_flag) begin
                    ufp_resp = 1'b1;
                end else begin
                    ufp_resp = 1'b0;
                end

                rdata_bits_hit = (stage_reg.offset / 5'b00100);
                rdata_temp_hit = '0;
                
                
                unique case (rdata_bits_hit)
                    0: rdata_temp_hit = dout0_data[hit_way][31:0];   
                    1: rdata_temp_hit = dout0_data[hit_way][63:32]; 
                    2: rdata_temp_hit = dout0_data[hit_way][95:64];  
                    3: rdata_temp_hit = dout0_data[hit_way][127:96]; 
                    4: rdata_temp_hit = dout0_data[hit_way][159:128];
                    5: rdata_temp_hit = dout0_data[hit_way][191:160];
                    6: rdata_temp_hit = dout0_data[hit_way][223:192];
                    7: rdata_temp_hit = dout0_data[hit_way][255:224];
                    default: rdata_temp_hit = 32'b0;      
                endcase

                if (stage_reg.ufp_rmask[3] == 1'b1) begin
                    ufp_rdata[31:24] = rdata_temp_hit[31:24]; 
                end else begin
                    ufp_rdata[31:24] = '0; 
                end

                if (stage_reg.ufp_rmask[2] == 1'b1) begin
                    ufp_rdata[23:16] = rdata_temp_hit[23:16]; 
                end else begin
                    ufp_rdata[23:16] = '0; 
                end

                if (stage_reg.ufp_rmask[1] == 1'b1) begin
                    ufp_rdata[15:8] = rdata_temp_hit[15:8]; 
                end else begin
                    ufp_rdata[15:8] = '0; 
                end

                if (stage_reg.ufp_rmask[0] == 1'b1) begin
                    ufp_rdata[7:0] = rdata_temp_hit[7:0]; 
                end else begin
                    ufp_rdata[7:0] = '0; 
                end 

                choose_way = '0;

                choose_lru = '0;
            end
        end      

    end

endmodule
