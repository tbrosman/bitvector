package bitvector;

import bitvector.diagnostics.Assert;
import hxmath.math.ShortVector2;

typedef BlitParams =
{
    // The starting X in the target.
    var targetX:Int;

    // The starting Y in the target.
    var targetY:Int;

    // The source BitMap.
    var source:BitMap;

    // The starting X in the source.
    var sourceX:Int;

    // The starting Y in the source.
    var sourceY:Int;

    // The width of the area to copy.
    var copyWidth:Int;

    // The height of the area to copy.
    var copyHeight:Int;
};

/**
 * A 2D bit array. Similar to DenseArray2<Bool>, but implemented using BitVector for optimal space efficiency.
 */
class BitMap
{
    public var keys(get, never):Iterator<ShortVector2>;
    public final height:Int;
    public final width:Int;
    
    private final data:BitVector;
    
    /**
     * Constructor. Build the underlying BitVector and resize it to fit the specified bounds.
     * @param width The width (in bits).
     * @param height The height (in bits).
     */
    public function new(width:Int, height:Int)
    {
        Assert.assert(
            width <= ShortVector2.fieldMax + 1 &&
            height <= ShortVector2.fieldMax + 1,
            "Coordinates must fit in a ShortVector2.");

        this.width = width;
        this.height = height;
        data = new BitVector();
        
        data.fill(width * height, 0);
    }
    
    /**
     * Get the value of a bit.
     * @param x 
     * @param y 
     * @return Int The bit value.
     */
    public function get(x:Int, y:Int):Int
    {
        Assert.assert(inBounds(x, y));
        var index = indexFromPoint(x, y);
        return data.getBit(index);
    }
    
    /**
     * Get a bit by key.
     * @param key The bit location as a vector.
     * @return Int The bit value.
     */
    public function getByKey(key:ShortVector2):Int
    {
        return get(key.x, key.y);
    }
    
    /**
     * Set the value of a bit.
     * @param x
     * @param y 
     * @param bit The bit value.
     */
    public function set(x:Int, y:Int, bit:Int):Void
    {
        Assert.assert(inBounds(x, y));
        var index = indexFromPoint(x, y);
        data.setBit(index, bit);
    }
    
    /**
     * Check whether a particular point is contained in the BitMap.
     * @param x 
     * @param y 
     * @return Bool True if in bounds.
     */
    public function inBounds(x:Int, y:Int):Bool
    {
        return x >= 0 &&
            x < width &&
            y >= 0 &&
            y < height;
    }
    
    /**
     * Fill the BitMap with a single bit value.
     * @param bit The bit value to use.
     */
    public function fill(bit:Int)
    {
        data.fill(width * height, 0);
    }
    
    /**
     * Blit a rectangular section of another BitMap onto this BitMap.
     * 

     * @return              The number of bits written.
     */
    public function blit(params:BlitParams):Int
    {
        final targetX = params.targetX;
        final targetY = params.targetY;
        final source = params.source;
        final sourceX = params.sourceX;
        final sourceY = params.sourceY;
        final copyWidth = params.copyWidth;
        final copyHeight = params.copyHeight;

        if (targetX < 0
            || targetY < 0
            || sourceX < 0
            || sourceY < 0
            || copyWidth <= 0
            || copyHeight <= 0)
        {
            throw 'Invalid parameters Target($targetX, $targetY) Source($sourceX, $sourceY) CopyWidthHeight($copyWidth, $copyHeight)';
        }
        
        if ((targetX + copyWidth > width) || (targetY + copyHeight > height))
        {
            throw 'Overlapping rect Target($targetX, $targetY) Source($sourceX, $sourceY) ' +
                'CopyWidthHeight($copyWidth, $copyHeight) CurrentRect($width, $height)';
        }
        
        var blitCount:Int = 0;
        
        for (y in 0...copyHeight)
        {
            for (x in 0...copyWidth)
            {
                var bit = source.get(x + sourceX, y + sourceY);
                set(x + targetX, y + targetY, bit);
                blitCount++;
            }
        }
        
        return blitCount;
    }
    
    private function indexFromPoint(x:Int, y:Int):Int
    {
        return x + y * width;
    }
    
    private inline function get_keys():Iterator<ShortVector2>
    {
        return new BitMapKeysIterator(this);
    }
}

/**
 * An iterator allowing key iteration similar to SparseArray2.
 */
private class BitMapKeysIterator
{
    private var bitMap:BitMap;
    private var currentX:Int = 0;
    private var currentY:Int = 0;
    
    public function new(bitMap:BitMap)
    {
        this.bitMap = bitMap;
    }
    
    public function hasNext():Bool
    {
        return currentX < bitMap.width &&
            currentY < bitMap.height;
    }
    
    public function next():ShortVector2
    {
        var currentKey = new ShortVector2(currentX, currentY);
        
        // Advance one cell in the current row
        if (currentX + 1 < bitMap.width)
        {
            currentX++;
        }
        
        // Advance one row
        else if (currentY + 1 < bitMap.height)
        {
            currentX = 0;
            currentY++;
        }
        
        // End of the array
        else
        {
            currentX = bitMap.width;
            currentY = bitMap.height;
        }
        
        return currentKey;
    }
}