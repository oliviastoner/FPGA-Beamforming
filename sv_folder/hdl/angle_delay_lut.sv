module angle_delay_lut (
    input wire clk_in,
    input wire rst_in,
    input logic [7:0] angle,                     // angle can go up to 180 degrees; max 8 bits
    output logic valid_out,                      // tells you if the delay is valid
    output logic signed [15:0] delay_1,          // time delay for mic 1 in cycles
    output logic signed [15:0] delay_2,          // time delay for mic 2 in cycles
    output logic signed [15:0] delay_3,          // time delay for mic 3 in cycles
    output logic signed [15:0] delay_4           // time delay for mic 4 in cycles
);

// Define the lookup table.

// Each entry corresponds to the value of d * cos(theta) / c * frequency.
// We scale this up to avoid fixed / floating-point storage & calculations.

// theta is the input angle value, from 0-180 degrees.

// c is the speed of sound, where we use 343 meters/second

    logic signed [180:0][31:0] delay_table;   // 180 entries, each holding d * cos(theta) / c * frequency at that theta value

    // initialize LUT 
    initial begin
        delay_table[0] = 2915;
        delay_table[1] = 2915;
        delay_table[2] = 2914;
        delay_table[3] = 2911;
        delay_table[4] = 2908;
        delay_table[5] = 2904;
        delay_table[6] = 2899;
        delay_table[7] = 2894;
        delay_table[8] = 2887;
        delay_table[9] = 2880;
        delay_table[10] = 2871;
        delay_table[11] = 2862;
        delay_table[12] = 2852;
        delay_table[13] = 2841;
        delay_table[14] = 2829;
        delay_table[15] = 2816;
        delay_table[16] = 2803;
        delay_table[17] = 2788;
        delay_table[18] = 2773;
        delay_table[19] = 2757;
        delay_table[20] = 2740; 
        delay_table[21] = 2722;
        delay_table[22] = 2703;
        delay_table[23] = 2684;
        delay_table[24] = 2663;
        delay_table[25] = 2642;
        delay_table[26] = 2620;
        delay_table[27] = 2598;
        delay_table[28] = 2574;
        delay_table[29] = 2550;
        delay_table[30] = 2525;
        delay_table[31] = 2499;
        delay_table[32] = 2472;
        delay_table[33] = 2445;
        delay_table[34] = 2417;
        delay_table[35] = 2388;
        delay_table[36] = 2359;
        delay_table[37] = 2328;
        delay_table[38] = 2297;
        delay_table[39] = 2266;
        delay_table[40] = 2233;
        delay_table[41] = 2200;
        delay_table[42] = 2167;
        delay_table[43] = 2132;
        delay_table[44] = 2097;
        delay_table[45] = 2062;
        delay_table[46] = 2025;
        delay_table[47] = 1988;
        delay_table[48] = 1951;
        delay_table[49] = 1913;
        delay_table[50] = 1874;
        delay_table[51] = 1835;
        delay_table[52] = 1795;
        delay_table[53] = 1755;
        delay_table[54] = 1714;
        delay_table[55] = 1672;
        delay_table[56] = 1630;
        delay_table[57] = 1588;
        delay_table[58] = 1545;
        delay_table[59] = 1502;
        delay_table[60] = 1458;
        delay_table[61] = 1413;
        delay_table[62] = 1369;
        delay_table[63] = 1324;
        delay_table[64] = 1278;
        delay_table[65] = 1232;
        delay_table[66] = 1186;
        delay_table[67] = 1139;
        delay_table[68] = 1092;
        delay_table[69] = 1045;
        delay_table[70] = 997;
        delay_table[71] = 949;
        delay_table[72] = 901;
        delay_table[73] = 852;
        delay_table[74] = 804;
        delay_table[75] = 755;
        delay_table[76] = 705;
        delay_table[77] = 656;
        delay_table[78] = 606;
        delay_table[79] = 556;
        delay_table[80] = 506;
        delay_table[81] = 456;
        delay_table[82] = 406;
        delay_table[83] = 355;
        delay_table[84] = 305;
        delay_table[85] = 254;
        delay_table[86] = 203;
        delay_table[87] = 153;
        delay_table[88] = 102;
        delay_table[89] = 51;
        delay_table[90] = 0;
        delay_table[91] = -51;
        delay_table[92] = -101;
        delay_table[93] = -153;
        delay_table[94] = -203;
        delay_table[95] = -254;
        delay_table[96] = -305;
        delay_table[97] = -355;
        delay_table[98] = -406;
        delay_table[99] = -456;
        delay_table[100] = -506;
        delay_table[101] = -556;
        delay_table[102] = -606;
        delay_table[103] = -656;
        delay_table[104] = -705;
        delay_table[105] = -755;
        delay_table[106] = -804;
        delay_table[107] = -852;
        delay_table[108] = -901;
        delay_table[109] = -949;
        delay_table[110] = -997;
        delay_table[111] = -1045;
        delay_table[112] = -1092;
        delay_table[113] = -1139;
        delay_table[114] = -1186;
        delay_table[115] = -1232;
        delay_table[116] = -1278;
        delay_table[117] = -1324;
        delay_table[118] = -1369;
        delay_table[119] = -1413;
        delay_table[120] = -1458;
        delay_table[121] = -1502;
        delay_table[122] = -1545;
        delay_table[123] = -1588;
        delay_table[124] = -1630;
        delay_table[125] = -1672;
        delay_table[126] = -1714;
        delay_table[127] = -1755;
        delay_table[128] = -1795;
        delay_table[129] = -1835;
        delay_table[130] = -1874;
        delay_table[131] = -1913;
        delay_table[132] = -1951;
        delay_table[133] = -1988;
        delay_table[134] = -2025;
        delay_table[135] = -2062;
        delay_table[136] = -2097;
        delay_table[137] = -2132;
        delay_table[138] = -2167;
        delay_table[139] = -2200;
        delay_table[140] = -2233;
        delay_table[141] = -2266;
        delay_table[142] = -2297;
        delay_table[143] = -2328;
        delay_table[144] = -2359;
        delay_table[145] = -2388;
        delay_table[146] = -2417;
        delay_table[147] = -2445;
        delay_table[148] = -2472;
        delay_table[149] = -2499;
        delay_table[150] = -2525;
        delay_table[151] = -2550;
        delay_table[152] = -2574;
        delay_table[153] = -2598;
        delay_table[154] = -2620;
        delay_table[155] = -2642;
        delay_table[156] = -2663;
        delay_table[157] = -2684;
        delay_table[158] = -2703;
        delay_table[159] = -2722;
        delay_table[160] = -2740;
        delay_table[161] = -2757;
        delay_table[162] = -2773;
        delay_table[163] = -2788;
        delay_table[164] = -2803;
        delay_table[165] = -2816;
        delay_table[166] = -2829;
        delay_table[167] = -2841;
        delay_table[168] = -2852;
        delay_table[169] = -2862;
        delay_table[170] = -2871;
        delay_table[171] = -2880;
        delay_table[172] = -2887;
        delay_table[173] = -2894;
        delay_table[174] = -2899;
        delay_table[175] = -2904;
        delay_table[176] = -2908;
        delay_table[177] = -2911;
        delay_table[178] = -2914;
        delay_table[179] = -2915;
        delay_table[180] = -2915;
    end

    // Main logic for looking up delay values based on angle
    always_ff @(posedge clk_in) begin
        // initialize the lookup table on system reset
        if (rst_in) begin

            delay_1 <= 0;
            delay_2 <= 0;
            delay_3 <= 0;
            delay_4 <= 0;
            valid_out <= 0;

        end else begin
            // if angle <= 90, then don't have to shift first 3 delays to account for negative values.
            // can just keep output as [0, 20, 40, 60], for example.
            if ((angle >= 0) && (angle <= 90)) begin
                delay_1 <= ($signed(delay_table[angle]) * $signed(0)); // num cycles delay for mic 1
                delay_2 <= ($signed(delay_table[angle]) * $signed(1)); // num cycles delay for mic 2
                delay_3 <= ($signed(delay_table[angle]) * $signed(2)); // num cycles delay for mic 3
                delay_4 <= ($signed(delay_table[angle]) * $signed(3)); // num cycles delay for mic 4
                valid_out <= 1;

            // must shift to account for negative values.
            // if the delay output is [0, -20, -40, -60],
            // this is effectively the same as [60, 40, 20, 0], so we output this instead.
            end else if ((angle > 90) && (angle <= 180)) begin
                delay_1 <= -($signed(delay_table[angle]) * $signed(3)); // num cycles delay for mic 1
                delay_2 <= -($signed(delay_table[angle]) * $signed(2)); // num cycles delay for mic 2
                delay_3 <= -($signed(delay_table[angle]) * $signed(1)); // num cycles delay for mic 3
                delay_4 <= -($signed(delay_table[angle]) * $signed(0)); // num cycles delay for mic 4
                valid_out <= 1;

            end else begin
                // invalid angle; invalid output
                valid_out <= 0;
            end

        end

    end
    
endmodule