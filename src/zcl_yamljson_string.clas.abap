CLASS zcl_yamljson_string DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_yamljson_value.

    CLASS-METHODS create
      IMPORTING value TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zcl_yamljson_string.

    methods get_string
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA string               TYPE string.
    DATA count_leading_spaces TYPE i.
    DATA trailing_newline     TYPE abap_bool.
ENDCLASS.


CLASS zcl_yamljson_string IMPLEMENTATION.
  METHOD create.
    result = NEW zcl_yamljson_string( ).
    result->string = value.

    DATA(i) = 0.
    WHILE     i   < strlen( value )
          AND ` ` = substring( val = value
                               off = i
                               len = 1 ).
      i = i + 1.
    ENDWHILE.
    result->count_leading_spaces = i.

    result->trailing_newline = xsdbool(     strlen( value ) >= 1
                                        AND |\n|             = substring( val = value
                                                                          off = strlen( value ) - 1
                                                                          len = 1 ) ).
  ENDMETHOD.

  METHOD get_string.
    result = string.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_json.
    result = |"{ escape( val    = string
                         format = cl_abap_format=>e_json_string )
             }"|.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_type.
    result = zif_yamljson_value=>type-string.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_yaml.
    IF string cs |\n|.
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Multiline
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " In the first line, use one of these 4 forms: | or |1 or |- or |1-
      result = '|'
                && cond #( when count_leading_spaces <> 0 then |{ count_leading_spaces }| )
                && cond #( when trailing_newline = abap_false then '-' )
                && |\n|
                && string.

    ELSEIF string CP '*:*'
        OR string CP '- *'
        OR string CP '|*'
        OR string CP ' *'
        OR string CP '"*'.
      " Present text between double quotes
      result = |"{ replace( val  = string
                            sub  = '"'
                            with = '\"'
                            occ  = 0 )
               }"|.

    ELSE.
      " Present text unchanged
      result = string.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
