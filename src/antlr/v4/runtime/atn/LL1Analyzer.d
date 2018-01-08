/*
 * [The "BSD license"]
 *  Copyright (c) 2012 Terence Parr
 *  Copyright (c) 2012 Sam Harwell
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

module antlr.v4.runtime.atn.LL1Analyzer;

import std.container.array;
import std.container.rbtree;
import std.conv;
import std.stdio;
import antlr.v4.runtime.RuleContext;
import antlr.v4.runtime.Token;
import antlr.v4.runtime.TokenConstantDefinition;
import antlr.v4.runtime.atn.AbstractPredicateTransition;
import antlr.v4.runtime.atn.ATN;
import antlr.v4.runtime.atn.ATNConfig;
import antlr.v4.runtime.atn.ATNState;
import antlr.v4.runtime.atn.NotSetTransition;
import antlr.v4.runtime.atn.PredictionContext;
import antlr.v4.runtime.atn.RuleTransition;
import antlr.v4.runtime.atn.RuleStopState;
import antlr.v4.runtime.atn.SingletonPredictionContext;
import antlr.v4.runtime.atn.Transition;
import antlr.v4.runtime.atn.WildcardTransition;
import antlr.v4.runtime.misc.IntervalSet;

// Class LL1Analyzer
/**
 * TODO add class description
 */
class LL1Analyzer
{

    public static const int HIT_PRED = TokenConstantDefinition.INVALID_TYPE;

    public ATN atn;

    public this(ATN atn)
    {
        this.atn = atn;
    }

    /**
     * @uml
     * Calculates the SLL(1) expected lookahead set for each outgoing transition
     * if an {@link ATNState}. The returned array has one element for each
     * outgoing transition in {@code s}. If the closure from transition
     * <em>i</em> leads to a semantic predicate before matching a symbol, the
     * element at index <em>i</em> of the result will be {@code null}.
     *
     *  @param s the ATN state
     *  @return the expected symbols for each outgoing transition of {@code s}.
     */
    public IntervalSet[] getDecisionLookahead(ATNState s)
    {
        //		System.out.println("LOOK("+s.stateNumber+")");
        if (s is null) {
            return null;
        }

        IntervalSet[] look = new IntervalSet[s.getNumberOfTransitions()];
        for (int alt = 0; alt < s.getNumberOfTransitions(); alt++) {
            look[alt] = new IntervalSet();
            auto lookBusy = new Array!ATNConfig();
            bool seeThruPreds = false; // fail to get lookahead upon pred
            _LOOK(s.transition(alt).target, null, cast(PredictionContext)PredictionContext.EMPTY,
                  look[alt], lookBusy, new Array!bool(), seeThruPreds, false);
            // Wipe out lookahead for this alternative if we found nothing
            // or we had a predicate when we !seeThruPreds
            if ( look[alt].size()==0 || look[alt].contains(HIT_PRED) ) {
                look[alt] = null;
            }
        }
        return look;
    }

    /**
     * @uml
     * Compute set of tokens that can follow {@code s} in the ATN in the
     * specified {@code ctx}.
     *
     * <p>If {@code ctx} is {@code null} and the end of the rule containing
     * {@code s} is reached, {@link Token#EPSILON} is added to the result set.
     * If {@code ctx} is not {@code null} and the end of the outermost rule is
     * reached, {@link Token#EOF} is added to the result set.</p>
     *
     *  @param s the ATN state
     *  @param ctx the complete parser context, or {@code null} if the context
     * should be ignored
     *
     *  @return The set of tokens that can follow {@code s} in the ATN in the
     * specified {@code ctx}.
     */
    public IntervalSet LOOK(ATNState s, RuleContext ctx)
    {
        return LOOK(s, null, ctx);
    }

    /**
     * @uml
     * Compute set of tokens that can follow {@code s} in the ATN in the
     * specified {@code ctx}.
     *
     * <p>If {@code ctx} is {@code null} and the end of the rule containing
     * {@code s} is reached, {@link Token#EPSILON} is added to the result set.
     * If {@code ctx} is not {@code null} and the end of the outermost rule is
     * reached, {@link Token#EOF} is added to the result set.</p>
     *
     *  @param s the ATN state
     *  @param stopState the ATN state to stop at. This can be a
     *  {@link BlockEndState} to detect epsilon paths through a closure.
     *  @param ctx the complete parser context, or {@code null} if the context
     * should be ignored
     *
     *  @return The set of tokens that can follow {@code s} in the ATN in the
     * specified {@code ctx}.
     */
    public IntervalSet LOOK(ATNState s, ATNState stopState, RuleContext ctx)
    {
        IntervalSet r = new IntervalSet();
        bool seeThruPreds = true; // ignore preds; get all lookahead
        PredictionContext lookContext = ctx !is null ? PredictionContext.fromRuleContext(s.atn, ctx) : null;
        _LOOK(s, stopState, lookContext,
              r, new Array!ATNConfig(),  new Array!bool(), seeThruPreds, true);
        return r;
    }

