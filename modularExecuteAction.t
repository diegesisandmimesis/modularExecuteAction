#charset "us-ascii"
//
// modularExecuteAction.t
//
//	This is a replacement for adv3's default executeAction() function,
//	re-organized to make updates and modifications easier.
//
//	The code from executeAction() is found in lib/adv3/exec.t in the
//	TASD3 source.  The original code carries the following copyright
//	message:
//
//	/* 
//	 *   Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved. 
//	 *   
//	 *   TADS 3 Library: command execution
//	 *
//	 *   This module defines functions that perform command execution.
//	 */
//
//	The modularExecuteAction module is distributed under the MIT license,
//	a copy of which can be found in LICENSE.txt in the top level of the
//	module source.
//
//
#include <adv3.h>
#include <en_us.h>

#include "modularExecuteAction.h"

// Module ID for the library
modularExecuteActionModuleID: ModuleID {
        name = 'Modular Execute Action Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// We replace the stock function with one that calls the execAction()
// method on the new modularExecuteAction singleton.
replace executeAction(dstActor, dstActorPhrase, srcActor, countsAsIssuerTurn,
	action) {
	modularExecuteAction.execAction(dstActor, dstActorPhrase, srcActor,
		countsAsIssuerTurn, action);
}

class ExecuteActionState: object
	dstActor = nil
	dstActorPhrase = nil
	srcActor = nil
	countsAsIssuerTurn = nil
	action = nil

	results = nil

	construct(da, dap, sa, c, a) {
		dstActor = da;
		dstActorPhrase = dap;
		srcActor = sa;
		countsAsIssuerTurn = c;
		action = a;
	}
;

// Global singleton.
// We aggressively subdivide parts of the native executeAction() method
// into separate methods, with the intent of making it easier to change
// parts of the process without having to replace the whole thing.
modularExecuteAction: PreinitObject
	// List of our exception handlers.
	_exceptionHandlers = nil

	// Most of our properties are arguments to the stock method.
	// Since we don't have to worry about reentrancy or anything like
	// that we just clear, set, and then re-clear most of our
	// properties for each action execution.

	// Preinit method.
	execute() {
		initExceptionHandlers();
	}

	// Create our exception handler list.
	initExceptionHandlers() {
		_exceptionHandlers = new Vector();
		forEachInstance(EaExceptionHandler, function(o) {
			_exceptionHandlers.append(o);
		});
	}

	// Entry point and main loop.
	// Args are the same as for the stock executeAction().
	execAction(dst, dstPhrase, src, count, act) {
		local st;

		// Create a state object to hold our arguments and other
		// variables for this run.
		st = new ExecuteActionState(dst, dstPhrase, src, count, act);

startOver:
		remap(st);
		setResults(st);

		try {
			st.action.resolveNouns(st.srcActor, st.dstActor,
				st.results);
		}

		catch(Exception e) {
			switch(exceptionHandler(e, st)) {
				case eaRestart:
					goto startOver;
				case eaHandled:
					break;
				default:
					throw e;
			}
		}

		executeActionEffects(st);
		executeActionMain(st);
	}

	// Handle global remappings, if there are any.
	remap(st) {
		local remap;

		remap = GlobalRemapping.findGlobalRemapping(st.srcActor,
			st.dstActor, st.action);
		st.dstActor = remap[1];
		st.action = remap[2];
	}

	// Create and set up the action results object.
	setResults(st) {
		st.results = new BasicResolveResults();
		st.results.setActors(st.dstActor, st.srcActor);
	}


	// This is where we actually execute the action.
	executeActionMain(st) {
		st.action.doAction(st.srcActor, st.dstActor, st.dstActorPhrase,
			st.countsAsIssuerTurn);
	}

	// All the stuff that happens after we've successfully done
	// noun resolution and before we actually execute the action.
	executeActionEffects(st) {
		createSavepoint(st);
		addBusyTime(st);
		checkOrder(st);
	}

	// Generic exception handler.
	// Here we check to see if we have a specific exception handler
	// for the thrown exception and punt off to it if we do.
	exceptionHandler(ex, st) {
		local i, o;

		for(i = 1; i <= _exceptionHandlers.length; i++) {
			o = _exceptionHandlers[i];

			if((o.type != nil) && ex.ofKind(o.type))
				return(o.handle(ex, st));
		}

		return(nil);
	}

	// Create a savepoint for this action if necessary.
	createSavepoint(st) {
		if(st.action.includeInUndo)
			return;
		if(st.action.parentAction != nil)
			return;

		if(!st.dstActor.isPlayerChar()
			&& !(st.srcActor.isPlayerChar()
			&& st.countsAsIssuerTurn))
			return;

		libGlobal.lastCommandForUndo = st.action.getOrigText();
		libGlobal.lastActorForUndo = (st.dstActorPhrase == nil
			? nil
			: st.dstActorPhrase.getOrigText());

		savepoint();
	}

	// Busy time update for an actor giving another actor an order.
	addBusyTime(st) {
		if(!st.countsAsIssuerTurn)
			return;
		if(st.action.isConversational(st.srcActor))
			return;

		st.srcActor.lastInterlocutor = st.dstActor;
		st.srcActor.addBusyTime(nil,
			st.srcActor.orderingTime(st.dstActor));
		st.dstActor.nonIdleTurn();
	}

	// Special case of one actor giving another actor an order they're
	// not obeying.
	checkOrder(st) {
		if(st.srcActor == st.dstActor)
			return;
		if(st.action.isConversational(st.srcActor))
			return;
		if(st.dstActor.obeyCommand(st.srcActor, st.action))
			return;

		if(st.srcActor.orderingTime(st.dstActor) == 0)
			st.srcActor.addBusyTime(nil, 1);

		st.action.saveActionForAgain(st.srcActor, st.countsAsIssuerTurn,
			st.dstActor, st.dstActorPhrase);

		throw new TerminateCommandException();
	}
;
