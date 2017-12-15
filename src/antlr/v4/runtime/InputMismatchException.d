module antlr.v4.runtime.InputMismatchException;

import antlr.v4.runtime.RecognitionException;
import antlr.v4.runtime.Token;
import antlr.v4.runtime.Parser;

// Class InputMismatchException
/**
 * @uml
 * This signifies any kind of mismatched input exceptions such as
 * when the current input does not match the expected token.
 */
class InputMismatchException : RecognitionException
{

    public this(Parser recognizer)
    {
	super(recognizer, recognizer.getInputStream(), recognizer.ctx_);
        this.setOffendingToken(recognizer.getCurrentToken());
    }

}
