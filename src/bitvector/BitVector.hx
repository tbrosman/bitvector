package bitvector;

import bitvector.diagnostics.Assert;
import hxmath.math.MathUtil;

/**
 * A vector of bits. Stores the bits internally in an array of Ints.
 */
class BitVector
{
    public static inline var bitsPerChunk:Int = 32;
    public var chunkLength(get, never):Int;
    public var bitLength(default, null):Int = 0;

    private var chunks:Array<Int> = new Array<Int>();

    public function new()
    {
    }

    /**
     * Clone the vector.
     * @return BitVector A copy of the vector. Shares no pointers with the original.
     */
    public function clone():BitVector
    {
        var copy = new BitVector();
        copy.chunks = chunks.copy();
        copy.bitLength = bitLength;
        
        return copy;
    }

    /**
     * Check if the vector is zero.
     * @return Bool True if all chunks are zero.
     */
    public function zero():Bool
    {
        for (chunk in chunks)
        {
            if (chunk != 0)
            {
                return false;
            }
        }

        return true;
    }

    /**
     * Fill the vector with a specific bit value.
     * @param fillBitLength The number of bits to fill.
     * @param value The bit value.
     */
    public function fill(fillBitLength:Int, bit:Int)
    {
        assertIsBit(bit);
        var fullChunkPattern = bit == 0 ? 0x00000000 : 0xFFFFFFFF;
        var fullChunksToBlit = getChunkIndex(fillBitLength);

        for (chunkIndex in 0...fullChunksToBlit)
        {
            chunks[chunkIndex] = fullChunkPattern;
        }

        // Is there a partial chunk?
        var chunkBoundaryBitIndex = buildBitIndex(fullChunksToBlit, 0);
        if (chunkBoundaryBitIndex < fillBitLength)
        {
            var patternOffset = bitsPerChunk - (fillBitLength - chunkBoundaryBitIndex);
            var pattern = fullChunkPattern << patternOffset;
            chunks[fullChunksToBlit] = pattern;
        }

        bitLength = MathUtil.intMax(bitLength, fillBitLength);
    }

    /**
     * Get a left-shifted bit vector.
     * @param shiftBitCount The number of bits to shift by.
     * @return BitVector The left-shifted bit vector.
     */
    public function getShiftedLeft(shiftBitCount:Int):BitVector
    {
        Assert.assert(shiftBitCount >= 0);

        var targetBitVector = new BitVector();
        var targetBitLength = bitLength - shiftBitCount;

        // Slow implementation
        for (targetBitIndex in 0...targetBitLength)
        {
            var sourceBitIndex = targetBitIndex + shiftBitCount;
            targetBitVector.setFlag(targetBitIndex, getFlag(sourceBitIndex));
        }

        return targetBitVector;
    }

    /**
     * Set all bits to 0. Does not modify bitLength.
     */
    public function clear()
    {
        for (i in 0...chunks.length)
        {
            chunks[i] = 0;
        }
    }

    /**
     * Get the bit (as a Bool) at index where index 0 is the leftmost/most significant bit.
     * @param index The bit index.
     * @return Bool The bit value.
     */
    public function getFlag(bitIndex:Int):Bool
    {
        return getBit(bitIndex) == 1;
    }

    /**
     * Get the bit (as an Int) at index where index 0 is the leftmost/most significant bit.
     * @param index The bit index.
     * @return Bool The bit value.
     */
    public function getBit(bitIndex:Int):Int
    {
        Assert.assert(bitIndex < bitLength);

        var chunkIndex:Int = getChunkIndex(bitIndex);
        var chunkBit:Int = getChunkBit(bitIndex);
        return (chunks[chunkIndex] >> (bitsPerChunk - 1 - chunkBit)) & 1;
    }

