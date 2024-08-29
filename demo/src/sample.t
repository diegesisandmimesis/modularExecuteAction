#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the modularExecuteAction library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "modularExecuteAction.h"

versionInfo: GameID;
gameMain: GameMainDef initialPlayerChar = me;

startRoom: Room 'Void'
	"This is a featureless void.  The other room is to the north. "
	north = otherRoom
;
+me: Person;
+alice: Person 'alice' 'Alice'
	"She looks like the first person you'd turn to with a problem. "
	isHer = true
	isProperName = true
;
++DefaultCommandTopic
	topicResponse() {
		defaultReport('<q>This is my default topic response,</q>
			Alice says. ');
	}
;
++CommandTopic @TakeAction
	topicResponse() {
		defaultReport('<q>This is my \'take\' topic response,</q>
			Alice says. ');
	}
;

otherRoom: Room 'Other Room'
	"This is the other room.  The void is to the south. "
	south = startRoom
;
+pebble: Thing '(small) (round) pebble' 'pebble' "A small, round pebble. ";
