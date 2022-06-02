//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Chris Larsen
//
// Create Date: 01/25/2020 08:04:53 AM
// Design Name:
// Module Name: ieee-754-flags
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Flag parameters so we can include this file and have consistent
//              definitions every time we need to access of the flags for an
//              IEEE 754 floating point value.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

localparam NORMAL    = 0;
localparam SUBNORMAL = NORMAL + 1;
localparam ZERO      = SUBNORMAL + 1;
localparam INFINITY  = ZERO + 1;
localparam QNAN      = INFINITY + 1;
localparam SNAN      = QNAN + 1;
localparam NTYPES    = SNAN + 1;

localparam BIAS = ((1 << (NEXP - 1)) - 1); // IEEE 754, section 3.3
localparam EMAX = BIAS; // IEEE 754, section 3.3
localparam EMIN = (1 - EMAX); // IEEE 754, section 3.3

localparam roundTiesToEven     = 0;
localparam roundTowardZero     = 1;
localparam roundTowardPositive = 2;
localparam roundTowardNegative = 3;
localparam roundTiesToAway     = 4;
localparam NRAS                = roundTiesToAway+1;
                                    
localparam INVALID             = 0;
localparam DIVIDEBYZERO        = 1;
localparam OVERFLOW            = 2;
localparam UNDERFLOW           = 3;
localparam INEXACT             = 4;
localparam NEXCEPTIONS     = INEXACT+1;
