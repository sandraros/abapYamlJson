CLASS zcl_yamljson_yaml_lexer DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ENUM enum_token_type STRUCTURE token_type,
        undefined,
        object_property_name,
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

    CLASS-METHODS class_constructor.

    CLASS-METHODS create
      IMPORTING yaml          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zcl_yamljson_yaml_lexer.

    "! The minimum is one token with level 0 for simple data (false, true, null, string, number).
    "! @parameter RESULT | Next token in the JSON string:
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
      RETURNING VALUE(result) TYPE ty_token
      RAISING   zcx_yamljson.

    METHODS is_token_available
      RETURNING VALUE(result) TYPE abap_bool.

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

    DATA yaml                        TYPE string.
    DATA yaml_length                 TYPE i.
    "! Current position in the yaml being parsed
    DATA offset                      TYPE i.
    DATA state                       TYPE enum_state.
    DATA levels                      TYPE string.
    "! value is always STRLEN( levels ) - 1
    DATA level                       TYPE i VALUE -1.
    DATA array_indexes               TYPE TABLE OF i.
    DATA last_token_is_at_same_level TYPE abap_bool.
*    DATA last_level TYPE i.
    DATA yamlpath                    TYPE string.
    DATA yamlpath_segments           TYPE TABLE OF i.

    METHODS get_next_array
      IMPORTING start_column_number TYPE i
                !lines              TYPE string_table
                array               TYPE REF TO zcl_yamljson_array
      CHANGING  current_line_number TYPE i.

    METHODS get_next_object
      IMPORTING start_column_number TYPE i
                !lines              TYPE string_table
                !object             TYPE REF TO zcl_yamljson_object
      CHANGING  current_line_number TYPE i.

    METHODS get_next_value
      IMPORTING start_column_number  TYPE i
                !lines               TYPE string_table
      CHANGING  current_line_number  TYPE i
      RETURNING VALUE(current_value) TYPE REF TO zif_yamljson_value.

    METHODS get_non_quoted_string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_yamljson.

    METHODS get_string_inside_double_quote
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_yamljson.
ENDCLASS.


CLASS zcl_yamljson_yaml_lexer IMPLEMENTATION.
  METHOD class_constructor.
    alert_bell = cl_abap_conv_in_ce=>uccp( '0007' ).
    backspace = cl_abap_conv_in_ce=>uccp( '0008' ).
    formfeed = cl_abap_conv_in_ce=>uccp( '000C' ).
    vertical_tab = cl_abap_conv_in_ce=>uccp( '000B' ).
  ENDMETHOD.

  METHOD create.
    result = NEW zcl_yamljson_yaml_lexer( ).
    result->yaml        = yaml.
    result->yaml_length = strlen( yaml ).
    result->state       = states-start_value.
    IF 0 = 1.

    ENDIF.
  ENDMETHOD.

  METHOD get_next_token.
*    DATA match_length TYPE i.

    DATA(token) = VALUE ty_token( type  = token_type-undefined
                                  level = level + 1 ).

    IF offset >= yaml_length.
      RAISE EXCEPTION TYPE zcx_yamljson
        EXPORTING text = 'End of YAML, no more token'.
    ENDIF.

    DATA(new_level) = space.
