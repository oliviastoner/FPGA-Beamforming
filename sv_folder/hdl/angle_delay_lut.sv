module angle_delay_lut (
    input wire [7:0] angle_in,                     // angle can go up to 180 degrees; max 8 bits
    output logic [7:0] delay_1_out,          // time delay for mic 1 in cycles
    output logic [7:0] delay_2_out,          // time delay for mic 2 in cycles
    output logic [7:0] delay_3_out,          // time delay for mic 3 in cycles
    output logic [7:0] delay_4_out           // time delay for mic 4 in cycles
);

// Define the lookup table.
// Each entry corresponds to the value of d * cos(theta) / c * frequency.
// We scale this up to avoid fixed / floating-point storage & calculations.
// theta is the input angle value, from 0-180 degrees.
// c is the speed of sound, where we use 343 meters/second

logic signed [7:0] delay;
always_comb begin
    case (angle_in)
        8'd0: delay = 8'd4;
        8'd1: delay = 8'd4;
        8'd2: delay = 8'd4;
        8'd3: delay = 8'd4;
        8'd4: delay = 8'd4;
        8'd5: delay = 8'd4;
        8'd6: delay = 8'd4;
        8'd7: delay = 8'd4;
        8'd8: delay = 8'd4;
        8'd9: delay = 8'd4;
        8'd10: delay = 8'd4;
        8'd11: delay = 8'd4;
        8'd12: delay = 8'd4;
        8'd13: delay = 8'd4;
        8'd14: delay = 8'd4;
        8'd15: delay = 8'd4;
        8'd16: delay = 8'd4;
        8'd17: delay = 8'd4;
        8'd18: delay = 8'd4;
        8'd19: delay = 8'd4;
        8'd20: delay = 8'd4;
        8'd21: delay = 8'd4;
        8'd22: delay = 8'd4;
        8'd23: delay = 8'd4;
        8'd24: delay = 8'd4;
        8'd25: delay = 8'd4;
        8'd26: delay = 8'd4;
        8'd27: delay = 8'd4;
        8'd28: delay = 8'd4;
        8'd29: delay = 8'd4;
        8'd30: delay = 8'd4;
        8'd31: delay = 8'd3;
        8'd32: delay = 8'd3;
        8'd33: delay = 8'd3;
        8'd34: delay = 8'd3;
        8'd35: delay = 8'd3;
        8'd36: delay = 8'd3;
        8'd37: delay = 8'd3;
        8'd38: delay = 8'd3;
        8'd39: delay = 8'd3;
        8'd40: delay = 8'd3;
        8'd41: delay = 8'd3;
        8'd42: delay = 8'd3;
        8'd43: delay = 8'd3;
        8'd44: delay = 8'd3;
        8'd45: delay = 8'd3;
        8'd46: delay = 8'd3;
        8'd47: delay = 8'd3;
        8'd48: delay = 8'd3;
        8'd49: delay = 8'd3;
        8'd50: delay = 8'd2;
        8'd51: delay = 8'd2;
        8'd52: delay = 8'd2;
        8'd53: delay = 8'd2;
        8'd54: delay = 8'd2;
        8'd55: delay = 8'd2;
        8'd56: delay = 8'd2;
        8'd57: delay = 8'd2;
        8'd58: delay = 8'd2;
        8'd59: delay = 8'd2;
        8'd60: delay = 8'd2;
        8'd61: delay = 8'd2;
        8'd62: delay = 8'd2;
        8'd63: delay = 8'd2;
        8'd64: delay = 8'd2;
        8'd65: delay = 8'd1;
        8'd66: delay = 8'd1;
        8'd67: delay = 8'd1;
        8'd68: delay = 8'd1;
        8'd69: delay = 8'd1;
        8'd70: delay = 8'd1;
        8'd71: delay = 8'd1;
        8'd72: delay = 8'd1;
        8'd73: delay = 8'd1;
        8'd74: delay = 8'd1;
        8'd75: delay = 8'd1;
        8'd76: delay = 8'd1;
        8'd77: delay = 8'd1;
        8'd78: delay = 8'd0;
        8'd79: delay = 8'd0;
        8'd80: delay = 8'd0;
        8'd81: delay = 8'd0;
        8'd82: delay = 8'd0;
        8'd83: delay = 8'd0;
        8'd84: delay = 8'd0;
        8'd85: delay = 8'd0;
        8'd86: delay = 8'd0;
        8'd87: delay = 8'd0;
        8'd88: delay = 8'd0;
        8'd89: delay = 8'd0;
        8'd90: delay = 8'd0;
        8'd91: delay = 8'd0;
        8'd92: delay = 8'd0;
        8'd93: delay = 8'd0;
        8'd94: delay = 8'd0;
        8'd95: delay = 8'd0;
        8'd96: delay = 8'd0;
        8'd97: delay = 8'd0;
        8'd98: delay = 8'd0;
        8'd99: delay = 8'd0;
        8'd100: delay = 8'd0;
        8'd101: delay = 8'd0;
        8'd102: delay = 8'd0;
        8'd103: delay = 8'd1;
        8'd104: delay = 8'd1;
        8'd105: delay = 8'd1;
        8'd106: delay = 8'd1;
        8'd107: delay = 8'd1;
        8'd108: delay = 8'd1;
        8'd109: delay = 8'd1;
        8'd110: delay = 8'd1;
        8'd111: delay = 8'd1;
        8'd112: delay = 8'd1;
        8'd113: delay = 8'd1;
        8'd114: delay = 8'd1;
        8'd115: delay = 8'd1;
        8'd116: delay = 8'd2;
        8'd117: delay = 8'd2;
        8'd118: delay = 8'd2;
        8'd119: delay = 8'd2;
        8'd120: delay = 8'd2;
        8'd121: delay = 8'd2;
        8'd122: delay = 8'd2;
        8'd123: delay = 8'd2;
        8'd124: delay = 8'd2;
        8'd125: delay = 8'd2;
        8'd126: delay = 8'd2;
        8'd127: delay = 8'd2;
        8'd128: delay = 8'd2;
        8'd129: delay = 8'd2;
        8'd130: delay = 8'd2;
        8'd131: delay = 8'd3;
        8'd132: delay = 8'd3;
        8'd133: delay = 8'd3;
        8'd134: delay = 8'd3;
        8'd135: delay = 8'd3;
        8'd136: delay = 8'd3;
        8'd137: delay = 8'd3;
        8'd138: delay = 8'd3;
        8'd139: delay = 8'd3;
        8'd140: delay = 8'd3;
        8'd141: delay = 8'd3;
        8'd142: delay = 8'd3;
        8'd143: delay = 8'd3;
        8'd144: delay = 8'd3;
        8'd145: delay = 8'd3;
        8'd146: delay = 8'd3;
        8'd147: delay = 8'd3;
        8'd148: delay = 8'd3;
        8'd149: delay = 8'd3;
        8'd150: delay = 8'd4;
        8'd151: delay = 8'd4;
        8'd152: delay = 8'd4;
        8'd153: delay = 8'd4;
        8'd154: delay = 8'd4;
        8'd155: delay = 8'd4;
        8'd156: delay = 8'd4;
        8'd157: delay = 8'd4;
        8'd158: delay = 8'd4;
        8'd159: delay = 8'd4;
        8'd160: delay = 8'd4;
        8'd161: delay = 8'd4;
        8'd162: delay = 8'd4;
        8'd163: delay = 8'd4;
        8'd164: delay = 8'd4;
        8'd165: delay = 8'd4;
        8'd166: delay = 8'd4;
        8'd167: delay = 8'd4;
        8'd168: delay = 8'd4;
        8'd169: delay = 8'd4;
        8'd170: delay = 8'd4;
        8'd171: delay = 8'd4;
        8'd172: delay = 8'd4;
        8'd173: delay = 8'd4;
        8'd174: delay = 8'd4;
        8'd175: delay = 8'd4;
        8'd176: delay = 8'd4;
        8'd177: delay = 8'd4;
        8'd178: delay = 8'd4;
        8'd179: delay = 8'd4;
        8'd180: delay = 8'd4;
        default: delay = 8'd0;
    endcase

    if (angle_in > 8'd90) begin
        delay_1_out = delay * 3;
        delay_2_out = delay * 2;
        delay_3_out = delay;
        delay_4_out = 0;
    end
    else begin
        delay_1_out = 0;
        delay_2_out = delay;
        delay_3_out = delay * 2;
        delay_4_out = delay * 3;
    end
end

endmodule