    /**
     * Get a bit substring up to the size of Int.
     * @param startBitIndex The starting index.
     * @param blockWidth The width of the block in bits. Must be smaller than the max bitsPerChunk (which is the bit length of Int).
     * @return Int The block value.
     */
    public function getBlock(startBitIndex:Int, blockWidth:Int):Int
    {
        Assert.assert(startBitIndex >= 0 && blockWidth >= 1);
        Assert.assert(blockWidth <= bitsPerChunk);
        Assert.assert((startBitIndex + blockWidth) <= bitLength);

        // Build the block right-aligned to start
        var rightCombinedBlock:Int = 0;
        
        var firstChunkIndex = getChunkIndex(startBitIndex);
        var secondChunkIndex = getChunkIndex(startBitIndex + blockWidth - 1);
        var localStartBitIndex = startBitIndex - bitsPerChunk * firstChunkIndex;
        var firstAlignedBlock = chunks[firstChunkIndex] << localStartBitIndex;
        rightCombinedBlock = firstAlignedBlock;

        if (firstChunkIndex != secondChunkIndex)
        {
            var leftOffset = bitsPerChunk - localStartBitIndex;
            var secondAlignedBlock = chunks[secondChunkIndex] >>> leftOffset;
            rightCombinedBlock |= secondAlignedBlock;
        }

        var combinedBlock = rightCombinedBlock >>> (bitsPerChunk - blockWidth);
        return combinedBlock;
    }

    /**
     * Get a block starting on an index that may be negative. Out-of-bounds bits will be 0.
     * @param startBitIndex The starting index, potentially negative.
     * @param blockWidth The width of the block in bits.
     * @return Int The block value.
     */
    public function getBlockPadded(startBitIndex:Int, blockWidth:Int):Int
    {
        var adjustedStartBitIndex = startBitIndex;
        var adjustedBlockWidth = blockWidth;
        var leftShiftAmount = 0;

        if (adjustedStartBitIndex < 0)
        {
            adjustedStartBitIndex = 0;
            adjustedBlockWidth = blockWidth + startBitIndex;
        }

        if ((adjustedStartBitIndex + adjustedBlockWidth) > bitLength)
        {
            var rightOverlap = (adjustedStartBitIndex + adjustedBlockWidth) - bitLength;
            adjustedBlockWidth -= rightOverlap;
            leftShiftAmount += rightOverlap;
        }

        if (adjustedBlockWidth > 0)
        {
            return getBlock(adjustedStartBitIndex, adjustedBlockWidth) << leftShiftAmount;
        }
        else 
        {
            return 0;
        }
    }

    /**
     * Get the chunk at the specified chunkIndex. Used for implementing fast copies/etc. Most consumers should use getBlock instead.
     * @param chunkIndex The index of the chunk.
     * @return Int The chunk.
     */
    public function getChunk(chunkIndex:Int):Int
    {
        Assert.assert(chunkIndex < chunks.length);
        return chunks[chunkIndex];
    }    

    /**
     * Set a single bit (as a Bool).
     * @param bitIndex The index of the bit to set.
     * @param value The bit value.
     */
    public function setFlag(bitIndex:Int, value:Bool):Void
    {
        setBit(bitIndex, value ? 1 : 0);
    }

    /**
     * Set a single bit (as an Int).
     * @param bitIndex The index of the bit to set.
     * @param value The bit value.
     */
    public function setBit(bitIndex:Int, bit:Int):Void
    {
        assertIsBit(bit);
        var chunkIndex:Int = getChunkIndex(bitIndex);
        var chunkBit:Int = getChunkBit(bitIndex);
        ensureSizeForChunkIndex(chunkIndex);

        // Bit indexes start from the left-hand side, but 1 is on the right-hand side
        var shiftBits = bitsPerChunk - 1 - chunkBit;
        
        if (bit == 1)
        {
            chunks[chunkIndex] = chunks[chunkIndex] | (1 << shiftBits);
        }
        else
        {
            chunks[chunkIndex] = chunks[chunkIndex] & ~(1 << shiftBits);
        }

        bitLength = MathUtil.intMax(bitLength, bitIndex + 1);
    }

