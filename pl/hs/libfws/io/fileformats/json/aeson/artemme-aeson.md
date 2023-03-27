% Aeson: the tutorial

[Skip to the actual tutorial][The actual tutorial] if you don't want to read a mini-rant.

-----------------------------------------------------------------------------

[Aeson](@hackage:aeson) is the most widely used library for parsing [JSON](@w) (I think). It's also hopelessly magical for people who try to learn it by looking at provided examples, because...


An analogy
----------

Examples in Aeson documentation:

~~~ haskell
f :: Int -> Int
f 0 = 1
f 1 = 2
f 2 = 3
~~~

The user wants to write:

~~~ haskell
f :: Int -> Int
f x = if even x then x `div` 2 else x*3 + 1
~~~

Failure. Confusion. Frustration. Pain. Anger.


Other Aeson tutorials, which are all worse than this one
--------------------------------------------------------

* [Parsing JSON with Aeson][tut-1]
* [Yet another Aeson tutorial][tut-2]
* [Parsing nested JSON in Haskell with Aeson][tut-3]
* [JSON, Aeson and Template Haskell for fun and profit][tut-4]
* [Easy JSON parsing in Haskell with Aeson][tut-5]
* [24 days of Hackage: aeson][tut-6]

[tut-1]: https://www.fpcomplete.com/school/starting-with-haskell/libraries-and-frameworks/text-manipulation/json
[tut-2]: http://doingmyprogramming.com/2014/04/14/yet-another-aeson-tutorial/
[tut-3]: http://the-singleton.com/2012/02/parsing-nested-json-in-haskell-with-aeson/
[tut-4]: http://pltconfusion.com/2014/05/10/json_aeson_and_template_haskell_for_fun_and_profit/
[tut-5]: http://blog.raynes.me/blog/2012/11/27/easy-json-parsing-in-haskell-with-aeson/
[tut-6]: https://ocharles.org.uk/blog/posts/2012-12-07-24-days-of-hackage-aeson.html

Of course, I tried to make sure that all bits of information present in those other tutorials are in mine as well – otherwise mine couldn't possibly be better. You can still say that mine is worse because it's longer or written in some way you don't like or something, but at least you can't *conclusively* say that mine is worse.

