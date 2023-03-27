import Pipes
import Prelude hiding (take)

import qualified Pipes.Prelude as P

loop :: Effect IO ()
loop = for P.stdinLn (lift . putStrLn)

produceNats :: (Monad m) => Producer Int m ()
produceNats = each [1..]

produceConst9 :: (Monad m) => Producer Int m ()
produceConst9 = forever $ yield 9

produceStringAAA :: (Monad m) => Producer String m ()
produceStringAAA = forever $ yield "aaa"

producePairs :: (MonadIO m) => Producer (Int,String) m ()
producePairs =  each [1..] `P.zip` P.stdinLn

consumer1 :: (MonadIO m) => Consumer (Int,String) m ()
consumer1  = forever $ do
  (i,s) <- await
  liftIO $ withFile (show i ++ ".out") WriteMode (\h -> hPutStrLn h s)

main :: IO ()
main = do
  putStrLn "start!"
  -- runEffect $
    -- P.take 5
    -- prod1 >-> P.print
    -- P.stdinLn >-> P.stdoutLn
    -- loop