*    DATA(remaining_length) = yaml_length.
    DATA(exit) = abap_false.

    WHILE     exit   = abap_false
          AND offset < yaml_length.

      " Skip spaces (if any)
      offset = find_any_not_of( val = yaml
                                off = offset
                                sub = ` ` ).

      DATA(remaining_length) = strlen( yaml ) - offset.
      " offset = offset + number_of_leading_spaces.

      CASE state.

        WHEN states-start_value.

          IF     remaining_length >= 4
             AND (    yaml+offset(4) = `TRUE`
                   OR yaml+offset(4) = `True`
                   OR yaml+offset(4) = `true` ).

            "=========
            " true
            "=========
            token-type = token_type-true.
            offset = offset + 4.
            state = states-after_value.

          ELSEIF     remaining_length >= 4
                 AND (    yaml+offset(4) = `NULL`
                       OR yaml+offset(4) = `Null`
                       OR yaml+offset(4) = `null` ).
            "=========
            " null
            "=========
            token-type = token_type-null.
            offset = offset + 4.
            state = states-after_value.

          ELSEIF     remaining_length >= 5
                 AND (    yaml+offset(5) = `FALSE`
                       OR yaml+offset(5) = `False`
                       OR yaml+offset(5) = `false` ).
            "=========
            " false
            "=========
            token-type = token_type-false.
            offset = offset + 5.
            state = states-after_value.

          ELSEIF yaml+offset(1) CA '+-0123456789'.
            "=========
            " NUMBER
            "=========
            FIND REGEX ''
                 & '\A' ##REGEX_POSIX       " Start of yaml+offset
                 & '('                      " start of submatch 1
                 & '[-+]?'                  " optional - or +
                 & '(?:0|[1-9][0-9]*)?'     " none, "0", "1" to "9" followed by optional digits "0" to "9"
                 & '(?:[.][0-9]+)?'         " optional "." followed by one or more digits 0 to 9
                 & '(?:[eE][+-]?[0-9]+)?'   " exponent
                 & ')'                      " end of submatch 1
                 & ' *'                     " 0 or more spaces
                 & '(?:$|\Z)'               " end of line or end of whole yaml string
                 IN SECTION OFFSET offset OF yaml
                 MATCH LENGTH DATA(match_length).
            IF sy-subrc <> 0.
              RAISE EXCEPTION TYPE zcx_yamljson
                EXPORTING text  = `'&1' is not a valid number`
                          msgv1 = substring( val = yaml
                                             off = offset ).
            ENDIF.

            token-type  = token_type-number.
            token-value = yaml+offset(match_length).

            offset = offset + match_length.
            state = states-after_value.

          ELSE.

            " Skip spaces (if any)
            offset = find_any_not_of( val = yaml
                                      off = offset
                                      sub = ` ` ).

            FIND REGEX '' ##REGEX_POSIX
*                 & '[ ]*'
                 & '('
                 &     '[^":][^ :]+'         " Starts with any character but " or :
                 &     '|'                   " or
                 &     '"(?:(?=[^"]|"").*)"' " starts with " followed by any sequence of characters ("" means ") and ends with single "
                 &     '[ ]*'                " optional spaces
                 & ')'
                 & ':'                       " colon
                 & '[ ]+'                    " optional spaces
                 & '('
                 &     '[^"].*'
                 &     '|'
                 &     '"(?:(?=[^"]|"").*)"'
                 &     '[ ]*'
                 & ')'
                 & '$'
                 IN SECTION
                 OFFSET offset
                 OF yaml
                 SUBMATCHES
                 DATA(property_name) ##NEEDED
                 DATA(property_value).
            IF     remaining_length >= 2
               AND yaml+offset(2)    = `- `.
*                 OR yaml+offset(1) = '{'
              "=========
              " OBJECT
              "=========
              token-type = token_type-object_start.
              offset = offset + 1.
              new_level = '{'.
              state = states-object_start.

            ELSEIF    (     remaining_length >= 2
                        AND yaml+offset(2)    = `- ` )
                   OR yaml+offset(1) = '['.
              "=========
              " ARRAY
              "=========
              token-type = token_type-array_start.
              offset = offset + 1.
              new_level = '['.
              state = states-array_start.

            ELSEIF yaml+offset(1) = '"'.
              "=========
              " STRING inside double quotes
              "=========
              token-type  = token_type-string.
              token-value = get_string_inside_double_quote( ).
              state = states-after_value.

            ELSE.
              "=========
              " Non-quoted STRING
              "=========
              token-type  = token_type-string.
              token-value = get_non_quoted_string( ).
              offset = offset + strlen( token-value ).
              state = states-after_value.
            ENDIF.
          ENDIF.

*          IF level > -1 AND levels+level(1) = '['.
*            token-name = |{ array_indexes[ level + 1 ] }|.
*            array_indexes[ level + 1 ] = array_indexes[ level + 1 ] + 1.
*          ENDIF.

        WHEN states-array_start.

          IF yaml+offset(1) = ']'.
            token-type = token_type-array_end.
            offset = offset + 1.
            state = states-after_value.
          ELSE.
            array_indexes = VALUE #( BASE array_indexes
                                     ( 0 ) ).
            state = states-start_value.
            exit = abap_false.
          ENDIF.

        WHEN states-object_start.

          IF yaml+offset(1) = '}'.
            token-type = token_type-object_end.
            offset = offset + 1.
            state = states-after_value.
          ELSE.
