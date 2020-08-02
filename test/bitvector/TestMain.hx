package bitvector;

import bitvector.test.BitVectorTestCase;
import haxe.unit.TestRunner;

class TestMain
{
    public static function main():Void
    {
        var runner = new TestRunner();
        runner.add(new BitVectorTestCase());
        runner.run();
    }
}