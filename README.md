# aleaiacta

Showcase of Elm

![Aleaiacta screenshot][screenshot]

## Synopsis

Aleaiacta is meant as a showcase of Elm that slightly exceeds the
"toy program" size. It is a multi-file project with library dependencies, non-trivial logic and JavaScript interop. My
intention with it was to play around with Elm and draw a comparison between the Elm Architecture and React/Redux, having
just finished a year-long project on the latter.

## Installation and Running

One needs Elm >v19.1. To build the game, one executes

```shell
elm make src/Aleaiacta.elm --output aleaiacta.js
```

or the equivalent in the Windows shell. This produces
`aleaicta.js` which is used by `aleaiacta.html`. Open
`aleaiacta.html` to play the game, or deploy it along with
`aleaicta.js` and `die*.png` on a web server.

## Mechanics

The actual mechanics of the game are of no importance to the technical discussion they are supposed to provide a basis
for, but one needs to understand them to use the program and maybe have some fun with the game along the way. It is
loosely based on
[Numedoom](https://www.youtube.com/watch?v=_CBeaKVtEqQ).

The board consists of tiles of various values, depicted as die faces, single ones, in fours or in nines. One tries to form 
"chains" of tiles by clicking on them. One can start a "chain" on any tile but, to continue a chain, one must click a
tile with the same value. Clicking one something else ends the chain, although there is an "End Chain" button to do it
explicitly.

But there is a twist: when you click on a _same colored_ tile, the latter doubles in value. This matters because, when a
chain ends, all but the last tile are removed and new tiles are "pushed" to the board. To make the programming logic
even more interesting (programmers have a twisted idea of what is interesting...), the direction from which the new
tiles enter the board (and shove the existing ones to) changes with every chain. There is an arrow indicator on top
which shows the last direction, but new tiles are also shown with a dashed border, so one can see where they came from
anyway.

New tiles have a range of values, and this matters when you try to create ever-higher-valued tiles, because the max
value is the max value that exists currently on the board. So, when one manages to up the max value, new tiles come with
values ranging up to that value, adding to the total value of all tiles on the board.

And now we come to how the score is computed, because the score is actually the total value of all tiles! One starts a
game with a target score in a limited number of moves (we'll see later how this is configured). So, even though the 
usual strategy is to form long chains, so that more new tiles are pushed to the board, creating long chains of
different-colored high-valued tiles might actually drive one's score _lower_! Because the chain (except the last tile)
will be replaced by new tiles that might have _less_ total value! So, there is a strategic element involved in playing.

## The Elm Architecture
Elm is a completely non-mainstream programming language for the Web. It is not a general-purpose language, even though
it borrows concepts and syntax from other languages like [Haskell][haskell] and [PureScript][purescript], which are.
It is a pure functional language, which means that anyone familiar with other such languages will need just a short
introduction in order to use it, while anyone not in that category will have a significant learning curve to master.
It is not in my scope for this document to provide a tutorial on Elm, but I will try to give pointers along the way.
Understanding the Elm Architecture does not really necessitate understanding the minutiae of Elm, the language, and this
is especially true for programmers familiar with React, even more so for users of React/Redux. Bear with me for a while.

### Elm and not-Elm
It is possible to write a useful Elm program completely in Elm, because the Elm Architecture takes care of managing its
piece of the DOM itself. However, to conceptualize the interaction of an Elm program inside the bigger context, it is
useful to understand it as an entity whose actual purpose is to talk to its outside context.

![Elm and not-Elm][elm and not elm]

The dashed arrows are built-in interop, which happens automatically by virtue of writing and executing Elm. The solid
arrows are explicit interop that one can declare in Elm, via the concept of "ports", and implement on "the other side",
in JavaScript. In *Aleaiacta* this is used to interact with Local Storage and with the browser window.

[screenshot]: ./screenshot.jpg
[elm and not elm]: ./ElmAndNonElm.png
[haskell]: https://www.haskell.org/
[purescript]: https://www.purescript.org/
