#!/usr/bin/env pwsh
# Convenience wrapper for scripts\uninstall.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\scripts\uninstall.ps1" @args