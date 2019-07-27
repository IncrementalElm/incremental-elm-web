module Metadata exposing (Metadata, metadata)

import Element exposing (Element)
import Element.Font as Font
import Mark


type alias Metadata msg =
    { title : { styled : Element msg, raw : String }
    }


metadata : Mark.Block (Metadata msg)
metadata =
    Mark.oneOf
        [ Mark.record "Article"
            (\title ->
                { title = title
                }
            )
            |> Mark.field "title"
                (Mark.map
                    gather
                    titleText
                )
            |> Mark.toBlock
        , Mark.record "Page"
            (\title ->
                { title = title
                }
            )
            |> Mark.field "title"
                (Mark.map
                    gather
                    titleText
                )
            |> Mark.toBlock
        ]


gather : List { styled : Element msg, raw : String } -> { styled : Element msg, raw : String }
gather myList =
    let
        styled =
            myList
                |> List.map .styled
                |> Element.paragraph []

        raw =
            myList
                |> List.map .raw
                |> String.join " "
    in
    { styled = styled, raw = raw }


titleText : Mark.Block (List { styled : Element msg, raw : String })
titleText =
    Mark.textWith
        { view =
            \styles string ->
                { styled = viewText styles string
                , raw = string
                }
        , replacements = Mark.commonReplacements
        , inlines = []
        }


viewText : { a | bold : Bool, italic : Bool, strike : Bool } -> String -> Element msg
viewText styles string =
    Element.el (stylesFor styles) (Element.text string)


stylesFor : { a | bold : Bool, italic : Bool, strike : Bool } -> List (Element.Attribute b)
stylesFor styles =
    [ if styles.bold then
        Just Font.bold

      else
        Nothing
    , if styles.italic then
        Just Font.italic

      else
        Nothing
    , if styles.strike then
        Just Font.strike

      else
        Nothing
    ]
        |> List.filterMap identity
