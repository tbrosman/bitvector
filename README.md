# BitVector

A bit vector implementation for Haxe. Features:

- Compactly stores an array of bits in an array of ints
- Conversion to/from binary and hex strings
- Partial implementation of extended-precision integer arithmetic (aka "BigInt")

## Overview

When I worked on [Starscend](http://starscend.com/) I commonly found that I needed a compact representation for manipulating bits. The Endless Mode levels are procedurally generated using a an algorithm that scans a dense 2D array of bits and applies rules to mutate wall sections. Another application was the animation system: we serialized state tags to compact bit vectors so that we could perform fast equality checks at runtime. Later, as part of another project I ended up writing a quick implementation of extended-precision addition and subtraction.

Example usage from the tests:

```haxe
public function testGetSetBlock()
{
    var bitVector = new BitVector();
    
    // Try to set | 0...11 | 10... |
    var inputBlock = 7;
    var blockWidth = 3;
    var startBitIndex = 30;
    bitVector.setBlock(startBitIndex, blockWidth, inputBlock);

    // The vector should be startBitIndex + blockWidth (33) bits in length and span two ints
    assertEquals(2, bitVector.chunkLength);
    assertEquals(33, bitVector.bitLength);
    assertEquals(0x00000003, bitVector.getChunk(0));
    assertEquals(0x80000000, bitVector.getChunk(1));

    // Read the block back
    var outputBlock = bitVector.getBlock(startBitIndex, blockWidth);
    assertEquals(inputBlock, outputBlock);
}
```
