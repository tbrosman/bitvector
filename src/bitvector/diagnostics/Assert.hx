package bitvector.diagnostics;

import haxe.PosInfos;

class Assert
{
    public static function assert(value:Bool, ?message:String, ?pos:PosInfos):Void
    {
        if (!value)
        {
            showAssert('assert($value)', message, pos);
        }
    }

    private static function showAssert(predicate:String, ?message:String, ?pos:PosInfos):Void
    {
        if (message == null)
        {
            message = "<no message>";
        }
        
        var assertMessage = 'Assert failed: $predicate, $message, Position: $pos';
        throw new AssertException(assertMessage);
    }
}