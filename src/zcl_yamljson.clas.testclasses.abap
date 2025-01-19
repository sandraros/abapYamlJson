*"* use this source file for your ABAP unit test classes

CLASS ltc_create_from_yaml DEFINITION FINAL
    FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
  PRIVATE SECTION.

    METHODS string_simple FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_create_from_yaml IMPLEMENTATION.
  METHOD string_simple.
    cl_abap_unit_assert=>assert_equals( act = cast zcl_yamljson_string( zcl_yamljson=>create_from_yaml( yaml = |Simple text| ) )->get_string( )
                                        exp = 'Simple text' ).
  ENDMETHOD.
ENDCLASS.


*CLASS ltc_create_from_yaml_get_json DEFINITION FINAL
*    FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
*  PUBLIC SECTION.
*  PRIVATE SECTION.
*
*    METHODS string_double_quotes FOR TESTING RAISING cx_static_check.
*    METHODS string_leading_spaces_ignored FOR TESTING RAISING cx_static_check.
*    METHODS string_simple FOR TESTING RAISING cx_static_check.
*ENDCLASS.
*
*
**CLASS lcl_find_token DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
**
**  PRIVATE SECTION.
**    METHODS simple         FOR TESTING RAISING lcx_json_parser.
**    METHODS simple2        FOR TESTING RAISING lcx_json_parser.
**    METHODS get_next_token FOR TESTING RAISING lcx_json_parser.
**    METHODS not_found      FOR TESTING RAISING lcx_json_parser.
**    METHODS empty_array    FOR TESTING RAISING lcx_json_parser.
**
**    TYPES ty_token  TYPE lcl_json_reader=>ty_token.
**    TYPES ty_tokens TYPE STANDARD TABLE OF lcl_json_reader=>ty_token WITH EMPTY KEY.
**
**    DATA token_type LIKE lcl_json_reader=>token_type VALUE lcl_json_reader=>token_type.
**
**ENDCLASS.
*
*
*CLASS ltc_create_from_yaml_get_json IMPLEMENTATION.
*  METHOD string_double_quotes.
*    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson=>create_from_yaml( yaml = '"\" text starting with a double quote"' )->get_json_string( )
*                                        exp = '"\" text starting with a double quote"' ).
*  ENDMETHOD.
*
*  METHOD string_Leading_spaces_ignored.
*    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson=>create_from_yaml( yaml = | Leading spaces ignored| )->get_json_string( )
*                                        exp = '"Leading spaces ignored"' ).
*  ENDMETHOD.
*  METHOD string_simple.
*    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson=>create_from_yaml( yaml = |Simple text| )->get_json_string( )
*                                        exp = '"Simple text"' ).
*  ENDMETHOD.
*ENDCLASS.
*
*
**CLASS lcl_find_token IMPLEMENTATION.
**  METHOD simple.
**    " when FIND_TOKEN is called
**    DATA(parser) = NEW lcl_json_reader( '{"pi":3.14}' ).
**    " then it should find the corresponding member
**    DATA(act_token) = parser->find_token( VALUE #( ( `$."pi"` ) ) ).
**    DATA(exp_token) = VALUE ty_token( level = 1
**                                      type  = token_type-number
**                                      name  = 'pi'
**                                      value = '3.14' ).
**    cl_abap_unit_assert=>assert_equals( act = act_token
**                                        exp = exp_token ).
***    " when FIND_TOKEN is called
***    DATA(parser) = NEW lcl_json_reader( '{"pi":3.14,"e":2.718}' ).
***    " then it should find the corresponding member
***    DATA(act_token) = parser->find_token( VALUE #( ( `$."e"` ) ) ).
***    DATA(exp_token) = VALUE ty_token( level = 1 type = token_type-number name = 'e' value = '2.718' ).
***    cl_abap_unit_assert=>assert_equals( act = act_token exp = exp_token ).
**  ENDMETHOD.
**
**  METHOD simple2.
**    " when FIND_TOKEN is called
**    DATA(parser) = NEW lcl_json_reader( '{"pi":[3.14],"e":2.718}' ).
**    " then it should find the corresponding member
**    DATA(act_token) = parser->find_token( VALUE #( ( `$."e"` ) ) ).
**    DATA(exp_token) = VALUE ty_token( level = 1
**                                      type  = token_type-number
**                                      name  = 'e'
**                                      value = '2.718' ).
**    cl_abap_unit_assert=>assert_equals( act = act_token
**                                        exp = exp_token ).
**  ENDMETHOD.
**
**  METHOD get_next_token.
**    " when FIND_TOKEN is called
**    DATA(parser) = NEW lcl_json_reader( '{ "_version": "1.2.0", "sap.fiori": { "_version": "1.1.0", "registrationIds": [ "F0842A" ], "archeType": "transactional" }}' ).
**    " then it should find the corresponding member
**    DATA(act_token) = parser->find_token( VALUE #( ( `$."sap\.fiori"."archeType"` ) ( `$."sap\.fiori"."registrationIds"` ) ) ).
**    DATA(exp_token) = VALUE ty_token( level = 2
**                                      type  = token_type-array_start
**                                      name  = 'registrationIds'
**                                      value = '' ).
**    cl_abap_unit_assert=>assert_equals( act = act_token
**                                        exp = exp_token ).
**    " and the next token should be as expected
**    act_token = parser->get_next_token( ).
**    exp_token = VALUE ty_token( level = 3
**                                type  = token_type-string
**                                name  = '0'
**                                value = 'F0842A' ).
**    cl_abap_unit_assert=>assert_equals( act = act_token
**                                        exp = exp_token ).
**  ENDMETHOD.
**
**  METHOD not_found.
**    " when FIND_TOKEN is called but nothing matches
**    DATA(act_token) = NEW lcl_json_reader( '{"pi":3.14,"e":2.718}' )->find_token( VALUE #( ( `aaa` ) ) ).
**    " then it should return initial
**    cl_abap_unit_assert=>assert_initial( act = act_token ).
**  ENDMETHOD.
**
**  METHOD empty_array.
**    " when 2 elements are searched, the first one being an empty array
**    DATA(parser) = NEW lcl_json_reader( `{"a":[],"pi":3.14}` ).
**    DO 2 TIMES.
**      DATA(act_token) = parser->find_token( VALUE #( ( `$."a"` ) ( `$."pi"` ) ) ).
**    ENDDO.
**    " then it should find the 2nd element
**    DATA(exp_token) = VALUE ty_token( level = 1
**                                      type  = token_type-number
**                                      name  = 'pi'
**                                      value = '3.14' ).
**    cl_abap_unit_assert=>assert_equals( act = act_token
**                                        exp = exp_token ).
**  ENDMETHOD.
**ENDCLASS.
