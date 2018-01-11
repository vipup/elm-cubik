module Decode exposing (model, origin)

import Json.Decode as Decode exposing (Value, Decoder)
import Types exposing (..)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3)
import Dict exposing (Dict)
import Utils exposing (..)
import Window


origin : Vec3
origin =
    Vec3.vec3 0 0 -11


model : Value -> Model
model value =
    let
        width =
            Decode.decodeValue (Decode.field "width" Decode.int) value
                |> Result.withDefault 0

        height =
            Decode.decodeValue (Decode.field "height" Decode.int) value
                |> Result.withDefault 0

        devicePixelRatio =
            Decode.decodeValue (Decode.field "devicePixelRatio" Decode.float) value
                |> Result.withDefault 1

        rotation =
            Decode.decodeValue (Decode.field "rotation" mat4) value
                |> Result.withDefault defaultRotation

        cubik =
            Decode.decodeValue (Decode.field "cubik" cells) value
                |> Result.withDefault defaultCubik
    in
        { state = Initial
        , rotation = rotation
        , perspective = Mat4.identity
        , camera = Mat4.makeLookAt origin (Vec3.vec3 0 0 0) Vec3.j
        , window = Window.Size width height
        , devicePixelRatio = devicePixelRatio
        , cubik = cubik
        , time = 0
        }


cells : Decoder (Dict Int Cell)
cells =
    Decode.map (List.indexedMap (,) >> Dict.fromList) (Decode.list cell)


cell : Decoder Cell
cell =
    Decode.map3 Cell
        (Decode.field "transform" mat4)
        (Decode.field "color" color)
        (Decode.field "normal" vec3)


color : Decoder Color
color =
    Decode.andThen
        (\c ->
            case c of
                "red" ->
                    Decode.succeed Red

                "white" ->
                    Decode.succeed White

                "blue" ->
                    Decode.succeed Blue

                "orange" ->
                    Decode.succeed Orange

                "yellow" ->
                    Decode.succeed Yellow

                "green" ->
                    Decode.succeed Green

                c ->
                    Decode.fail ("Unknown color: " ++ c)
        )
        Decode.string


vec3 : Decoder Vec3
vec3 =
    Decode.andThen
        (\l ->
            case l of
                [ x, y, z ] ->
                    Decode.succeed (Vec3.vec3 x y z)

                _ ->
                    Decode.fail "Wrong number of vector components"
        )
        (Decode.list Decode.float)


mat4 : Decoder Mat4
mat4 =
    Decode.andThen
        (\l ->
            case l of
                [ m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44 ] ->
                    { m11 = m11, m21 = m21, m31 = m31, m41 = m41, m12 = m12, m22 = m22, m32 = m32, m42 = m42, m13 = m13, m23 = m23, m33 = m33, m43 = m43, m14 = m14, m24 = m24, m34 = m34, m44 = m44 }
                        |> Mat4.fromRecord
                        |> Decode.succeed

                _ ->
                    Decode.fail "Wrong number of matrix components"
        )
        (Decode.list Decode.float)


defaultRotation : Mat4
defaultRotation =
    Mat4.identity
        |> Mat4.mul (Mat4.makeRotate (pi / 4) Vec3.j)
        |> Mat4.mul (Mat4.makeRotate (-pi / 4) Vec3.i)


defaultCubik : Dict Int Cell
defaultCubik =
    List.concatMap makeSide [ Red, Green, White, Blue, Orange, Yellow ]
        |> List.indexedMap (,)
        |> Dict.fromList


makeSide : Color -> List Cell
makeSide color =
    case color of
        Green ->
            frontFace color

        Blue ->
            List.map (rotateCell XAxis pi) (frontFace color)

        White ->
            List.map (rotateCell XAxis (pi / 2)) (frontFace color)

        Yellow ->
            List.map (rotateCell XAxis (-pi / 2)) (frontFace color)

        Orange ->
            List.map (rotateCell YAxis (-pi / 2)) (frontFace color)

        Red ->
            List.map (rotateCell YAxis (pi / 2)) (frontFace color)


frontFace : Color -> List Cell
frontFace color =
    List.range -1 1
        |> List.concatMap
            (\x ->
                List.map
                    (\y -> Cell (Mat4.makeTranslate3 (toFloat x) (toFloat y) -1) color (Vec3.vec3 0 0 -1))
                    (List.range -1 1)
            )
