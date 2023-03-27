% Pipes
% Gabriel Gonzalez
% May 1, 2014 - CS240H

# Overview

* **[The problem `pipes` solves]**
* How `pipes` works
* Theory behind `pipes`
* Tour of the `pipes` API

# The problem

```haskell
replicateM :: Monad m => Int -> m a -> m [a]

mapM :: Monad m => (a -> m b) -> [a] -> m [b]

sequence :: Monad m => [m a] -> m [a]
```

* Does not work on infinite lists
* You can't consume any results until everything has been processed
* You have to run the entire computation, even if you don't need every result
* This wastes memory by buffering every result

# Non-solution: lazy IO

* Only works for `IO`
* Only works for effectful sources, not effectful sinks or transformations
* Invalidates equational reasoning by tying effects to evaluation order
* Admission of defeat ("Monads are too awkward")

# `pipes` - a coroutine library

```haskell
import Pipes
import System.IO (isEOF)

stdinLn :: Producer String IO ()
stdinLn = do
    eof <- lift isEOF
    if eof
        then return ()
        else do
            str <- lift getLine
            yield str
            stdinLn

useString:: String -> Effect IO ()
useString str = lift (putStrLn str)

echo :: Effect IO ()
echo = for stdinLn useString

main :: IO ()
main = runEffect echo
```

# Example

```bash
$ ./example
Hello<Enter>
Hello
CS240H<Enter>
CS240H
<Ctrl-D>
$
```

# Questions?

# Overview

* The problem `pipes` solves
* **[How `pipes` works]**
* Theory behind `pipes`
* Tour of the `pipes` API

# `Producer`

```haskell
import Control.Monad.Trans.Class (MonadTrans(lift))

data Producer a m r
    = Yield a (Producer a m r)
    | M    (m (Producer a m r))
    | Return r

yield :: a -> Producer a m ()
yield a = Yield a (Return ())

instance Monad m => Monad (Producer a m) where
--  return :: Monad m => r -> Producer a m r
    return r = Return r

--  (>>=) :: Monad m
--        => Producer a m r -> (r -> Producer a m s) -> Producer a m s
    (Yield a p) >>= return' = Yield a (p >>= return')
    (M       m) >>= return' = M (m >>= \p -> return (p >>= return'))
    (Return  r) >>= return' = return' r

instance MonadTrans (Producer a) where
--  lift :: Monad m => m r -> Producer a m r
    lift m = M (liftM Return m)
```

# `stdinLn`

```haskell
stdinLn = do
    eof <- lift isEOF
    if eof
        then return ()
        else do
            str <- lift getLine
            yield str
            stdinLn

useString str = lift (putStrLn str)
```

```haskell
stdinLn =
    M (isEOF >>= \eof -> return $
        if eof
        then Return ()
        else M (getLine >>= \str ->
            Yield str stdinLn ) )

useString str = M (putStrLn str >>= \r -> return (Return r))
```

# `for`

```haskell
for :: Monad m
    => Producer a m ()
    -> (a -> Producer b m ())
    -> Producer b m ()
for (Yield a p) yield' = yield' a >> for p yield'
for (M       m) yield' = M (m >>= \p -> return (for p yield'))
for (Return  r) _      = Return r
```

```haskell
echo = for stdinLn useString 

echo =
    M (isEOF >>= \eof -> return $
        if eof
        then Return ()
        else M (getLine >>= \str ->
                 M (putStrLn str >> return echo) ) )
```

# `runEffect`

```haskell
data Void  -- No constructors

type Effect = Producer Void

runEffect :: Monad m => Effect m r -> m r
runEffect (M      m) = m >>= runEffect
runEffect (Return r) = return r
```

```haskell
main = runEffect echo

main =
    isEOF >>= \eof ->
        if eof 
        then return ()
        else getLine >>= \str ->
                 putStrLn str >> main
```

# Questions?

# Overview

* The problem `pipes` solves
* How `pipes` works
* **[Theory behind `pipes`]**
* Tour of the `pipes` API

# What makes Haskell unique?

* Design patterns are inspired by category theory
* Theory is culturally enshrined in type classes:
    * `Monoid`, `Category`, `Applicative`, `Monad`, ...
* **Goal:** reduce software complexity

# The problem

![](noflo.png)

# How do we reduce complexity?

