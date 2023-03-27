@echo off
setlocal

call vars-haskell.bat
::set GHC_PACKAGE_PATH=%HASKELL_CABAL_DEV_SANDBOXES_HOME%\pipes\cabal-dev\packages-%_HASKELL_COMPILER_VER%.conf;
set GHC_PACKAGE_PATH=%HASKELL_CABAL_DEV_SANDBOXES_HOME%\ghc-heap-view\cabal-dev\packages-%_HASKELL_COMPILER_VER%.conf;

ghci
::-x "hs" a.hs

endlocal
