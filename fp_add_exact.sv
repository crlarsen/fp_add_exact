`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2022 01:10:46 PM
// Design Name: 
// Module Name: fp_add_exact
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


module fp_add_exact(a, b, ra, s, sFlags, exception);
  parameter NEXP = 5;
  parameter NSIG = 10;
  `include "ieee-754-flags.vh"
  localparam CLOG2_NSIG = $clog2(NSIG+1);
  input [NEXP+NSIG:0] a, b;
  input [NRAS:0] ra;
  output [NEXP+NSIG:0] s;
  output [NTYPES-1:0] sFlags;
  reg [NTYPES-1:0] sFlags;
  output [NEXCEPTIONS-1:0] exception;
  reg [NEXCEPTIONS-1:0] exception;
  wire inexact;

  wire signed [NEXP+1:0] aExp, bExp, expOut;
  wire signed [NEXP+1:0] qExp, expIn;
  wire [NSIG:0] aSig, bSig, sigOut;
  reg signed [NSIG+5:0] dTmp, bTmp[15:1], iTmp[15:1];
  reg [NSIG+5:0] tSig;
  wire [NSIG:0] qSig;
  wire [NTYPES-1:0] aFlags, bFlags;

  fp_class #(NEXP,NSIG) aClass(a, aExp, aSig, aFlags);
  fp_class #(NEXP,NSIG) bClass(b, bExp, bSig, bFlags);

  wire aSign = a[NEXP+NSIG];
  wire bSign = b[NEXP+NSIG];

  reg signed [NSIG+1:0] shiftAmt;
  // augendSig: Significand of the operand with the larger exponent
  // addendSig: Significand of the operand with the smaller exponent
  // Note: The exponent of the augend may note be strictly larger than
  //       the exponent of the addend. The two exponents may be equal
  //       but the exponent of the augend will never be smaller than
  //       the exponent of the addend.
  // sumSig:    Significand of the augend/addend significands.
  //            ***** This value may be negative!
  // absSig:    Absolute value of sumSig.
  // bigSig:    If adding augendSig and addendSig caused a carry out
  //            bigSig is right shifted so that the MSB of the significand
  //            sum will never be farther to the left than bit NSIG.
  //            ***** See bigExp below.
  // normSig:   If one of the numbers being added is negative, and the
  //            other is positive then it's likely the MSB of the sum
  //            isn't in bit NSIG. This means that we need to left shift
  //            the sum until the MSB is in bit NSIG. We then use the
  //            shift amount to adjust the corresponding exponent value.
  //            ***** See normExp below.
  reg signed [EMAX+2:EMIN-NSIG] augendSig, addendSig, sumSig, absSig, bigSig,
             normSig;

  // adjExp:  max(aExp, bExp)
  // bigExp:  Renormalized exponent if adding the augend/addend
  //          significands caused the MSB to be left of bit NSIG.
  //          ***** See bigSig above.
  // normExp: Renormalized exponent if the augend/addend has opposite
  //          signs.
  //          ***** See normSig above.
  // biasExp: Sum significand after adding the BIAS value into normExp.
  reg signed [NEXP+1:0] adjExp, bigExp, normExp, biasExp;

  // Sign of significand sum before taking the absolute value of sumSig.
  reg sumSign;
  // Adjusted sumSign after taking absolute value of sumSig.
  wire absSign;

  // shiftCount to renormlize after adding to numbers with opposite
  // signs.
  reg [3:0] shiftCount;
  reg [CLOG2_NSIG-1:0] na;
  reg [EMAX+2:EMIN-NSIG] mask = ~0;

  wire Cout1, Cout2;
  reg subtract, zero, e0, si;

  reg [NEXP+NSIG:0] alwaysS;

  integer i;

  always @(*)
  begin
    sFlags = 0;
    exception = 0;
    subtract = a[NEXP+NSIG] ^ b[NEXP+NSIG];

    if (aFlags[SNAN] | bFlags[SNAN])
      begin
        {alwaysS, sFlags} = aFlags[SNAN] ? {a, aFlags} : {b, bFlags};
      end
    else if (aFlags[QNAN] | bFlags[QNAN])
      begin
        {alwaysS, sFlags} = aFlags[QNAN] ? {a, aFlags} : {b, bFlags};
      end
    else if (aFlags[ZERO] | bFlags[ZERO])
      begin
        {alwaysS, sFlags} = aFlags[ZERO] ? {b, bFlags} : {a, aFlags};
      end
    else if (aFlags[INFINITY] & bFlags[INFINITY])
      begin
        e0 =  ra[roundTiesToEven] |
             (ra[roundTowardPositive] & ~aSign) |
             (ra[roundTowardNegative] &  aSign) |
              subtract;
        si =  ra[roundTowardZero] |
             (ra[roundTowardPositive] &  aSign) |
             (ra[roundTowardNegative] & ~aSign) |
              subtract;
        exception[INVALID] =  subtract;
        sFlags[INFINITY]   = ~si;
        sFlags[QNAN]       =  subtract;
        sFlags[NORMAL]     = ~e0;
        alwaysS = {aSign, {{NEXP-1{1'b1}}, e0},{NSIG{si}}};
      end
    else if (aFlags[INFINITY] | bFlags[INFINITY])
      begin
        {alwaysS, sFlags} = aFlags[INFINITY] ? {a, aFlags} : {b, bFlags};
      end
    else // a and b are both (sub-)normal numbers
      begin
        augendSig = 0;
        addendSig = 0;
        na = 0;
        zero = 1;

        if (aExp < bExp)
          begin
            sumSign = b[NEXP+NSIG];
            shiftAmt = bExp - aExp;
            augendSig[EMAX:EMAX-NSIG] = bSig;
            addendSig[EMAX:EMAX-NSIG] = aSig;
            adjExp = bExp;
          end
        else
          begin
            sumSign = a[NEXP+NSIG];
            shiftAmt = aExp - bExp;
            augendSig[EMAX:EMAX-NSIG] = aSig;
            addendSig[EMAX:EMAX-NSIG] = bSig;
            adjExp = aExp;
          end

        addendSig = addendSig >> shiftAmt;

        // Check to see if we actually calculated a difference, and, if so,
        // renormalize the significand, and adjust the exponent accordingly.
        normSig = bigSig;

        for (i = (1 << (CLOG2_NSIG - 1)); i > 0; i = i >> 1)
          begin
            if ((normSig & (mask << ((EMAX-(EMIN-NSIG)+1) - i))) == 0)
              begin
                normSig = normSig << i;
                na = na | i;
              end
            else
              zero = 0;
          end

        normExp = bigExp - na;

        // Control should return to the rounding logic from here.

        if (zero)
          begin
            sFlags[ZERO] = 1;
            alwaysS = {ra[roundTowardNegative], {NEXP+NSIG{1'b0}}};
          end
        else if (expOut < EMIN)
          begin
            sFlags[SUBNORMAL] = 1;
            alwaysS = {absSign, {NEXP{1'b0}}, sigOut[NSIG:1]};
          end
        else if (expOut > EMAX)
          begin
//            exception[OVERFLOW] = 1;
//            sFlags[INFINITY] = 1;
//            alwaysS = {absSign, {NEXP{1'b1}}, {NSIG{1'b0}}};
            si = ra[roundTowardZero] |
                (ra[roundTowardNegative] & ~absSign) |
                (ra[roundTowardPositive] &  absSign);
            alwaysS = {absSign, {NEXP-1{1'b1}}, ~si, {NSIG{si}}};
            sFlags[INFINITY] = ~si;
            sFlags[NORMAL]   =  si;
            exception[OVERFLOW] = 1;
          end
        else
          begin
            sFlags[NORMAL] = 1;
            biasExp = expOut + BIAS;

            alwaysS = {absSign, biasExp[NEXP-1:0], sigOut[NSIG-1:0]};
          end

        exception[INEXACT] = inexact;
      end
  end

  // Compute sum/difference of significands
  padder42 U0(augendSig, addendSig^{EMAX-(EMIN-NSIG)+3{subtract}}, subtract, sumSig, Cout1);

  // Adjusted sign if absSum = -sigSum:
  assign absSign = sumSign ^ sumSig[EMAX+2];

  // Compute abs(sumSig):
  // If sumSig is negative then sumSig[NSIG+2] (the sign bit) will be 1.
  // If sumSig is negative then "sumSig^{2*NSIG+6{sumSig[NSIG+2]}}" is the
  // ones complement of sumSig. Otherwise this value is just sumSig.
  // By using the sign bit of sumSig as the carry in value when sumSig is
  // negative we compute the twos complement of sumSig, i.e., we find sumSig's
  // absolute value. If sumSig is positive, or zero, the output from this
  // adder is sumSig.
  padder42 U1({EMAX-(EMIN-NSIG)+3{1'b0}}, sumSig^{EMAX-(EMIN-NSIG)+3{sumSig[EMAX+2]}}, sumSig[EMAX+2],
              absSig, Cout2);

  // See if the addition caused a carry-out. If so, adjust the significand
  // and the exponent.
  assign bigSig = absSig >> absSig[EMAX+1];
  assign bigExp = adjExp + absSig[EMAX+1];

  // Control returns to the "always" block above so we can renormalize if
  // what we're really calculating is a difference.

  // Round the significand.
  round #(EMAX-(EMIN-NSIG)+1, NEXP, NSIG) U2((absSign), normExp,
                                             normSig[EMAX:EMIN-NSIG], ra, expOut,
                                             sigOut, inexact);
  assign s = alwaysS;

endmodule
