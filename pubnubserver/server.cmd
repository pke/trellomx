@echo off
call node_modules\.bin\coffee -c server.coffee
call node_modules\.bin\coffee server.coffee