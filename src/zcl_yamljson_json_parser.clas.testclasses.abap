*"* use this source file for your ABAP unit test classes

CLASS ltc_app DEFINITION FINAL
    FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
  PRIVATE SECTION.

    METHODS string_simple FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_app IMPLEMENTATION.
  METHOD string_simple.
    DATA(json_lexer) = zcl_yamljson_json_lexer=>create( json = |"Simple text"| ).
    DATA(yamljson_value) = zcl_yamljson_json_parser=>parse( json_lexer ).
    cl_abap_unit_assert=>assert_equals( act = cast zcl_yamljson_string( yamljson_value )->get_string( )
                                        exp = 'Simple text' ).
  ENDMETHOD.
ENDCLASS.
