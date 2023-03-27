@echo off
setlocal
call cabal.bat sandbox init
call cabal.bat install hpc --enable-documentation --haddock-hyperlink-source
endlocal

