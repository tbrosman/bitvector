package bitvector.test;

import haxe.unit.TestCase;

class BitVectorTestCase extends TestCase
{
    public function new()
    {
        super();
    }

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

    public function testGetRightAligned()
    {
        var bitVector = new BitVector();

        var inputBlock = 5;
        var blockWidth = 3;
        var startBitIndex = 32;

        bitVector.setBlock(startBitIndex, blockWidth, inputBlock);
        assertEquals(2, bitVector.chunkLength);
        assertEquals(35, bitVector.bitLength);

        var alignedBitVector = bitVector.getRightAlignedBitVector();
        assertEquals(2, alignedBitVector.chunkLength);
        assertEquals(64, alignedBitVector.bitLength);
        assertEquals(0, alignedBitVector.getChunk(0));
        assertEquals(inputBlock, alignedBitVector.getChunk(1));
    }

    public function testGetFirstSetBit()
    {
        var bitVector = new BitVector();
        var bitIndex = 36;

        bitVector.setFlag(bitIndex, true);
        bitVector.setFlag(38, true);
        assertEquals(2, bitVector.chunkLength);
        assertEquals(bitIndex, bitVector.firstSetBitIndex());
    }

    public function testFill()
    {
        var bitVector = new BitVector();
        var fillLength = 35;

        bitVector.fill(fillLength, 1);
        assertEquals(2, bitVector.chunkLength);
        assertEquals(0xFFFFFFFF, bitVector.getChunk(0));
        assertEquals(0xE0000000, bitVector.getChunk(1));
    }

    public function testEquals()
    {
        var bitVectorA = new BitVector();
        bitVectorA.setBlock(30, 4, 0xC);

        var bitVectorB = new BitVector();
        bitVectorB.setBlock(30, 4, 0xC);

        assertTrue(bitVectorA.equals(bitVectorB));
    }

    public function testZero()
    {
        var bitVector = new BitVector();
        assertTrue(bitVector.zero());

        bitVector.setBlock(36, 4, 0xC);
        assertFalse(bitVector.zero());
    }

    public function testFromHexString()
    {
        // Should give two chunks: [ 0x0000000C, 0xF0000000 ]
        var inputString = "0000000CF";
        var bitVector = BitVector.fromHexString(inputString);
        
        assertEquals(2, bitVector.chunkLength);
        assertEquals(36, bitVector.bitLength);
        assertEquals(0x0000000C, bitVector.getChunk(0));
        assertEquals(0xF0000000, bitVector.getChunk(1));
    }

    public function testToHexString()
    {
        var bitVector = new BitVector();
        bitVector.setBlock(28, 8, 0xCF);

        var hexString = bitVector.toHexString();
        assertEquals("0000000CF", hexString);
    }

    public function testFromBinString()
    {
        var zeroByteString = "00000000";

        // Hex: 0000 0005 A
        var inputString = zeroByteString + zeroByteString + zeroByteString + "00000101" + "101";
        var bitVector = BitVector.fromBinString(inputString);
        
        assertEquals(2, bitVector.chunkLength);
        assertEquals(5, bitVector.getChunk(0));
        assertEquals(0xA0000000, bitVector.getChunk(1));
    }

    public function testToBinString()
    {
        var zeroByteString = "00000000";

        // Hex: 0000 0005 A, but we are writing "101101" (0x2D) in a 6-bit block
        var expectedString = zeroByteString + zeroByteString + zeroByteString + "00000101" + "101";
        var bitVector = new BitVector();
        bitVector.setBlock(29, 6, 0x2D);

        assertEquals(expectedString, bitVector.toBinString());
    }

    public function testGetBlockPadded()
    {
        var bitVector = new BitVector();
        bitVector.setBlock(0, 32, 0x80018001);

        assertEquals(0x18, bitVector.getBlockPadded(12, 8));
        assertEquals(0x01, bitVector.getBlockPadded(-7, 8));
        assertEquals(0x80, bitVector.getBlockPadded(31, 8));
    }

    public function testShiftLeft()
    {
        var bitVector = new BitVector();
        bitVector.setBlock(33, 1, 1);
        var shiftedBitVector = bitVector.getShiftedLeft(33);

        assertEquals(1, shiftedBitVector.chunkLength);
        assertEquals(0x80000000, shiftedBitVector.getChunk(0));
    }

