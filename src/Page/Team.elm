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


wrappedText contents =
    Element.paragraph [] [ Element.text contents ]


bulletPoint content =
    "→ "
        ++ content
        |> wrappedText
        |> Element.el
            [ fonts.body
            , fontSize.body
            ]


view :
    { width : Float
    , height : Float
    , device : Element.Device
    }
    -> Element.Element msg
view dimensions =
    Element.column
        [ Background.gradient
            { angle = -180
            , steps = [ Element.rgba255 0 52 89 0.7, Element.rgba255 0 126 167 0.7 ]
            }
        , Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 30
        ]
        [ aboutDillon ]


aboutDillon =
    Element.row
        [ Element.height (Element.fill |> Element.maximum 300)
        , Element.spacing 30
        , Element.padding 20
        , Element.Border.shadow { offset = ( 2, 1 ), size = 1, blur = 4, color = Element.rgb 0.8 0.8 0.8 }
        , Background.color (Element.rgb255 255 255 255)
        , Element.centerX
        ]
        [ Element.column [ Element.spacing 15 ]
            [ Element.paragraph
                [ fontSize.title
                , Element.Font.center
                , Element.width Element.fill
                ]
                [ Element.text "Dillon Kearns" ]
            , Element.image [ Element.height (Element.px 150) ]
                { src = "/assets/dillon.jpg"
                , description = "Dillon Kearns"
                }
            ]
        , wrappedText dillonBio
        ]


dillonBio =
    "Dillon is an Agile Coach and Software Craftsman based out of Southern California. As an Agile Consultant, Dillon introduced Elm at a Fortune 10 company and trained several teams to help them adopt it as their primary front-end framework. He is a big proponent of emergent design, test-driven development, and continuous refactorings and hopes to help the community explore these techniques in the context of Elm. In his free time, he loves backpacking and playing the piano."


contactSection =
    Element.column
        [ Background.color palette.highlight
        , Element.height (Element.shrink |> Element.minimum 300)
        , Element.width Element.fill
        ]
        [ Element.el
            [ Element.Font.color palette.bold
            , Element.centerX
            , fontSize.title
            , fonts.body
            , Element.padding 30
            ]
            ("Get in touch"
                |> wrappedText
                |> Element.el
                    [ fonts.title
                    , Element.centerX
                    , Element.Font.center
                    , Element.Font.color palette.mainBackground
                    ]
            )
        , contactButton
        ]


contactButton =
    Element.link
        [ Element.centerX
        ]
        { url =
            "mailto:info@incrementalelm.com"
        , label =
            Style.Helpers.button
                { fontColor = .mainBackground
                , backgroundColor = .bold
                , size = fontSize.body
                }
                [ envelopeIcon |> Element.el []
                , Element.text "info@incrementalelm.com"
                ]
        }


envelopeIcon =
    View.FontAwesome.icon "far fa-envelope"


servicesSection dimensions =
    Element.column
        [ Background.color palette.main
        , Element.height (Element.shrink |> Element.minimum 300)
        , Element.width Element.fill
        ]
        [ Element.column
            [ Element.Font.color palette.bold
            , Element.centerY
            , Element.width Element.fill
            , fontSize.title
            , fonts.body
            , Element.spacing 25
            , Element.padding 30
            ]
            [ "Services"
                |> wrappedText
                |> Element.el
                    [ fonts.title
                    , Element.centerX
                    , Element.Font.center
                    ]
            , iterations dimensions
            ]
        ]


iterations dimensions =
    (if dimensions.width > 1000 then
        Element.row
            [ Element.spaceEvenly
            , Element.width Element.fill
            , Element.padding 50
            ]

     else
        Element.column
            [ Element.width Element.fill
            , Element.padding 20
            ]
    )
        [ iteration 0
            [ "Elm Fundamentals training for your team"
            , "Ship Elm code to production in under a week"
            , "Master The Elm Architecture"
            , "Fundamentals of Test-Driven Development in Elm"
            ]
        , iteration 1
            [ "Reuse and scaling patterns"
            , "Advanced JavaScript interop techniques"
            , "Choose the right Elm styling approach for your environment"
            ]
        , iteration 2
            [ "Transition your codebase to a full Single-Page Elm App"
            , "Master Elm architectural patterns"
            ]
        ]


iteration iterationNumber bulletPoints =
    [ iterationBubble iterationNumber
    , List.map bulletPoint bulletPoints
        |> Element.column
            [ Element.centerX
            , Element.spacing 30
            ]
    ]
        |> Element.column
            [ Element.spacing 50
            , Element.alignTop
            , Element.width Element.fill
            ]


faTransform =
    attribute "data-fa-transform"


iterationBubble iterationNumber =
    (Element.paragraph [ Element.height Element.shrink, Element.centerY ]
        [ Element.text "Iteration "
        , Element.text (String.fromInt iterationNumber)
        ]
        |> Element.el
            [ Element.Font.color white
            , fonts.title
            , Element.centerX
            , Element.centerY
            , Element.Font.center
            , fontSize.medium
            , Element.Font.bold
            , Background.color palette.highlight
            , Element.width (Element.px 150)
            , Element.height (Element.px 150)
            , Element.Border.rounded 10000
            ]
    )
        |> Element.el [ Element.centerX ]


whyElmSection =
    bulletSection
        { backgroundColor = palette.highlightBackground
        , fontColor = Element.rgb 255 255 255
        , headingText = "Want a highly reliable & maintainable frontend?"
        , bulletContents =
            [ "Zero runtime exceptions"
            , "Rely on language guarantees instead of discipline"
            , "Predictable code - no globals or hidden side-effects"
            ]
        , append =
            Element.link
                [ Element.centerX
                ]
                { url = "/why-elm"
                , label =
                    Style.Helpers.button
                        { fontColor = .mainBackground
                        , backgroundColor = .light
                        , size = fontSize.small
                        }
                        [ "Read About Why Elm?" |> wrappedText
                        ]
                }
        }


elementRgb red green blue =
    Element.rgb (red / 255) (green / 255) (blue / 255)


white =
    elementRgb 255 255 255


bulletSection { backgroundColor, fontColor, headingText, bulletContents, append } =
    Element.column
        [ Background.color backgroundColor
        , Element.height (Element.shrink |> Element.minimum 300)
        , Element.width Element.fill
        ]
        [ Element.column
            [ Element.Font.color fontColor
            , Element.centerY
            , Element.width Element.fill
            , fontSize.title
            , fonts.body
            , Element.spacing 25
            , Element.padding 30
            ]
            (List.concat
                [ [ headingText
                        |> wrappedText
                        |> Element.el
                            [ fonts.title
                            , Element.centerX
                            , Element.Font.center
                            ]
                  ]
                , List.map bulletPoint bulletContents
                , [ append ]
                ]
            )
        ]


whyIncrementalSection =
    bulletSection
        { backgroundColor = palette.mainBackground
        , fontColor = palette.bold
        , headingText = "How do I start?"
        , bulletContents =
            [ "One tiny step at a time!"
            , "See how Elm fits in your environment: learn the fundamentals and ship something in less than a week!"
            , "Elm is all about reliability. Incremental Elm Consulting gets you there reliably"
            ]
        , append = Element.none
        }