*            token-name = get_string( ).
            array_indexes = VALUE #( BASE array_indexes
                                     ( 0 ) ).
            state = states-between_member_name_and_value.
            exit = abap_false.
          ENDIF.

        WHEN states-between_member_name_and_value.
          "=========
          " separator between object member name and value
          "=========
          IF yaml+offset(1) <> ':'.
            RAISE EXCEPTION TYPE zcx_yamljson.
          ENDIF.
          offset = offset + 1.
          state = states-start_value.
          exit = abap_false.

        WHEN states-after_value.

          CASE yaml+offset(1).

            WHEN '}'.
              "=========
              " end of object
              "=========
              IF level = -1 OR levels+level(1) <> '{'.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type = token_type-object_end.
              offset = offset + 1.

            WHEN ']'.
              "=========
              " end of array
              "=========
              IF level = -1 OR levels+level(1) <> '['.
                RAISE EXCEPTION TYPE zcx_yamljson.
              ENDIF.
              token-type = token_type-array_end.
              offset = offset + 1.
              DELETE array_indexes INDEX lines( array_indexes ).

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
      REPLACE SECTION OFFSET ( strlen( yamlpath ) - yamlpath_segments[ lines( yamlpath_segments ) ] ) OF yamlpath WITH ``.
      DELETE yamlpath_segments INDEX lines( yamlpath_segments ).
      last_token_is_at_same_level = abap_false.
    ENDIF.
    IF level = -1.
      yamlpath = `$`.
      yamlpath_segments = VALUE #( ).
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
            REPLACE SECTION OFFSET ( strlen( yamlpath ) - yamlpath_segments[ lines( yamlpath_segments ) ] ) OF yamlpath WITH ``.
            DELETE yamlpath_segments INDEX lines( yamlpath_segments ).
          ENDIF.
        WHEN OTHERS.
          DATA(yamlpath_segment) = |."{ replace( val   = token-name
                                                 regex = '([."\\])' ##REGEX_POSIX
                                                 with  = '\\$1'
                                                 occ   = 0 ) }"|.
          yamlpath = yamlpath && yamlpath_segment.
          APPEND strlen( yamlpath_segment ) TO yamlpath_segments.
          CASE token-type.
            WHEN token_type-array_start OR token_type-object_start.
              levels = levels && new_level.
              level = level + 1.
            WHEN OTHERS.
              last_token_is_at_same_level = abap_true.
          ENDCASE.
      ENDCASE.
    ENDIF.

    IF     offset >= yaml_length
       AND level  <> -1.
      " end of yaml, all objects and arrays must have been closed
      RAISE EXCEPTION TYPE zcx_yamljson.
    ENDIF.

    result = token.
  ENDMETHOD.

  METHOD get_non_quoted_string.
    FIND REGEX '' ##REGEX_POSIX     " dummy empty literal for defining all RegEx parts the same way in the next lines
         & '^'                      " start of yaml+offset
         & ' *'                     " skip spaces (if any)
         & '([^ ].*)'               " all characters (till the end of line or end of yaml string)
         & '$'                      " end of line or end of yaml string
         IN SECTION OFFSET offset OF yaml
         SUBMATCHES result.
*         MATCH LENGTH DATA(length).
*         RESULTS DATA(match).
    IF sy-subrc <> 0.
      " Unexpected
      RAISE EXCEPTION TYPE zcx_yamljson.
    ENDIF.
