`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2022 03:42:54 PM
// Design Name: 
// Module Name: PijGij
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// This module exists to keep the Verilog compiler from complaining about
// outputs not being connected to inputs. Otherwise, I would have just used
// the module PijGij everywhere and been done with it. Also, it does use a few
// less gates than the PijGij module but I suspect a good Verilog compiler
// would make such optimizations for unused outputs automatically.
module Gij(\Pi:k , \Gi:k , \Gk-1:j , \Gi:j );
  input \Pi:k , \Gi:k , \Gk-1:j ;
  output \Gi:j ;

  assign \Gi:j = \Gi:k | (\Pi:k  & \Gk-1:j );
endmodule

module PijGij(\Pi:k , \Pk-1:j , \Gi:k , \Gk-1:j , \Pi:j , \Gi:j );
  input \Pi:k , \Pk-1:j , \Gi:k , \Gk-1:j ;
  output \Pi:j , \Gi:j ;

  assign \Pi:j = \Pi:k & \Pk-1:j ;
  assign \Gi:j = \Gi:k | (\Pi:k  & \Gk-1:j );
endmodule

module Sum(\Gi-1:-1 , Ai, Bi, Si);
  input \Gi-1:-1 , Ai, Bi;
  output Si;

  assign Si = \Gi-1:-1 ^ Ai ^ Bi;
endmodule

