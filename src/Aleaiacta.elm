port module Aleaiacta exposing (..)

import Browser
import Debug exposing (toString)
import Random
import Time
import Basics exposing ((^))

import SavedNameList
import Board exposing (..)
import Types exposing (..)
import View exposing (..)

type alias Flags =
  { sz : Int
  , seed : Int
  , goalScore : Int
  , goalChains : Int
  , now : Int
  , names: List String
  }

port localStorageSaveState : { name : String, model : SavedModel } -> Cmd msg
port localStorageSaveStateResp : (Bool -> msg) -> Sub msg

port localStorageLoadState : String -> Cmd msg
port localStorageLoadStateResp : (Maybe SavedModel -> msg) -> Sub msg

port localStorageListNames : () -> Cmd msg
port localStorageListNamesResp : (List String -> msg) -> Sub msg

port localStorageDelete : () -> Cmd msg

port reload: () -> Cmd msg

init : Flags -> ( Model, Cmd Msg )
init {sz, seed, goalScore, goalChains, now, names} =
  let
    (mat, seed1) = Random.step (genBoard sz 4) (Random.initialSeed seed)
    t = tally mat
  in
  ({ sz = sz
  , moves = 0
  , chainMoves = 0
  , chains = 0
  , directionCounter = 1
  , lastPos = Nothing
  , ar = oldify mat
  , seed = seed1
  , timeSec = 0
  , timeNow = now
  , initSum = t
  , curSum = t
  , maxValue = maxMat mat
  , savedNameListModel = names
  , goalScore = goalScore
  , goalChains = goalChains
  , nameForSave = "state"
  }, localStorageListNames () {-- Cmd.none --})

chainedLocations : Int -> Int -> Int -> Int -> Bool
chainedLocations i j prevI prevJ = Basics.abs (prevI - i) > 1 || Basics.abs (prevJ - j) > 1 -- || Basics.abs (prevI - i) * Basics.abs (prevJ - j) > 0

maxPower : Int -> Int
maxPower maxValue = Basics.max 4 <| floor (logBase 2 (toFloat maxValue))

updFirstMove : Element -> Element
updFirstMove el = {el | status = GreyedOut}

direction : Int -> Direction
direction c =
  case c of
    0 -> Forwards
    1 -> Forwards
    _ -> Backwards

cr : Int -> ColumnOrRow
cr c =
  case c of
    1 -> Column
    _ ->Row

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
  Click i j ->
    let {sz, lastPos, ar, moves, chainMoves, chains, directionCounter, seed, timeSec, maxValue} = model in
      case lastPos of
        Nothing -> -- No previous move
          let
            ar1 = updateBoard sz i j updFirstMove ar
          in
            ({ model | ar = ar1, curSum = tally ar, moves = moves + 1, chainMoves = chainMoves + 1, lastPos = Just (i, j)}, Cmd.none)
        Just (prevI, prevJ) -> -- Previous move exists
          if chainedLocations i j prevI prevJ then -- New chain starts
            let
              (mat1, seed1) = refreshBoard sz (cr directionCounter) (direction directionCounter) (maxPower maxValue) prevI prevJ ar seed
            in
              update msg { model | seed = seed1, moves = moves, chainMoves = 0, chains = chains + 1, directionCounter = modBy 3 (directionCounter + 1), ar = mat1, curSum = tally mat1, lastPos = Nothing }
          else -- Possibly chained move
            let
              prevEl = getBoardElement sz prevI prevJ ar
              el = getBoardElement sz i j ar
            in
              if el.status == Active then -- Possibly chained move
                if prevEl.value == el.value then -- Chained move
                  if prevEl.color == el.color then -- Same color, double value
                    let
                      ar1 = oldify <| setBoardElement sz i j {el | value = el.value * 2, status =  GreyedOut} ar
                    in
                      ({ model | ar =  ar1, curSum = tally ar1, maxValue = maxMat ar1, moves = moves + 1, chainMoves = chainMoves + 1, lastPos = Just (i, j)}, Cmd.none)
                  else
                    let
                      ar1 = oldify <| setBoardElement sz i j {el | status = GreyedOut} ar
                    in
                      ({ model | ar = ar1, curSum = tally ar1, maxValue = maxMat ar1, moves = moves + 1, chainMoves = chainMoves + 1, lastPos = Just (i, j)}, Cmd.none)
                else -- Restart chain
                  let
                    (mat1, seed1) = refreshBoard sz (cr directionCounter) (direction directionCounter) (maxPower maxValue) prevI prevJ ar seed
                  in
                    update msg { model | ar = mat1, curSum = tally mat1, moves = moves, chainMoves = 0, chains = chains + 1, directionCounter = modBy 3 (directionCounter + 1), lastPos = Nothing, seed = seed1 }
              else (model, Cmd.none) --invalid move
  Stop ->
      let {sz, lastPos, ar, seed, maxValue, chains, directionCounter} = model in
        case lastPos of
          Nothing -> -- No previous move
            (model, Cmd.none)
          Just (prevI, prevJ) -> -- Previous move exists
            let
              (mat1, seed1) = refreshBoard sz (cr directionCounter) (direction directionCounter) (maxPower maxValue) prevI prevJ ar seed
            in
              ({ model | seed = seed1, ar = mat1, curSum = tally mat1, chainMoves = 0, chains = chains + 1, directionCounter = modBy 3 (directionCounter + 1), lastPos = Nothing }, Cmd.none)
  Tick t ->
    let {timeSec} = model in
      ({ model | timeSec = timeSec + 1, timeNow = Time.posixToMillis t, nameForSave = "s" ++ (toString (Time.posixToMillis t))}, Cmd.none)
  Save ->
    ({model | savedNameListModel = model.savedNameListModel ++ [model.nameForSave]}, localStorageSaveState { name = model.nameForSave, model = savedModelFromModel model})
  Delete ->
    ({model | savedNameListModel = []}, localStorageDelete ())
  SaveDone _ ->
    (model, localStorageListNames ())
  Reload ->
    (model, reload ())
--  Load ->
--    (model, localStorageLoadState "state")
  SetModel Nothing ->
    (model, Cmd.none)
  SetModel (Just sm) ->
    let newModel = (modelFromSavedModel model.seed model.savedNameListModel sm) in
    ({newModel | timeSec = 0} , Cmd.none)
  SavedNameListMsg (SavedNameList.LoadName name) ->
    (model, localStorageLoadState name)
  SavedNamesSet names ->
    let
      (updatedSavedNameListModel, savedNameListCmd) = SavedNameList.update (SavedNameList.SetNames names) model.savedNameListModel
    in
      ({ model | savedNameListModel = updatedSavedNameListModel }, Cmd.map SavedNameListMsg savedNameListCmd )
  SavedNameListMsg subMsg ->
    let
      (updatedSavedNameListModel, savedNameListCmd) = SavedNameList.update subMsg model.savedNameListModel
    in
      ({ model | savedNameListModel = updatedSavedNameListModel }, Cmd.map SavedNameListMsg savedNameListCmd )

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.batch [ Time.every 1000 Tick, localStorageLoadStateResp SetModel, localStorageListNamesResp SavedNamesSet, localStorageSaveStateResp SaveDone ]

main : Program Flags Model Msg
main =
  Browser.element
  { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }
