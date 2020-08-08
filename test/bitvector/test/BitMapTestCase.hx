package bitvector.test;

import hxmath.math.ShortVector2;
import haxe.unit.TestCase;

class BitMapTestCase extends TestCase
{
    public function new()
    {
        super();
    }

    public function testSimpleSet():Void
    {
        var map = new BitMap(23, 41);
        map.set(4, 5, 1);

        assertEquals(0, map.get(4, 4));
        assertEquals(1, map.get(4, 5));
    }

    public function testBlit():Void
    {
        /**
         * 0000
         * 0010
         * 0000
         */
        var mapA = new BitMap(4, 3);
        mapA.set(2, 1, 1);

        /**
         * 0000
         * 1000
         * 0000
         */
        var mapB = new BitMap(5, 5);
        mapB.set(0, 1, 1);

        /**
         * Blit mapA (x: 0, y: 1, w: 3, h: 2) onto mapB at (x: 1, y: 1)
         * 
         * Sources | From mapA | From mapB | Result | Bit keys in mapB
         *         |           |           |        |
         * bbbb    | ....      | 0000      | 0000   | (0, 1)
         * baaa    | .001      | 1...      | 1001   | (3, 1)
         * baaa    | .000      | 0...      | 0000   |
         */
        var bitsWritten = mapB.blit({
            targetX: 1,
            targetY: 1,
            source: mapA,
            sourceX: 0,
            sourceY: 1,
            copyWidth: 3,
            copyHeight: 2
        });
        assertEquals(6, bitsWritten);

        var setBitKeys = new Array<ShortVector2>();
        for (key in mapB.keys)
        {
            if (mapB.getByKey(key) == 1)
            {
                trace('${key.x}, ${key.y}');
                setBitKeys.push(key);
            }
        }

        assertEquals(2, setBitKeys.length);
        assertTrue(setBitKeys.indexOf(new ShortVector2(0, 1)) != -1);
        assertTrue(setBitKeys.indexOf(new ShortVector2(3, 1)) != -1);
    }
}