# spa framework

A lightweight MVC framework geared towards Single Page Appliations. This framework is meant to serve as a sandbox for your application.


## About

A JavaScript library by Jonnie Spratley.

See the [project homepage](http://jonniespratley.github.io/spa.js/).



## Installation

Using Bower:

    bower install spa

Or grab the [source](https://github.com/jonniespratley/spa/dist/spa.js) ([minified](https://github.com/jonniespratley/spa/dist/spa.min.js)).



## Usage

Basic usage is as follows:

    var n = new spa();

For advanced usage, see the documentation.



## Documentation

Start with `docs/MAIN.md`.

#### Overview
This spa sandbox class is framework agnostic. It is for seperating out the logic that is usllay performed by Single Page Applications.
  
Most SPAs usually need the following:
  
* DOM access / mulitiplation
* HTTP/REST access
* Object/Template compiling
* Router / History
* Modular component driven
* Promisses/Utilities
* Pub/Sub event system


#### Core
The framework is designed to be simple to implement, utilizing the modules to define how the application functions. The modules tell the system when they should be loaded into DOM via routes, what events to bind to, and any other scripts/utils to load as dependencies.


#### Templates
Templates should be placed in the /templates directory and given the same file name as the module and use the .html extension.

#### Routing
The framework adheres to Google's recommended #! convention. 

#### Models
Simple structure for working with models:

#### Utilities

#### URLs
The router will split off any data passed as slash-delimited strings after the initial fragment.

#### Event Binding
Events listeners are created using a simple structur similar to other frameworks:

#### Ajax

#### Persistent Storage
Includes support for persistent storage using localStorage, with a fallback to cookies for older browsers. The methods to utilize this are as follows:

#### Publish/Subscribe
Includes publish + subscribe functions to allow decoupling of events and facilitate interation between modules.


## Contributing

We'll check out your contribution if you:

* Provide a comprehensive suite of tests for your fork.
* Have a clear and documented rationale for your changes.
* Package these up in a pull request.

We'll do our best to help you out with any contribution issues you may have.

## License

MIT. See `LICENSE.txt` in this directory.
