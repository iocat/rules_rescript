// open Nums

open Streams.StreamUtil
open Nums

fromArray(Belt.Array.range(0, 1_000))
  ->keepMap(item => item->isEven ? Some(item * 2): None)
  ->map(item => item*item)
  ->consumeEach(item => item->Js.log)