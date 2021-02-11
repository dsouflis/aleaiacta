module SavedNameList exposing (..)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
type alias Model = List String

isEmpty : Model -> Bool
isEmpty model = model == []

type Msg = LoadName String | SetNames Model | Save

view : Model -> Html Msg
view model =
  div [] (List.map (\n -> button [onClick (LoadName n)] [text ("Load "++n)]) model)

update : Msg -> Model -> (Model, Cmd Msg )
update msg model =
  case msg of
    LoadName _ -> (model, Cmd.none) -- actually handled by the parent
    SetNames m -> (m, Cmd.none)
    Save -> (model, Cmd.none)