```haskell
class Monoid m where
    mappend :: m -> m -> m
    mempty  :: m

(<>) :: Monoid m => m -> m -> m
(<>) = mappend
```

```haskell
instance Monoid Int where
    -- mappend :: Int -> Int -> Int
    mappend = (+)

    -- mappend :: Int
    mempty  =  0
```

```haskell
-- Associativity
(x <> y) <> z = x <> (y <> z)  -- (x + y) + z = x + (y + z)

-- Identity:
mempty <> x = x                -- 0 + x = x

x <> mempty = x                -- x + 0 = x
```

# `yield` 

```haskell
yield :: a -> Producer a IO ()
```

A `Producer` that `yield`s exactly one element:

```haskell
yieldOne :: Monad m => Producer String m ()
yieldOne = yield "Hello"
```

A `Producer` that `yield`s more than one element:

```haskell
yieldTwo :: Monad m => Producer String m ()
yieldTwo = do
    yield "Hello"
    yield "CS240H"

-- yieldTwo = yield "Hello" >> yield "CS240H"
```

A `Producer` that `yield`s less than one element:

```haskell
yieldZero :: Monad m => Producer String m ()
yieldZero = return ()
```

# Example

```
>>> runEffect (for yieldOne useString)
Hello
>>> runEffect (for yieldTwo useString)
Hello
CS240H
>>> runEffect (for yieldZero useString)
>>> -- Nothing output
```

# Primitive vs. Derived

```haskell
yieldFour :: Monad m => Producer String m ()
yieldFour = do
    yieldTwo
    yieldTwo

-- yieldFour = yieldTwo >> yieldTwo
```

```
>>> runEffect (for yieldFour useString)
Hello
CS240H
Hello
CS240H
```

# `(>>)` and `return ()` form a Monoid

```haskell
(>>)      :: Producer a IO ()  -- (<>)    :: m
          -> Producer a IO ()  --         -> m
          -> Producer a IO ()  --         -> m

return () :: Producer a IO ()  -- mempty  :: m
```

Associativity:

```haskell
(p1 >> p2) >> p3 = p1 >> (p2 >> p3)  -- (x <> y) <> z = x <> (y <> z)
```

Identity:

```haskell
return () >> p = p                   -- mempty <> x = x

p >> return () = p                   -- x <> mempty = x
```

# Categories generalize Monoids

```haskell
class Category cat where                  -- class Monoid m where
    (.) :: cat b c -> cat a b -> cat a c  --     mappend :: m -> m -> m
    id  :: cat a a                        --     mempty  :: m

(>>>) :: Category cat => cat a b -> cat b c -> cat a c
(>>>) = flip (.)
```

```haskell
instance Category (->) where
    -- (.) :: (b -> c) -> (a -> b) -> (a -> c)
    (g . f) x = g (f x)

    -- id  :: (a -> a)
    id x = x
```

```haskell
-- Associativity
(f . g) . h = f . (g . h)                 -- (x <> y) <> z = x <> (y <> z)

-- Identity
id . f = f                                -- mempty <> x = x

f . id = f                                -- x <> mempty = x
```

# `(>=>)` and `return` form a Category

```haskell
(>=>)  :: Monad m
       => (a -> Producer o m b)  -- (>>>) :: cat a b
       -> (b -> Producer o m c)  --       -> cat b c
       -> (a -> Producer o m c)  --       -> cat a c
(f >=> g) x = f x >>= g

return :: Monad m
       => (a -> Producer o m a)  -- id    :: cat a a
```

Associativity:

```haskell
(f >=> g) >=> h = f >=> (g >=> h)      -- (f >>> g) >>> h = f >>> (g >>> h)
```

Identity:

```haskell
return >=> f = f                       -- id >>> f = f

f >=> return = f                       -- f >>> id = f
```

# Monad Laws

Associativity:

```haskell
(f >=> g) >=> h = f >=> (g >=> h)

(m >>= g) >>= h = m >>= \x -> g x >>= h
```

Left identity:

```haskell
return >=> f = f

return x >>= f = f
```

```haskell
f >=> return = f

m >>= return = m
```

# `(~>)` and `yield` form a Category

```haskell
(~>)  :: (a -> Producer b IO ())  -- (>>>) :: cat a b
      -> (b -> Producer c IO ())  --       -> cat b c
      -> (a -> Producer c IO ())  --       -> cat a c
(f ~> g) x = for (f x) g

yield :: (a -> Producer a IO ())  -- id    :: cat a a
```

