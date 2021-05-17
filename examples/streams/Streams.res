let map = (stream, functor) =>
  Stream.from(_ =>
    try Some(stream->Stream.next->functor) catch {
    | Stream.Failure => None
    }
  )

let keep = (stream, predicate) =>
  Stream.from(_ => {
    let rec getNext = () => {
      try {
        let next = stream->Stream.next
        if next->predicate {
          Some(next)
        } else {
          getNext()
        }
      } catch {
      | Stream.Failure => None
      }
    }
    getNext()
  })

let toList = (stream: Stream.t<'a>): list<'a> => {
  let l = ref(list{})
  stream->Stream.iter(item => {
    l := l.contents->Belt.List.add(item)
  }, _)
  l.contents
}

let fromArray = items => {
  let i = ref(-1)
  Stream.from(_ => {
    i := i.contents + 1
    if i.contents < items->Belt.Array.length {
      Some(items[i.contents])
    } else {
      None
    }
  })
}

let fromList = Stream.of_list

let discard = (stream, predicate) => stream->keep(item => !(item->predicate))

let fork = stream => {
  open Belt
  let q1 = MutableQueue.make()
  let q2 = MutableQueue.make()

  let makeStream = (. myQueue, otherQueue): (int => option<'a>) => {
    _ => {
      open MutableQueue
      if myQueue->isEmpty {
        try {
          // Consumes from the original queue and broadcast it to the other stream.
          let value = stream->Stream.next
          otherQueue->add(value)
          Some(value)
        } catch {
        | Stream.Failure => None
        }
      } else {
        myQueue->pop
      }
    }
  }

  (Stream.from(makeStream(. q1, q2)), Stream.from(makeStream(. q2, q1)))
}

let keepMap = (stream, predicate) =>
  Stream.from(_ => {
    let rec getNext = () => {
      try {
        let next = stream->Stream.next
        switch next->predicate {
        | Some(mappedNext) => Some(mappedNext)
        | None => getNext()
        }
      } catch {
      | Stream.Failure => None
      }
    }
    getNext()
  })

let fold = (stream, accum, reducer) => {
  let result = ref(accum)
  stream->Stream.iter(item => {
    result := reducer(result.contents, item)
  }, _)
  result.contents
}

let flatten = streams => {
  let currStream = ref(None)

  let rec next = (_index: int) => {
    switch currStream.contents {
    | None =>
      try {
        currStream := Some(streams->Stream.next)
        next(_index)
      } catch {
      | Stream.Failure => {
          currStream := None
          None
        }
      }

    | Some(curr) =>
      try {
        let nextItem = curr->Stream.next
        Some(nextItem)
      } catch {
      | Stream.Failure => {
          currStream := None
          next(_index)
        }
      }
    }
  }

  Stream.from(next)
}

let concat2 = (a, b) => fromList(list{a, b})->flatten
let concat3 = (a, b, c) => fromList(list{a, b, c})->flatten
let concat4 = (a, b, c, d) => fromList(list{a, b, c, d})->flatten
let concat5 = (a, b, c, d, e) => fromList(list{a, b, c, d, e})->flatten

let zip2 = (a, b) =>
  Stream.from(_ => {
    try {
      let itemA = a->Stream.next
      let itemB = b->Stream.next
      Some((itemA, itemB))
    } catch {
    | Stream.Failure => None
    }
  })

let zip3 = (a, b, c) =>
  Stream.from(_ => {
    try {
      let itemA = a->Stream.next
      let itemB = b->Stream.next
      let itemC = c->Stream.next
      Some((itemA, itemB, itemC))
    } catch {
    | Stream.Failure => None
    }
  })

let zip4 = (a, b, c, d) =>
  Stream.from(_ => {
    try {
      let itemA = a->Stream.next
      let itemB = b->Stream.next
      let itemC = c->Stream.next
      let itemD = d->Stream.next
      Some((itemA, itemB, itemC, itemD))
    } catch {
    | Stream.Failure => None
    }
  })

let zip5 = (a, b, c, d, e) =>
  Stream.from(_ => {
    try {
      let itemA = a->Stream.next
      let itemB = b->Stream.next
      let itemC = c->Stream.next
      let itemD = d->Stream.next
      let itemE = e->Stream.next
      Some((itemA, itemB, itemC, itemD, itemE))
    } catch {
    | Stream.Failure => None
    }
  })

let zipMany = streams => {
  let allStreams = streams->toList

  Stream.from(_ => {
    try Some(allStreams->Belt.List.map(stream => stream->Stream.next)) catch {
    | Stream.Failure => None
    }
  })
}

let void = () => Stream.from(_ => None)
let once = value => Stream.of_list(list{value})
let infinite = value => Stream.from(_ => Some(value))
let consumeEach = (stream, work) => stream->Stream.iter(work, _)
let iterateEach = (stream, work) => {
  let (og, forked) = stream->fork
  og->consumeEach(work)
  forked
}

let sumInt = stream => stream->fold(0, (a, b) => a + b)
let sumFloat = stream => stream->fold(0., (a, b) => a +. b)
let join = (~sep=" ", stream) =>
  stream->fold("", (acc, item) => acc == "" ? item : Js.String2.concatMany(acc, [sep, item]))