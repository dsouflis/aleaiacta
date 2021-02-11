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

The board consists of tiles of various values, depicted as die faces, single, in fours or in nines. One tries to form "
chains" of tiles by clicking on them. One can start a "chain" on any tile but, to continue a chain, one must click a
tile with the same value. Clicking one something else ends the chain, although there is an "End Chain" button to do it
explicitly.

But there is a twist: when you click on a _same colored_ tile, the latter doubles in value. This matters because, when a
chain ends, all but the last tile are removed and new tiles are "pushed" to the board. To make the programming logic
even more interesting (programmers have a twisted idea of what is interesting...), the direction from which the new
tiles enter the board (and shove the existing ones to) changed with every chain. There is an arrow indicator on top
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

[screenshot]: ./screenshot.jpg
