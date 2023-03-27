-- Inspired by the writings of Edward Kmett, Edward Yang and Gabriel Gonzalez
-- concerning free monads and the codensity transformation.
--
-- http://comonad.com/reader/2011/free-monads-for-less/
-- http://blog.ezyang.com/2012/01/problem-set-the-codensity-transformation/
-- http://www.haskellforall.com/2012/06/you-could-have-invented-free-monads.html
--
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NamedFieldPuns #-}
module Codensity
       (
         -- Hughes lists
         Hughes
       , fromList, toList
       , (++:)

         -- Tree transformations
       , Tree(..), CTree(..)
       , toTree, fromTree
       , improveTree
       , treesample1, treesample2

         -- Full codensity transformation
       , Free(..)
       , F(..)
       , treeToFree, freeToTree

       , C(..)
       , toC, fromC
       , improve
       ) where
import Prelude hiding (abs)
import Control.Applicative ((<$>))

-------------------------------------------------------------------------------
-- Basic reduction rules

{--
Reduction rules for a lazy language:

     --------------------
     (\x. e) v ==> e[v/x]         (BETA, Reduction)


          e1 ==> e2
     --------------------         (EVAL, Congruence)
        e1 x ==> e2 x
--}


-------------------------------------------------------------------------------
-- Hughes lists, AKA difference lists.

-- Regular lists with linear append

(++.) :: [a] -> [a] -> [a]
(++.) a b = foldr (:) b a

listsample1 as bs cs = (as ++. bs) ++. cs
--                   = foldr (:) cs (as ++. bs)
--                   = foldr (:) cs (foldr (:) bs as)
--                   = foldr (:) cs (foldr (:) bs (a:as))
--                   = foldr (:) cs (a : foldr (:) bs as)
--                   = a : foldr (:) cs (foldr (:) bs as)
--
-- This is obviously linear time per append, because in order
-- to construct the result, evaluation shows we will have
-- to pass over the entire first list.
--
-- NB:
--   foldr f e1 (x:xs) ==> f x (foldr f e1 xs)
-- ergo:
--   foldr (:) e1 (x:xs) ==> (x:) (foldr f e1 xs)
--                        =  x : foldr f e1 xs
--
--

-- Hughes lists with constant-time append/snoc.
type Hughes a = [a] -> [a]

fromList :: [a] -> Hughes a
-- ...   :: [a] -> ([a] -> [a])
fromList = (++)

toList :: Hughes a     -> [a]
-- ... :: ([a] -> [a]) -> [a]
toList = ($ [])

(++:) :: Hughes a     -> Hughes a     -> Hughes a
-- ...  :: ([a] -> [a]) -> ([a] -> [a]) -> ([a] -> [a])
-- ...  :: ([a] -> [a]) -> ([a] -> [a]) -> [a]  -> [a]
(++:) a b c = a (b c)

listsample2 as bs cs = toList (as ++: (bs ++: cs))
--                   = ($ []) (as ++: (bs ++: cs))
--                   = (as ++: (bs ++: cs)) []
--                   = as ((bs ++: cs) [])
--                   = as (bs (cs []))
-- 
-- This takes constant time per *element*. If as, bs and cs
-- are all functions of the form (\x -> z1:z2:..:x), then evaluation looks
-- like:
-- 
--     as = fromList [1,2,3] = ([1,2,3]++)
--     bs = fromList [4,5,6] = ([4,5,6]++)
--     cs = fromList [7,8,9] = ([7,8,9]++)
-- 
-- Then:
-- 
--     as (bs (cs []))
--   = (\z -> [1,2,3] ++ z) (bs (cs []))
--   = [1,2,3] ++ (bs (cs []))
--   = ...
-- 
-- Note crucially that the fold operation has now changed to a function
-- application. Thus, to concatenate is to only take the time of applying
-- a function, which is constant time. If we were to actually iterate the
-- result of this list (via toList,) we would evaluate (++) terms, and
-- thus actually touch the whole list in O(n). But, **as a difference list
-- is actually a function that prepends itself to another list** (i.e.
-- ([1,2,3]++) which is a partial function,) to append is merely to apply
-- a function.
-- 
-- The real gem here underlying all this is that everything is a nice, right
-- associative function application. Laziness means we can begin evaluation
-- without worrying about evaluating the arguments 'right now' and evaluation
-- can be interleaved. Compare:
-- 
--     (f >>= g) >>= h
-- 
-- to:
-- 
--     f >>= (\x -> g x >>= (\y -> h y))
-- 
-- The monad laws of associativity tell us they are the same. But in the first,
-- we build a structure up and tear it down in (f >>= g), and then pass it to
-- 'h' which builds a new structure. Instead, the second acts more lazy-like,
-- and this structural laziness acts like a 'stream' you could think.
-- 
-- 
-- This transformation from lists to difference lists roughly operates like the
-- Codensity transformation, and gets better performance by reassociating those
-- bindings.

-------------------------------------------------------------------------------
-- Tree transformations


-- Tree and Codensity tree data types -----------------------------------------

-- A trivial unordered binary tree, with a natural Monad instance.
data Tree a = Leaf a | Node (Tree a) (Tree a)
  deriving (Eq, Show)

