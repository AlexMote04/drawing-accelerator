# Phase 1: Verification Findings

Five black-box line-drawing units (`unit_1` to `unit_5`) were run through the self-checking testbench in `src/Phase_1/unit_Testbench.sv`. Each unit's framestore writes were compared against the golden pixel stream from the C++ reference model in `models/`.

## Unit 1
- `de_data` always carries `0xFFFFFFFF`, whatever colour was requested.
- Reversed lines are plotted in reverse order compared with the C++ model.
- Everything else matches.

## Unit 2
- `de_req` drops low while pixels are still left to draw.
- The 8-bit colour is copied to all four byte lanes of `de_data`, even though only one lane is enabled. This is not strictly an error.
- Reversed lines (x1 > x2 or y1 > y2) are plotted in reverse order. The coordinates and colours are correct, so the output is still functionally right.

## Unit 3
- Reversed lines are plotted in reverse order. Coordinates and colours are correct.

## Unit 4
- The unit starts drawing without acknowledging the request. `req` therefore never drops, and the unit redraws the same line forever.

## Unit 5
- The colour is sometimes written to the wrong byte lane.

## General observations
- `de_req` drops in the same cycle that `de_ack` rises on the final pixel. This is not strictly an error, but it suggests `de_req` is driven combinationally.
- Some units copy the colour to every byte lane when only one is needed. This is harmless because of the byte-enable mask.
