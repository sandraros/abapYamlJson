*"* use this source file for your ABAP unit test classes

CLASS ltc_app DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS get_json                     FOR TESTING RAISING cx_static_check.
    METHODS get_json_escape_double_quote FOR TESTING RAISING cx_static_check.
    METHODS get_string                   FOR TESTING RAISING cx_static_check.
    METHODS get_yaml                     FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_app IMPLEMENTATION.
  METHOD get_json.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_string=>create( 'text' )->zif_yamljson_value~get_json( )
                                        exp = '"text"' ).
  ENDMETHOD.

  METHOD get_json_escape_double_quote.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_string=>create( 'this "text" in double quotes' )->zif_yamljson_value~get_json( )
                                        exp = '"this \"text\" in double quotes"' ).
  ENDMETHOD.

  METHOD get_string.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_string=>create( 'text' )->get_string( )
                                        exp = 'text' ).
  ENDMETHOD.

  METHOD get_yaml.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_string=>create( 'text' )->zif_yamljson_value~get_yaml( )
                                        exp = 'text' ).
  ENDMETHOD.
ENDCLASS.
