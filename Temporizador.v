module Temporizador(clkIn, clkOut);
    input clkIn;
    output wire clkOut;
   
    parameter nDiv = 17; //
    reg[nDiv:0] freq;
   
    always@(posedge clkIn)
        begin   
            freq <= freq + 1;
        end
       
    assign clkOut = freq[nDiv];
endmodule