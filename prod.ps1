<#
.SYNOPSIS
    Launch backend and frontend production servers in parallel using linux shell on the right half of the screen using splitted consoles in Conemu
#>

Push-Location $(git rev-parse --show-toplevel)
npm start --workspace server -new_console:s50H:n:t:server
npm start --workspace client -new_console:s50V:n:t:client
Pop-Location
