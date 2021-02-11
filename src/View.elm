module View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Parser
import Html.Parser.Util
import Debug exposing (toString)

import Board exposing (..)
import Types exposing (..)
import SavedNameList

textHtml : String -> List (Html.Html msg)
textHtml t =
    case Html.Parser.run t of
        Ok nodes ->
            Html.Parser.Util.toVirtualDom nodes

        Err _ ->
            []
valueClass : Int -> String
valueClass v = "value" ++ (toString v)

statusClass : Status -> String
statusClass s =
  case s of
    GreyedOut -> "greyed-out"
    Active -> "active"

colorClass : Color -> String
colorClass c =
  case c of
    Red -> "red"
    Green -> "green"
    Blue -> "blue"

newnessClass : Newness -> String
newnessClass n =
  case n of
    New -> "new-cell"
    Old -> "old-cell"

currentClass : Maybe (Int, Int) -> Int -> Int -> String
currentClass lastPos i j = if lastPos == Just (i, j) then "current" else ""

valueToString : Int -> String
valueToString val =
  let p = floor (logBase 2 (toFloat val)) in
    if p < 10 then toString val else toString (p - 9) ++ "k"

renderCell : Bool -> Maybe (Int, Int) -> Int -> Int -> Element -> Html Msg
renderCell enableClicks lastPos i j el =
  td ([
  class ((valueClass el.value) ++ " " ++ (statusClass el.status) ++ " " ++ (colorClass el.color) ++ " " ++ (newnessClass el.newness) ++ " " ++ (currentClass lastPos i j))
  ] ++ if enableClicks then [onClick (Click i j)] else []) []

renderRow : Int -> Bool -> Maybe (Int, Int) -> Int -> Board -> Html Msg
renderRow sz enableClicks lastPos i b =
  tr [] (boardRowIndexedMap sz b i (renderCell enableClicks lastPos))

aux i accum sz enableClicks lastPos b=
    if i == -1 then accum
    else aux (i - 1) ((renderRow sz enableClicks lastPos i b) :: accum) sz enableClicks lastPos b

renderBoard : Int -> Bool -> Maybe (Int, Int) -> Board -> List (Html Msg)
renderBoard sz enableClicks lastPos b =
  aux (sz - 1) [] sz enableClicks lastPos b

renderDirectionCounter : Int -> List (Html msg)
renderDirectionCounter i =
  case i of
    0 -> textHtml "&#8594;" --">"
    1 -> textHtml "&#8592;" --"v"
    _ -> textHtml "&#8595;" --"<"

inPlay : Model -> Bool
inPlay model =
  model.chains < model.goalChains

promptText : Model -> String
promptText model =
  if model.moves == 0
  then "Get " ++ (toString model.goalScore) ++ " points in " ++ (toString model.goalChains) ++ " moves"
  else if inPlay model
       then if (model.curSum - model.initSum) < model.goalScore
            then "Get " ++ (toString (model.goalScore - model.curSum + model.initSum)) ++ " more points in " ++ (toString (model.goalChains - model.chains)) ++ " more moves"
            else "Get as many points as you can in " ++ (toString (model.goalChains - model.chains)) ++ " more moves"
       else if (model.curSum - model.initSum) < model.goalScore
            then "You lost"
            else "You won with " ++ (toString (model.curSum - model.initSum)) ++ " points"

renderSavedModelList : SavedNameList.Model -> List (Html Msg)
renderSavedModelList savedNameListModel =
  if not (SavedNameList.isEmpty savedNameListModel)
  then
    [ Html.map SavedNameListMsg (SavedNameList.view savedNameListModel) ]
  else []

debugOutput: Model -> Html msg
debugOutput model =
              text ("DEBUG> "
                ++ (toString model.timeSec)
                ++ "s, moves: " ++ (toString model.moves)
                ++ ", score= " ++ (toString (model.curSum - model.initSum))
                ++ ", chains: " ++ (toString model.chains)
                ++ ", max: " ++ (toString model.maxValue)
                ++ " (2^" ++ (toString (logBase 2 (toFloat model.maxValue)))
                ++ "), chainMoves: " ++ (toString model.chainMoves)
                ++ " "
                )

view : Model -> Html Msg
view model =
  div []
      [ div [class "mask2", style "display" (if (not (inPlay model)) && (model.curSum - model.initSum) < model.goalScore then "inherit" else "none")]
              [ h1 [] [ text "You Lost"]
              , button [ onClick Reload] [text "Reload"]
              ]
      , div [style "position" "relative"] [
          div [style "position" "relative", style "text-align" "center"] [
            h2 [] [text "Aleaiacta"]
            , h1 [] [
                text (promptText model)
                , text " "
                , span [
                                style "font-size" "20px"
                                , style "border-style" "solid"
                                , style "width" "fit-content"
                                , style "margin" "auto"
                                , style "border-color" "#0F9D58"
                                ] (renderDirectionCounter model.directionCounter)
            ]
            , h4 [] [
                debugOutput model
              ]
              , div [] [
                div [style "width" "100%"] [table [style "margin" "auto"] (renderBoard model.sz (inPlay model) model.lastPos model.ar)]
                , div [style "width" "100%"] [button [style "margin" "auto", onClick Stop] [text "End Chain"]]
                , div [
                style "width" "30%"
                , style "color" "#0F9D58"
                --, style "margin-left" "auto"
                --, style "margin-right" "0px"
                , style "position" "absolute"
                , style "top" "0px"
                , style "right" "0px"
                ] ((renderSavedModelList model.savedNameListModel)++[
                  button [onClick Save, style "margin-top" "5px"] [text "Save Game"]
                  , button [onClick Delete, style "margin-top" "5px"] [text "Delete All"]
                ])
                ]
          ]

      ]
  ]