    /**
     * Set a single block of the specified width.
     * @param startBitIndex The starting index.
     * @param blockWidth The width of the block. Must be smaller than the max bitsPerChunk (which is the bit length of Int).
     * @param block The block value.
     */
    public function setBlock(startBitIndex:Int, blockWidth:Int, block:Int):Void
    {
        var maxValue:Int = blockWidth == bitsPerChunk ? 0xFFFFFFFF : (1 << blockWidth) - 1;

        if (block & ~maxValue != 0)
        {
            throw "Invalid bounds";
        }

        // Special case for zero. Otherwise, the chunk indices below are incorrect.
        if (blockWidth == 0)
        {
            return;
        }

        var rightAlignedBlock = block << (bitsPerChunk - blockWidth);

        //   chunk n     chunk n+1
        // | xxxbbb... | ...bbbxxx |
        //      ^ bit 0|      ^ bit (blockWidth - 1)
        var firstChunkIndex = getChunkIndex(startBitIndex);
        var secondChunkIndex = getChunkIndex(startBitIndex + blockWidth - 1);

        var localStartBitIndex = startBitIndex - bitsPerChunk * firstChunkIndex;
        var firstAlignedChunk = rightAlignedBlock >>> localStartBitIndex;
        chunks[firstChunkIndex] |= firstAlignedChunk;

        if (firstChunkIndex != secondChunkIndex)
        {
            var leftOffset = bitsPerChunk - localStartBitIndex;
            var secondAlignedChunk = rightAlignedBlock << leftOffset;
            chunks[secondChunkIndex] |= secondAlignedChunk;
        }

        bitLength = MathUtil.intMax(bitLength, startBitIndex + blockWidth);
    }

    /**
     * Set a block and automatically calculate the width.
     * @param startBitIndex The starting index.
     * @param block The block.
     */
    public function setBlockAutosize(startBitIndex:Int, block:Int):Void
    {
        var blockWidth = 0;
        
        if (block != 0)
        {
            // Slow/non-fancy floor(log2(block))
            for (i in 0...bitsPerChunk)
            {
                var bitMask = 1 << (31 - i);
                if ((block & bitMask) != 0)
                {
                    blockWidth = (31 - i) + 1;
                    break;
                }
            }
        }

        setBlock(startBitIndex, blockWidth, block);
    }

    /**
     * Right-align a BitVector so that the least-significant bit is the right-most bit of the last chunk.
     * 
     * Example: if the input is a run of 33 1-bits followed by 31 0-bits, the output will be a right-aligned run of 33 1-bits.
     * 
     *         chunk 0  | chunk 1
     * input:  FFFFFFFF | 80000000
     * output: 00000001 | FFFFFFFF
     */
    public function getRightAlignedBitVector():BitVector
    {
        var paddedBitLength = bitsPerChunk * Math.ceil(bitLength / bitsPerChunk);
        return getPaddedBitVector(paddedBitLength);
    }

    /**
     * Create a copy of this BitVector with zeroes padding the left side.
     * @param paddedBitLength The length of the new vector.
     * @return BitVector A copy of this vector with (paddedBitLength - bitLength) additional leading zeroes.
     */
    public function getPaddedBitVector(paddedBitLength:Int):BitVector
    {
        Assert.assert(paddedBitLength >= bitLength);

        var paddedBitVector = new BitVector();
        var bitOffset = paddedBitLength - bitLength;

        paddedBitVector.chunks.resize(Math.ceil(paddedBitLength / bitsPerChunk));

        for (sourceBitIndex in 0...bitLength)
        {
            var targetBitIndex = sourceBitIndex + bitOffset;
            var bit = getFlag(sourceBitIndex);
            paddedBitVector.setFlag(targetBitIndex, bit);
        }

        return paddedBitVector;
    }

    /**
     * Get the index of the first set bit.
     * @return Int The index.
     */
    public function firstSetBitIndex():Int
    {
        for (bitIndex in 0...bitLength)
        {
            if (getFlag(bitIndex))
            {
                return bitIndex;
            }
        }

        // Empty or zero
        return -1;
    }

    /**
     * Exact bitwise equality between all chunks.
     * @param b The BitVector to check against.
     * @return Bool True if equal.
     */
    public function equals(b:BitVector):Bool
    {
        if (bitLength != b.bitLength)
        {
            return false;
        }

        for (chunkIndex in 0...chunkLength)
        {
            var chunkA = chunks[chunkIndex];
            var chunkB = b.chunks[chunkIndex];

            if (chunkA != chunkB)
            {
                return false;
            }
        }

        return true;
    }

    /**
     * Create a BitVector from an unsigned int.
     * @param number An int. Interpreted as unsigned.
     * @return BitVector The equivalent BitVector.
     */
    public static function fromUnsignedInt(number:Int):BitVector
    {
        var bitVector = new BitVector();
        bitVector.setBlockAutosize(0, number);
        return bitVector;
    }

