#!/usr/bin/env pwsh
# Convenience wrapper for scripts\upgrade.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\scripts\upgrade.ps1" @args