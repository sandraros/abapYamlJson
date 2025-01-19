CLASS zcl_yamljson DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS create_from_json
      IMPORTING json          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_yamljson_value
      RAISING   zcx_lpp_priv_yaml_json
                zcx_yamljson.

    CLASS-METHODS create_from_yaml
      IMPORTING yaml          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_yamljson_value
      RAISING   zcx_yamljson.

    METHODS get_json
      RETURNING VALUE(result) TYPE string.

    METHODS get_yaml
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA value TYPE REF TO zif_yamljson_value.

ENDCLASS.


CLASS zcl_yamljson IMPLEMENTATION.
  METHOD create_from_json.
    DATA(json_lexer) = zcl_yamljson_json_lexer=>create( json ).
    result = zcl_yamljson_json_parser=>parse( json_lexer ).
  ENDMETHOD.

  METHOD create_from_yaml.
    DATA(yaml_lexer) = zcl_yamljson_yaml_lexer=>create( yaml ).
    result = zcl_yamljson_yaml_parser=>parse( yaml_lexer ).
  ENDMETHOD.

  METHOD get_json.
    result = value->get_json( ).
  ENDMETHOD.

  METHOD get_yaml.
    result = value->get_yaml( ).
  ENDMETHOD.
ENDCLASS.
