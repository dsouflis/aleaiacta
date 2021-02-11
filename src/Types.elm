module Types exposing (..)

import Random
import Time

import Board exposing (..)
import SavedNameList

type Msg =
  Click Int Int
  | Stop
  | Tick Time.Posix
  | Save
  | Delete
  | Reload
--  | Load
  | SetModel (Maybe SavedModel)
  | SavedNameListMsg SavedNameList.Msg
  | SaveDone Bool
  | SavedNamesSet (List String)


type alias Model =
  { sz : Int
  , moves : Int
  , chainMoves : Int
  , chains : Int
  , directionCounter : Int
  , lastPos : Maybe (Int, Int)
  , ar : Board
  , seed : Random.Seed
  , timeSec : Int
  , timeNow : Int
  , initSum : Int
  , curSum : Int
  , maxValue : Int
  , savedNameListModel : SavedNameList.Model
  , goalScore : Int
  , goalChains : Int
  , nameForSave: String
  }

type alias SavedModel =
  { sz : Int
  , moves : Int
  , chainMoves : Int
  , chains : Int
  , directionCounter : Int
  , lastPos : Maybe (Int, Int)
  , ar : SavedBoard
  , timeSec : Int
  , timeNow : Int
  , initSum : Int
  , curSum : Int
  , maxValue : Int
  , goalScore : Int
  , goalChains : Int
  }

modelFromSavedModel : Random.Seed -> SavedNameList.Model -> SavedModel -> Model
modelFromSavedModel seed savedNameList model =
  { sz = model.sz
  , moves = model.moves
  , chainMoves = model.chainMoves
  , chains = model.chains
  , directionCounter = model.directionCounter
  , lastPos = model.lastPos
  , ar = boardFromSavedBoard model.ar
  , seed = seed
  , timeSec = model.timeSec
  , timeNow = model.timeNow
  , initSum = model.initSum
  , curSum = model.curSum
  , maxValue = model.maxValue
  , savedNameListModel = savedNameList
  , goalScore = model.goalScore
  , goalChains = model.goalChains
  , nameForSave = "state"
  }

savedModelFromModel : Model -> SavedModel
savedModelFromModel model =
  { sz = model.sz
  , moves = model.moves
  , chainMoves = model.chainMoves
  , chains = model.chains
  , directionCounter = model.directionCounter
  , lastPos = model.lastPos
  , ar = savedBoardFromBoard model.ar
  , timeSec = model.timeSec
  , timeNow = model.timeNow
  , initSum = model.initSum
  , curSum = model.curSum
  , maxValue = model.maxValue
  , goalScore = model.goalScore
  , goalChains = model.goalChains
  }
