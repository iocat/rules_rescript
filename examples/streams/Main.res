open Streams

fromArray([1, 2, 3, 4])
->keepMap(item => item->Nums.isEven ? Some(item * 2): None)
->consumeEach(item => item->Js.log)