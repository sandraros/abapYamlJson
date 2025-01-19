CLASS zcl_yamljson_json_lexer DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ENUM enum_token_type STRUCTURE token_type,
        undefined,
        object_start,
        object_end,
        array_start,
        array_end,
        null,
        false,
        true,
        string,
        number,
      END OF ENUM enum_token_type STRUCTURE token_type.
    TYPES:
      BEGIN OF ty_token,
        level TYPE i,
        "! ENUM
        "! <ul>
        "! <li>Undefined: ?</li>
        "! <li>Object start</li>
        "! <li>Object end</li>
        "! <li>Array start</li>
        "! <li>Array end</li>
        "! <li>Null</li>
        "! <li>False</li>
        "! <li>True</li>
        "! <li>String</li>
        "! <li>Number</li>
        "! </ul>
        type  TYPE enum_token_type,
        "! Applicable only to the tokens between Object start and Object end, empty otherwise.
        name  TYPE string,
        "! Applicable only to the types String and Number, empty otherwise.
        value TYPE string,
      END OF ty_token.
    TYPES ty_tokens    TYPE STANDARD TABLE OF ty_token WITH EMPTY KEY.
    TYPES ty_jsonpaths TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.

    CLASS-METHODS class_constructor.

    "! @parameter JSON | CSEQUENCE
    CLASS-METHODS create
      IMPORTING json TYPE CSEQUENCE
      RETURNING VALUE(result) type ref to zcl_yamljson_json_lexer
      RAISING   zcx_yamljson.

    "! The minimum is one token with level 0 for simple data (false, true, null, string, number).
    "! @parameter TOKEN | Next token in the JSON string:
    "! <ul>
    "! <li>Level: The first extracted token is always level 0.</li>
    "! <li>Type:<ul>
    "!     <li>ARRAY_START</li>
    "!     <li>ARRAY_END</li>
    "!     <li>OBJECT_START</li>
    "!     <li>OBJECT_END</li>
    "!     <li>FALSE</li>
    "!     <li>TRUE</li>
    "!     <li>NULL</li>
    "!     <li>STRING</li>
    "!     <li>NUMBER</li>
    "!     </ul></li>
    "! <li>Name: in an object it's the member name, in an array it's a zero-based index number, otherwise it's empty</li>
    "! <li>Value: only for string and number</li>
    "! </ul>
    METHODS get_next_token
      RETURNING VALUE(token) TYPE ty_token
      RAISING   zcx_yamljson.

    "! Finds the next token which matches one of the JSON paths. Valid paths are:
    "! <ul>
    "! <li>$."pi" : for {"pi":3.14} returns 3.14</li>
    "! <li>$."math.pi" : for {"math.pi":3.14} returns 3.14</li>
    "! <li>$."element\"\\" : for {"element\"\\":1} returns 1</li>
    "! <li>$."array"."1" : for {"array":[3,6,9]} returns 6</li>
    "! </ul>
    METHODS find_token
      IMPORTING jsonpaths    TYPE ty_jsonpaths
      RETURNING VALUE(token) TYPE ty_token
      RAISING   zcx_yamljson.

    "! Reset the position at the beginning of the JSON
    METHODS is_token_available
      RETURNING VALUE(result) TYPE abap_bool.

    "! Reset the position at the beginning of the JSON
    METHODS reset.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ENUM enum_state STRUCTURE states,
*        end_json,
        start_value,
        after_value,
        array_start,
*        array_inter,
        object_start,
*        object_inter,
        between_member_name_and_value,
*        member_value,
*        next_member, " object
      END OF ENUM enum_state STRUCTURE states.

    CLASS-DATA alert_bell   TYPE c LENGTH 1.
    CLASS-DATA backspace    TYPE c LENGTH 1.
    CLASS-DATA formfeed     TYPE c LENGTH 1.
    CLASS-DATA vertical_tab TYPE c LENGTH 1.

    DATA json                        TYPE string.
    DATA jsonlen                     TYPE i.
    "! Current position in the JSON being parsed
    DATA offset                      TYPE i.
    DATA state                       TYPE enum_state.
    DATA levels                      TYPE string.
    "! value is always STRLEN( levels ) - 1
    DATA level                       TYPE i.
    DATA array_indexes               TYPE TABLE OF i.
    DATA last_token_is_at_same_level TYPE abap_bool.
