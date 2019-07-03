// 1 clk delay on gnt assertion
// Hold gnt until req deasserts
// Priority encoder w/ LSb as highest priority
// If multiple requests, act as round robin arbiter
// Default to priority encoder if reqs aren't masked (single or multiple)
// Reset round robin once each channel has had been granted once

module arb #(parameter NUM_REQS = 4) (
  input  logic                clk,
  input  logic                rst,
  input  logic [NUM_REQS-1:0] req,
  output logic [NUM_REQS-1:0] gnt
);

  logic [NUM_REQS-1:0] pri_sel;
  logic [NUM_REQS-1:0] pri_sel_mask;
  logic [NUM_REQS-1:0] pre_gnt;
  logic [NUM_REQS-1:0] gnt_mask = 0;
  logic [NUM_REQS-1:0] prev_gnt = 0;

  always_comb begin
    pri_sel      = '0;
    pri_sel_mask = '0;
    pre_gnt      = '0;

    // priority arbiter
    for (int i=0; i<NUM_REQS; i++) begin
      if (req[i]) begin
        pri_sel[i] = 1'b1;
        break;
      end
    end

    // priority arbiter w/ mask
    for (int i=0; i<NUM_REQS; i++) begin
      if (req[i] && !gnt_mask[i]) begin
        pri_sel_mask[i] = 1'b1;
        break;
      end
    end

    // use pri_sel with mask if able, else use pri only
    pre_gnt = (pri_sel_mask != 0) ? pri_sel_mask : pri_sel;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      gnt      <= '0;
      prev_gnt <= '0;
      gnt_mask <= '0;
    end else begin
      prev_gnt <= gnt;

      // no previous valid activity, or granted req has deasserted
      // update gnt and check if saturated
      if ((prev_gnt & req) == '0) begin
        gnt <= pre_gnt;

        if (gnt_mask == '1) begin
          gnt_mask <= '0;
        end else begin
          for (int i=0; i<NUM_REQS; i++) begin
            if (gnt[i]) begin
              gnt_mask[i] <= 1'b1;
            end
          end
        end
      end
    end
  end

endmodule
