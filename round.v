`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen, 2021
// Engineer: Chris Larsen
// 
// Create Date: 03/22/2022 01:32:35 PM
// Design Name: 
// Module Name: round
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


module round(negIn, expIn, sigIn, ra, expOut, sigOut, inexact);
  parameter INTn = 32;
  parameter NEXP =  8;
  parameter NSIG = 23;
  `include "ieee-754-flags.vh"
  input negIn;
  input signed [NEXP+1:0] expIn;
  input [INTn-1:0] sigIn;
  input [NRAS:0] ra;
  output signed [NEXP+1:0] expOut;
  output [NSIG:0] sigOut;
  output inexact;
  reg inexact;
  
  wire Cout;
  wire [NSIG:0] aSig, rSig;
  wire signed [NEXP+1:0] rExp;

  reg [NSIG:0] tSig;
  reg [INTn-1:0] yBar;
  
  // Flags used in determination of whether we should be rounding:
  reg lastKeptBitIsOdd, decidingBitIsOne, remainingBitsAreNonzero;
  
  reg subnormal;
  
  always @(*)
  begin
    subnormal = 1;
    
    if (expIn < EMIN-NSIG-1)
      begin
        // Is the last bit to be saved a `1', that is, is it odd?
        lastKeptBitIsOdd        =  1'b0; // No bits are being kept.
           
        // Is the first bit to be truncated a `1'?
        // Then we use the last bit being kept to break the tie
        // in choosing to round, or use the rest of the truncated
        // bits.
        decidingBitIsOne        =  1'b0;
  
        // Are the bits beyond the first bit to be truncated all zero?
        // If not, we don't have a tie situation.
        remainingBitsAreNonzero = |sigIn;
              
        tSig = {NSIG+1{1'b0}};
      end
    else if (expIn < EMIN-NSIG)
      begin
        // Is the last bit to be saved a `1', that is, is it odd?
        lastKeptBitIsOdd        =  1'b0; // No bits are being kept.
           
        // Is the first bit to be truncated a `1'?
        // Then we use the last bit being kept to break the tie
        // in choosing to round, or use the rest of the truncated
        // bits.
        decidingBitIsOne        =  sigIn[INTn-1];
  
        // Are the bits beyond the first bit to be truncated all zero?
        // If not, we don't have a tie situation.
        remainingBitsAreNonzero = |sigIn[INTn-2:0];
              
        tSig = {NSIG+1{1'b0}};
      end
    else if (expIn < EMIN)
      begin
        // Is the last bit to be saved a `1', that is, is it odd?
        lastKeptBitIsOdd        =  sigIn[INTn-NSIG+EMIN-expIn-1];
           
        // Is the first bit to be truncated a `1'?
        // Then we use the last bit being kept to break the tie
        // in choosing to round, or use the rest of the truncated
        // bits.
        decidingBitIsOne        =  sigIn[INTn-NSIG+EMIN-expIn-2];
  
        // Calculate which bits are the remaining bits of y-bar.
        yBar = sigIn << (NSIG-EMIN+expIn+1);

        // Are the bits beyond the first bit to be truncated all zero?
        // If not, we don't have a tie situation.
        remainingBitsAreNonzero = |yBar[INTn-2:0];
        
        tSig = {(sigIn >> (INTn-NSIG+EMIN-expIn-1)), 1'b0};
      end
    else
      begin
        // Is the last bit to be saved a `1', that is, is it odd?
        lastKeptBitIsOdd        =  sigIn[INTn-NSIG-1];
           
        // Is the first bit to be truncated a `1'?
        // Then we use the last bit being kept to break the tie
        // in choosing to round, or use the rest of the truncated
        // bits.
        decidingBitIsOne        =  sigIn[INTn-NSIG-2];
  
        // Are the bits beyond the first bit to be truncated all zero?
        // If not, we don't have a tie situation.
        remainingBitsAreNonzero = |sigIn[INTn-NSIG-3:0];

        tSig = sigIn[INTn-1:INTn-NSIG-1];
        
        subnormal = 0;
    end
    
    // Are any of the truncated bits one, i.e., non-zero?
    inexact = decidingBitIsOne | remainingBitsAreNonzero;
  end
                
  // This flag holds the boolean value of whether or not we need to round this
  // significand. It's used as the carry-in bit for the instantiation of
  // padder24() below.
  wire roundBit = 
   (ra[roundTiesToEven] & // First rounding case
     decidingBitIsOne & (lastKeptBitIsOdd | remainingBitsAreNonzero)) |
   (ra[roundTowardPositive] & // Second rounding case
    ~negIn & (decidingBitIsOne | remainingBitsAreNonzero)) |
   (ra[roundTowardNegative] & // Third rounding case
     negIn & (decidingBitIsOne | remainingBitsAreNonzero));
   // When ra[roundTowardZero] is true we don't round, we
   // truncate.

  // Compute the rounded significand.
  if (NSIG == 10)
    padder11 U11(tSig, {{NSIG{1'b0}}, (roundBit&subnormal)}, roundBit, aSig, Cout);
  else if (NSIG == 23)
    padder24 U23(tSig, {{NSIG{1'b0}}, (roundBit&subnormal)}, roundBit, aSig, Cout);
  else
    assign {Cout, aSig} = {1'b0, tSig} + roundBit;
   
  // If there was a carry-out then the carry-out is the new most significant
  // bit set to 1 (one).
  assign rSig = Cout ? {Cout, aSig[NSIG:1]} : aSig;
  
  // If when we rounded sigIn there was a carry-out we need to adjust the exponent
  // to re-normalize the result.
  assign rExp = expIn + Cout; // We're adding either 1 or 0 to expIn.
  
  // Return final exponent and significand values.
  assign expOut = |rSig ? ((rExp<EMIN-NSIG) ? EMIN-NSIG : rExp) : rExp;
  assign sigOut = rSig;

endmodule
