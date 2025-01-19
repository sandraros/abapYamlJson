*"* use this source file for your ABAP unit test classes

CLASS class_name DEFINITION
    FOR TESTING
    DURATION SHORT
    RISK LEVEL HARMLESS
    FINAL.
  PRIVATE SECTION.
    METHODS string FOR TESTING RAISING cx_static_check.
    METHODS number FOR TESTING RAISING cx_static_check.
    METHODS false FOR TESTING RAISING cx_static_check.
    METHODS true FOR TESTING RAISING cx_static_check.
    METHODS string_leading_spaces FOR TESTING RAISING cx_static_check.
    METHODS string_trailing_spaces FOR TESTING RAISING cx_static_check.
    METHODS string_multiline FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS class_name IMPLEMENTATION.
  METHOD false.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( 'false' )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-false
                                                        name  = ''
                                                        value = '' ) ).
  ENDMETHOD.
  METHOD number.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( '123' )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-number
                                                        name  = ''
                                                        value = '123' ) ).
  ENDMETHOD.
  METHOD string.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( 'Simple text' )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                        name  = ''
                                                        value = 'Simple text' ) ).
  ENDMETHOD.
  METHOD string_leading_spaces.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( '   Simple text' )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                        name  = ''
                                                        value = 'Simple text' ) ).
  ENDMETHOD.
  METHOD string_multiline.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( |\|\nFirst line\nSecond line| )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                        name  = ''
                                                        value = |First line\nSecond line\n| ) ).
  ENDMETHOD.
  METHOD string_trailing_spaces.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( `Simple text   ` )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                        name  = ''
                                                        value = `Simple text   ` ) ).
  ENDMETHOD.
  METHOD true.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( 'true' )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-true
                                                        name  = ''
                                                        value = '' ) ).
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( 'True' )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-true
                                                        name  = ''
                                                        value = '' ) ).
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_yaml_lexer=>create( 'TRUE' )->get_next_token( )
                                        exp = VALUE zcl_yamljson_yaml_lexer=>ty_token(
                                                        level = 0
                                                        type  = zcl_yamljson_yaml_lexer=>token_type-true
                                                        name  = ''
                                                        value = '' ) ).
  ENDMETHOD.
ENDCLASS.
