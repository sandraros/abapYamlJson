CLASS zcl_yamljson_yaml_parser DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS parse
      IMPORTING yaml_lexer    TYPE REF TO zcl_yamljson_yaml_lexer
      RETURNING VALUE(result) TYPE REF TO zif_yamljson_value
      RAISING   zcx_yamljson.
ENDCLASS.


CLASS zcl_yamljson_yaml_parser IMPLEMENTATION.
  METHOD parse.
*    result = new zcl_yamljson( ).

    WHILE yaml_lexer->is_token_available( ).
      " TODO: variable is assigned but never used (ABAP cleaner)
      DATA(json_token) = yaml_lexer->get_next_token( ).

      IF result IS NOT BOUND.
*        result = NEW zcl_yamljson( ).
*        result->value = VALUE ty_ref_to_value( ).
      ENDIF.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
