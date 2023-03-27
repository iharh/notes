@echo off
setlocal
call cabal.bat sandbox init
call cabal.bat install hlint --enable-documentation --haddock-hyperlink-source
endlocal