(Also, I honestly haven't left out any good tutorials on purpose. If you know some I missed while googling, send me a link.)


The actual tutorial
-------------------

### A note on string types

For following examples to work, you need to enable the `OverloadedStrings` extension – either by writing `{-# LANGUAGE OverloadedStrings #-}` at the top of the module, or doing `:set -XOverloadedStrings` in GHCi prompt. The reason is:

* Most of the time you have JSON in a file or receive it over network, so JSON decoding/encoding functions work with [`ByteString`][] and not with [`String`][] or [`Text`][]. (If you need to convert JSON to/from `Text`, there's a possibility you're doing something wrong.)

* Normally string literals like `"foo"` can only mean `String`.

* The `OverloadedStrings` extension lifts this restriction and lets string literals be converted to `ByteString` or `Text` automatically.

So, if you want to read JSON from a file, for instance, you should read it with [`Data.ByteString.Lazy.readFile`][] and not with Prelude's [`readFile`][]. If you really need it for some reason, you can also convert a `ByteString` to/from `String` by using [`fromString`][] and [`toString`][] from [`Data.ByteString.Lazy.UTF8`][] in the [utf8-string](@hackage) package, or to/from `Text` by using [`encodeUtf8`][] and [`decodeUtf8`][] from [`Data.Text.Lazy.Encoding`][] – but don't expect good performance.

### Very basic decoding and encoding

There are 2 main classes used in Aeson – [`FromJSON`][] and [`ToJSON`][]. A type which you want to convert to/from JSON should be an instance of these classes. You can think of `FromJSON` as of [`Read`][], and of `ToJSON` as of [`Show`][] – but instead of reading from a string or convering to a string, you read from JSON or convert to JSON.

There are also 2 functions for actually doing “reading” and “showing”, which are called [`decode`][] and [`encode`][]. (`decode` differs from `read` a bit by returning `Nothing` if reading was unsuccessful, instead of throwing an exception – so, it's closer to [`readMaybe`][] in this regard.)

An example of decoding a list of integers from JSON:

~~~ {.haskell .repl}
> import Data.Aeson

> decode "[1,2,3]" :: Maybe [Integer]
Just [1,2,3]

> decode "foo" :: Maybe [Integer]
Nothing
~~~

If you want to see the error too, use [`eitherDecode`][]:

~~~ {.haskell .repl}
> eitherDecode "[]" :: Either String Integer
Left "when expecting a Integral, encountered Array instead"
~~~

An example of encoding a list of integers to JSON:

~~~ {.haskell .repl}
> encode [1,2,3]
"[1,2,3]"
~~~

### Working directly with JSON

Aeson has its own datatype for representing JSON, which is called simply [`Value`][`type Value`]. It has got 6 constructors:

~~~ haskell
data Value
  = Object Object	 
  | Array Array	 
  | String Text	 
  | Number Scientific	 
  | Bool Bool	 
  | Null
~~~

So, if you want to construct JSON directly, you can do it by constructing a `Value` and then converting it to JSON with `encode`:

~~~ haskell
val :: Value
val = Object $ fromList
  [ ("numbers", Array $ fromList [Number 1, Number 2, Number 3])
  , ("boolean", Bool True) ]
~~~

~~~ {.haskell .repl}
> import qualified Data.Text.Lazy.IO as T
> import qualified Data.Text.Lazy.Encoding as T

> T.putStrLn . T.decodeUtf8 . encode $ val
{"boolean":true,"numbers":[1,2,3]}
~~~

We had to use [`fromList`][] 2 times – once to convert a list of pairs to [`Object`][`type Object`], another time to convert a list to [`Array`][]. These are just type synonyms – the actual types are [`HashMap`][] (for `Object`) and [`Vector`][] (for `Array`).

To make constructing JSON a bit easier, there is a function called [`object`][] (which accepts a list of pairs instead of a `HashMap`) and an operator called [`.=`][] (which is the same as `(,)` except that it also converts the value to JSON). So, this example could be rewritten like this:

~~~ haskell
val :: Value
val = object
  [ "numbers" .= [1,2,3]
  , "boolean" .= True ]
~~~

Working with `Value` is easy as well, just keep in mind that

  * an object is a `HashMap`
  * an array is a `Vector`
  * a string is a `Text`
  * a number is [`Scientific`][] (because JSON doesn't specify precision and so a type which allows arbitrary precision is used)

For instance, here's a function which reverses all strings in a `Value`:

~~~ haskell
import qualified Data.Text as T
import qualified Data.HashMap.Strict as H

revStrings :: Value -> Value
revStrings (String x) = String (T.reverse x)
revStrings (Array x)  = Array (fmap revStrings x)
revStrings (Object x) = let revPair (k, v) = (T.reverse k, revStrings v)
                        in  Object . H.fromList . map revPair . H.toList $ x
revStrings other      = other
~~~

You can combine it with `encode` and `decode`, if you want:

~~~ {.haskell .repl}
> import qualified Data.Text.Lazy.IO as T
> import qualified Data.Text.Lazy.Encoding as T

> let revJSON = encode . revStrings . fromJust . decode

> T.putStrLn . T.decodeUtf8 . revJSON . T.encodeUtf8 =<< T.getLine
{"numbers":[1,2,3],"names":["Jane","Artyom"]}
{"seman":["enaJ","moytrA"],"srebmun":[1,2,3]}
~~~

### Parsing simple types

Let's say our task is to parse an array of objects, each of which has fields "a" (a string) and "b" (a boolean), into a list of tuples. How shall we do it?

First, let's write a parser for inner objects. In Aeson, a `Parser a` means pretty much the same as `Either String a` – you can get either `a` from it, or an error message. (The actual implementation is different, and uses CPS for speed, but it's not important.) So, a *parser* actually has the type `Value -> Parser a`; in our case, it shall be `Value -> Parser (String, Bool)`.

~~~ haskell
parseTuple :: Value -> Parser (String, Bool)
~~~

What now? Okay, we know that the `Value` has to be an `Object`, but what to do about other types? Well, we can just use [`fail`][] to signal an error:

~~~ haskell
parseTuple (Object o) = ...
parseTuple _          = fail "expected an object"
~~~

The thing about `Parser` is that it's a monad (and also [`Applicative`][] and [`Alternative`][]), so we can use all the usual things on it; if you ever used [Parsec](@hackage:parsec), this shouldn't be too unfamiliar for you.

Now we can already kinda write our function, by doing manual lookups in the object:

~~~ haskell
parseTuple (Object obj) = do
  -- Look up the "a" field.
  let mbFieldA = H.lookup "a" obj

  -- Fail if it wasn't found.
  fieldA <- case mbFieldA of
    Just x  -> return x
    Nothing -> fail "no field 'a'"

  -- Extract the value from it, or fail if it's of the wrong type.
  a <- case fieldA of
    String x -> return (T.unpack x)
    _        -> fail "wrong type of field 'a'"

  -- Do all the same for "b" (in a slightly terser way, to save space):
  b <- case H.lookup "b" obj of
    Just (Bool x) -> return x
    Just _        -> fail "wrong type of field 'b'"
    Nothing       -> fail "no field 'b'"

  -- That's all!
  return (a, b)
~~~

Parsing an array of tuples is much easier:

~~~ haskell
import qualified Data.Vector as V

parseArray :: Value -> Parser [(String, Bool)]
parseArray (Array arr) = mapM parseTuple (V.toList arr)
parseArray _           = fail "expected an array"
~~~

If this is confusing, just look at the type of [`mapM`][]:

~~~ haskell
mapM :: Monad m => (a -> m b) -> [a] -> m [b]
~~~

(In GHC 7.10 and newer it's more general, but nothing changes if you consider this less general version.)

`mapM` applies a function to a list (getting `[m a]`) and then “lumps together” all results. What “lumping together” means is different for each type, but in case of `Parser` it's simply “try getting the value out of all parsers, fail if there is any parser that fails, return the value otherwise”. So, in our case the type is:

~~~ haskell
mapM :: (Value -> Parser a) -> [Value] -> Parser [a]
~~~

Finally, when we have a parser for arrays, there's a function called [`parseMaybe`][] in [`Data.Aeson.Types`][], which applies a parser to a value. You still have to `decode` the value before using `parseMaybe`; I wish there was a function in Aeson which would do both tasks, but for some reason there isn't. I guess Aeson wasn't really designed for parsing simple types. Anyway, here goes:

~~~ {.haskell .repl}
> import qualified Data.Text.Lazy.IO as T
> import qualified Data.Text.Lazy.Encoding as T

> s <- T.encodeUtf8 <$> T.getLine      -- Going to enter input now.
[{"a":"hello", "b":true}, {"a":"world", "b":false}]

> parseMaybe parseArray =<< decode s   -- Using =<< to chain Maybes.
Just [("hello",True),("world",False)]
~~~

(The reason I'm using `getLine` is that I'd have to escape all those quotation marks if I used a string literal, and I hate doing that.)

### Avoiding manual type checks

`parseTuple` was fairly big for such a simple task, and one reason for that is that we had to check for type mismatch manually. Instead of doing that, we can use the `with*` family of functions, as well as [`parseJSON`][].

There are 5 functions in the `with*` family: [`withObject`][], [`withText`][], [`withArray`][], [`withScientific`][], and [`withBool`][] (there's also `withNumber`, but it's deprecated and will be removed one day. Instead of explaining what they do, I'll just show an example because this is easy and writing is hard.

`parseArray`, manual version:

~~~ haskell
parseArray :: Value -> Parser [(String, Bool)]
parseArray (Array arr) = mapM parseTuple (V.toList arr)
parseArray _           = fail "expected an array"
~~~

`parseArray`, nicer version:

~~~ haskell
parseArray :: Value -> Parser [(String, Bool)]
parseArray = withArray "array" $ \arr ->
               mapM parseTuple (V.toList arr)
~~~

`withArray` just checks the type and generates an error message for you, that's all.

[`parseJSON`][] is more interesting; basically, it's a universal parser for strings, integers, lists, and so on. It can be many things at once, because it's actually a method of the [`FromJSON`][] typeclass:

~~~ haskell
parseJSON :: FromJSON a => Value -> Parser a
~~~

For instance, take the code we used to parse the string field:

~~~ haskell
  a <- case fieldA of
    String x -> return (T.unpack x)
    _        -> fail "wrong type of field 'a'"
~~~

It just checks the type and either fails or returns the value. For comparison, here's the `FromJSON` instance for `String` (slightly rewritten):

~~~ haskell
instance FromJSON String where
  parseJSON = withText "String" (\s -> return (T.unpack s))
~~~

The same thing, really (except that in case of failure it would say simply “expected String, got ...” instead of “wrong type of field 'a'”). We can use `parseJSON` for both fields, and get shorter code:

~~~ haskell
parseTuple = withObject "tuple" $ \obj -> do
  -- Parse "a".
  a <- case H.lookup "a" obj of
    Just x  -> parseJSON x
    Nothing -> fail "no field 'a'"

  -- Parse "b".
  b <- case H.lookup "b" obj of
    Just x  -> parseJSON x
    Nothing -> fail "no field 'b'"

  -- That's all!
  return (a, b)
~~~

### Avoiding manual lookups

The `lookup`-and-`parseJSON` pattern can be simplified too, by using the [`.:`][] operator, which does exactly what we are doing for each field:

~~~ haskell
(.:) :: (FromJSON a) => Object -> Text -> Parser a
obj .: key = case H.lookup key obj of
               Nothing -> fail ("key " ++ show key ++ " not present")
               Just v  -> parseJSON v
~~~

So, the final form of `parseTuple` is:

~~~ haskell
parseTuple = withObject "tuple" $ \obj -> do
  a <- obj .: "a"
  b <- obj .: "b"
  return (a, b)
~~~

Or, if you like writing things in the applicative style:

~~~ haskell
parseTuple = withObject "tuple" $ \obj ->
               (,) <$> obj .: "a"
                   <*> obj .: "b"
~~~

### `FromJSON` instances for other types

It'd be nice to be able to use `parseJSON` wherever possible. Instances already exist for many types, however, they aren't documented, so I'm going to document them here. (Just in case: this all is valid for aeson-0.8.0.2, and can change, tho I really hope that if it changes there would be a warning somewhere.) If you want to know where to look for such things, it's in the [`Data.Aeson.Types.Instances`][] module.

[`Data.Aeson.Types.Instances`]: http://hackage.haskell.org/package/aeson-0.8.0.2/docs/src/Data-Aeson-Types-Instances.html

  * `()` is `[]` (an empty array).

  * `Bool` is either `true` or `false`.

  * `Char` is a string with a single character in it.

  * `String` and `Text` are strings.

  * Various numeric types are all converted to a number, rounded down if you are converting into an integer (so `"-1.2"` gets decoded as −2). Beware that if you are parsing an `Integer`, someone can write `1e1000000000000` in JSON and your program will eat all your memory.

  * `Rational` is an object with keys `numerator` and `denominator`.

  * Lists and arrays are `[]`-arrays.

  * `Set` is an array too.

  * Tuples of various lengths are arrays. (Moreover, when you parse JSON, you won't be able to parse e.g. `[1,2,3]` as a tuple of length 2.)

  * `Maybe a` is the same as `a`, except that `Nothing` is `null` (which means that you can't distinguish `Nothing` from `Just Nothing`).

  * `Either` is an object with a single key called either `Left` or `Right`.

  * `Map String`, `Map Text`, etc. are objects. (Maps with other types of keys aren't instances at all.)

  * `UTCTime` and `ZonedTime` are represented as strings according to the ISO 8601 standard (specifically, the [ECMA-262][] subset), which every other JSON parser should understand as well. You can also wrap a date into [`DotNetTime`][] to get the non-standard format used by Microsoft.

    [ECMA-262]: http://www.ecma-international.org/ecma-262/5.1/#sec-15.9.1.15

### Records and JSON

(Almost all other Aeson tutorials consist of nothing but this section, which is the reason why people think Aeson is magical – and then they come on IRC and start asking questions about how to do *anything* with Aeson that's not straightforward record-parsing. If you ever decide to write a library, please, please try to prevent this from happening.)

Parsing records is absolutely the same as parsing tuples or whatever else. First get all fields, then put them into a record. You can also make your type an instance of `FromJSON`, to be able to use `decode` instead of `parseMaybe`.

~~~ haskell
-- I'm just going to reuse the example from documentation.
data Person = Person {name :: String, age :: Int}

instance FromJSON Person where
  parseJSON = withObject "person" $ \o ->
    Person
      <$> o .: "name"
      <*> o .: "age"
~~~

The reverse is just as easy:

~~~ haskell
instance ToJSON Person where
  toJSON p = object
    [ "name" .= name p
    , "age"  .= age  p ]
~~~

### `RecordWildCards`

There is a slightly different style, however, which I think is better. It relies on the `RecordWildCards` extension, which does 2 transformations:

* instead of deconstructing the record like `f (Person name age) = ...`, you can write `f Person{..} = ...`

* instead of constructing the record like `Person name age`, you can write `Person{..}`

That's very simple, and very useful.

The code from the previous section, rewritten with `RecordWildCards`:

~~~ haskell
{-# LANGUAGE RecordWildCards #-}

data Person = Person {name :: String, age :: Int}

instance FromJSON Person where
  parseJSON = withObject "person" $ \o -> do
    name <- o .: "name"
    age  <- o .: "age"
    return Person{..}

instance ToJSON Person where
  toJSON Person{..} = object
    [ "name" .= name
    , "age"  .= age  ]
~~~

### Handling extra fields

This should be obvious, but I'll say again just in case: extra fields would be ignored by your parsing functions (if it's not obvious, reread previous sections, because it *should* be obvious – from the first example, where we were doing everything by hand – that it's not possible for the parser to find out about “extra” fields in principle).

You can, of course, check for extra fields by yourself if you want to. Just use [`keys`][] on the object to get a list of fields it has, and then check (with [`\\`][], for instance) whether there are any fields you don't expect there to be.

### Postprocessing

The style that uses `do` is better because it makes postprocessing easier. For instance, imagine that records have fields `name` and `surname`, but you want to combine them when parsing the record:

~~~ haskell
instance FromJSON Person where
  parseJSON = withObject "person" $ \o -> do
    firstName <- o .: "name"
    lastName  <- o .: "surname"
    let name = firstName ++ " " ++ lastName
    age       <- o .: "age"
    return Person{..}
~~~

You could do it in applicative style as well, but it'd be a bit awkward.

### Optional fields

A common situation is that some field can be optional, and if it's not present you want to provide a default value. I'm not sure whether it's *actually* that common, but Aeson provides some operators specifically for this case anyway: [`.:?`][] and [`.!=`][].

~~~ haskell
(.:?) :: FromJSON a => Object -> Text -> Parser (Maybe a)
(.!=) :: Parser (Maybe a) -> a -> Parser a
~~~

`.:?` is just like `.:`, but doesn't fail if the field wasn't found (it does fail if the field was found but has a different type, however). `.!=` takes a parser returning `Maybe a` and supplies it with some default value to be returned if the parser returns `Nothing`. They can be used together like this:

~~~ haskell
instance FromJSON Person where
  parseJSON = withObject "person" $ \o -> do
    name <- o .:  "name"
    age  <- o .:? "age" .!= 18
    return Person{..}
~~~

### More interesting choices

What if you wanted to take age from the `age` field, and if it's not found – from the `AGE` field (because some other software you're using behaves weirdly), and give up only if both fields aren't present? To do this, we can use [`Alternative`][], which provides the [`<|>`][] operator. `a <|> b` can be read as “if `a` doesn't fail, then `a`, otherwise `b`”.

An example:

~~~ haskell
import Control.Applicative

instance FromJSON Person where
  parseJSON = withObject "person" $ \o -> do
    name <- o .: "name"
    age  <- o .: "age" <|> o .: "AGE"
    return Person{..}
~~~

You could choose from a list of parsers, even, with the [`asum`][] function from [`Data.Foldable`][] (which is generalised `choice` from various parsing libraries). Here's how you could deal with age which could be:

* in the `age` field, as a number
* in the `age` field, as a string
* in the `AGE` field, as a tuple consisting of “years” and “months”
* not present but we know that if the name is “John” then it's 24

~~~ haskell
import Control.Applicative
import Control.Monad (when)
import Text.Read (readMaybe)

instance FromJSON Person where
  parseJSON = withObject "person" $ \o -> do
    name <- o .: "name"
    age  <- asum
      -- The simple “number” case.
      [ o .: "age"
      -- The more complicated “string” case.
      , do s <- o .: "age"
           case readMaybe s of
             Nothing -> fail "not a number"
             Just x  -> return x
      -- The “tuple” case.
      , fst <$> o .: "AGE"
      -- The “John” case.
      , do guard (name == "John")
           return 24
      ]
    return Person{..}
~~~

If you don't want to use `fail`, you can use [`empty`][], which is equivalent to `fail "empty"`. There's also [`guard`][] in [`Control.Monad`][], which fails unless some condition is met, and [`when`][], which does something conditionally. The following pieces of code do the same thing:

~~~ haskell
do guard (name == "John")
   return 24
~~~

~~~ haskell
do when (name /= "John") $ fail "mzero"
   return 24
~~~

~~~ haskell
if name == "John"
  then return 24
  else fail "mzero"
~~~

Or, for instance, let's say that you consider a record invalid if the name is “Ann”, because you hate your friend Ann. Then you could simply use `when` to fail whenever Ann appears in your data:

~~~ haskell
instance FromJSON Person where
  parseJSON = withObject "person" $ \o -> do
    name <- o .: "name"
    when (name == "Ann") $
      fail "GO AWAY ANN"
    age  <- o .: "age"
    return Person{..}
~~~

### Types with many constructors

If you have a type with several constructors, such as this one:

~~~ haskell
data Something
  = Person {name :: String, age :: Int}
  | Book {name :: String, author :: String}
~~~

there are several ways to encode it. For instance, you could just use the fact that fields have different names:

~~~ haskell
instance FromJSON Something where
  parseJSON = withObject "book or person" $ \o -> asum
    [ Person <$> o .: "name" <*> o .: "age"
    , Book <$> o .: "name" <*> o .: "author" ]
~~~

Or you could add a separate field denoting the kind of thing encoded:

~~~ haskell
instance FromJSON Something where
  parseJSON = withObject "book or person" $ \o -> do
    kind <- o .: "kind"
    case kind of
      "person" -> Person <$> o .: "name" <*> o .: "age"
      "book"   -> Book <$> o .: "name" <*> o .: "author"
      _        -> fail ("unknown kind: " ++ kind)
~~~

### Nested records

Say, you have JSON looking like this:

~~~ json
{ "name": "Nightfall"
, "author":
    { "name": "Isaac Asimov"
    , "born": 1920 } }
~~~

However, you don't like nested records and you want to convert it into this:

~~~ haskell
data Story = Story
  { name       :: String
  , author     :: String
  , authorBorn :: Int
  }
~~~

Doing this is rather simple; just use the fact that you can use `.:` to get an object out, and then use `.:` on it again. An example:

~~~ haskell
instance ParseJSON Story where
  parseJSON = withObject "story" $ \o -> do
    name <- o .: "name"
    -- authorO :: Object
    authorO <- o .: "author"
    -- Now we can deconstruct authorO.
    author     <- authorO .: "name"
    authorBorn <- authorO .: "born"
    -- And finally return the value.
    return Story{..}
~~~

### Pecularities of parsing top-level values

In the past, some Javascript implementations abused the fact that JSON uses Javascript's syntax, and parsed JSON by simply doing `eval`, which was a horrible security breach because anyone could give some code instead of JSON and get it executed by the “parser”. The solution was to forbid parsing of any top-level value which isn't an array or object, and so this fails:

~~~ {.haskell .repl}
> decode "3" :: Maybe Int
Nothing
~~~

And so does this:

~~~ {.haskell .repl}
> decode "3" :: Maybe Value
Nothing
~~~

To get around it, you have to use the [`value`][] parser (which is an actual Attoparsec parser):

~~~ {.haskell .repl}
> import Data.Attoparsec.ByteString
> import Data.Aeson.Parser

> parseOnly value "3"
Right (Number 3.0)
~~~

### Records and JSON: generics

When you don't care about doing any postprocessing, or handling optional fields, or anything of the sort, you can use generics to make your types instances of `ToJSON` and `FromJSON` without writing *any* boilerplate code, which is really nice. (This trick depends on GHC knowing the internals of your data types and willing to share them with Aeson.)

~~~ haskell
{-# LANGUAGE DeriveGeneric #-}

import GHC.Generics
import Data.Aeson

data Person = Person
  { name :: String
  , age  :: Int
  }
  deriving (Generic)

instance ToJSON Person
instance FromJSON Person
~~~

Starting from GHC 7.10, it's possible to simplify this even further by using the `DeriveAnyClass` extension (which still requires a `Generic` instance):

~~~ haskell
{-# LANGUAGE DeriveGeneric, DeriveAnyClass #-}

import GHC.Generics
import Data.Aeson

data Person = Person
  { name :: String
  , age  :: Int
  }
  deriving (Generic, ToJSON, FromJSON)
~~~

You may still want to be able to control the way field names are treated. If you're using lenses, for instance, you might have your fields prefixed with “_”, but you don't want those underscores to appear in JSON. Aeson provides functions [`genericParseJSON`][] and [`genericToJSON`][], which use generics as well but also take a [`Options`][] parameter which lets you customise some things. For instance, the [`fieldLabelModifier`][] field stores a function to be applied to field names:

~~~ haskell
{-# LANGUAGE DeriveGeneric #-}

import GHC.Generics
import Data.Aeson
import Data.Aeson.Types

data Person = Person
  { _name :: String
  , _age  :: Int
  }
  deriving (Generic)

instance ToJSON Person where
  toJSON = genericToJSON defaultOptions
             { fieldLabelModifier = drop 1 }

instance FromJSON Person where
  parseJSON = genericParseJSON defaultOptions
                { fieldLabelModifier = drop 1 }
~~~

~~~ {.haskell .repl}
> import qualified Data.Text.Lazy.IO as T
> import qualified Data.Text.Lazy.Encoding as T

> T.putStrLn . T.decodeUtf8 . encode $ Person "John" 24
{"age":24,"name":"John"}
~~~

Or you could use the [`camelTo`][] function to turn names like `personName` into `person_name`.

There are other options available, which let you specify e.g. how types with several constructors are encoded, but for that just read the documentation on [`Options`][].

Finally, this approach works just as well on datatypes which aren't records – `data Person = Person String Int`, for instance – but then your types would be encoded as arrays instead of objects.

### Records and JSON: Template Haskell

If you care about performance, you probably should use Template Haskell to generate `ToJSON` and `FromJSON` instances, and not generics, as Template Haskell generates the same code you could've written by hand and so doesn't impose any runtime overhead. A downside is that with Template Haskell enabled, GHC suddenly becomes picky about the order of your declarations (anywhere in the module), and in some cases it's rather annoying.

Documentation in [`Data.Aeson.TH`][] is pretty good, so I'll just give an example:

~~~ haskell
{-# LANGUAGE TemplateHaskell #-}

import Data.Aeson
import Data.Aeson.TH

data Person = Person
  { name :: String
  , age  :: Int
  }

deriveJSON defaultOptions ''Person
~~~

You can also generate instances for several types at once:

~~~ haskell
{-# LANGUAGE TemplateHaskell #-}

import Control.Applicative
import Data.Aeson
import Data.Aeson.TH

data Person = Person
  { name :: String
  , age  :: Int
  }

data Book = Book
  { title, author :: String
  }

concat <$> mapM (deriveJSON defaultOptions) [''Person, ''Book]
~~~

### Strictness

Just for completeness, I'll also mention that there is function called [`decode'`][] which performs strict decoding of JSON, and that the documentation claims that you should use `decode` when you don't plan to access all of parsed data, and `decode'` – when you do. I haven't checked, but I believe the author.

### Comments

You can comment on [Reddit](http://www.reddit.com/r/haskell/comments/324vrx/aeson_the_tutorial_which_actually_tries_to/) or [HN](https://news.ycombinator.com/item?id=9356580).

[`.!=`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:.-33--61-
[`.:?`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:.:-63-
[`.:`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:.:
[`.=`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:.-61-
[`<|>`]: http://hackage.haskell.org/package/base/docs/Control-Applicative.html#v:-60--124--62-
[`Alternative`]: http://hackage.haskell.org/package/base/docs/Control-Applicative.html#t:Alternative
[`Applicative`]: http://hackage.haskell.org/package/base/docs/Control-Applicative.html#t:Applicative
[`Array`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#t:Array
[`ByteString`]: http://hackage.haskell.org/package/bytestring/docs/Data-ByteString-Lazy.html#t:ByteString
[`Control.Monad`]: http://hackage.haskell.org/package/base/docs/Control-Monad.html
[`Data.Aeson.TH`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson-TH.html
[`Data.Aeson.Types`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson-Types.html
[`Data.ByteString.Lazy.UTF8`]: http://hackage.haskell.org/package/utf8-string/docs/Data-ByteString-Lazy-UTF8.html
[`Data.ByteString.Lazy.readFile`]: http://hackage.haskell.org/package/bytestring/docs/Data-ByteString-Lazy.html#v:readFile
[`Data.Foldable`]: http://hackage.haskell.org/package/base/docs/Data-Foldable.html
[`Data.Text.Lazy.Encoding`]: http://hackage.haskell.org/package/text/docs/Data-Text-Lazy-Encoding.html
[`DotNetTime`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#t:DotNetTime
[`FromJSON`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#t:FromJSON
[`HashMap`]: http://hackage.haskell.org/package/unordered-containers/docs/Data-HashMap-Strict.html#t:HashMap
[`Options`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson-Types.html#t:Options
[`Read`]: http://hackage.haskell.org/package/base/docs/Prelude.html#t:Read
[`Scientific`]: http://hackage.haskell.org/package/scientific/docs/Data-Scientific.html#t:Scientific
[`Show`]: http://hackage.haskell.org/package/base/docs/Prelude.html#t:Show
[`String`]: http://hackage.haskell.org/package/base/docs/Prelude.html#t:String
[`Text`]: http://hackage.haskell.org/package/text/docs/Data-Text.html#t:Text
[`ToJSON`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#t:ToJSON
[`Vector`]: http://hackage.haskell.org/package/vector/docs/Data-Vector.html#t:Vector
[`\\`]: http://hackage.haskell.org/package/base/docs/Data-List.html#v:-92--92-
[`asum`]: http://hackage.haskell.org/package/base/docs/Data-Foldable.html#v:asum
[`camelTo`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson-Types.html#v:camelTo
[`decode'`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:decode-39-
[`decodeUtf8`]: http://hackage.haskell.org/package/text/docs/Data-Text-Lazy-Encoding.html#v:decodeUtf8
[`decode`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:decode
[`eitherDecode`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:eitherDecode
[`empty`]: http://hackage.haskell.org/package/base/docs/Control-Applicative.html#v:empty
[`encodeUtf8`]: http://hackage.haskell.org/package/text/docs/Data-Text-Lazy-Encoding.html#v:encodeUtf8
[`encode`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:encode
[`fail`]: http://hackage.haskell.org/package/base/docs/Prelude.html#v:fail
[`fieldLabelModifier`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson-Types.html#v:fieldLabelModifier
[`fromList`]: http://hackage.haskell.org/package/base/docs/GHC-Exts.html#v:fromList
[`fromString`]: http://hackage.haskell.org/package/utf8-string/docs/Data-ByteString-Lazy-UTF8.html#v:fromString
[`genericParseJSON`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:genericParseJSON
[`genericToJSON`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:genericToJSON
[`guard`]: http://hackage.haskell.org/package/base/docs/Control-Monad.html#v:guard
[`keys`]: http://hackage.haskell.org/package/unordered-containers/docs/Data-HashMap-Strict.html#v:keys
[`mapM`]: http://hackage.haskell.org/package/base/docs/Control-Monad.html#v:mapM
[`object`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:object
[`parseJSON`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:parseJSON
[`parseMaybe`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson-Types.html#v:parseMaybe
[`readFile`]: http://hackage.haskell.org/package/base/docs/Prelude.html#v:readFile
[`readMaybe`]: http://hackage.haskell.org/package/base/docs/Text-Read.html#v:readMaybe
[`toString`]: http://hackage.haskell.org/package/utf8-string/docs/Data-ByteString-Lazy-UTF8.html#v:toString
[`type Object`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#t:Object
[`type Value`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#t:Value
[`value`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson-Parser.html#v:value
[`when`]: http://hackage.haskell.org/package/base/docs/Control-Monad.html#v:when
[`withArray`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:withArray
[`withBool`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:withBool
[`withObject`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:withObject
[`withScientific`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:withScientific
[`withText`]: http://hackage.haskell.org/package/aeson/docs/Data-Aeson.html#v:withText
