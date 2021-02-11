module Board exposing (Board, SavedBoard, Element, savedBoardFromBoard, boardFromSavedBoard, genBoard, updateBoard, refreshBoard, tally, getBoardElement, setBoardElement, boardRowIndexedMap,
  Status(..), Color(..), Newness(..), Direction(..), ColumnOrRow(..), oldify, maxMat)

import Array exposing (Array)
import Random
import Debug

type Status = GreyedOut | Active
type Color = Red | Green | Blue
type Newness = New | Old
type Direction = Forwards | Backwards
type ColumnOrRow = Column | Row

type alias Element = 
  { value: Int
  , status: Status
  , color: Color
  , newness: Newness
  }
type alias Board = Array Element

ind : Int -> Int -> Int -> Int
ind sz i j = i * sz + j

directionForwards : Direction -> Int
directionForwards d =
  case d of
    Forwards -> 1
    _ -> 0

directionBackwards : Direction -> Int
directionBackwards d =
  case d of
    Forwards -> 0
    _ -> 1

-- Generating
colorFromInt : Int -> Color
colorFromInt i =
  case i of
    0 -> Red
    1 -> Green
    _ -> Blue

genColor : Random.Generator Color
genColor = Random.map colorFromInt (Random.int 0 2)

genValue : Int -> Random.Generator Int
genValue maxPower = Random.map (\i -> 2 ^ (maxPower + 1 - (floor (logBase 2 (toFloat i))))) (Random.int 2 31)

genElement : Int -> Random.Generator Element
genElement maxPower = Random.map2 (\v c -> { value = v, status = Active, color = c, newness = New}) (genValue maxPower) genColor

genBoard : Int -> Int -> Random.Generator Board
genBoard sz maxPower = Random.map Array.fromList <| Random.list (sz * sz) (genElement maxPower)

-- Saving and restoring
statusFromInt : Int -> Status
statusFromInt i =
  case i of
    0 -> GreyedOut
    _ -> Active

intFromStatus : Status -> Int
intFromStatus s =
  case s of
    GreyedOut -> 0
    Active -> 1

intFromColor : Color -> Int
intFromColor c =
  case c of
    Red -> 0
    Green -> 1
    Blue -> 2

newnessFromInt : Int -> Newness
newnessFromInt i =
  case i of
    0 -> New
    _ -> Old

intFromNewness : Newness -> Int
intFromNewness n =
  case n of
    New -> 0
    Old -> 1

type alias SavedElement = 
 { value: Int
 , statusInt: Int
 , colorInt: Int
 , newnessInt: Int
 } 

elementFromSavedElement : SavedElement -> Element
elementFromSavedElement {value, statusInt, colorInt, newnessInt} =
  {value = value, status = statusFromInt statusInt, color = colorFromInt colorInt, newness = newnessFromInt newnessInt}

savedElementFromElement : Element -> SavedElement
savedElementFromElement {value, status, color, newness} =
  {value = value, statusInt = intFromStatus status, colorInt = intFromColor color, newnessInt = intFromNewness newness}

type alias SavedBoard = Array SavedElement
boardFromSavedBoard : SavedBoard -> Board
boardFromSavedBoard =
  Array.map elementFromSavedElement

savedBoardFromBoard : Board -> SavedBoard
savedBoardFromBoard =
  Array.map savedElementFromElement

-- Accessing and modifying
getWithDef : a -> Int -> Array a -> a
getWithDef d i a =
  case Array.get i a of
    Nothing -> d
    Just e -> e

updateArrayWithDef : a -> Int -> (a -> a) -> Array a -> Array a
updateArrayWithDef def i f a =
  let
    e = getWithDef def i a
    e1 = f e
  in
    Array.set i e1 a

updateBoard : Int -> Int -> Int -> (Element -> Element) -> Board -> Board
updateBoard sz i j f mat =
  updateArrayWithDef { value = 0, status = GreyedOut, color = Red, newness = Old} (ind sz i j) f mat

setBoardElement : Int -> Int -> Int -> Element -> Board -> Board
setBoardElement sz i j e = updateBoard sz i j (\_ -> e)

getBoardElement : Int -> Int -> Int -> Board -> Element
getBoardElement sz i j mat =
  getWithDef { value = 0, status = GreyedOut, color = Red, newness = Old} (ind sz i j) mat