Associativity:

```haskell
(f ~> g) ~> h = f ~> (g ~> h)     -- (f >>> g) >>> h = f >>> (g >>> h)
```

Identity:

```haskell
yield ~> f = f                    -- id >>> f = f

f ~> yield = f                    -- f >>> id = f
```

# `for` loop laws - Part 1

```haskell
yield ~> f = f

for (yield x) f = f x
```

```
>>> runEffect (for (yield "Hello") useString)
Hello
>>> runEffect (useString "Hello")
Hello
>>>
```

```haskell
f ~> yield = f

for m yield = m
```

```
>>> let yieldTwo' = for yieldTwo yield
>>> runEffect (for yieldTwo' useString)
Hello
CS240H
>>> runEffect (for yieldTwo useString)
Hello
CS240H
>>>
```

# `for` loop laws - Part 2

```haskell
(f ~> g) ~> h = f ~> (g ~> h)

for (for p g) h = for p (\x -> for (g x) h)
```

```haskell
stdinLn :: Producer String IO ()       -- Same as before

twice :: Monad m => a -> Producer a m ()
twice a = do
    yield a
    yield a

useString :: String -> Effect IO ()    -- Same as before
```

```haskell
echoTwice :: Effect IO ()
echoTwice = for (for stdinLn twice) useString

echoTwice' :: Effect IO ()
echoTwice' = for stdinLn $ \str1 -> for (twice str1) useString
```

# Example

```
>>> runEffect echoTwice
Hello<Enter>
Hello
Hello
CS240H<Enter>
CS240H
CS240H
...
>>> runEffect echoTwice'
Hello<Enter>
Hello
Hello
CS240H<Enter>
CS240H
CS240H
...
```

# Reduce the complexity of coroutines

```haskell
import Pipes
import System.IO (isEOF)

stdinLn :: Producer String IO ()
stdinLn = do
    eof <- lift isEOF
    if eof
        then return ()
        else do
            str <- lift getLine
            yield str
            stdinLn

useString:: String -> Effect IO ()
useString str = lift (putStrLn str)

echo :: Effect IO ()
echo = for stdinLn useString

main :: IO ()
main = runEffect echo
```

# Questions?

# Overview

* The problem `pipes` solves
* How `pipes` works
* Theory behind `pipes`
* **[Tour of the `pipes` API]**

# `Consumer`

A sink that changes over time

```haskell
import Pipes
import Pipes.Prelude (stdinLn)

numbered :: Int -> Consumer String IO r
numbered n = do
    str <- await
    let str' = show n ++ ": " ++ str
    lift (putStrLn str')
    numbered (n + 1)

giveString :: Effect IO String
giveString = lift getLine

nl :: Effect IO ()
nl = giveString >~ numbered 0

main :: IO ()
main = runEffect nl
```

# Example

```
>>> main
Hello<Enter>
0: Hello
CS240H<Enter>
1: CS240H
...
```

# `Consumer`

```haskell
data Consumer a m r
    = Await (a -> Consumer a m r )
    | M       (m (Consumer a m r))
    | Return r

await :: Consumer a m a
await = Await (\a -> Return a)
```

# `await`

```haskell
await :: Consumer a IO a
```

A `Consumer` that `await`s more than one element:

```haskell
awaitTwo :: Monad m => Consumer String m String
awaitTwo = do
    str1 <- await
    str2 <- await
    return (str1 ++ " " ++ str2)
```

A `Consumer` that `await`s zero elements:

```haskell
awaitZero :: Monad m => Consumer String m String
awaitZero = return "Some string"
```

# Example

```
>>> runEffect (giveString >~ awaitOne)
Hello<Enter>
Hello
>>> runEffect (giveString >~ awaitTwo)
Hello<Enter>
CS240H<Enter>
Hello CS240H
>>> runEffect (giveString >~ awaitZero)
Some string
```

# Primitive vs. Derived

```haskell
awaitFour :: Monad m => Consumer String m String
awaitFour = do
    str1 <- awaitTwo
    str2 <- awaitTwo
    return (str1 ++ " " ++ str2)
```

```
>>> runEffect (giveString >~ awaitFour)
Hello<Enter>
CS240H<Enter>
You're<Enter>
welcome!<Enter>
Hello CS240H You're welcome!
```

