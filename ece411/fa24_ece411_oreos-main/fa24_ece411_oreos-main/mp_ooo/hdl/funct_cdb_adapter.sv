module funct_cdb_adapter
import rv32i_types::*;
import params::*;
(
  input     funct_unit_out_t    funct_unit_out_alu,
  input     funct_unit_out_t    funct_unit_out_mul,  
  input     funct_unit_out_t    funct_unit_out_div,
  input     funct_unit_out_t    funct_unit_out_ls,
  input     funct_unit_out_t    funct_unit_out_control,

  output    cdb_out_t           cdb_out_entry,

  output    logic               cdb_ready_alu,
  output    logic               cdb_ready_mul,
  output    logic               cdb_ready_div,
  output    logic               cdb_ready_ls,
  output    logic               cdb_ready_control,
  
  output    logic               mul_flag,
  output    logic               div_flag,
  output    logic               alu_flag,
  output    logic               ls_flag,
  output    logic               control_flag
);

funct_unit_out_t       funct_unit_arr[5];
logic                  cdb_ready_arr[5];

cdb_out_t cdb_entry_out;

assign funct_unit_arr[0] = funct_unit_out_ls;
assign funct_unit_arr[1] = funct_unit_out_alu;
assign funct_unit_arr[2] = funct_unit_out_mul;
assign funct_unit_arr[3] = funct_unit_out_div;
assign funct_unit_arr[4] = funct_unit_out_control;

assign cdb_ready_ls      = cdb_ready_arr[0];
assign cdb_ready_alu     = cdb_ready_arr[1];
assign cdb_ready_mul     = cdb_ready_arr[2];
assign cdb_ready_div     = cdb_ready_arr[3];
assign cdb_ready_control = cdb_ready_arr[4];

always_comb begin
    mul_flag = 1'b0;
    div_flag = 1'b0;
    alu_flag = 1'b0;
    ls_flag = 1'b0;
    control_flag = 1'b0;

    for(int i = 0; i < 5; i++) begin
        cdb_ready_arr[i] = 1'b1;
    end

    for(int i = 0; i < 5; i++) begin
        cdb_ready_arr[i] = 1'b1;
        cdb_entry_out.rd = funct_unit_arr[i].rd;
        cdb_entry_out.pd = funct_unit_arr[i].pd;
        cdb_entry_out.ready_commit = funct_unit_arr[i].ready_commit;
        cdb_entry_out.data = funct_unit_arr[i].funct_unit_out;
        cdb_entry_out.rob_idx = funct_unit_arr[i].rob_idx;
        cdb_entry_out.rvfi_data_out = funct_unit_arr[i].rvfi_data;

        if (funct_unit_arr[i].ready_commit == 1'b1) begin
            if(i == 0) begin
                ls_flag = 1'b1;
            end
            if(i == 1) begin
                alu_flag = 1'b1;
            end
            if (i == 2) begin
                mul_flag = 1'b1;
            end
            if (i == 3) begin
                div_flag = 1'b1;
            end
            if (i == 4) begin
                control_flag = 1'b1;
            end
            break;
        end
        
    end
end

assign cdb_out_entry = cdb_entry_out;

endmodule : funct_cdb_adapter
