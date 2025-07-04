#charset "us-ascii"
//
// modularExecuteActionDebug.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "modularExecuteAction.h"

#ifdef __DEBUG

modify ExecuteActionState
	_log(msg) { aioSay('\n<<msg>>\n '); }

	_debugState() {
		_log('===ExecuteActionState start===');
		_log('\tdstActor = <<toString(dstActor)>>');
		_log('\tdstActorPhrase = <<toString(dstActorPhrase)>>');
		_log('\tsrcActor = <<toString(srcActor)>>');
		_log('\tcountsAsIssuerTurn = <<toString(countsAsIssuerTurn)>>');
		_log('\taction = <<toString(action)>>');
		_log('===ExecuteActionState end===');
	}
;

#endif // __DEBUG
