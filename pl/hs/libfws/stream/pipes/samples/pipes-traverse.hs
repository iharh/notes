module Main where

import Control.Monad ( forM_, liftM )
import Control.Proxy
import System.Directory ( doesDirectoryExist, getDirectoryContents )
import System.Environment ( getArgs )
import System.FilePath ( (</>) )

getRecursiveContents :: (Proxy p) => FilePath -> () -> Producer p FilePath IO ()
getRecursiveContents topPath () = runIdentityP $ do
  names <- lift $ getDirectoryContents topPath
  let properNames = filter (`notElem` [".", ".."]) names
  forM_ properNames $ \name -> do
    let path = topPath </> name
    isDirectory <- lift $ doesDirectoryExist path
    if isDirectory
      then getRecursiveContents path ()
      else respond path

unusedFun :: a -> a
unusedFun i = i

-- TODO: look at Pipes utils ...
-- useD .. execD
-- readLnS, fromListS, hGetLineS, takeB_ n

main :: IO ()
main = do
    [path] <- getArgs
    runProxy $
            getRecursiveContents path
        >-> useD (\file -> putStrLn $ "Found file " ++ file)
