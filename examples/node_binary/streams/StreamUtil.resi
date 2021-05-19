// Lazy stream operations.
let map: (Stream.t<'a>, 'a => 'b) => Stream.t<'b>
let keepMap: (Stream.t<'a>, 'a => option<'b>) => Stream.t<'b>
let keep: (Stream.t<'a>, 'a => bool) => Stream.t<'a>
// Like keep, but the predicate is used to discard.
let discard: (Stream.t<'a>, 'a => bool) => Stream.t<'a>
let fork: Stream.t<'a> => (Stream.t<'a>, Stream.t<'a>)
let fold: (Stream.t<'a>, 'b, ('b, 'a) => 'b) => 'b

let flatten: Stream.t<Stream.t<'a>> => Stream.t<'a>
let concat2: (Stream.t<'a>, Stream.t<'a>) => Stream.t<'a>
let concat3: (Stream.t<'a>, Stream.t<'a>, Stream.t<'a>) => Stream.t<'a>
let concat4: (Stream.t<'a>, Stream.t<'a>, Stream.t<'a>, Stream.t<'a>) => Stream.t<'a>
let concat5: (Stream.t<'a>, Stream.t<'a>, Stream.t<'a>, Stream.t<'a>, Stream.t<'a>) => Stream.t<'a>

let zipMany: Stream.t<Stream.t<'a>> => Stream.t<list<'a>>
let zip2: (Stream.t<'a>, Stream.t<'b>) => Stream.t<('a, 'b)>
let zip3: (Stream.t<'a>, Stream.t<'b>, Stream.t<'c>) => Stream.t<('a, 'b, 'c)>
let zip4: (Stream.t<'a>, Stream.t<'b>, Stream.t<'c>, Stream.t<'d>) => Stream.t<('a, 'b, 'c, 'd)>
let zip5: (
  Stream.t<'a>,
  Stream.t<'b>,
  Stream.t<'c>,
  Stream.t<'d>,
  Stream.t<'e>,
) => Stream.t<('a, 'b, 'c, 'd, 'e)>

// Stream construction.
let void: unit => Stream.t<'a>
let once: 'a => Stream.t<'a>
let infinite: 'a => Stream.t<'a>
let fromList: list<'a> => Stream.t<'a>
let fromArray: array<'a> => Stream.t<'a>

// Stream consumption
let toList: Stream.t<'a> => list<'a>
let consumeEach: (Stream.t<'a>, 'a => unit) => unit
// Similar to consumeEach, but dehydrate the stream,
// do work, and return the clone of it.
//
// This operation revives the stream.
let iterateEach: (Stream.t<'a>, 'a => unit) => Stream.t<'a>

let sumInt: Stream.t<int> => int
let sumFloat: Stream.t<float> => float
let join: (~sep: string=?, Stream.t<string>) => string