boardRowIndexedMap : Int -> Board -> Int -> (Int -> Int -> Element -> a) -> List a
boardRowIndexedMap sz b i f =
  let
    aux j accum =
      if j == -1 then accum
      else
        let
          el = getBoardElement sz i j b
          a = f i j el
        in aux (j - 1) (a :: accum)
  in aux (sz - 1) []

getBoardRow : Int -> Int -> Board -> Array Element
getBoardRow sz i board =
  let
    aux j accum =
      if j == 0 then (getBoardElement sz i j board) :: accum
      else aux (j - 1) ((getBoardElement sz i j board) :: accum)
    rowList = aux (sz - 1) []
  in
      Array.fromList rowList

setBoardRow : Int -> Int -> Array Element -> Board -> Board
setBoardRow sz i row board =
  let
    rowList = Array.toList row
    aux j l b =
      case l of
        [] -> b
        elem :: rest -> aux (j + 1) rest (setBoardElement sz i j elem b)
  in
    aux 0 rowList board

getBoardColumn : Int -> Int -> Board -> Array Element
getBoardColumn sz j board =
  let
    aux i accum =
      if i == 0 then (getBoardElement sz i j board) :: accum
      else aux (i - 1) ((getBoardElement sz i j board) :: accum)
    colList = aux (sz - 1) []
  in
      Array.fromList colList

setBoardColumn : Int -> Int -> Array Element -> Board -> Board
setBoardColumn sz j row board =
  let
    colList = Array.toList row
    aux i l b =
      case l of
        [] -> b
        elem :: rest -> aux (i + 1) rest (setBoardElement sz i j elem b)
  in
    aux 0 colList board

boardRowIndexedTransform : Int -> (Int -> Array Element -> Array Element) -> Board -> Board
boardRowIndexedTransform sz f board =
  let
    aux i b =
      if i == sz then b
      else
        let
          row = getBoardRow sz i b
          newRow = f i row
        in aux (i + 1) (setBoardRow sz i newRow b)
  in aux 0 board

boardColumnIndexedTransform : Int -> (Int -> Array Element -> Array Element) -> Board -> Board
boardColumnIndexedTransform sz f board =
  let
    aux j b =
      if j == sz then b
      else
        let
          column = getBoardColumn sz j b
          newColumn = f j column
        in aux (j + 1) (setBoardColumn sz j newColumn b)
  in aux 0 board

refreshBoard : Int -> ColumnOrRow -> Direction -> Int -> Int -> Int -> Board -> Random.Seed -> (Board, Random.Seed)
refreshBoard sz cr dir maxPower prevI prevJ ar seed =
  let
    (randomMat, seed1) = Random.step (genBoard sz maxPower) seed
    overrideGrey : Int -> Int -> Element -> Element -> Element
    overrideGrey i1 j1 el el2 =
      if el2.status == GreyedOut then el
      else el2
    overrideGreysRow : Int -> Array Element -> Array Element
    overrideGreysRow i row =
      let
        randomRow = getBoardRow sz i randomMat
        reorderedRow = Array.fromList <| List.sortBy (\el -> if el.status == Active then directionForwards dir else directionBackwards dir) <| Array.toList row
      in
        Array.indexedMap (\j e -> overrideGrey i j (getWithDef { value = 0, status = Active, color = Red, newness= Old} j randomRow) e) reorderedRow
    overrideGreysColumn : Int -> Array Element -> Array Element
    overrideGreysColumn j column =
      let
        randomColumn = getBoardColumn sz j randomMat
        reorderedColumn = Array.fromList <| List.sortBy (\el -> if el.status == Active then directionForwards dir else directionBackwards dir) <| Array.toList column
        ret = Array.indexedMap (\i e -> overrideGrey i j (getWithDef { value = 0, status = Active, color = Red, newness = Old} i randomColumn) e) reorderedColumn
      in
        ret
    ar2 = updateBoard sz prevI prevJ (\el -> { el| status = Active}) ar
--    mat1 = boardRowIndexedTransform sz overrideGreysRow ar2
    mat1 = (if cr == Column then boardColumnIndexedTransform sz overrideGreysColumn else boardRowIndexedTransform sz overrideGreysRow) ar2
  in
    (mat1, seed1)

oldify : Board -> Board
oldify = Array.map (\el -> { el | newness = Old})

foldBoard : (Int -> Int -> Int) -> Board -> Int
foldBoard f mat =
  let
    elemVal : Element -> Int
    elemVal e = e.value
  in
      Array.map elemVal mat |> Array.foldl f 0

tally : Board -> Int
tally = foldBoard (+)

maxMat : Board -> Int
maxMat = foldBoard (Basics.max)