*    DATA last_level TYPE i.
    DATA jsonpath                    TYPE string.
    DATA jsonpath_segments           TYPE TABLE OF i.

    METHODS get_string
      RETURNING VALUE(abap_string) TYPE string
      RAISING   zcx_yamljson.
ENDCLASS.



CLASS zcl_yamljson_json_lexer IMPLEMENTATION.
  METHOD class_constructor.
    alert_bell = cl_abap_conv_in_ce=>uccp( '0007' ).
    backspace = cl_abap_conv_in_ce=>uccp( '0008' ).
    formfeed = cl_abap_conv_in_ce=>uccp( '000C' ).
    vertical_tab = cl_abap_conv_in_ce=>uccp( '000B' ).
  ENDMETHOD.

  METHOD create.
    result = NEW zcl_yamljson_json_lexer( ).
    result->json = json.
*    DATA(jsontype) = cl_abap_typedescr=>describe_by_data( json ).
*    IF jsontype->type_kind = jsontype->typekind_xstring.
*      result->json = cl_abap_codepage=>convert_from( json ).
*    ELSE.
*      me->json = json.
*    ENDIF.

    " Remove trailing space-like characters (why?)
    REPLACE REGEX '[ \t\n\r]+\z' IN result->json WITH `` ##REGEX_POSIX.

    result->jsonlen = strlen( result->json ).
    IF result->jsonlen = 0.
      RAISE EXCEPTION TYPE zcx_yamljson.
    ENDIF.
    result->reset( ).
  ENDMETHOD.

  METHOD find_token.
    DATA(found) = abap_false.

    WHILE found = abap_false AND is_token_available( ).

      DATA(next_token) = get_next_token( ).

      IF     next_token-type <> token_type-array_end
         AND next_token-type <> token_type-object_end
         AND line_exists( jsonpaths[ table_line = jsonpath ] ).
        found = abap_true.
      ENDIF.

    ENDWHILE.

    IF found = abap_true.
      token = next_token.
    ENDIF.
  ENDMETHOD.

  METHOD get_next_token.
    DATA c5     TYPE c LENGTH 5.
    DATA length TYPE i.

    token-type  = token_type-undefined.
    token-level = level + 1.

    IF offset >= jsonlen.
      " end of JSON, all objects and arrays must have been closed
      RAISE EXCEPTION TYPE zcx_yamljson.
    ENDIF.

    DATA(new_level) = space.
*    " TODO: variable is assigned but never used (ABAP cleaner)
*    DATA(end_level) = space.
*    " TODO: variable is assigned but never used (ABAP cleaner)
*    DATA(reset_state_to_current_level) = abap_false.

*    TRY.

    " Loop once, or 3 times to get one object member
    DATA(exit) = abap_false.
    WHILE exit = abap_false AND offset < jsonlen.

      " skip space-like characters (20 09 0a 0d)
      FIND REGEX '^[ \t\n\r]*' IN SECTION OFFSET offset OF json MATCH LENGTH length ##REGEX_POSIX.
      ASSERT sy-subrc = 0.
      offset = offset + length.

      exit = abap_true.

      CASE state.

        WHEN states-start_value.

          CASE json+offset(1).

            WHEN 't'.
              "=========
              " true
              "=========
              c5 = json+offset.
              IF c5(4) <> 'true'.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type = token_type-true.
              offset = offset + 4.
              state = states-after_value.

            WHEN 'n'.
              "=========
              " null
              "=========
              c5 = json+offset.
              IF c5(4) <> 'null'.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type = token_type-null.
              offset = offset + 4.
              state = states-after_value.

            WHEN 'f'.
              "=========
              " false
              "=========
              c5 = json+offset.
              IF c5 <> 'false'.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type = token_type-false.
              offset = offset + 5.
              state = states-after_value.

            WHEN '-' OR '0' OR '1' OR '2' OR '3' OR '4' OR '5' OR '6' OR '7' OR '8' OR '9'.
              "=========
              " NUMBER
              "=========
              FIND REGEX '^((?:-?)(?:0|[1-9][0-9]*)(?:[.][0-9]+)?(?:[eE][+-]?[0-9]+)?)' ##REGEX_POSIX
                   IN SECTION OFFSET offset OF json
                   MATCH LENGTH length.
              IF sy-subrc <> 0.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type  = token_type-number.
              token-value = json+offset(length).
              offset = offset + length.
              state = states-after_value.

            WHEN '"'.
              "=========
              " STRING
              "=========
              token-type  = token_type-string.
              token-value = get_string( ).
              state = states-after_value.

            WHEN '{'.
              "=========
              " OBJECT
              "=========
              token-type = token_type-object_start.
              offset = offset + 1.
              new_level = '{'.
              state = states-object_start.

            WHEN '['.
              "=========
              " ARRAY
              "=========
              token-type = token_type-array_start.
              offset = offset + 1.
              new_level = '['.
              state = states-array_start.

            WHEN OTHERS.
              RAISE EXCEPTION TYPE zcx_yamljson.

          ENDCASE.

          IF level > -1 AND levels+level(1) = '['.
            token-name = |{ array_indexes[ level + 1 ] }|.
            array_indexes[ level + 1 ] = array_indexes[ level + 1 ] + 1.
          ENDIF.
