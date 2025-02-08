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
    WHILE yaml_lexer->is_token_available( ).

      DATA(yaml_token) = yaml_lexer->get_next_token( ).

      CASE yaml_token-type.
        WHEN yaml_lexer->token_type-false.
          result = zcl_yamljson_boolean=>create( abap_false ).
        WHEN yaml_lexer->token_type-null.
          result = zcl_yamljson_null=>create( ).
        WHEN yaml_lexer->token_type-number.
          result = zcl_yamljson_number=>create( EXACT decfloat34( yaml_token-value ) ).
        WHEN yaml_lexer->token_type-string.
          result = zcl_yamljson_string=>create( yaml_token-value ).
        WHEN yaml_lexer->token_type-true.
          result = zcl_yamljson_boolean=>create( abap_true ).
      ENDCASE.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
