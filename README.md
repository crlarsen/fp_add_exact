# Verilog IEEE 754 Addition

## Description

Create fp_add_exact module. The intermediate result of the sum is the exact value.

Code is explained in the video series [Building an FPU in Verilog](https://www.youtube.com/watch?v=rYkVdJnVJFQ&list=PLlO9sSrh8HrwcDHAtwec1ycV-m50nfUVs).
See the video *Building an FPU in Verilog: Adding Floating Point Numbers, Part 1*.

## Manifest

|   Filename        |                        Description                           |
|-------------------|--------------------------------------------------------------|
| README.md         | This file.                                                   |
| ieee-754-flags.vh | Verilog header file to define constants for datum type (NaN, Infinity, Zero, Subnormal, and Normal), rounding attributes, and IEEE exceptions. |
| fp_class.sv       | Utility module to identify the type of the IEEE 754 value passed in, and extract the exponent & significand fields for use by other modules. |
| fp_add_exact.v    | Addition circuit for the IEEE 754 binary16 data type.        |
| padder11.v        | Prefix adder used by round module.                           |
| padder42.v        | Prefix adder used by fp_add_exact module.                    |
| PijGij.v          | Utility routines needed by the various prefix adder modules. |
| round.v           | Parameterized rounding module.                               |

## Copyright

:copyright: Chris Larsen, 2019-2022
