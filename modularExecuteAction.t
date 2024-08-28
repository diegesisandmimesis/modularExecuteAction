#charset "us-ascii"
//
// modularExecuteAction.t
//
#include <adv3.h>
#include <en_us.h>

// Module ID for the library
modularExecuteActionModuleID: ModuleID {
        name = 'Modular Execute Action Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

class EaObject: object
	eaID = nil
	_debug(msg?) {}
;

replace executeAction(dstActor, dstActorPhrase, srcActor, countsAsIssuerTurn,
	action) {
	modularExecuteAction.execAction(dstActor, dstActorPhrase, srcActor,
		countsAsIssuerTurn, action);
}

modularExecuteAction: EaObject, PreinitObject
	eaID = 'modularExecuteAction'

	_exceptionHandlers = nil

	_dstActor = nil
	_dstActorPhrase = nil
	_srcActor = nil
	_countsAsIssuerTurn = nil
	_action = nil

	_results = nil

	clearState() {
		_dstActor = nil;
		_dstActorPhrase = nil;
		_srcActor = nil;
		_countsAsIssuerTurn = nil;
		_action = nil;

		_results = nil;
	}

	execute() {
		initExceptionHandlers();
	}

	initExceptionHandlers() {
		_exceptionHandlers = new Vector();
		forEachInstance(EaExceptionHandler, function(o) {
			_exceptionHandlers.append(o);
		});
	}

	execAction(dstActor, dstActorPhrase, srcActor, countsAsIssuerTurn,
		action) {

		clearState();

		_dstActor = dstActor;
		_dstActorPhrase = dstActorPhrase;
		_srcActor = srcActor;
		_countsAsIssuerTurn = countsAsIssuerTurn;
		_action = action;

		mainExecLoop();

		clearState();
	}

	remap() {
		local remap;

		remap = GlobalRemapping.findGlobalRemapping(_srcActor,
			_dstActor, _action);
		_dstActor = remap[1];
		_action = remap[2];
	}

	mainExecLoop() {
startOver:
		remap();

		_results = new BasicResolveResults();
		_results.setActors(_dstActor, _srcActor);

		try {
			_action.resolveNouns(_srcActor, _dstActor, _results);
		}
/*
		catch(RemapActionSignal sig) {
			sig.action_.setRemapped(action);
			action = sig.action_;
			goto startOver;
		}
*/
		catch(Exception e) {
			switch(exceptionHandler(e)) {
				case eaRestart:
					goto startOver;
				default:
					throw e;
			}
		}

		if(_action.includeInUndo
			&& (_action.parentAction == nil)
			&& (_dstActor.isPlayerChar()
				|| (_srcActor.isPlayerChar() && _countsAsIssuerTurn))) {
			libGlobal.lastCommandForUndo = _action.getOrigText();
			libGlobal.lastActorForUndo =
				(_dstActorPhrase == nil
					? nil
					: _dstActorPhrase.getOrigText());

			savepoint();
		}

		if(_countsAsIssuerTurn && !_action.isConversational(_srcActor)) {
			_srcActor.lastInterlocutor = _dstActor;
			_srcActor.addBusyTime(nil, _srcActor.orderingTime(_dstActor));
			_dstActor.nonIdleTurn();
		}

		if((_srcActor != _dstActor)
			&& !_action.isConversational(_srcActor)
			&& !_dstActor.obeyCommand(_srcActor, _action)) {
			if(_srcActor.orderingTime(_dstActor) == 0)
				_srcActor.addBusyTime(nil, 1);

			_action.saveActionForAgain(_srcActor, _countsAsIssuerTurn,
				_dstActor, _dstActorPhrase);

			throw new TerminateCommandException();
		}

		_action.doAction(_srcActor, _dstActor, _dstActorPhrase, _countsAsIssuerTurn);
	}

	exceptionHandler(ex) {
		local i, o;

		for(i = 1; i <= _exceptionHandlers.length; i++) {
			o = _exceptionHandlers[i];

			if((o.type != nil) && ex.ofKind(o.type))
				return(o.handle(ex));
		}

		return(nil);
	}
;

enum eaRestart, eaContinue;

class EaExceptionHandler: EaObject
	eaID = 'EaExceptionHandler'

	type = nil

	handle(ex) { return(eaContinue); }
;

eaRemapActionSignalHandler: EaExceptionHandler
	type = RemapActionSignal
	actionState = modularExecuteAction
	handle(ex) {
		ex.action_.setRemapped(actionState,_action);
		actionState._action = ex.action_;
		return(eaRestart);
	}
;
