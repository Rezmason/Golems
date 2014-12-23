Golems
======

Golems is a simple cross-platform Haxe worker system. Its goal is to make it easier for developers to benefit from Haxe's targets' concurrency features.
Golems currently supports the Flash, JS, NekoVM and C++ targets, and perhaps others.

What's inside
-------------

The Golems library currently includes two solutions:

* A simple cross-platform "worker" implementation
    - To kick tasks to a separate thread, wrap them in a `BasicWorker` and invoke them through a `BasicBoss` (usually a `QuickBoss`).
* A cross-platform macro for embedding workers into the main executable
    - Most workers are initialized from separate executables. `Golem::rise` lets you compile and embed workers inline into one executable.

Technically, these two solutions can be used independent of one another. They may in the future be replaced or supplemented with better solutions to the same problems. Additionally, a helper class called `TempAgency` can be used to spin up and manage multiple threads that are performing the same operation on different data simultaneously.


A simple use case
-----------------

`BasicWorker`s are simple objects containing a `process` function of type `TInput->Null<TOutput>`. They run synchronously; they do not return until they're done processing their input. Their output is sent to the main thread, and if an error occurs, that is sent to the main thread as well.

`BasicBoss`es are the objects that maintain communication between the main thread and worker thread. Extending `BasicBoss` is possible, but nine times out of ten, its subclass `QuickBoss` will be sufficient for our needs.

Say you're writing an application that includes a utility to crunch data. One day you find that when the utility is given an especially heavy task, your application becomes unresponsive.

Rats! Well, here's something you can do.

First, create a small hxml project adjacent to your application's. This will be the workers' project. Inside, write a standard compile target description for each platform your application runs on– but prepend each one with the special comment `###GOLEM###`:

    ##GOLEM##
    -main com.whoeveryouare.app.workers.DataCruncher
    -js golems/DataCruncher.js
    -cp src
    -lib golems

You'll want to create a class called `DataCruncher`, then, in the package mentioned above:

    package com.whoeveryouare.app.workers;

    import com.whoeveryouare.app.utils.SlowUtility;
    import net.rezmason.utils.workers.BasicWorker;

    class TestWorker extends BasicWorker<YourInputType, YourOutputType> {
        override function process(input) return SlowUtility.crunchData(input);
    }

There we go! We just wrote a worker. This will compile separately from the rest of your project. No need for a `main` function; Golems shove their own in. You may use a constructor, if you'd like.

To use this worker, we'll shoehorn it into your existing code:

    // grab the worker once
    var worker = Golem.rise('datacruncher.hxml');

    // invoke the boss when you know there's work to be done
    var boss = new QuickBoss(worker, onDataCrunched, onDataCrunchError);
    boss.start();

    // send the worker its work when you have it
    boss.send(someInput);

    // handle the worker's output
    function onDataCrunched(crunchedData:YourOutputType) { ... }

    // optionally handle the worker's errors
    function onDataCrunchError(error:Dynamic) { ... }

    // finally, when you're done with the worker, well...
    boss.die();
    boss = null;


When you build your application, `Golem::rise` will run the Haxe compiler against the worker project, grab the output, and assign it to the `worker` variable. When your code runs, the `boss` will create the worker, start it, communicate with it, and terminate it. Voilà! Your data will be crunched outside your application's event loop, its responsiveness will improve, and you'll be able to shift your focus to the other bugs in your code.


What's not in Golems
--------------------

I suspect the current version of the library will support eighty to ninety percent of what people want from a Haxe concurrency library. Bitcoin miners, bioinformatics lab technicians and AI researchers might wish that Golems had a richer feature set, such as more nuanced communications between threads or shared memory. I'd point them to another library, *if there was one*. 

Maybe Golems will become that library. I'm not only open to contributions, I would in fact like someone else to maintain it, preferably someone who uses concurrency more frequently than I do, or who is more actively involved in the Haxe community than I am.


License
=======

Golems is licensed under the [LGPLv3](LICENSE). It's a real page-turner.
