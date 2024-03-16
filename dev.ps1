<#
.SYNOPSIS
    Launch backend and frontend development servers in parallel on the right half of the screen using splitted consoles in Conemu
#>

Push-Location $(git rev-parse --show-toplevel)
npm run dev --workspace server -new_console:s50H:n:t:server
npm run dev --workspace client -new_console:s50V:n:t:client
Pop-Location