instance Monad Tree where
  return         = Leaf
  Leaf x   >>= f = f x
  Node l r >>= f = Node (l >>= f) (r >>= f)

-- This is inefficient.
treesample1 = (Leaf 0 >>= f) >>= f
  where f n = Node (Leaf (n + 1)) (Leaf (n + 1))

-- Let us force treesample1 to normal form:
-- 
--            (Leaf 0 >>= f) >>= f
--          = (f 0) >>= f
--          = Node (Leaf (0 + 1)) (Leaf (0 + 1)) >>= f
--          = Node (Leaf (0 + 1) >>= f) (Leaf (0 + 1) >>= f)
--          = Node (f (0 + 1)) (f (0 + 1))
--          = Node (Node (Leaf ((0 + 1) + 1)) (Leaf ((0 + 1) + 1))) (Node (Leaf ((0 + 1) + 1)) (Leaf ((0 + 1) + 1)))
--          = Node (Node (Leaf (1 + 1)) (Leaf (1 + 1))) (Node (Leaf (1 + 1)) (Leaf (1 + 1)))
--          = Node (Node (Leaf 2) (Leaf 2)) (Node (Leaf 2) (Leaf 2))

-- The 'C' stands for Codensity. This tree has abstracted leaves.
newtype CTree a = CTree { unCTree :: forall r. (a -> Tree r) -> Tree r }


-- Isomorphisms between tree types --------------------------------------------

fromTree :: Tree a -> CTree a
-- ...   :: Tree a -> (forall r. (a -> Tree r) -> Tree r)
fromTree (Leaf x)   = CTree (\f -> f x)
fromTree (Node l r) = CTree (\f -> Node (l >>= f) (r >>= f))

toTree :: CTree a                             -> Tree a
-- ... :: (forall r. (a -> Tree r) -> Tree r) -> Tree a
toTree (CTree unT)  = unT Leaf

-- Because they are isomorphic, the abstracted version also has a Monad
-- instance.
instance Monad CTree where
  return x        = CTree (\f -> f x)
  -- (>>=) :: m a -> (a -> m b) -> m b
  (CTree f) >>= g = CTree (\h -> f (toTree . g) >>= h)

-- An interface for trees that any monad can satisfy.
class Monad m => TreeLike m where
  node :: m a -> m a -> m a
  leaf :: a -> m a
  leaf = return

instance TreeLike Tree where
  node = Node

instance TreeLike CTree where
  node (CTree l) (CTree r) = CTree $ \f -> Node (l f) (r f)


-- moar faster
improveTree :: (forall m. TreeLike m => m a) -> Tree a
improveTree m = toTree m

-- Example
treesample2 :: CTree Int
treesample2 = (leaf 0 >>= f) >>= f
  where f n = node (leaf (n + 1)) (leaf (n + 1))

treesample2' :: Tree Int
treesample2' = improveTree $ (leaf 0 >>= f) >>= f
  where f n = node (leaf (n + 1)) (leaf (n + 1))

-------------------------------------------------------------------------------
-- General case codensity transformation


-- Free monads
data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Monad (Free f) where
  return        = Pure
  Pure a >>= f  = f a
  Free f >>= g  = Free $ (>>= g) <$> f
  -- f       :: f (Free f a)
  -- g       :: a -> Free f b
  -- fmap    :: (a -> b) -> f a          -> f b
  --         ~  (a -> b) -> f (Free f a) -> f (Free f b)
  -- (>>= g) :: Free f a -> Free f b
  -- (<$> f) :: (a -> b) -> f (Free f a) -> f b
  --         ~  (Free f a -> b) -> f b
  -- 
  -- ergo:
  -- 
  -- Free $ (>>= g) <$> f :: Free f b
  -- 

-- the functor for free monads of trees defined above.
data F a = N a a

instance Functor F where
  fmap f (N a b) = N (f a) (f b)

-- Tree isomorphisms

freeToTree :: Free F a -> Tree a
freeToTree (Pure a)       = Leaf a
freeToTree (Free (N a b)) = Node (freeToTree a) (freeToTree b)

treeToFree :: Tree a -> Free F a
treeToFree (Leaf a)   = Pure a
treeToFree (Node l r) = Free (N (treeToFree l) (treeToFree r))

-- Abstract, codensified monads. Generalized versions of the
-- codensified trees above.
newtype C m a = C { unC :: forall r. (a -> m r) -> m r }

-- Monad isomorphisms
toC :: Monad m => m a -> C m a
toC x = C (x >>=)

fromC :: Monad m => C m a -> m a
fromC (C f) = f return

instance Monad (C m) where
  return x  = C (\f -> f x)
  C f >>= g = C (\h -> f (\a -> unC (g a) h))

class (Functor f, Monad m) => FreeLike f m where
  wrap :: f (m a) -> m a

instance Functor f => FreeLike f (Free f) where
  wrap = Free

instance FreeLike f m => FreeLike f (C m) where
  wrap f = C (\h -> wrap $ (\p -> unC p h) <$> f)

improve :: Functor f => (forall m. FreeLike f m => m a) -> Free f a
improve m = fromC m
