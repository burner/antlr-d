module antlr.v4.runtime.atn.PrecedencePredicate;

import std.conv;
import antlr.v4.runtime.atn.SemanticContext;
import antlr.v4.runtime.RuleContext;
import antlr.v4.runtime.Recognizer;
import antlr.v4.runtime.atn.ParserATNSimulator;
import antlr.v4.runtime.Token;

// Class PrecedencePredicate
/**
 * TODO add class description
 */
class PrecedencePredicate : SemanticContext
{

    /**
     * @uml
     * @final
     */
    public int precedence;

    protected this()
    {
        this.precedence = 0;
    }

    public this(int precedence)
    {
        this.precedence = precedence;
    }

    /**
     * @uml
     * @override
     */
    public override bool eval(Recognizer!(Token, ParserATNSimulator) parser, RuleContext parserCallStack)
    {
        return parser.precpred(parserCallStack, precedence);
    }

    /**
     * @uml
     * @override
     */
    public override SemanticContext evalPrecedence(Recognizer!(Token, ParserATNSimulator) parser,
        RuleContext parserCallStack)
    {
        if (parser.precpred(parserCallStack, precedence)) {
            return SemanticContext.NONE;
        }
        else {
            return null;
        }
    }

    /**
     * @uml
     * @override
     */
    public override int opCmp(Object o)
    {
        return precedence - (cast(PrecedencePredicate)o).precedence;
    }

    /**
     * @uml
     * @override
     * @safe
     * @nothrow
     */
    public override size_t toHash() @safe nothrow
    {
       	int hashCode = 1;
        hashCode = 31 * hashCode + precedence;
        return hashCode;
    }

    /**
     * @uml
     * @override
     */
    public override bool opEquals(Object obj)
    {
	if (obj.classinfo != PrecedencePredicate.classinfo) {
            return false;
        }

        if (this == obj) {
            return true;
        }

        PrecedencePredicate other = cast(PrecedencePredicate)obj;
        return this.precedence == other.precedence;
    }

    /**
     * @uml
     * @override
     * precedence >= _precedenceStack.peek()
     */
    public override string toString()
    {
        return "{" ~ to!string(precedence) ~ ">=prec}?";
    }

}
