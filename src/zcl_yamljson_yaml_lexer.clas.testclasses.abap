*"* use this source file for your ABAP unit test classes

CLASS ltc_app DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS false                  FOR TESTING RAISING cx_static_check.
    METHODS number                 FOR TESTING RAISING cx_static_check.
    METHODS object                 FOR TESTING RAISING cx_static_check.
    METHODS object_two_properties  FOR TESTING RAISING cx_static_check.
    METHODS string                 FOR TESTING RAISING cx_static_check.
    METHODS string_leading_spaces  FOR TESTING RAISING cx_static_check.
    METHODS string_multiline       FOR TESTING RAISING cx_static_check.
    METHODS string_trailing_spaces FOR TESTING RAISING cx_static_check.
    METHODS true                   FOR TESTING RAISING cx_static_check.

    TYPES ty_tokens TYPE STANDARD TABLE OF zcl_yamljson_yaml_lexer=>ty_token WITH EMPTY KEY.

    DATA tokens TYPE ty_tokens.

    METHODS get_all_tokens
      IMPORTING yaml            TYPE csequence
                number_expected TYPE i
      RETURNING VALUE(result)   TYPE ty_tokens.
ENDCLASS.


CLASS ltc_app IMPLEMENTATION.
  METHOD false.
    tokens = get_all_tokens( yaml            = 'false'
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-false
                                                                 name  = ''
                                                                 value = '' ) ) ).
  ENDMETHOD.

  METHOD get_all_tokens.
    DATA(yaml_lexer) = zcl_yamljson_yaml_lexer=>create( yaml ).
    DATA(number_of_tokens_read) = 0.
    DO number_expected TIMES.
      TRY.
          INSERT yaml_lexer->get_next_token( )
                 INTO TABLE result.
          number_of_tokens_read = number_of_tokens_read + 1.
        CATCH zcx_yamljson.
          cl_abap_unit_assert=>fail(
              msg = |Only { number_of_tokens_read } token(s) could be actually read versus { number_expected } expected| ).
      ENDTRY.
    ENDDO.

    " Make sure there's no more token (must fail)
    TRY.
        yaml_lexer->get_next_token( ).
      CATCH zcx_yamljson ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD number.
    tokens = get_all_tokens( yaml            = '123'
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-number
                                                                 name  = ''
                                                                 value = '123' ) ) ).
  ENDMETHOD.

  METHOD object.
    tokens = get_all_tokens( yaml            = 'prop: value'
                             number_expected = 3 ).
    cl_abap_unit_assert=>assert_equals(
        act = tokens
        exp = VALUE ty_tokens( value = ''
                               ( level = 0 type = zcl_yamljson_yaml_lexer=>token_type-object_start name = '' )
                               ( level = 1 type = zcl_yamljson_yaml_lexer=>token_type-string       name = 'prop' )
                               ( level = 0 type = zcl_yamljson_yaml_lexer=>token_type-object_end   name = '' ) ) ).
  ENDMETHOD.

  METHOD object_two_properties.
    tokens = get_all_tokens( yaml            = concat_lines_of( sep   = |\n|
                                                                table = VALUE string_table( ( `prop1: value1` )
                                                                                            ( `prop2: value2` ) ) )
                             number_expected = 4 ).
    cl_abap_unit_assert=>assert_equals(
        act = tokens
        exp = VALUE ty_tokens(
                        ( level = 0 type = zcl_yamljson_yaml_lexer=>token_type-object_start name = ''      value = '' )
                        ( level = 1 type = zcl_yamljson_yaml_lexer=>token_type-string       name = 'prop1' value = 'value1' )
                        ( level = 1 type = zcl_yamljson_yaml_lexer=>token_type-string       name = 'prop2' value = 'value2' )
                        ( level = 0 type = zcl_yamljson_yaml_lexer=>token_type-object_end   name = ''      value = '' ) ) ).
  ENDMETHOD.

  METHOD string.
    tokens = get_all_tokens( yaml            = 'Simple text'
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                                 name  = ''
                                                                 value = 'Simple text' ) ) ).
  ENDMETHOD.

  METHOD string_leading_spaces.
    tokens = get_all_tokens( yaml            = '   Simple text'
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                                 name  = ''
                                                                 value = 'Simple text' ) ) ).
  ENDMETHOD.

  METHOD string_multiline.
    tokens = get_all_tokens( yaml            = concat_lines_of( sep   = |\n|
                                                                table = VALUE string_table( ( `|` )
                                                                                            ( `First line` )
                                                                                            ( `Second line` ) ) )
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                                 name  = ''
                                                                 value = |First line\nSecond line\n| ) ) ).
  ENDMETHOD.

  METHOD string_trailing_spaces.
    tokens = get_all_tokens( yaml            = `Simple text   `
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-string
                                                                 name  = ''
                                                                 value = `Simple text   ` ) ) ).
  ENDMETHOD.

  METHOD true.
    tokens = get_all_tokens( yaml            = 'true'
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-true
                                                                 name  = ''
                                                                 value = '' ) ) ).

    tokens = get_all_tokens( yaml            = 'True'
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-true
                                                                 name  = ''
                                                                 value = '' ) ) ).

    tokens = get_all_tokens( yaml            = 'TRUE'
                             number_expected = 1 ).
    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE ty_tokens( ( level = 0
                                                                 type  = zcl_yamljson_yaml_lexer=>token_type-true
                                                                 name  = ''
                                                                 value = '' ) ) ).
  ENDMETHOD.
ENDCLASS.
