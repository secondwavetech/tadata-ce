#!/usr/bin/env pwsh
# Convenience wrapper for scripts\stop.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\scripts\stop.ps1" @args