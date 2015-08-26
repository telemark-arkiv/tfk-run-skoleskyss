#!/bin/bash

SAKSBEHANDLINGS_BIN=/srv/ws/tfk-saksbehandling/cli.js
SAKSBEHANDLINGS_OPTS=/srv/ws/tfk-saksbehandling/options.json
SAKSBEHANDLING_PATH=/srv/ws/tfk-saksbehandling/
FLOW_BIN=/srv/ws/tfk-flow/index.js
FLOW_PATH=/srv/ws/tfk-flow/
SI_BIN=/srv/ws/360import/skoleskyss.php
SI_PATH=/srv/ws/360import/

IMPORT_PATH=/srv/saksbehandling/json/
DONE_PATH=/srv/saksbehandling/json-done/
FAILED_PATH=/srv/saksbehandling/json-failed/

function delAll {
  echo Deletes files in $IMPORT_PATH
  rm -rf $IMPORT_PATH*
}

function fileExist {
  if [ -f $1 ]; then
     echo "File $1 exists."
  else
     echo "File $1 does not exist."
     exit 1
  fi
}

function errorMessage {
  echo -e "*** Error in $1 ! ***"
  exit 1
}

function giveMeError {
 if [ -z "$2" ]; then
   errorMessage $1
   exit 1
 else
   filename=$(basename $2)
   echo -e "Moving: $2 to $FAILED_PATH$filename"
   mv $2 $FAILED_PATH$filename
   delAll
   errorMessage $1
 fi
}

function saksbehandling {
  echo -e "\n*** RUNNING SAKSBEHANDLING ***"
  cd $SAKSBEHANDLING_PATH
  echo Command: node $SAKSBEHANDLINGS_BIN $SAKSBEHANDLINGS_OPTS
  node $SAKSBEHANDLINGS_BIN $SAKSBEHANDLINGS_OPTS
  if [ $? -ne 0 ]; then
    giveMeError saksbehandling
  fi
}

function flow {
  echo -e "\n*** RUNNING FLOW ***"
  cd $FLOW_PATH
  echo Command: node $FLOW_BIN $1
  node $FLOW_BIN $1
  if [ $? -ne 0 ]; then
     giveMeError flow $1
  fi
}

function siimport {
  echo -e "\n*** RUNNING 360IMPORT ***"
  cd $SI_PATH
  echo Command: php $SI_BIN $1
  php $SI_BIN $1
  if [ $? -ne 0 ]; then
   giveMeError siimport $1
  fi
}

saksbehandling

for f in $IMPORT_PATH*.json; do
  echo "Processing $f file..";
  fileExist $f
  flow $f
  siimport $f
  filename=$(basename $f)
  mv $f $DONE_PATH$filename
  delAll
done
