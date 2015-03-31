@echo off

pushd %cd%
cd %~dp0

call node_modules\.bin\coffee -cw trello.Shared\js trello.Shared\pages trello.Windows\pages trello.WindowsPhone\pages

popd