*          reset_state_to_current_level = abap_true.

        WHEN states-array_start.

          IF json+offset(1) = ']'.
            token-type = token_type-array_end.
            offset = offset + 1.
*            end_level = ']'.
            state = states-after_value.
          ELSE.
            array_indexes = VALUE #( BASE array_indexes
                                     ( 0 ) ).
            state = states-start_value.
            exit = abap_false.
          ENDIF.

        WHEN states-object_start.

          IF json+offset(1) = '}'.
            token-type = token_type-object_end.
            offset = offset + 1.
*            end_level = '}'.
            state = states-after_value.
          ELSE.
            token-name = get_string( ).
            array_indexes = VALUE #( BASE array_indexes
                                     ( 0 ) ).
            state = states-between_member_name_and_value.
            exit = abap_false.
          ENDIF.

        WHEN states-between_member_name_and_value.
          "=========
          " separator between object member name and value
          "=========
          IF json+offset(1) <> ':'.
            RAISE EXCEPTION TYPE zcx_yamljson.
          ENDIF.
          offset = offset + 1.
          state = states-start_value.
          exit = abap_false.

        WHEN states-after_value.

          CASE json+offset(1).

            WHEN '}'.
              "=========
              " end of object
              "=========
              IF level = -1 OR levels+level(1) <> '{'.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type = token_type-object_end.
              offset = offset + 1.
*              end_level = '}'.
*              reset_state_to_current_level = abap_true.

            WHEN ']'.
              "=========
              " end of array
              "=========
              IF level = -1 OR levels+level(1) <> '['.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type = token_type-array_end.
              offset = offset + 1.
*              end_level = ']'.
              DELETE array_indexes INDEX lines( array_indexes ).
