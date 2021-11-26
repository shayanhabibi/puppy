when not compileOption("threads"):
  echo "This test requres --threads:on"
else:
  import std/os, std/locks, puppy, puppy/requestpools, osproc, streams, times

  var p = startProcess("tests/debug_server", options={poParentStreams})
  sleep(100)

  let t1 = epochTime()
  try:
    var pool = newRequestPool(100)

    for i in 0 ..< 10:
      var handles: seq[(int, ResponseHandle)]
      for j in 0 ..< 100:
        handles.add (j, pool.fetch(Request(
          url: parseUrl("http://localhost:8080/page?ret=" & $j),
          verb: "get"
        )))

      while true:
        var running = 0
        var change = false
        for j in countdown(handles.high, 0, 1):
          let (id, handle) = handles[j]
          if handle.ready:
            let r = handle.response
            doAssert r.code == 200
            doAssert r.headers.len == 1
            doAssert r.body == $id
            handles.del(j)
            change = true
          else:
            inc running

        # if change:
          # echo "running: ", running, "/", handles.len
        if running == 0:
          break

        sleep(1)
  finally:
    let t2 = epochTime()
    echo "Time to complete: ", t2 - t1
    p.terminate()
