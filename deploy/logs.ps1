#!/usr/bin/env pwsh
# Convenience wrapper for scripts\logs.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\scripts\logs.ps1" @args