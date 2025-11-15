#!/usr/bin/env pwsh
# Convenience wrapper for scripts\restart.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\scripts\restart.ps1" @args