    /**
     * Create a BitVector from a hex string.
     * @param hexString The input string. May only contain hex digits.
     * @return BitVector The bit vector.
     */
    public static function fromHexString(hexString:String):BitVector
    {
        var number = new BitVector();
        number.fill(4 * hexString.length, 0);
        
        for (nibbleIndex in 0...hexString.length)
        {
            var charCode:Int = nibbleIndex >= 0 ? hexString.charCodeAt(nibbleIndex) : "0".charCodeAt(0);
            var digit:Int;

            if (charCode >= "0".charCodeAt(0) && charCode <= "9".charCodeAt(0))
            {
                digit = charCode - "0".charCodeAt(0);
            }
            else if (charCode >= "a".charCodeAt(0) && charCode <= "f".charCodeAt(0))
            {
                digit = 10 + charCode - "a".charCodeAt(0);
            }
            else if (charCode >= "A".charCodeAt(0) && charCode <= "F".charCodeAt(0))
            {
                digit = 10 + charCode - "A".charCodeAt(0);
            }
            else
            {
                throw "Invalid digit";
            }

            number.setBlock(4 * nibbleIndex, 4, digit);
        }

        return number;
    }

    /**
     * TODO: Align for number case?
     * Get the hex string form of the vector. Note that this left-aligned: each digit in the string represents a nibble aligned with
     * the chunk boundaries. For example, the BitVector containing "111" in binary will be printed as "E", not "7" (which would be
     * right-aligned).
     * @return String The hex string with uppercase letters.
     */
    public function toHexString():String
    {
        var zero = "0".charCodeAt(0);
        var letterA = "A".charCodeAt(0);
        var resultBuffer = new StringBuf();
        var nibbleLength = Math.ceil(bitLength / 4);
        for (nibbleIndex in 0...nibbleLength)
        {
            var nibble = getBlockPadded(4 * nibbleIndex, 4);
            
            resultBuffer.addChar(
                nibble < 10
                    ? zero + nibble
                    : letterA + (nibble - 10));
        }

        return resultBuffer.toString();
    }

    /**
     * Create a BitVector from a binary string.
     * @param binString A string of 1s and 0s.
     * @return BitVector The bit vector.
     */
    public static function fromBinString(binString:String):BitVector
    {
        var zero = "0".charCodeAt(0);
        var one = "1".charCodeAt(0);

        var number = new BitVector();
        number.fill(binString.length, 0);

        for (bitIndex in 0...binString.length)
        {
            var charCode:Int = binString.charCodeAt(bitIndex);
            var digit:Bool;

            if (charCode == zero)
            {
                digit = false;
            }
            else if (charCode == one)
            {
                digit = true;
            }
            else
            {
                throw "Invalid digit";
            }

            number.setFlag(bitIndex, digit);
        }

        return number;
    }

    /**
     * Get the hex string form of the vector.
     * @return String The bin string.
     */
    public function toBinString():String
    {
        var zero = "0".charCodeAt(0);
        var one = "1".charCodeAt(0);
        var resultBuffer = new StringBuf();
        for (bitIndex in 0...bitLength)
        {
            resultBuffer.addChar(getFlag(bitIndex) ? one : zero);
        }

        return resultBuffer.toString();
    }

    private function ensureSizeForChunkIndex(chunkIndex:Int):Void
    {
        var newChunkLength = chunkIndex + 1;
        if (chunks.length < newChunkLength)
        {
            chunks.resize(newChunkLength);
        }
    }

    private function get_chunkLength():Int
    {
        return chunks.length;
    }

    private static function getChunkIndex(index:Int):Int
    {
        return index >>> 5;
    }

    private static function getChunkBit(index:Int):Int
    {
        return index & 0x1F;
    }

    private static function buildBitIndex(chunkIndex:Int, chunkBit:Int):Int
    {
        Assert.assert(chunkBit < bitsPerChunk);
        return (chunkIndex << 5) | chunkBit;
    }

    private static inline function assertIsBit(value:Int):Void
    {
        Assert.assert(value & ~1 == 0);
    }
}