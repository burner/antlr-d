/*
 * [The "BSD license"]
 *  Copyright (c) 2016 Terence Parr
 *  Copyright (c) 2016 Sam Harwell
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

module antlr.v4.runtime.ANTLRErrorListener;

import antlr.v4.runtime.RecognitionException;
import antlr.v4.runtime.Recognizer;
import antlr.v4.runtime.atn.ATNSimulator;

// Interface ANTLRErrorListener
/**
 * TODO add interface description
 */
interface ANTLRErrorListener
{

    /**
     * @uml
     * Upon syntax error, notify any interested parties. This is not how to
     * recover from errors or compute error messages. {@link ANTLRErrorStrategy}
     * specifies how to recover from syntax errors and how to compute error
     * messages. This listener's job is simply to emit a computed message,
     * though it has enough information to create its own message in many cases.
     *
     * <p>The {@link RecognitionException} is non-null for all syntax errors except
     * when we discover mismatched token errors that we can recover from
     * in-line, without returning from the surrounding rule (via the single
     * token insertion and deletion mechanism).</p>
     *
     *  @param recognizer
     *         What parser got the error. From this
     * 		  object, you can access the context as well
     * 		  as the input stream.
     *  @param offendingSymbol
     *        The offending token in the input token
     * 		  stream, unless recognizer is a lexer (then it's null). If
     * 		  no viable alternative error, {@code e} has token at which we
     * 		  started production for the decision.
     *  @param line
     * 		  The line number in the input where the error occurred.
     *  @param charPositionInLine
     * 		  The character position within that line where the error occurred.
     *  @param msg
     * 		  The message to emit.
     *  @param e
     *        The exception generated by the parser that led to
     *        the reporting of an error. It is null in the case where
     *        the parser was able to recover in line without exiting the
     *        surrounding rule.
     */
    public void syntaxError(Recognizer!(void, ATNSimulator) recognizer, Object offendingSymbol,
        int line, int charPositionInLine, string msg, RecognitionException e);

}
