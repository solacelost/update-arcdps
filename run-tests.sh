#!/bin/bash

if ! pwsh -Command 'Invoke-Pester /app/Update-ArcDPS/tests -CI'; then
    cat $APPDATA/Update-ArcDPS/Update-ArcDPS.log
    exit 1
fi
