module Page.Team exposing (view)

import Element exposing (Element)
import Element.Background as Background
import Element.Border
import Element.Font
import Html
import Html.Attributes exposing (attribute, class, style)
import Style exposing (fontSize, fonts, palette)
import Style.Helpers
import View.FontAwesome


view :
    { width : Float
    , height : Float
    , device : Element.Device
    }
    -> Element.Element msg
view dimensions =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 50
        , Element.spacing 30
        ]
        [ Element.text "Our Elm Coaches"
            |> Element.el
                [ Style.fontSize.title
                , Style.fonts.title
                , Element.Font.center
                , Element.width Element.fill
                ]
        , aboutDillon
        ]


aboutDillon =
    Element.row
        [ Element.height (Element.shrink |> Element.minimum 200)
        , Element.Border.shadow { offset = ( 2, 1 ), size = 1, blur = 4, color = Element.rgb 0.8 0.8 0.8 }
        , Element.centerX
        , Element.width (Element.fill |> Element.maximum 1200)
        ]
        [ avatar
        , Element.el
            [ Element.width (Element.fill |> Element.maximum 1000)
            , Element.padding 30
            ]
            (Element.column
                [ Element.spacing 15
                , Element.centerX
                ]
                [ name
                , bioView
                , authorResources
                ]
            )
        ]


authorResources =
    Element.column [ Element.spacing 8, Element.width Element.fill ]
        [ Element.row [ Element.spaceEvenly, Element.width Element.fill ]
            [ resource "elm-graphql" "https://github.com/dillonkearns/elm-graphql" Library
            , resource "elm-typescript-interop" "https://github.com/dillonkearns/elm-typescript-interop" Library
            ]
        , Element.row
            [ Element.spaceEvenly, Element.width Element.fill ]
            [ resource "Developing for the Web with Extreme Safety" "https://www.youtube.com/watch?v=t-2GiOuLRZc" Video
            , resource "Mobster" "http://mobster.cc" App
            ]
        ]


type Resource
    = Library
    | Video
    | App


resource resourceName url resourceType =
    let
        ( iconClasses, color ) =
            case resourceType of
                Library ->
                    ( "fa fa-code", palette.highlight )

                Video ->
                    ( "fab fa-youtube", Element.rgb255 255 0 0 )

                App ->
                    ( "fas fa-desktop", Element.rgb255 0 122 255 )
    in
    Element.newTabLink []
        { label =
            Element.row [ Element.spacing 5 ]
                [ View.FontAwesome.styledIcon iconClasses [ Element.Font.color color ]
                , Element.text resourceName |> Element.el [ Style.fonts.code ]
                ]
        , url = url
        }


bioView =
    Element.paragraph
        [ Element.width Element.fill
        , Element.Font.size 16
        , Style.fonts.body
        ]
        [ Element.text dillonBio ]


avatar =
    Element.image [ Element.width (Element.fill |> Element.maximum 250), Element.centerX ]
        { src = "/assets/dillon2.jpg"
        , description = "Dillon Kearns"
        }


name =
    Element.paragraph
        [ fontSize.title
        , Element.Font.size 32
        , Element.width Element.fill
        ]
        [ Element.text "Dillon Kearns" ]


dillonBio =
    "Dillon is an Agile Coach and Software Craftsman based out of Southern California. As an Agile Consultant, Dillon introduced Elm at a Fortune 10 company and trained several teams to help them adopt it as their primary front-end framework. He is a big proponent of emergent design, test-driven development, and continuous refactorings and hopes to help the community explore these techniques in the context of Elm. In his free time, he loves backpacking and playing the piano."