# `(>~)`

```haskell
(>~) :: Monad m
     => Consumer a m b  -- (>>>) :: cat a b
     -> Consumer b m c  --       -> cat b c
     -> Consumer a m c  --       -> cat a c
```

```
>>> runEffect (giveString >~ awaitTwo >~ numbered)
Hello<Enter>
CS240H<Enter>
0: Hello CS240H
You're<Enter>
welcome!<Enter>
1: You're welcome!
...
```

# `(>~)` and `await` form a Category

```haskell
(>~)  :: Consumer a IO b       -- (>>>) :: cat a b
      -> Consumer b IO c       --       -> cat b c
      -> Consumer a IO c       --       -> cat a c

await :: Consumer a IO a       -- id    :: cat a a
```

Associativity:

```haskell
(f >~ g) >~ h = f >~ (g >~ h)  -- (f >>> g) >>> h = f >>> (g >>> h)
```

Identity:

```haskell
await >~ f = f                 -- id >>> f = f

f >~ await = f                 -- f >>> id = f
```

# Questions?

# Mix `Producer`s and `Consumer`s using `(>->)`

```haskell
(>->) :: Producer a IO r
      -> Consumer a IO r
      -> Effect     IO r
```

```haskell
main :: IO ()
main = runEffect (stdinLn >-> numbered)
```

```
$ ./example
Hello<Enter>
0: Hello
CS240H<Enter>
1: CS240
<Ctrl-D>
$
```

# `Pipe`

```haskell
data Pipe a b m r
    = Await (a -> Pipe a b m r )
    | Yield  b   (Pipe a b m r)
    | M     (m   (Pipe a b m r))
    | Return r

await :: Pipe a b IO a

yield :: b -> Pipe a b IO ()
```

```haskell
take :: Int -> Pipe a a IO ()
take n | n <= 0    = lift (putStrLn "You shall not pass!")
       | otherwise = do a <- await
                        yield a
                        take (n - 1)
```

```haskell
import Control.Monad (replicateM_)

take n = do
    replicateM_ n (await >>= yield)
    lift (putStrLn "You shall not pass!")
```

# Example

```
>>> runEffect (stdinLn >-> take 2 >-> numbered)
Hello<Enter>
0: Hello
CS240H<Enter>
1: CS240H
You shall not pass!
```

# Behavior switching

```haskell
import Control.Monad (forever)  -- forever m = m >> forever m

cat :: Pipe a a IO r
cat = forever $ do
    a <- await
    yield a

customerService :: Pipe String String IO ()
customerService = do
    yield "Hello"
    take 10
    yield "Could you please hold for one second?"
    cat
```

# What the types? - Part 1

What is the deal?

```haskell
lift :: IO r -> Producer a IO r
lift :: IO r -> Consumer a IO r
lift :: IO r -> Effect     IO r
```

```haskell
await :: Consumer a   m a
await :: Pipe     a b m a
```

```haskell
yield :: b -> Producer b m ()
yield :: b -> Pipe   a b m ()
```

# What the types? - Part 2

```haskell
(>->) :: Producer a IO r
      -> Pipe   a b IO r
      -> Producer b IO r

(>->) :: Pipe   a b IO r
      -> Consumer b IO r
      -> Consumer a IO r

(>->) :: Pipe a b IO r
      -> Pipe b c IO r
      -> Pipe a c IO r
```

# Polymorphism

`Consumer` is special case of `Pipe`

```haskell
type Consumer a = Pipe a Void
```

`Producer` is (basically) a special case of `Pipe`

```haskell
type Producer b = Pipe () b     -- White lie
```

* This is "parametric polymorphism" (i.e. generics)

* This is *not* ad-hoc polymorphism (i.e. type classes)

# `(>->)` and `cat` form a `Category`

```haskell
(>->) :: Pipe a b IO r  -- (>>>) :: cat a b
      -> Pipe b c IO r  --       -> cat b c
      -> Pipe a c IO r  --       -> cat a c

cat   :: Pipe a a IO r  -- id    :: cat a a
```

Associativity:

```haskell
(f >-> g) >-> h = f >-> (g >-> h)  -- (f >>> g) >>> h = f >>> (g >> h)
```

Identity:

```haskell
cat >-> f = f                      -- id >>> f = f

f >-> cat = f                      -- f >>> id = f
```