*    result = substring( val = yaml
*                        off = offset
*                        len = length ).
  ENDMETHOD.

  METHOD get_string_inside_double_quote.
    FIND REGEX '' ##REGEX_POSIX     " dummy empty literal for defining all RegEx parts the same way in the next lines
         & '^'                      " start of yaml+offset
         & '"'                      " start of string
         & '('                      " start of subgroup
         & '(\\u[0-9a-zA-Z]{4})'    " Unicode code point e.g. \u0041 is "A" (U+0041)
         & '|'                      " OR
         & '(\\["\\/abefnrtv])'     " \ followed by " (U+0022), \ (U+005C), / (U+002F), a (U+0007), b (U+0008), e (U+001B), f (U+000C), n (U+000A), r (U+000D), t (U+0009), v (U+000B)
         & '|'                      " OR
         & '([^"\\])'               " any other character which is neither " nor \
         & ')'                      " end of subgroup
         & '*'                      " previous subgroup may occur 0 or any number of times
         & '"'                      " end of string
         & '$'                      " end of line or end of yaml string
         IN SECTION OFFSET offset OF yaml
         RESULTS DATA(match).
    IF sy-subrc <> 0.
      " Not a valid string
      RAISE EXCEPTION TYPE zcx_yamljson.
    ENDIF.

    LOOP AT match-submatches REFERENCE INTO DATA(submatch).
      DATA(yaml_character_entity) = substring( val = yaml
                                               off = offset + submatch->offset
                                               len = submatch->length ).
      IF yaml_character_entity CP '\u*'.
        result = result && cl_abap_conv_in_ce=>uccp( to_upper( substring( val = yaml_character_entity
                                                                          off = 2
                                                                          len = 4 ) ) ).
      ELSEIF     strlen( yaml_character_entity ) = 2
             AND yaml_character_entity(1)        = '\'.
        result = result
          && SWITCH char1( substring( val = yaml_character_entity
                                      off = 1
                                      len = 1 )
                           WHEN '"' THEN '"'
                           WHEN '\' THEN '\'
                           WHEN '/' THEN '\'
                           WHEN 'a' THEN alert_bell
                           WHEN 'b' THEN backspace
                           WHEN 'f' THEN formfeed
                           WHEN 'n' THEN |\n|
                           WHEN 'r' THEN |\r|
                           WHEN 't' THEN |\t|
                           WHEN 'v' THEN vertical_tab ).
      ELSE.
        result = result && yaml_character_entity.
      ENDIF.
    ENDLOOP.

    offset = offset + match-length.
  ENDMETHOD.

  METHOD is_token_available.
    IF offset < yaml_length.
      result = abap_true.
    ELSE.
      result = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD get_next_array.
*    TYPES ty_ref_to_value TYPE REF TO lcl_value.

    WHILE current_line_number <= lines( lines ).
      DATA(line) = REF #( lines[ current_line_number ] ).

      IF NOT substring( val = line->*
                        len = start_column_number ) CO space.
        current_line_number = current_line_number - 1.
        RETURN.
      ENDIF.

      DATA(line_from_starting_column) = substring( val = line->*
                                                   off = start_column_number ).
      IF     line_from_starting_column <> '-'
         AND line_from_starting_column NP '- *'.
        RAISE EXCEPTION TYPE zcx_yamljson.
      ENDIF.

      IF line_from_starting_column = '-'.
        current_line_number = current_line_number + 1.
      ENDIF.

      DATA(current_value) = " VALUE ty_ref_to_value( ).
      get_next_value( EXPORTING start_column_number = start_column_number + 2
                                lines               = lines
                      CHANGING  current_line_number = current_line_number ).
*                             current_value       = current_value ).

      array->append_item( current_value ).

      current_line_number = current_line_number + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD get_next_object.
