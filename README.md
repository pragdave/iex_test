# IexTest

Elixit comes with a wonderful doctest extension to its testing
framework. This reads the documentation for the functions in your code
and extracts from them and `iex` sessions. It then runs the code in
these sessions and verifies that the output is the same as the output
shown in the example.

Unfortunately, this code is hardwired into the testing framework. It
also only works on `@doc` comments in compiled Elixir files.

I had a need to do something a little different. In the book
_Programming Elixir_, I have lots of sample iex sessions. These are
used to demonstrate various language features. Although the book was
written in Markdown, the iex sessions are actually formatted using a
preprocessor, and it looks for something like this:

~~~
Elixir has some operators that work specifically on lists:

<iex>
iex>  [ 1, 2, 3 ] ++ [ 4, 5, 6 ]      # concatenation
[1,2,3,4,5,6]
iex> [1, 2, 3, 4] -- [2, 4]           # difference
[1,3]
iex> 1 in [1,2,3,4]                   # membership
true
iex> "wombat" in [1,2,3,4]
false
</iex>

#### Keyword Lists {#sec-keyword-list}

Because we often need simple lists of key/value pairs, Elixir gives us
a short-circuit syntax. If you write
~~~

So I wrote a little tool that does the same thing doctest does, but
that works on the book's source files.

## Running The Tool

~~~
$ bin/iex_test path_to_file...
~~~

## Contents of the File

Right now, it only looks for iex sessions between `<iex>` and `</iex>`
tags.

The opening `<iex>` tag can take options:

`in="dir"`

: specify a directory (relative to pwd) in which to run the code. This
  allows you to open files, compile, and so on.
  
`test="no"`

: Do not run iex_test on this example.

## License


The MIT License (MIT)

Copyright © 2013 Dave Thomas

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