# API inspired by category theory

| Composition |  Identity |
|:-----------:|:---------:|
|   `(>=>)`   |  `return` |
|   `(~>)`    |  `yield`  |
|   `(>~)`    |  `await`  |
|   `(>->)`   |  `cat`    |

This is just the beginning:

```haskell
(f >=> g) ~> h = (f ~> h) >=> (g ~> h)  -- (x + y) * z = (x * z) + (y * z)

return ~> h = return                    -- 0 * z = 0
```

**Goal:** Categorical semantics

# Conclusion

* Composability keeps software architectures flat

* Small amounts of theory go a very long way

# Exercise #1

Implement `takeWhile`

```haskell
import Pipes
import Pipes.Prelude (stdinLn, stdoutLn)
import Prelude hiding (takeWhile)

takeWhile :: Monad m => (a -> Bool) -> Pipe a a m ()
takeWhile keep = ???

main = runEffect (stdinLn >-> takeWhile (/= "quit") >-> stdoutLn)
```

```
>>> main
Hello<Enter>
Hello
CS240H<Enter>
CS240H
quit<Enter>
>>>
```

# Solution #1

```haskell
import Pipes
import Pipes.Prelude (stdinLn, stdoutLn)
import Prelude hiding (takeWhile)

takeWhile :: Monad m => (a -> Bool) -> Pipe a a m ()
takeWhile keep = do
    a <- await
    if keep a
        then do
            yield a
            takeWhile keep
        else return ()

main = runEffect (stdinLn >-> takeWhile (/= "quit") >-> stdoutLn)
```

# Exercise #2

Implement `map`

```haskell
import Pipes
import Pipes.Prelude (stdinLn, stdoutLn)
import Prelude hiding (map)

map :: Monad m => (a -> b) -> Pipe a b m ()
map f = ???

main = runEffect (stdinLn >-> map (++ "!") >-> stdoutLn)
```

```
>>> main
Hello<Enter>
Hello!
CS240H<Enter>
CS240H!
...
```

# Solution #2

```haskell
import Pipes
import Pipes.Prelude (stdinLn, stdoutLn)
import Prelude hiding (map)

map :: Monad m => (a -> b) -> Pipe a b m ()
map f = for cat (yield . f)

main = runEffect (stdinLn >-> map (++ "!") >-> stdoutLn)
```

```
cat = forever $ do
    a <- await
    yield a

for cat (yield . f)

= forever $ do
    a <- await
    (yield . f) a

= forever $ do
    a <- await
    yield (f a)
```

# Exercise #3

What does `mystery` do?

```haskell
import Control.Monad (replicateM_)
import Pipes

mystery :: Monad m => Int -> Pipe a a m r
mystery n = do
    replicateM_ n await
    cat
```

# Solution #3

```haskell
import Control.Monad (replicateM_)
import Pipes

drop :: Monad m => Int -> Pipe a a m r
drop n = do
    replicateM_ n await
    cat
```

```
>>> runEffect (stdinLn >-> drop 2 >-> stdoutLn)
A<Enter>
B<Enter>
C<Enter>
C
D<Enter>
D
...
```

# Exercise #4

What does `mystery` do?

```haskell
import Pipes

mystery :: Monad m => Producer String m r
mystery = return "y" >~ cat
```

# Solution #4

```haskell
import Pipes

yes :: Monad m => Producer String m r
yes = return "y" >~ cat
```

# Exercise #5

Implement `grep`

```haskell
-- grep.hs

import Data.List (isInfixOf)
import Pipes
import qualified Pipes.Prelude as Pipes

-- Use: hackage.haskell.org/package/pipes

grep :: Monad m => String -> Pipe String String m r
grep str = ???

main = runEffect (Pipes.stdinLn >-> grep "import" >-> Pipes.stdoutLn)
```

```
$ ./grep < grep.hs
import Pipes
import qualified Pipes.Prelude as Pipes
$
```

# Solution #5

```haskell
-- grep.hs

import Data.List (isInfixOf)
import Pipes
import qualified Pipes.Prelude as Pipes

grep :: Monad m => String -> Pipe String String m r
grep str = Pipes.filter (str `isInfixOf`)

main = runEffect (Pipes.stdinLn >-> grep "import" >-> Pipes.stdoutLn)
```
