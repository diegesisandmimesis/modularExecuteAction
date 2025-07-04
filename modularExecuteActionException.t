#charset "us-ascii"
//
// modularExecuteActionException.t
//
//	Exception handlers.
//
//	The executeAction() replacement doesn't use a hardcoded
//	try/catch block but instead uses a configurable exception handler
//	list.
//
//	All declared EaExceptionHandler instances are automagically added
//	to modularExecuteAction during preinit.
//
//
#include <adv3.h>
#include <en_us.h>

#include "modularExecuteAction.h"

// Exception handler return values.
//
//	eaRestart
//		After the exception handler is done, re-run the action
//		execution process.  This is done by the stock exception
//		handler, which handles action remapping.
//
//	eaContinue
//		After the exception handler is done, continue processing.
//		This will lead to the exception being re-thrown to be
//		handled by someone else.
//		This is the default behavior for most exceptions (including
//		those with no explicit action handler in this module).
//
//	eaHandled
//		After the exception handler is done stop processing.
//		This WILL NOT re-throw the exception, meaning nobody else
//		will get a chance to handle it.
//		This is for exception handlers that want to change
//		the default action execution process.
//
//
enum eaRestart, eaContinue, eaHandled;

class EaExceptionHandler: object
	// The type of exception this handler handles.
	type = nil

	// Handler method.  Arguments are the exception and the
	// action execution state.
	// The return value one of the values in the enum above.
	handle(ex, st) { return(eaContinue); }
;

// Replacement for the single stock exception handler.
eaRemapActionSignalHandler: EaExceptionHandler
	type = RemapActionSignal

	handle(ex, st) {
		ex.action_.setRemapped(st.action);
		st.action = ex.action_;
		return(eaRestart);
	}
;