*    TYPES ty_ref_to_value TYPE REF TO lcl_value.

    WHILE current_line_number <= lines( lines ).
      DATA(line) = REF #( lines[ current_line_number ] ).

      IF NOT substring( val = line->*
                        len = start_column_number ) CO ` `. " SPACE.
        current_line_number = current_line_number - 1.
        RETURN.
      ENDIF.

      DATA(line_from_starting_column) = substring( val = line->*
                                                   off = start_column_number ).

      SPLIT line_from_starting_column AT `:` INTO DATA(property_name) DATA(property_value).
      property_value = condense( property_value ).

      IF    line_from_starting_column  = ':'
         OR property_name             IS INITIAL.
        RAISE EXCEPTION TYPE zcx_yamljson.
      ENDIF.

      IF    property_value IS INITIAL
         OR property_value  = '|'.
        current_line_number = current_line_number + 1.
      ENDIF.

      DATA(object_property_value) = " VALUE ty_ref_to_value( ).
      get_next_value(
        EXPORTING
          start_column_number = COND #( WHEN property_value IS INITIAL THEN start_column_number + 2
                                        WHEN property_value = '|'      THEN start_column_number + 4
                                        ELSE                                start_column_number + strlen( property_name ) + 2 )
          lines               = lines
        CHANGING
          current_line_number = current_line_number ).
*          current_value       = object_property_value ).

      object->append_property( VALUE #( name  = property_name
                                        value = object_property_value ) ).

      current_line_number = current_line_number + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD get_next_value.
*    TYPES ty_ref_to_value TYPE REF TO lcl_value.

    DATA(line) = REF #( lines[ current_line_number ] ).

    DATA(line_from_starting_column) = substring( val = line->*
                                                 off = start_column_number ).

    IF line_from_starting_column CP `- *`.
      " ARRAY ITEM being itself an array or object
      current_value = zcl_yamljson_array=>create( ).
      get_next_array( EXPORTING start_column_number = start_column_number
                                lines               = lines
                                array               = CAST #( current_value )
                      CHANGING  current_line_number = current_line_number ).

    ELSEIF line_from_starting_column CS `: `.
      " OBJECT PROPERTY whose value is an array or object starting from the next line
      current_value = zcl_yamljson_object=>create( ).
      " TODO: variable is assigned but never used (ABAP cleaner)
      DATA(property_value_start_next_line) = xsdbool( line_from_starting_column CP `*:` ).
      get_next_object( EXPORTING start_column_number = start_column_number
                                 lines               = lines
                                 object              = CAST #( current_value )
                       CHANGING  current_line_number = current_line_number ).

    ELSE.
      IF line_from_starting_column CP `'*'`.
        " STRING
        current_value = zcl_yamljson_string=>create( substring( val = line_from_starting_column
                                                                off = 1
                                                                len = strlen( line_from_starting_column ) - 2 ) ).
      ELSE.
        " NUMBER
        TRY.
            DATA(number) = EXACT decfloat34( line_from_starting_column ).
            current_value = zcl_yamljson_number=>create( number ).
          CATCH cx_sy_conversion_no_number.
            DATA(unescaped_line_from_starting_c) = ``.
            IF line_from_starting_column CP '"*'.
              unescaped_line_from_starting_c = replace( val  = substring( val = line_from_starting_column
                                                                          off = 1
                                                                          len = strlen( line_from_starting_column ) - 2 )
                                                        sub  = '""'
                                                        with = '"'
                                                        occ  = 0 ).
            ELSEIF line_from_starting_column = '|'.
              current_line_number = current_line_number + 1.
              DATA(initial_line_number) = current_line_number.
              WHILE     current_line_number <= lines( lines )
                    AND strlen( lines[ current_line_number ] )        >= start_column_number
                    AND substring( val = lines[ current_line_number ]
                                   len = start_column_number )        CO ` `.
                current_line_number = current_line_number + 1.
              ENDWHILE.
              unescaped_line_from_starting_c = concat_lines_of(
                  sep   = |\n|
                  table = VALUE string_table( FOR <line> IN lines FROM initial_line_number TO current_line_number - 1
                                              ( substring( val = <line>
                                                           off = start_column_number ) ) ) ).
            ELSE.
              unescaped_line_from_starting_c = line_from_starting_column.
            ENDIF.
            current_value = zcl_yamljson_string=>create( unescaped_line_from_starting_c ).
        ENDTRY.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
