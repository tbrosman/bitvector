package bitvector.diagnostics;

/**
 * The kind of object thrown by asserts.
 */
class AssertException
{
    public final message:String;

    public function new(message:String)
    {
        this.message = message;
    }

    public function toString():String
    {
        return message;
    }
}