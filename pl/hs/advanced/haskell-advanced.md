Andres Loeh, Duncan Coutts

6-7 Feb 2013

## Internals and Performance

### Language Extensions

* Current version: Haskell 2010 (that's what current version of GHC gives out of the box)
* Language extensions: GHC supports over a hundred, there is a consensus in community which ones are standard and stable and which ones experimental
* Recommended way of enabling: `{-# LANGUAGE xxx #-}` pragma (also declare in cabal file as "enabled extensions")

### Data Structures

#### Lists

Imperative: destructive update (ephemeral data structures); functinal: creation of a new value (persistent data structures).

`[1,2,3,4]` is syntactic sugar for `1:(2:(3:(4:[])))`

when we do `let y = 0:x`, the x is reused (it's safe to share it, because it's immutable); same when we do `drop 3 y`, it's pointer. However, when we do `take 2`, we have
to copy the cons `(:)` cells (see slides).

#### In-memory representation

Words of memory:

* first identifies the constructor
* other ones contain payload (pointers to constructor args)

~~~
+---+----------+----------+
|(:)|hd ptr -> |tl ptr -> |
+---+----------+----------+
~~~

Thunks are represented similarly, as heap objects:

~~~
+---+----------+----------+
|fn |arg 1 ->  |arg 2 ->  |
+---+----------+----------+
~~~

The first field indicates whether it's a thunk or constructor. If thunk, it can be replaced by evaluated value (one of very few cases where in Haskell something gets changed destructively). The benefit is that if a shared thunk is evaluated, the value will be available to all places pointing to it.

#### Inspection Tools

* vacuum -- older, shows evaluated values
* ghc-vis/ghc-heap-view -- lets see the thunks and prod them

useful for visualisation, not so useful for large program debugging

ghc-vis in ghci:

~~~
let x = [1,2,3,4]; w = take 2 x
:vis
:view x
:view w
:switch
-- now we can prod thunks!
:clear
let x = cycle [1,2] -- shows how infinite structures like this are represented
let y = take 5 x -- we need 5 real conses!
let z = drop 3 x
~~~

AP - unevaluated thunk
BCO - bytecode of function
Thunk - another type of thunk (the difference doesn't really matter)

#### Trees

There is a lot of syntactic sugar for lists, but only very few operations on them are efficient. `snoc`, `reverse`, `elem`, `splitAt`, `union` are all linear. They are suitable if all we need are stack operations, if data is small (in the order of hundreds) or if we don't care about performance (data is small). Problematic case: `String` -- it's a list of chars, convenient, but unsuitable for large pieces of text.

Trees are very suitable for persistent, functional setting. Most of persistent data structures are internally represented as trees (cf. binary tries in Scala). Balanced search tree is a sensible representation for data structure that involves lookups.

* `Data.Map`
* `Data.IntMap` (special, efficient case for `Int` keys)
* `Data.Set` (note: values need to be instances of `Ord`)

#### A glimpse at implementation of `Map`

~~~ {.haskell}
data Map k a = Tip
             | Bin {-# UNPACK #-} !Size
                   (Map k a) k a (Map k a)
type Size = Int
~~~

`!` means size will never be a thunk; `UNPACK` changes in-memory representation so that Size is not a pointer, but is stored unboxed.

The library uses *smart constructors* -- wrappers around constructors that maintain invariants (e.g. size)

~~~ {.haskell}
bin :: Map k a -> a -> Map k a -> Map k a
bin l kx x r = Bin (size l + size r + 1) l kx x r
~~~

We have to remember to use smart constructor, not the regular one -- can be ensured by exporting only smart constructors.

~~~ {.haskell}
size Tip              = 0
size (Bin sz _ _ _ _) = sz

insert kx x Tim = singleton kx x
insert kx x (Bin sz l ky y r) =
  case compare kx ky of
    LT -> balance (insert kx x l) ky y
    GT -> balance              l  ky y (insert kx x r)
    EQ -> Bin sz l kx x r
~~~

`balance` is another type of smart constructor, even smarter than bin, because it does the balancing. Bonus: rotation (`singleL` and `doubleL`) is easy to write in Haskell!

#### Sequences

* efficient random access
* efficient access to both ends
* efficient concatenation and splitting

e.g. queueus, pattern matching, search and replace etc.

Solution: `Data.Sequence`. Slightly underused, better list. List still has its uses due to syntax, conceptual simplicity and adequacy for small data sets and possibilit to be infinite.

How is it implemented? Take a tree with sequence elements in leaves; then invert it so that start and end are treated as "roots" of the tree, and the pointers are reversed. In the end we get finger tree, with strong trunk a lot of branches (start and end are on the first level).

Check ghc-viz :view `Data.Sequence.fromList([1..30])` -- note that we can see unpacked values in constructor nodes, not as pointers

~~~ {.haskell}
newtype Seq a = Seq (FingerTree a)
data FingerTree a = Empty
                  | Single a
                  | Deep {-# UNPACK #-} !Int
                         !(Digit a) (FingerTree (Node a)) !(Digit a)

data Node a = Node2 {-# UNPACK #-} !Int a a
            | Node3 {-# UNPACK #-} !Int a a a

data Digit a = One a | Two a a | Three a a a | Four a a a a
~~~

#### Arrays

Constant time access to data and compact storage. `array` package is the old solution, `vector` is new favourite.

~~~ {.haskell}
let x = fromList [1,2,3,4,5] in x // [(2,13)]
~~~

The price to pay is that we need to copy the entire array on update -- that's why we can do bulk updates, `(//)` where updated values are specified as list. Because of this arrays are used much less in functional languages than in imperative languages. Ideal use cases: 

1. construct once, use many times
2. update all elements at once

`Data.Vector` operations: `slice` is constant time, but `(++)` is linear. Vectors can be constructed `fromList` and using generating function (`generate`).

Arrays are special in that we can't define them using `data`, they have to be built into the compiler. In GHC it's a heap object consisting of descriptor, length and a number of words containing data (see in ghc-vis, we'll see that actual sizes are powers of 2).

#### Unboxed Types

ghci:

~~~
> :i Int
data Int = GHC.Types.I# GHC.Prim.Int#
~~~

what is `Int#`?

~~~
> :i GHC.Prim.Int#
data GHC.Prim.Int# -- Defined in `GHC.Prim'
~~~

`#` is to scare people. To get names like these to parse we need `MagicHash` extension. `Int#` is real machine integer. So Int has a tag I# and unpacked machine integer. Heap representation:

~~~
           +----+----+
x: Int ->  | I# | 3# |
           +----+----+
~~~

x is a boxed integer; 3# is unboxed integer. By default everything is boxed, compiler will unbox if possible and appropriate. We can force unpacked values to be stored in our data structure using the pragma `{-# UNPACK #-}` and strictness annotation -- see earlier examples. Pragma and annotations are separate because pragma should not introduce sematic changes and strictness is a semantic change. There's a flag `-funbox-strict-fields` that will attempt to unbox all strict fields.

Why do we want to box? It admits laziness and polymorphism. Unboxed ints are good when we just use them in comparison, but stop to be an optimisation when we later use them in operation that would need to re-box them.

Aside: specialisation is normally done explicitly (`Map` and `IntMap`), but there are advanced techniques for implicit specialisation (used e.g. in `Vectors`).

~~~ {.haskell}
3#    :: Int#
3##   :: Word#
3.0#  :: Float# 
3.0## :: Double#
'c'#  :: Char#
~~~

also functions, e.g. `(+##)` for doubles.

Kinds are also incompatible:

~~~ {.haskell}
Int :: *
[] :: * -> *
Int# :: #
~~~

so we can't have a list of `Int#`s. Fortunately, we very rarely use unboxed types directly, GHC deals with it for us. We can tell what unpacking was applied by looking at core. Any type that has a *single* data constructor can be unpacked; this can affect how we choose to represent data, if we care about low-level efficiency.

`Data.Vector.Unboxed` provides more compact and more local storage, but restricts the types of elements we can store. There is a type class `Unbox` that describe things that can be stored in it. Interesting case:

~~~ {.haskell}
instance (Unbox a, Unbox b) => Unbox (a, b)
~~~

The vector representation in this case is actually a pair of vectors instead of vector of pairs!

Interesting trick with normal arrays: values can depend on each other, like in a spreadsheet -- a way to do dynamic programming. Not feasible in case of unboxed vectors. That's why compiler will not change the type of compiler for us -- it changes the semantics.

#### Mutable Vectors

There are (few) algorithms that can be implemented more efficiently with destructive updates (e.g. DFS). Haskell offers mutable arrays and most oprations on them are in `IO`. Packages: `Data.Vector.Mutable` and `Data.Vector.Unboxed.Mutable`.

~~~ {.haskell}
data IOVector -- abstract

new :: Int -> IO (IOVector a)
read :: IOVector a -> Int -> IO a
write :: IOVector a -> Int -> a -> IO ()
~~~

#### Strings

~~~ {.haskell}
type String = [Char]
~~~

"foo" takes 15 words to represent in memory (see list representation).

`ByteString` and `Text` (newer) offer compact representations, like unboxed vectors. There are also lazy versions of these, suitable for huge strings that should not be held in memory completely. `Text` is UTF16, `ByteString` is a byte array, without encoding implied. `ByteString ` is appropraite for ASCII, `Text` for Unicode.

Use case: reading infinite stream from socket: `Data.ByteString.Lazy` and then use `hGetContents`. In network protocols it's better to be more explicit, i.e. read line by line and have a chance to respond.

#### Summary

* sets, maps and sequences are good general-purpose structures
* lists are good for small data and incremental streaming
* vectors and arrays are useful in some cases, but need to be careful (copying) 


### Lazy Evaluation and Profiling

We don't need to understand evaluation to write semantically correct programs, but it's crucial for performance.

#### Reduction

_Redex_ is an expression that can be reduced. Typically replacing lhs of fun definition by right hand side. How does Haskell choose which redex to reduce?

~~~ {.haskell}
id (id (\z -> id z))
~~~

there are three possible reductions.

~~~ {.haskell}
head (repeat 1)
~~~

Can't reduce head because it needs to know if thing is non-empty. We can reduce `(repeat 1)` and then we can reduce `head`. Here the choice of reduction makes a difference between termination and non-termination.

~~~ {.haskell}
let minimum xs = head (sort xs) in minimum [4,1,3]
~~~

Here the redex choice makes a difference in performance.

Rules in haskell:

* leftmost outermost redex is chosen first
* sharing is introduced: whenever a name is bound to an expression

When no redexes are left, expression is in *normal form*. If top-level of an expression is a constructor or lambda, the expression is in *(weak) head normal form* (even if inside there are still redexes). Weak head normal form is important because it signifies progress in our program.

Evaluation strategies:

* *call by value*/eager (strict) evaluation -- most common. Args are reduced as far as possible before function application
* *call by name* -- not very often, occurs in some macro languages e.g. (TeX). Function is reduced before their arguments, so evalution of args can be run multiple times
* *call by need*/lazy evaluation -- optimised "call by name". Args are only reduced when needed, but shared if used multiple times.

Example of sharing: `\f g x -> combine (f x) (g x)`

From Church-Rosser theorem, each term has at most one normal form -- the order in which redexes are chosen does not affect semantics, only termination/non-termination and performance.

Also: if a term has a normal form, lazy evaluation will always find it, while strict might loop, e.g. `head (repeat 1)`.

Example: the first 100 odd square numbers

~~~ {.haskell}
example :: [Int]
example = (take 100 . filter odd . map (\x -> x * x)) [1..]
~~~

Good thing: lets us separate generation from consumption; in this case we don't know in advance how many numbers we have to generate.

What drives evaluation?

* On top level, in ghci, printing to string.
* In function, pattern matching; we have to evaluate enough of arguments to know which pattern to choose. That's where WHNF comes into play.

#### Tracking Demand

`const x y = x` -- demanding the result demands first arg, but not second

~~~ {.haskell}
True  || _ = True
False || y = y
~~~

will demand first arg, and if it's false, will then demand the second.

We read it backwards: assume the result of the function is depanded and then see what args are required for that. Note that form of function definition has implications for runtime:

~~~ {.haskell}
True  || True = True
True  || False = True
False || True = True
False || False = False
~~~

that would have different properties -- would demand evaluation of both args (no short ciruit!).

~~~ {.haskell}
map f [] = []
map f (x:xs) = f x : map f xs
~~~

This will not demand `f`.

What are other ways for tracking demand? 

#### Bottoms

Feed non-terminating (or undefined) computation into a function and demand its result. Note: if it loops we can't be sure if it was our bomb, or some other problem in the function

Strictness: a function f is called strict iff `f _|_ = _|_`. What follows is a useful optimisation technique: when calling strict functions, it's safe to evaluate the argument before applying the function to it. Compiler does a lot of it; it's allowed because 1) Haskell standard only mandates non-strict semantics, not lazy evaluation and 2) we consider all bottoms equal. Aside, regarding the last point: use `error` for programming errors; for validation use exceptions -- here we care about what error it was.

In a strict language, all functions are strict. In Haskell we have both strict and non-strict functions.

#### Trace

`Debug.Trace`

~~~ {.haskell}
trace :: String -> a -> a
traceShow :: Show a => a -> b -> b
~~~

Provided first arg will be printed when the second arg is demanded (evaluated).

Try the cons/nil trace exercise.

#### Data in Memory

Suspended computations (thunks) are created on the heap. These can be shared just as other subterms. There are subtleties with respect to parallel evaluation, but other than that it's a straightforward pointer replacement when thunk is evaluated, and all users can see the calculated value.

GHC uses generational GC, optimised for lots of short-lived data. Young generation is small (half of L2 cache by default) and collected often. The size of the heap grows and shrinks as required. With lazy evaluation it's hard to predict how long things are held on to -- cause of space leaks.

~~~ {.haskell}
sum1 [] = 0
sum1 (x:xs) = x + sum1 xs
~~~

This will put all of these numbers on stack before they can be summed up. Not heap, because function args are put on stack, not heap.

There are useful RTS options for tracking what's happening. In particular: `-t`, `-s` and `-S`. With `-s` we can see the proportion of time spent in GC (MUT is our program!). Other interesting metrics: maximum residency -- how much memory was needed at once. Gen 0 is young, Gen 1 is old.

Useful tool: ekg gives these stats live!

#### Heap Profiling

need to compile all libraries with profiling, best add `library-profiling: True` to cabal-install config.

Compile: `ghc --make -prof -auto-all -rtsopts Prog`
Run: `Prog +RTS -hc`

`-hc` is for const-centre heap profiling. It then produces .prof and .hp files, the latter can be rendered using hp2svg or hp2ps. Note: amount of live data is shown in the graph, this will be much smaller than total heap size.

----

Improvement of our sum (via tail recursion):

~~~ {.haskell}
sum2 xs = go 0 xs
  where go n [] = n
        go n (x:xs) = go (n + x) xs
~~~

But heap profile looks even worse! That's because all additions are allocated as thunks. So we first build huge list of thunks, and then reducing this chain wil take lots of stack space.

What we really want to do is evaluate `(n + x)` immediately! In fact, if we enable `-O` compiler will do strictness analysis and will evaluate it. However, in more complex scenarios that might not be the case. We need more control over evaluation.

#### Forcing evaluation

~~~ {.haskell}
seq :: a -> b -> b -- primitive
~~~

When second arg is demanded, the first one will be demanded as well. Sane uses of `seq`: first arg is a variable. For it to make sense there needs to be some sharing between firsst and second arg of `seq`.

why `seq :: a -> b -> b` and not `seq :: a -> a`? Because the latter would have been a noop

With this we can define "strict" application:

~~~ {.haskell}
($!) :: (a -> b) -> a -> b
f $! x = x `seq` f x
~~~

Note it will only evaluate x to WHNF, not fully. See interesting quiz in the slides: it illustrates that there is a lot of subtlety in where the bottom is in the structure -- that's a complexity of lazy languages that strict don't have.

So, how do we fix our sum?

~~~ {.haskell}
sum3 xs = go 0 xs
  where go n [] = n
        go n (x:xs) = (go $! n + x) xs
~~~

Note: `n + x 'seq' go (n + x) xs` won't work becuase there's not sharing between the two additions!

Now the heap profile looks reasonable.

Note: 

~~~ {.haskell}
sum1 = foldr (+) 0
sum2 = foldl (+) 0 -- never us it! foldl' is (almost) never worse, often much better
sum3 = foldl' (+) 0
~~~

`foldr` can be e.g. used to implement `map` lazily. In general: if our function is lazy in recursive call, use `foldr`, if it's strict, use `foldl'`.

#### Bang patterns

~~~ {.haskell}
{-# LANGUAGE BangPatterns #-}

sum4 xs = go 0 xs
  where go !n [] = n
        go !n (x:xs) = go (n + x) xs
~~~

The `!` tells the runtime that go is strict in first argument. Strictly speaking, we only need it in the second case, but convention is to put it everywhere. It's easier to understand than `sum3`. `!` only makes sense in front of a variable, not type constructor (because that would cause strictness anyway).

Why we want bang patterns and not rely on strictness analysis?

~~~ {.haskell}
sum5 xs = go 0 xs
  where go n [] = 0
        go n [x] = x + n
        go n (x:xs) = go (n + x) xs
~~~

Here compiler strictness analysis doesnt's work, because the first case does not use n!

#### Strictness analysis

~~~ {.haskell}
sum2 xs = go 0 xs
  where go n [] = n
        go n (x:xs) = go (n + x) xs
~~~

compile with `-ddump-simpl` and behold the core language output (beware of dictionaries for type classes such as `Num`!). If we now run the optimised one, we'll see that function arg is unboxed type, which is by necessity strict. In core, the type of things tells us the calling convention. If we wanted to check strictness for non-primitive type, there is `[Str=DmdType LS]` annotation which tells us demand type for args (L for lazy, S for strict). Also if there is a case in core, the arg affected will always be strictly evaluated.

#### Irrefutable (Lazy) Patterns

~~~ {.haskell}
unzip :: [(a, b)] -> ([a], [b])
unzip = foldr (\(x, y) (xs, ys) -> (x:xs, y:ys)) ([], [])
~~~

This results in stack overflow for large lists. Remember what we said about `foldr`? It should be used with functions lazy in the second arg, but here we have a pair, i.e. pattern match, i.e. strict. Here we know that the arg will always be a pair, so we could rewrite our function as:

~~~ {.haskell}
unzip = foldr (\(x, y) xys -> (x:(fst xys), y:(snd xys))) ([], [])
~~~

and that would fix it, but it complicates the definition somewhat. We can do instead:

~~~ {.haskell}
unzip = foldr (\(x, y) ~(xs, ys) -> (x:xs, y:ys)) ([], [])
~~~

`~` delays evaluation, even though there is a pattern match. Can only be used in front of a constructor where there is only one case in the pattern match. In principle, should only be used for single constructor data types. Comes up infrequently, bang patterns are much more used.

If a pattern is in let/where, it's implicitly irrefutable: `let (xs, ys) = unzip xys in xys`. This can be undone with `!`. Case, on the other hand, is strict by default, so here we can use `~`.

#### `Control.DeepSeq`

`seq` evaluates to WHNF. When it's not sufficient, we can use

~~~ {.haskell}
deepseq :: NFData a => a -> b -> b
($!!) :: NFData a => (a -> b) -> a -> b
force :: NFData a => a -> a
~~~

Note: here `force` makes sence to. Unfortunately `NFData` is not derivable, but definition of instances is mechanical. 

~~~ {.haskell}
instance NFData a => NFData [a] where
  rnf []     = ()
  rnf (x:xs) = rnf x `seq` rnf xs
~~~

Be careful with `deepseq` -- unlike `seq`, it can be expensive to run when unnecessary.

Advice: make accummulating args strict, otherwise don't worry about strictness of arguments. When necessary, use strict data structures instead. Certainly don't sprinkle bangs everywhere, it can make matters worse!


### Parallelism and Concurrency

*Paralleism* is about speed.

On paper, Haskell (and GHC) should be great at parallelism, because function applications are side-effect free: in `f x` in theory it's safe to evaluate `f` and `x` in parallel (even if `f` doesn't need `x`, we have plenty of cores so no harm is done by evaluating `x`). This is particularly attractive if `x` is a producer and `f` a consumer. However:

* there is an overhead in parallelism
* number of cores is limited
* GC is difficult to parallelise (at the moment it's almost stop-the-world)
* non-strictness: it's not clear how to evaluate speculatively

Conclusion: fully automatic parallelism is still an area of research.

*Concurrency* is about having many threads of control and is a goal in its own. This is where Haskell shines.

Unlike most other languages, Haskell offers many approaches to parallelism. 

Deterministic:

* Data-Parallel Haskell (dph) -- experimental, about to be released
* flat data parallelism (repa) -- also accellerate, which runs on GPU
* evaluation strategies (parallel) -- part of Haskell Platform
* safe dataflow specification (monad-par)

Data parallelism is restricted to same operation modifying array of data; with nested we can also process arrays of arrays, even if the inner arrays have different lengths.

Non-deterministic:

* concurrency primitives (`forkIO`, `MVar`)
* software transactional memory (stm)
* high-level async computations (async) -- in Haskell Platform, similar to monad-par, offers futures

#### Evaluation Strategies

`collatz` -- a function that even for small inputs can take long to compute, not proven to terminate for all inputs. A good representative of a function we might want to run in parallel.

~~~ {.haskell}
maxC lo hi = maximum (map (collatz . fromIntegral) [lo..hi])
~~~

Eval monad lets us evaluate safely: `runEval :: Eval a -> a`; we can think of it as an expression with evaluation annotations attached.

~~~ {.haskell}
partest1 n = runEval $ do
    r1 <- rpar $ maxC 1 h
    r2 <- rpar $ maxC (h+1) n
    return (r1 `max` r2)
  where h = n `div` 2
~~~

`rpar` is an evaluation strategy.

Compile with `-O -threaded -rtsopts`, run with `+RTS -s -N2`. If we use `-N`, it will attempt to use all available cores.

#### Eventlog and Threadscope

Event log is an easier to use alternative to profiling. Compile with `-eventlog`, run with `-l`, then read with `ghc-events` or display with `threadscope`. Observe that GC stops the threads.

#### Sparks

`rpar` creates a spark. It says that "this is something I'd like to evaluate to WHNF, but elsewhere". The runtime system creates a spark pointing to that expression and will put it on a spark queue. Whenever there are CPUs that are idle, they will pick up a spark and evaluate (_convert_) it. Note that if main thread evaluates one of sparked expression, the spark will not count as converted, but as _fizzled_. If there is a lot of fizzling it means we don't get as much parallelism as we were hoping for.

The limit of spark queue is 8000. if we create more sparks, they are lost (_overflow_) if we create a spark for something already evaluated, it's _dud_. Sparks can also be garbage collected.

#### Pitfalls of `rpar`

Let's modify our program to also report sum:

~~~ {.haskell}
maxC lo hi = let xs = (map (collatz . fromIntegral) [lo..hi])
             in (maximum xs, sum xs)

partest2 n = runEval $ do
    (max1, sum1) <- rpar $ maxC 1 h
    (max2, sum2) <- rpar $ maxC (h+1) n
    return (max1 `max` max2, sum1 + sum2)
  where h = n `div` 2
~~~

This one, run on two cores, runs longer and converts no sparks. Why? Because pattern matching drives evaluation, we are demanding result immediately. Fix:

~~~ {.haskell}
partest3 n = runEval $ do
    ~(max1, sum1) <- rpar $ maxC 1 h
    ~(max2, sum2) <- rpar $ maxC (h+1) n
    return (max1 `max` max2, sum1 + sum2)
  where h = n `div` 2
~~~

This lets one spark convert, but the time is still long! Looking at spark creation and conversion graphs in threadscope, we see that the spark gets converted immediately at the beginning. Why? Because `rpar` says "evaluate to WHNF"; previously these were ints, which meant fully evaluated. Now, with pair, it's sufficient for it to produce (_thunk_, _thunk_). How do we fix it?

Strategies:

* `r0` -- none (default)
* `rseq` -- WHNF
* `rpar` -- WHNF in parallel
* `rdeepseq` -- annotates for complete evaluation (NF)
* `dot :: Strategy a -> Strategy a -> Strategy a` -- strategy composition (like function composition)

~~~ {.haskell}
partest4 n = runEval $ do
    ~(max1, sum1) <- rpar `dot` rdeepseq $ maxC 1 h
    ~(max2, sum2) <- rpar `dot` rdeepseq $ maxC (h+1) n
    return (max1 `max` max2, sum1 + sum2)
  where h = n `div` 2
~~~

Conclusions: 

* most of the time we want to use `rpar` with `rdeepseq`; monad-par will do this by default. 
* if our parallel program runs slower than non-parallel, we either have not enough parallelism or the overhead is too large -- typically when parallel tasks are too small. 
* Chunks of work should be of reasonable tasks, if something takes just a couple of milliseconds it's usually not worth running in parallel.

#### Dynamic Partitioning

Our example so far used static partitioning that could only use two cores and could lead to imbalance of work between the threads. Recall that `Strategy a` is `a -> Eval a`. We can define a strategy to evaluate elements of list in parallel:

~~~ {.haskell}
evalList s [] = return []
evalList s (x:xs) = do
  r <- s x
  rs <- evalList s xs
  return (r:rs)
parList s = evalList (rpar `dot` s)
~~~

Note that this forces the spine, so might not be ideal for very long lists! 

Note: library already defines this, as well as `evalTraversable` and `parTraversable`, which are more generic.

Now:

~~~ {.haskell}
partest5 n = let cs = map (collatz . fromIntegral) [1..n] `using` parList rdeepseq
             in (maximum cs, sum cs)
~~~

`using` applies a strategy and immediately runs it. When we run it, we get 100000 sparks, with 90% overflowing. How do we fix this? By making individual tasks larger (chunking). There is a strategy for this already defined: `parListChunk`. A problem with this is that we still have to tranverse the entire initial list in order to chunk. This shows that lists are not a great structure for parallelism; trees are better for parallelisation!

~~~ {.haskell}
partest6 n = let cs = map (collatz . fromIntegral) [1..n] `using` parListChunk 500 rdeepseq
             in (maximum cs, sum cs)
~~~

We can define our own map/reduce abstraction (TODO: see slides).

~~~ {.haskell}
combine = ...
threshold = 1000 
partest7 n = mapReduce threshold 1 n rdeepseq
                       ((\x -> (x, x)) . collatz . fromIntegral)
                       (foldl1' combine)
~~~

That's even better, because we don't force spine of the list. We can adapt the threashold (size of chunks) to the number of cores: `GHC.Conc.numCapabilities :: Int`.

#### `Control.Monad.Par`

~~~ {.haskell}
partest 1 n = runPar $ do
    v1 <- spawnP $ maxC 1 h
    v2 <- spawnP $ maxC (h+1) n
    r1 <- get v1
    r2 <- get v2
    return (r1 `max r2)
  where h = n `div` 2
~~~

`spawnP` produces a future (`IVar`), which we retrieve result from using `get`. It applies `deepseq` by default. `IVar` can be written to only once.

What are the advantages of explicit synchronisation using `get`? It makes it easier to structure the flow of parallelism, e.g. control that we don't too many things in parallel. Also lets us express data-dependency graph.

On top of `Par` monad we can create pretty much te same abstractions as for `Eval`; the code will look pretty much the same as with evaluation strategies, we'll just use `runPar`. 

Note: `Par` monad doesn't use sparks, so threadscope feedback is slightly less insightful.

#### `Control.Concurrent.Async`

Very similar in style to `Par` monad, but in `IO`:

* `IVar` -> `Async`
* `spawn` -> `async`
* `get` -> `wait`

In addition, we can `poll`, `cancel` asyncs and tell what should happen when it gets cancelled. `concurrently` takes two asyncs and gives us back a pair of results once both finish.

### Monads and More

`Monad` is a type class. `>>=` is powerful because it lets to determine the next step completely by the results of previous one. Some interesting monads I didn't know about:

* `ST` -- provides local mutable variables, can be executed with `runST` and the code will still be pure
* `Signal` -- time-changing value (useful for FRP)

What when we want to use a couple of these in one place? We can define our own data type and write monad instance for it, but it doesn't feel very compositional. That's where monad transformers come into the picture.

Let's consider that we want to use state as such an aspect.

~~~ {.haskell}
newtype State s a = State { runState :: s -> (a,s) }
~~~

the kind of state is `* -> * -> *`.

~~~ {.haskell}
instance Monad (State s) where
  return x = State (\s -> (x, s))
  m >>= f = State (\s -> case runState m s of (x, s') -> ...)
~~~

Monads typically come int with additional interface:

~~~ {.haskell}
get :: State s s
put :: s -> State s ()
~~~ 

This lets us forget about the implementation of State, we can just use this interface.

Example: 

~~~ {.haskell}
data Expr = Num Int
          | Add Expr Expr
          | Var Name
type Name = String

type Env = Map Name Int

eval :: Expr -> Env -> Int
~~~ 

1. in the simple implementation lookup can fail
2. if we use Maybe (`eval :: Expr -> Env -> Maybe Int`), add case gets ugly because it has to deal with env and Maybe
3. if we just use State (`eval :: Expr -> State Env Int`), we don't have explicit state, but still have to deal with lookup error:

~~~ {.haskell}
eval :: Expr -> State Env Int
eval (Num n)     = return n
eval (Add e1 e2) = (+) <$> eval e1 <*> eval e2
eval (Var x)     = (! x) <$> get
-- or we can use liftM2 and liftM
~~~

Exercise: how do we define `Applicative` instance for an instance of `Monad`?

~~~ {.haskell}
mf <*> ma = do
  f <- mf
  a <- ma
  return (f a)
~~~

Application to DSL: if we represent user's programs as data, we can then inspect them, optimise and transform. This is much easier done with Applicative than with Monad.

Back to the example -- we don't really need State, Reader is sufficient:

~~~ {.haskell}
eval :: Expr -> Reader Env Int
eval (Num n)     = return n
eval (Add e1 e2) = (+) <$> eval e1 <*> eval e2
eval (Var x)     = (! x) <$> ask
~~~

But what about the errors from lookup? We could define `MaybeReader` as a monad, but then we have to redefine `ask` as well -- not very modular. Monad transformers to the rescue: we start with the simplest monad (`Identity`) and build on top of it.

`Identity`: return -- just wraps; bind -- function application.

~~~ {.haskell}
newtype ReaderT r m a = ReaderT { runReaderT :: r -> m a}

instance Monad m => Monad (ReaderT r m) where
  return x = ReaderT (\_ -> return x)
  m >>= f = ReaderT (\r -> do
    a <- runReaderT m r
    runReaderT (f a) r)
~~~

Kind of ReaderT: `* -> (* -> *) -> * -> *`

Now, `Reader a` is just `ReaderT a Identity`. With that, we can do:

~~~ {.haskell}
eval :: Expr -> ErrorT String (Reader Env) Int
eval (Num n)     = return n
eval (Add e1 e2) = (+) <$> eval e1 <*> eval e2
eval (Var x)     = ...
~~~

how do we define `ask` for all monad stacks that contain `ReaderT`?

#### Multi-parameter type classes

Normal type-classes relate two types to each other. Multi-parameter type classes are relations of higher arity.

~~~ {.haskell}
class Monad m => MonadReader r m where
  ask :: m r
  ...

instance Monad m => MonadReader (ReaderT) where
  ask = ...
~~~

but with this we could define both `instance MonadReader Int (Reader Int)` and `instance MonadReader Char (Reader Int)` and the compiler wouldn't allow it. To solve it, we use another language extension:

#### Functional Dependencies

~~~ {.haskell}
class Monad m => MonadReader r m | m -> r where
  ...
~~~

This says that we can't define multiple instances with the same `m` but different `r`

Another way to look at it is that there is a function from a monad to its reader type (type-level function): given a particular monad, we can compute the type of state.

#### Type Families

~~~ {.haskell}
class Monad m => MonadReader m where
  type EnvType m
  ...
~~~

Now we have to specify `EnvType m` for every instance of `MonadReader`. This now plays the role of `r` in previous definition. All monad transformers could be defined using type families instead of functional dependencies. Type families are more recent. There is still a discussion about whether both are needed and which one should make it to the standard. The majority of the community likes type families better.

Why called type families? Because it can be alternatively defined outside of type class:

~~~ {.haskell}
type family EnvType m
...
type instance EnvType (ReaderT r m) ...
~~~

Use case for type families: use a library, but replace all uses of list with dense vector.

#### Defining Monad Transformers

Now we can lift a monad through a transformer:

~~~ {.haskell}
instance
TODO
~~~ 

Issue: we need to define lifting for every pair of transformers!

And finally complete our evaluator:

~~~ {.haskell}
eval (Var x) = do
  env <-ask
  case lookup x env of
    Nothing -> throwError "unknown var"
    Just v  -> return v
~~~

Note: no transformer for IO, but IO can be used as the base of transformer stack.

Conclusions: defining a monad transformer is not trivial, but it's good that we can define our own. Good examples: haskelline (readline implementation, provides `InputT` that can be used on top of `IO`); Parsec.

#### Phantom Types 

Let's consider a variant of our simple language that adds booleans:

~~~ {.haskell}
data Expr = Int n
          | Bool b
          | IsZero Expr

data Val = VInt Int
         | VBool Bool

eval :: Expr -> Val
eval (IsZero e) = case eval e of
  VInt n -> ...
  _      -> error "type error"
~~~

Not nice: a lot of type checking in evaluation, we also carry run-time type tags. This is equivalent to dynamically typed language. What if we wanted a static type checker and have Haskell compiler help us with that?

~~~ {.haskell}
data Expr a = Int Int
            | Bool Bool
            | IsZero (Expr Int)
            | Plus (Expr Int) (Expr Int)
            | If   (Expr Bool) (Expr a) (Expr a)

-- Plus :: Expr Int -> Expr Int -> Expr a
plus :: Expr Int -> Expr Int -> Expr Int -- smart constructor that restricts type
plus = Plus
~~~

Phantom types such as this are useful to impose more rigid typing when binding to C libraries; used eg. for pointers in FFI.

Unfortuantely, this still doesn't let us write `eval :: Expr a -> a`:

~~~ {.haskell}
eval :: Expr a -> a
eval (Int n)  = n
eval (Bool b) = b
-- error: Haskell doesn't know that we used our smart constructor and that `n` and `b` have the right type!
~~~

We can achieve this using another feature of Haskell.

### GADTs

~~~ {.haskell}
data Tree a = Leaf a
            | Node (Tree a) (Tree a)
~~~

alternative formulation:

~~~ {.haskell}
data Tree :: * -> * where
  Leaf :: a -> Tree a
  Node :: Tree a -> Tree a -> Tree a
~~~

This allows us to restrict the result types of constructors.
Note: we can also write `data Tree a where ...`, but it's misleading, because the type variable a isn't scoped over constructors, each is typed independently and can introduce its own variables. Therefore it's better to write the kind instead.

~~~ {.haskell}
data Expr :: * -> * where
  Int  :: Int -> Expr Int
  Bool :: Bool -> Expr Bool
  If   :: Expr Bool -> Expr a -> Expr a -> Expr a
  ...
~~~

Now the evaluator is a piece of cake and doesn't require type tags!

~~~ {.haskell}
eval (Int n) = n
eval (Bool b) = b
...
eval (If e1 e2 e3) = if eval e1 then eval e2 else eval e3
~~~

GADT syntax is better in almost every respect (expect perhaps for trivial enum types) and provides more power.

If we wanted to write actual DSL, we could parse into the untyped (initial datatype), then have a type checker that constructs the typed data type.

#### Principal Types Property

We lose an important property with GADTs: principal types property, i.e. each expression having a single most-generic type.

~~~ {.haskell}
data X :: * -> * where
  C :: Int -> X Int
  D :: X a

f (C n) = [n]
f D     = []
~~~~

here `f` can have type `X a -> [a]` as well as `X a -> [Int]`, which are incomparable! This prevents compiler from doing local type inference. As a result, if we pattern-match on a GADT we have to write a type signature. It's not a very high price to pay.

#### Existential Types

~~~ {.haskell}
...
Fst :: Expr (a, b) -> Expr a
Snd :: Expr (a, b) -> Expr b
~~~~

`Fst` hides type `b` -- `b` is existentially quantified.

A (somewhat) useful example:

~~~ {.haskell}
data Stepper :: * -> * where
  Stepper : s -> (s -> (a,s)) -> Stepper a

counter :: Stepper Int
counter = Stepper 0 (\n -> (n, n+1))

fibs :: Stepper Int
fibs = Stepper (0, 1) (\(x, y) -> (x, (y, x + y)))
~~~

Actually Stepper is a different representataion of an infinite stream.

#### Other Type of Vectors

Name "vector" is also used for lists with fixed length, known statically. Can we encode it in type system?

How do we encode natural numbers in type system?

~~~ {.haskell}
data Zero
data Suc n
type One = Suc Zero
~~~

We could do `Suc Char`, GHC folks are working on providing specific kinds for our types (DataKinds, KindPolymorphism).

Now:

~~~ {.haskell}
data Vec :: * -> * -> * where
  Nil  :: Vec a Zero
  Cons :: a -> Vec a n -> Vec a (Suc n)
~~~

Now, if `map :: (a -> b) -> Vec a n -> Vec b n`, we can't write an incorrect clause for Nil.

How do we deal with `(++)`? We need to add numbers on the type level, i.e. have a type-level function.

~~~ {.haskell}
type family Add (m :: *) (n :: *) :: *
type instance Add Zero n = n
type instance Add (Suc m) n = Suc (Add m n)

(++) :: Vec a m -> Vec a n -> Vec a (Add m n)
~~~

Note: this works nicely, because the recursion on value level matches the recursion on type level. But GHC e.g. doesn't know that Add is symmmetric and commutative.

From list doesn't work:

~~~ {.haskell}
fromList :: [a] -> Vec a n -- what is n?
~~~

We can specify the length as an input or hide the length using an existential type. To do the former, we specify a singleton type:

~~~ {.haskell}
data SNat :: * -> * where
  SZero :: Nat Zero
  SSucc :: SNat n -> SNat (Suc n)

fromList :: SNat n -> [a] -> Vec a n
~~~

For the latter:

~~~ {.haskell}
data VecAny :: * -> * where
  VeAny :: Vec a n -> VecAny a

fromList :: [a] -> VecAny a
~~~

How about `equalLength :: Vec a m -> Vec b n -> Bool`? Not useful, because:

~~~ {.haskell}
if equalLength v w then head (zipWith (,) v, w) else ...
~~~

Doesn't compile, because compiler still doesn't know that lengths of `v` and `w`. 

Lesson: write informative tests in the code; e.g. pattern matching is superior to boolean tests, because the former informs compiler, while the other requires us to keep the result of the test in our head when coding.

In this scenario, we need some sort of evidence that we can provide to the compiler that the values were equal:

~~~ {.haskell}
data Equal :: * -> * -> * where
  Refl :: Equal a a

equalLength :: Vec a m -> Vec b n -> Maybe (Equal m n)
equalLength Nil Nil = Just Refl
equalLength (Cons x xs) (Cons y ys) =
  case equalLength xs ys of
    Just Refl -> Just Refl
    Nothing   -> Nothing
equalLength _ _ = Nothing
~~~

Our method produces a proof of equality.

Lessons: with GADTs and type families we can express advanced contraints on type level. Typically, we start by trying to eliminate certain classes of errors, not with the proof as a goal.