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

One can save a game in order to go back to it at a separate time, and can delete all saved games. Adding more functionality
to the save/load logic, e.g. allowing one to name the games and to update a game or delete an individual game, is one of
the "extension points" I have left in the program for ambitious Elm programmers!

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
This clean separation of side-effecting and non-side-effecting code reminds one of how [Redux Sagas][redux sagas] are 
written: yielding an effect from inside a Saga, gives control to the Saga middleware to enable outside code to run (which, an Elm 
program does by sending a message to an outgoing "port"), and allows the middleware to communicate a value back to the 
Saga (which, the Elm program receives from the outside JavaScript by means of an incoming "port"). I'll show how ports
look like when we get to the code walkthrough.

### Render, update, repeat if necessary
The Elm Architecture will be very familiar to users of React/Redux, and this is no coincidence, since Elm was one of the
inspirations for Redux. Even though Dan Abramov states he never actually ran Elm, the description of the
Elm Architecture was one of the ideas Redux was based upon, as shown in the README.

While React/Redux fits inside a regular JavaScript program and the user is responsible for all the plumbing necessary,
a user of Elm gives the Elm runtime three things (at first approximation): an initial value of what is called a "model",
a way to render (view) a model, and a way to update the
model based on messages. One would be very justified to make a direct connection...

| from | to |
| ---- | ---|
| model | Redux state |
| view function | React render |
| message | Redux action |
| update function | Redux reducer |

Like in Redux, the model is never updated in-place, the update function just returns the value that will replace the
previous value of the model but, unlike Redux, this is not simply encouraged; it's mandatory and cannot, in fact, happen
in any other way, because there's no mutation in the Elm language. That's right. No assignment of any kind, and no way
to change values. One can only compute new values based on old ones.

### Some additional details
At first approximation, that's what the Elm Architecture is about. But to understand a real Elm program, one must go one
level deeper. The user does not actually give the initial value of the model to Elm, one gives a function to compute the
initial model, and an initial _command_, from any runtime flags that were used to initialize the program. So this is an
initial interaction from the not-Elm world to the Elm world. The update function, also does not just compute a new 
model, it computes a new model and a _command_. And one gives one more function, that computes a list of _subscriptions_
from the model. _Commands_ and _Subscriptions_ are what flow through outgoing and incoming ports. And that is not all, 
because there are even more elaborate ways to initialize an Elm program, but I'll stick to this one because this is what
*Aleaiacta* uses.

## Finally, the code
The entry point of *Aleaiacta* is function `main` in `Aleaiacta.elm`. Function `main` is always the entrypoint of an Elm 
program, and it is defined as

```elm
main : Program Flags Model Msg
main =
  Browser.element
  { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }
```

Elm is a strongly-typed language and, because it does not provide higher-kind polymorphism, its typechecker can do type
inferencing on its own, probably with no exceptions. However, it is considered good practice to write type annotations
for top-level functions. As you can see, main is using the `Browser.element` helper, whose type is

```elm
element :
    { init : flags -> ( model, Cmd msg )
    , view : model -> Html msg
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    }
    -> Program flags model msg
```

Few comments on Elm: the argument to `element` is defined structurally, so you see that it is not mandatory to name
everything with a specific name. The return value of the function type of the `init` field, is a tuple, denoted simply
by parentheses. And the function type of `update` has... two arrows, which may seem weird for people already using types in
Flow or TypeScript. This is because all functions in Elm are curried. So `update` can be thought of as a function taking
an argument (of generic kind) and returning a function taking an argument (again of generic type) and returning a value
of type `( model, Cmd msg )`, a tuple. Because juxtaposition in Elm means function application, one can write an
expression returning a function, followed by a number of expressions, and think of it as applying the function to some
arguments.

*Aleaiacta* defines the following type for its flags:

```elm
type alias Flags =
  { sz : Int
  , seed : Int
  , goalScore : Int
  , goalChains : Int
  , now : Int
  , names: List String
  }
```

Which is computed as follows inside the script in `aleaiacta.html` that initializes Elm.

```javascript
const flags = {
  sz: 5,
  seed: Math.floor(Math.random()*0xFFFFFFFF),
  goalScore: 200,
  goalChains: 20,
  now: Date.now(),
  names: Object.keys(getState())
};
```

Types `Msg` and `Model` are defined in `Types.elm`. The `view` function is factored out in `View.elm`, but the `update`
function is in `Aleaiacta.elm`. However, the logic that updates the board is factored out in `Board.elm`. File 
`SavedNameList.elm` is an example of separating what one could think of as a "component", because it defines the model,
the view function and the update function for the list of saved games. However, because of the strongly-typed nature of
Elm, it is not possible to achieve complete separation, as the type of the model and the message should be reflected in
the model and message of the whole program. One might think of it as a necessary boilerplate or as a nuisance, but it is
an integral part of what Elm is.

Here's how the "component" types are embedded inside the "top-level" types, and the corresponding functions are used.

```elm
type Msg =
  Click Int Int
...
  | SavedNameListMsg SavedNameList.Msg
...

type alias Model =
  { sz : Int
...
  , savedNameListModel : SavedNameList.Model
...
  }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
  Click i j ->
...
  SavedNameListMsg (SavedNameList.LoadName name) ->
    (model, localStorageLoadState name)
...
  SavedNameListMsg subMsg ->
    let
      (updatedSavedNameListModel, savedNameListCmd) = SavedNameList.update subMsg model.savedNameListModel
    in
      ({ model | savedNameListModel = updatedSavedNameListModel }, Cmd.map SavedNameListMsg savedNameListCmd )


```

## Happy Elming!
I encourage you to study the code and even download, run it and try modifying it in small or big ways. It does not seem
possible that Elm will conquer the world, but it is still something that will give ideas and help you avoid the tunnel
vision one can get when only doing one thing and never exposing oneself to new ideas. The Web ecosystem is always 
evolving and, even if Elm is not something that will catch the mainstream's attention, new languages still come about,
like [ReScript][rescript] that are halfway between JavaScript and Elm.

Happy Elming!

[screenshot]: ./screenshot.jpg
[elm and not elm]: ./ElmAndNonElm.png
[haskell]: https://www.haskell.org/
[purescript]: https://www.purescript.org/
[redux sagas]: https://redux-saga.js.org/
[rescript]: https://rescript-lang.org/