*              reset_state_to_current_level = abap_true.

            WHEN ','.
              "=========
              " separator of members in array or object
              "=========
              IF level = -1.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              offset = offset + 1.
              IF levels+level(1) = '{'.
                state = states-object_start.
              ELSE.
                state = states-start_value.
              ENDIF.
              exit = abap_false.

            WHEN OTHERS.
              " Invalid character
              RAISE EXCEPTION TYPE zcx_yamljson.
          ENDCASE.

        WHEN OTHERS.
          " Invalid state
          RAISE EXCEPTION TYPE zcx_yamljson.
      ENDCASE.

    ENDWHILE.

    IF last_token_is_at_same_level = abap_true.
      REPLACE SECTION OFFSET ( strlen( jsonpath ) - jsonpath_segments[ lines( jsonpath_segments ) ] ) OF jsonpath WITH ``.
      DELETE jsonpath_segments INDEX lines( jsonpath_segments ).
      last_token_is_at_same_level = abap_false.
    ENDIF.
    IF level = -1.
      jsonpath = `$`.
      jsonpath_segments = VALUE #( ).
      CASE token-type.
        WHEN token_type-array_start OR token_type-object_start.
          levels = levels && new_level.
          level = level + 1.
      ENDCASE.
    ELSE.
      CASE token-type.
        WHEN token_type-array_end OR token_type-object_end.
          REPLACE SECTION OFFSET level OF levels WITH ``.
          level = level - 1.
          IF level > -1.
            REPLACE SECTION OFFSET ( strlen( jsonpath ) - jsonpath_segments[ lines( jsonpath_segments ) ] ) OF jsonpath WITH ``.
            DELETE jsonpath_segments INDEX lines( jsonpath_segments ).
          ENDIF.
        WHEN OTHERS.
          DATA(jsonpath_segment) = |."{ replace( val   = token-name
                                                 regex = '([."\\])' ##REGEX_POSIX
                                                 with  = '\\$1'
                                                 occ   = 0 ) }"|.
          jsonpath = jsonpath && jsonpath_segment.
          APPEND strlen( jsonpath_segment ) TO jsonpath_segments.
          CASE token-type.
            WHEN token_type-array_start OR token_type-object_start.
              levels = levels && new_level.
              level = level + 1.
            WHEN OTHERS.
              last_token_is_at_same_level = abap_true.
          ENDCASE.
      ENDCASE.
    ENDIF.

    IF offset >= jsonlen AND level <> -1.
      " end of JSON, all objects and arrays must have been closed
      RAISE EXCEPTION TYPE zcx_yamljson.
    ENDIF.
  ENDMETHOD.

  METHOD get_string.
    DATA length TYPE i.

    " calculate total length
    FIND REGEX '^"(?:(?:\\u[0-9a-zA-Z]{4})|(\\["\\/bfnrt])|([^"\\]))*"' ##REGEX_POSIX
         IN SECTION OFFSET offset OF json
         MATCH LENGTH length.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_yamljson.
    ENDIF.

    IF length = 2.
      abap_string = ``.
    ELSE.
      FIND ALL OCCURRENCES OF REGEX '(\\u[0-9a-zA-Z]{4})|(\\["\\/bfnrt])|([^"\\]+)' ##REGEX_POSIX
           IN SECTION OFFSET offset + 1 LENGTH length - 2
           OF json
           RESULTS DATA(json_string_parts).
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_yamljson.
      ENDIF.
      abap_string = ``.
      LOOP AT json_string_parts ASSIGNING FIELD-SYMBOL(<part>).
        IF <part>-submatches[ 1 ]-length <> 0.
          abap_string = abap_string && cl_abap_conv_in_ce=>uccp( to_upper( substring( val = json
                                                                                      off = <part>-submatches[ 1 ]-offset + 2
                                                                                      len = 4 ) ) ).
        ELSEIF <part>-submatches[ 2 ]-length <> 0.
          abap_string = abap_string
            && SWITCH char1( substring( val = json
                                        off = <part>-submatches[ 2 ]-offset + 1
                                        len = 1 )
                             WHEN '"' THEN '"'
                             WHEN '\' THEN '\'
                             WHEN '/' THEN '\'
                             WHEN 'b' THEN backspace
                             WHEN 'f' THEN formfeed
                             WHEN 'n' THEN |\n|
                             WHEN 'r' THEN |\r|
                             WHEN 't' THEN |\t| ).
        ELSE.
          abap_string = abap_string && substring( val = json
                                                  off = <part>-submatches[ 3 ]-offset
                                                  len = <part>-submatches[ 3 ]-length ).
        ENDIF.
      ENDLOOP.
    ENDIF.

    offset = offset + length.

*    " calculate total length
*    IF json+offset(1) <> '"'.
*      RAISE EXCEPTION TYPE zcx_json_parser.
*    ENDIF.
*    offset = offset + 1.
*    WHILE offset < jsonlen AND json+offset(1) <> '"'.
*      IF json+offset(1) = '\'.
*        offset = offset + 2.
*      ELSE.
*        offset = offset + 1.
*      ENDIF.
*    ENDWHILE.
*    IF offset >= jsonlen.
*      RAISE EXCEPTION TYPE zcx_json_parser.
*    ELSE.
*      offset = offset + 1.
*    ENDIF.
  ENDMETHOD.

  METHOD is_token_available.
    result = xsdbool( offset < jsonlen ).
  ENDMETHOD.

  METHOD reset.
    offset = 0.
    state = states-start_value.
    levels = ``.
    level = -1.
    last_token_is_at_same_level = abap_false.
    " last_level = -1.
    jsonpath = ``.
    jsonpath_segments = VALUE #( ).
  ENDMETHOD.
ENDCLASS.
