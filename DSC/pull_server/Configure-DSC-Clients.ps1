﻿param(
    LocalConfigurationManager

$node = [guid]::NewGuid().Guid
LetsGetConfiguring -NodeId $node.ToString() -PullServer $pull_server

Write-Host "Copy This Guid Down = $($node.ToString())  . . ."
Get-DscLocalConfigurationManager