    public function testAddNoOverflow()
    {
        var numberA = new BitNumber();
        numberA.setBlock(33, 1, 1);
        var numberB = new BitNumber();
        numberB.setBlock(33, 2, 2);

        var result = numberA.add(numberB);

        assertEquals(2, result.bitLength);
        assertEquals(3, result.getBlock(0, 2));
    }

    public function testAddWithOverflow()
    {
        var numberA = new BitNumber();
        numberA.setBlock(0, 32, 0xFFFFFFFF);
        var numberB = new BitNumber();
        numberB.setBlock(0, 32, 0x00000001);

        var result = numberA.add(numberB);

        assertEquals(33, result.bitLength);
        assertEquals(0x80000000, result.getChunk(0));
        assertEquals(0, result.getChunk(1));
    }

    public function testSubtractNoUnderflow()
    {
        var numberA = new BitNumber();
        numberA.setBlock(33, 2, 3);
        var numberB = new BitNumber();
        numberB.setBlock(33, 2, 2);

        var result = numberA.subtract(numberB);

        assertEquals(1, result.bitLength);
        assertEquals(1, result.getBlock(0, 1));
    }

    public function testSubtractWithUnderflow()
    {
        var numberA = new BitNumber();
        numberA.setBlock(33, 2, 2);
        var numberB = new BitNumber();
        numberB.setBlock(33, 2, 3);

        //        . bit 32       . bit 32
        //   0...|010   -   0...|011
        // = 0...|010   +   1...|100 + 1 (complement, add carry bit)
        // = 1...|1111                   (extra bit added for overflow/underflow)
        var result = numberA.subtract(numberB);

        // In the case of overflow, the length of the result will be the max of the input lengths plus 1
        assertEquals(36, result.bitLength);
        assertEquals(0xFFFFFFFF, result.getChunk(0));
        assertEquals(0xF0000000, result.getChunk(1));
    }

    public function testShift()
    {
        var bitVector = new BitVector();
        bitVector.setBlock(0, 32, 0x00010000);
        bitVector.setBlock(32, 16, 0x0001);

        var shifted = bitVector.getShiftedLeft(15);
        
        assertEquals(33, shifted.bitLength);
        assertEquals(0x80000000, shifted.getChunk(0));
        assertEquals(1, shifted.getBlock(32, 1));
    }

    /**
     * Subtract two vectors where one of the blocks starts before the 0 bit.
     */
    public function testSubtractBlockOverlap()
    {
        // 0x00000008
        var a = new BitNumber();
        a.setBlock(28, 4, 8);
        
        // 0x3
        var b = new BitNumber();
        b.setBlock(0, 4, 3);

        var c = a.subtract(b);
        assertEquals(3, c.bitLength);
        assertEquals(5, c.getBlock(0, 3));
    }

    public function testSetBlockAutosize()
    {
        var has0BitValue = new BitNumber();
        has0BitValue.setBlockAutosize(0, 0);
        assertEquals(0, has0BitValue.bitLength);

        var has32BitValue = new BitNumber();
        has32BitValue.setBlockAutosize(0, 0x80000000);
        assertEquals(32, has32BitValue.bitLength);
        assertEquals(0x80000000, has32BitValue.getBlock(0, 32));

        var has5BitValue = new BitNumber();
        has5BitValue.setBlockAutosize(0, 0x1F);
        assertEquals(5, has5BitValue.bitLength);
        assertEquals(0x1F, has5BitValue.getBlock(0, 5));
    }

    public function testLessThanOrEqual_twoChunk()
    {
        var a = new BitNumber();
        a.setBlock(0, 1, 1);
        a.setBlock(1, 32, 1);

        var b = new BitNumber();
        b.setBlock(0, 1, 1);
        b.setBlock(1, 32, 2);

        assertTrue(a.lessThanOrEqual(b));
        assertFalse(b.lessThanOrEqual(a));
    }

    public function testLessThanOrEqual_leadingZeroes()
    {
        var a = new BitNumber();
        a.setBlock(1, 32, 1);
        var b = BitNumber.fromBitVector(BitVector.fromUnsignedInt(2));

        assertTrue(a.lessThanOrEqual(b));
        assertFalse(b.lessThanOrEqual(a));
    }

    public function testLessThanOrEqual_leadingZeroesEqual()
    {
        var a = new BitNumber();
        a.setBlock(1, 32, 1);
        var b = BitNumber.fromBitVector(BitVector.fromUnsignedInt(1));

        assertTrue(a.lessThanOrEqual(b));
        assertTrue(b.lessThanOrEqual(a));
    }
}