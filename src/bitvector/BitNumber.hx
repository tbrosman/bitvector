package bitvector;

import hxmath.math.MathUtil;

/**
 * A simple BigInt implementation built on top of BitVector. Last bit (highest index) is the least-significant.
 */
class BitNumber extends BitVector
{
    public static function fromBitVector(bitVector:BitVector):BitNumber
    {
        var number = new BitNumber();
        number.chunks = bitVector.chunks;
        number.bitLength = bitVector.bitLength;
        return number;
    }

    /**
     * Get an equivalent BitNumber with leading zeroes removed.
     * @return BitNumber The trimmed number.
     */
    public function getTrimmed():BitNumber
    {
        // Remove the leading 0s
        var highBitIndex = firstSetBitIndex();
        return highBitIndex == -1
            ? this
            : BitNumber.fromBitVector(getShiftedLeft(highBitIndex));
    }

    /**
     * The number of bits contributing to the numeric value.
     * @return Int The number of bits, which is also floor(log_2(N)).
     */
    public function significantBitCount():Int
    {
        var highBitIndex = firstSetBitIndex();
        return highBitIndex == -1
            ? 0
            : bitLength - highBitIndex;
    }

    /**
     * Subtract b from this BitNumber and return the result. Does not modify this number.
     * @param b The number to subtract.
     * @return BitNumber The result.
     */
    public function subtract(b:BitNumber):BitNumber
    {
        return addOrSubtract(this, b, true);
    }

    /**
     * Add b to this BitNumber and return the result. Does not modify this number.
     * @param b The number to add.
     * @return BitNumber The result.
     */
    public function add(b:BitNumber):BitNumber
    {
        return addOrSubtract(this, b, false);
    }

    /**
     * Check if this BitNumber is less than or equal to the other number.
     * @param b The right-hand number.
     * @return Bool True if this <= b
     */
    public function lessThanOrEqual(b:BitNumber):Bool
    {
        var a = this;
        var bitsToCheck = MathUtil.intMax(a.bitLength, b.bitLength);

        // Index from the end (index of least significant = 0): a and b may have different numbers of leading zeroes
        // Example (the index is reverseBitIndex):
        // A: 3 bits              |1 |0 |0 |
        // B: 5 bits        |0 |0 |0 |1 |1 |
        // bitIndex:         0  1  2  3  4
        // reverseBitIndex:  5  4  3  2  1
        // bitIndexA:        0  1  2  3  4
        // bitIndexB:       -2 -1  0  1  2
        // We will stop at bitIndex = 2. All previous bits are equal, and A[2] > B[0].
        for (bitIndex in 0...bitsToCheck)
        {
            // Flip the index. We want to start counting at the most-significant bit.
            var reverseBitIndex = bitsToCheck - bitIndex;

            // Calculate the offsets individually. This way we align the least-significant digits.
            var bitIndexA = a.bitLength - reverseBitIndex;
            var aBit = bitIndexA < a.bitLength ? a.getFlag(bitIndexA) : false;
            var bitIndexB = b.bitLength - reverseBitIndex;
            var bBit = bitIndexB < b.bitLength ? b.getFlag(bitIndexB) : false;

            if (!aBit && bBit)
            {
                return true;
            }
            else if (aBit && !bBit)
            {
                return false;
            }
        }

        // Equal
        return true;
    }

    private static function addOrSubtract(a:BitNumber, b:BitNumber, sub:Bool = false):BitNumber
    {
        var bitsPerHalfChunk = BitVector.bitsPerChunk >> 1;
        var halfChunkMask = 0xFFFF;
        var carry:Int = sub ? 1 : 0;
        var c:BitNumber = new BitNumber();
        
        var minBitLength = MathUtil.intMax(a.bitLength, b.bitLength) + 1;

        // Don't bother calculating whether there will be overflow, just add an extra half-chunk
        var halfChunkLengthC = Math.ceil(minBitLength / bitsPerHalfChunk);
        c.fill(bitsPerHalfChunk * halfChunkLengthC, false);

        // Split in half to make handling overflow easier
        for (halfChunkIndexReverse in 0...halfChunkLengthC)
        {
            var reverseBitOffset = bitsPerHalfChunk * (halfChunkIndexReverse + 1);
            var blockIndexA = a.bitLength - reverseBitOffset;
            var blockIndexB = b.bitLength - reverseBitOffset;
            var blockIndexC = c.bitLength - reverseBitOffset;
            
            var blockA = a.getBlockPadded(blockIndexA, bitsPerHalfChunk);
            var blockB = b.getBlockPadded(blockIndexB, bitsPerHalfChunk);

            if (sub)
            {
                // Invert the block (two's complement)
                blockB = halfChunkMask & ~blockB;
            }

            var result = blockA + blockB + carry;
            carry = result >> bitsPerHalfChunk;
            var blockC = halfChunkMask & result;

            c.setBlock(blockIndexC, bitsPerHalfChunk, blockC);
        }

        // If leading 1s were introduced by underflow, trim to the min size.
        // Otherwise, trim all leading zeroes.
        var trimmedC = c.getFlag(0)
            ? BitNumber.fromBitVector(c.getShiftedLeft(c.bitLength - minBitLength))
            : c.getTrimmed();

        return trimmedC;
    }
}