    /**
     * @uml
     * Compute set of tokens that can follow {@code s} in the ATN in the
     * specified {@code ctx}.
     *
     * <p>If {@code ctx} is {@code null} and {@code stopState} or the end of the
     * rule containing {@code s} is reached, {@link Token#EPSILON} is added to
     * the result set. If {@code ctx} is not {@code null} and {@code addEOF} is
     * {@code true} and {@code stopState} or the end of the outermost rule is
     * reached, {@link Token#EOF} is added to the result set.</p>
     *
     *  @param s the ATN state.
     *  @param stopState the ATN state to stop at. This can be a
     *  {@link BlockEndState} to detect epsilon paths through a closure.
     *  @param ctx The outer context, or {@code null} if the outer context should
     *  not be used.
     *  @param look The result lookahead set.
     *  @param lookBusy A set used for preventing epsilon closures in the ATN
     *  from causing a stack overflow. Outside code should pass
     *  {@code new HashSet<ATNConfig>} for this argument.
     *  @param calledRuleStack A set used for preventing left recursion in the
     *  ATN from causing a stack overflow. Outside code should pass
     *  {@code new BitSet()} for this argument.
     *  @param seeThruPreds {@code true} to true semantic predicates as
     *  implicitly {@code true} and "see through them", otherwise {@code false}
     *  to treat semantic predicates as opaque and add {@link #HIT_PRED} to the
     *  result if one is encountered.
     *  @param addEOF Add {@link Token#EOF} to the result if the end of the
     *  outermost context is reached. This parameter has no effect if {@code ctx}
     *  is {@code null}.
     */
    protected void _LOOK(ATNState s, ATNState stopState, PredictionContext ctx, ref IntervalSet look,
                         Array!ATNConfig* lookBusy, Array!bool* calledRuleStack, bool seeThruPreds, bool addEOF)
    {
        debug
            writefln("LL1Ana:_LOOK(%s, ctx=%s), look = %s", s.stateNumber, ctx, look.intervals);
        ATNConfig c = new ATNConfig(s, 0, ctx);
        foreach(lb; *lookBusy)
            if (lb == c)
                return;
        *lookBusy = *lookBusy ~ c;
        if (s == stopState) {
            if (ctx is null) {
                look.add(TokenConstantDefinition.EPSILON);
                return;
            } else if (ctx.isEmpty && addEOF) {
                look.add(TokenConstantDefinition.EOF);
                return;
            }
        }
        if (s.classinfo == RuleStopState.classinfo) {
            if (ctx is null ) {
                look.add(TokenConstantDefinition.EPSILON);
                return;
            } else if (ctx.isEmpty() && addEOF) {
                look.add(TokenConstantDefinition.EOF);
                return;
            }

            if (ctx != PredictionContext.EMPTY) {
                // run thru all possible stack tops in ctx
                for (int i = 0; i < ctx.size(); i++) {
                    ATNState returnState = atn.states[ctx.getReturnState(i)];
                    //					System.out.println("popping back to "+retState);

                    bool removed = calledRuleStack.opSlice[returnState.ruleIndex];
                    try {
                        calledRuleStack.opIndexAssign(false, returnState.ruleIndex);
                        _LOOK(returnState, stopState, ctx.getParent(i), look, lookBusy, calledRuleStack, seeThruPreds, addEOF);
                    }
                    finally {
                        if (removed) {
                            calledRuleStack.opIndexAssign(true, returnState.ruleIndex);
                        }
                    }
                }
                return;
            }
        }

        int n = s.getNumberOfTransitions;
        for (int i=0; i<n; i++) {
            Transition t = s.transition(i);
            if (t.classinfo == RuleTransition.classinfo) {
                if (calledRuleStack.length >
                    (cast(RuleTransition)t).target.ruleIndex &&
                    (*calledRuleStack)[(cast(RuleTransition)t).target.ruleIndex]) {
                    continue;
                }
                PredictionContext newContext =
                    SingletonPredictionContext.create(ctx, (cast(RuleTransition)t).followState.stateNumber);
                try {
                    if (calledRuleStack.length <= (cast(RuleTransition)t).target.ruleIndex)
                        calledRuleStack.length = (cast(RuleTransition)t).target.ruleIndex +1;
                    calledRuleStack.opIndexAssign(true, (cast(RuleTransition)t).target.ruleIndex);
                    _LOOK(t.target, stopState, newContext, look, lookBusy, calledRuleStack, seeThruPreds, addEOF);
                }
                finally {
                    calledRuleStack.opIndexAssign(false, (cast(RuleTransition)t).target.ruleIndex);
                }
            }
            else if (cast(AbstractPredicateTransition)t) {
                if ( seeThruPreds ) {
                    _LOOK(t.target, stopState, ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF);
                }
                else {
                    look.add(HIT_PRED);
                }
            }
            else if ( t.isEpsilon() ) {
                _LOOK(t.target, stopState, ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF);
            }
            else if (t.classinfo == WildcardTransition.classinfo) {
                look.addAll( IntervalSet.of(TokenConstantDefinition.MIN_USER_TOKEN_TYPE, atn.maxTokenType) );
            }
            else {
                debug
                    writeln("LL1Analyzer: adding " ~ to!string(t));
                IntervalSet set = t.label();
                if (set !is null) {
                    if (cast(NotSetTransition)t) {
                        set = set.complement(IntervalSet.of(TokenConstantDefinition.MIN_USER_TOKEN_TYPE, atn.maxTokenType));
                    }
                    look.addAll(set);
                }
            }
        }
    }

}
