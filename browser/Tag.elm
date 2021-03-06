module Tag
    exposing
        ( addSuggestedTag
        , addTag
        , deleteTag
        , editNewTag
        , get
        , keyDown
        , nextSuggestion
        , previousSuggestion
        , selectedSuggestion
        , tags
        , unselect
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import List
import Messages
import Model exposing (Entry, TagSuggestion)
import Events exposing (onEnter, onDownArrow, onUpArrow, onKeyDown, keyCodes)
import Html.Events exposing (onInput, onClick)
import Http
import Json.Decode as JD
import Set


addTag : Entry -> Entry
addTag entry =
    { entry
        | newTag = ""
        , tags = List.append entry.tags [ entry.newTag ]
        , tagSuggestions = []
    }


deleteTag : Entry -> String -> Entry
deleteTag entry tag =
    { entry
        | tags = List.filter (\t -> t /= tag) entry.tags
    }


keyDown : Entry -> Int -> Entry
keyDown entry keyCode =
    if keyCode == keyCodes.up then
        previousSuggestion entry
    else if keyCode == keyCodes.down then
        nextSuggestion entry
    else if keyCode == keyCodes.escape then
        unselect entry
    else
        entry


addSuggestedTag : Entry -> String -> Entry
addSuggestedTag entry tag =
    { entry
        | tags = List.append entry.tags [ tag ]
        , newTag = ""
        , tagSuggestions = []
    }


matchTag : String -> String -> Bool
matchTag partialTag fullTag =
    if String.length partialTag < 1 then
        False
    else
        String.startsWith (String.toLower partialTag) (String.toLower fullTag)


editNewTag : Entry -> Set.Set String -> String -> Entry
editNewTag entry tags tag =
    let
        matchingSet =
            Set.filter (matchTag tag) tags

        inEntry =
            Set.fromList (entry.tags)
    in
        { entry
            | newTag = tag
            , tagSuggestions = Set.toList (Set.diff matchingSet inEntry)
            , selectedSuggestionIndex = -1
        }


unselect : Model.Entry -> Model.Entry
unselect entry =
    { entry | selectedSuggestionIndex = -1 }


nextSuggestion : Model.Entry -> Model.Entry
nextSuggestion entry =
    let
        max =
            List.length entry.tagSuggestions - 1

        index =
            if entry.selectedSuggestionIndex >= max then
                max
            else
                entry.selectedSuggestionIndex + 1
    in
        { entry | selectedSuggestionIndex = index }


previousSuggestion : Model.Entry -> Model.Entry
previousSuggestion entry =
    let
        index =
            if entry.selectedSuggestionIndex < 1 then
                0
            else
                entry.selectedSuggestionIndex - 1
    in
        { entry | selectedSuggestionIndex = index }


get : Model.Model -> Cmd Messages.Msg
get model =
    if Set.isEmpty model.tags then
        Http.send Messages.GetTagsDone <|
            Http.get ("/api/entries/tags") decodeTags
    else
        Cmd.none


decodeTags : JD.Decoder (List String)
decodeTags =
    JD.list decodeTag


decodeTag : JD.Decoder String
decodeTag =
    JD.field "text" JD.string


tagItem : Entry -> String -> Html Messages.Msg
tagItem entry tag =
    li
        [ class "tag-item" ]
        [ span
            []
            [ text tag ]
        , a
            [ class "remove-button"
            , onClick (Messages.DeleteTag entry tag)
            ]
            [ text "×" ]
        ]


isSelected : Int -> Int -> String -> ( Bool, String )
isSelected selectedIndex index tag =
    ( selectedIndex == index, tag )


suggestionHtml : Model.Entry -> ( Bool, String ) -> Html Messages.Msg
suggestionHtml entry boolTag =
    let
        selected =
            Tuple.first boolTag

        tag =
            Tuple.second boolTag
    in
        li
            [ class "suggestion-item"
            , classList [ ( "selected", selected ) ]
            , onClick (Messages.AddSuggestedTag entry tag)
            ]
            [ text tag ]


suggestionsHtml : Model.Entry -> Html Messages.Msg
suggestionsHtml entry =
    let
        boolTag =
            tagIndexedMap entry
    in
        ul
            [ class "suggestion-list" ]
            (List.map (suggestionHtml entry) boolTag)


tagIndexedMap : Model.Entry -> List ( Bool, String )
tagIndexedMap entry =
    List.indexedMap (isSelected entry.selectedSuggestionIndex) entry.tagSuggestions


selectedSuggestion : Model.Entry -> String
selectedSuggestion entry =
    let
        selectedTuple =
            List.filter (\t -> Tuple.first t) (tagIndexedMap entry)
    in
        case List.head selectedTuple of
            Nothing ->
                ""

            Just tuple ->
                Tuple.second tuple


tags : Entry -> Html Messages.Msg
tags entry =
    node "tags-input"
        [ class " meta" ]
        [ div
            [ class "host" ]
            [ div [ class "tags" ]
                [ ul
                    [ class "tag-list" ]
                    (List.map (tagItem entry) entry.tags)
                , input
                    [ class "input ti-autosize"
                    , placeholder "Add a tag"
                    , tabindex 0
                    , style [ ( "width", "69px" ) ]
                    , onKeyDown (Messages.TagKeyDown entry)
                    , onInput (Messages.InputNewTag entry)
                    , value entry.newTag
                    ]
                    []
                ]
            , if List.length entry.tagSuggestions > 0 then
                node "auto-complete"
                    []
                    [ div
                        [ class "autocomplete" ]
                        [ suggestionsHtml entry
                        ]
                    ]
              else
                text ""
            ]
        ]
