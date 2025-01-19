*"* use this source file for your ABAP unit test classes

CLASS ltc_app DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS get_json                   FOR TESTING RAISING cx_static_check.
    METHODS get_json_exponent_negative FOR TESTING RAISING cx_static_check.
    METHODS get_json_exponent_positive FOR TESTING RAISING cx_static_check.
    METHODS get_number                 FOR TESTING RAISING cx_static_check.
    METHODS get_number_as_f            FOR TESTING RAISING cx_static_check.
    METHODS get_yaml                   FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_app IMPLEMENTATION.
  METHOD get_json.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_number=>create( 123 )->zif_yamljson_value~get_json( )
                                        exp = '123' ).
  ENDMETHOD.

  METHOD get_json_exponent_negative.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_number=>create( CONV f( '1E-1' ) )->zif_yamljson_value~get_json( )
                                        exp = '0.10000000000000001' ).
  ENDMETHOD.

  METHOD get_json_exponent_positive.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_number=>create( EXACT f( '1E5' ) )->zif_yamljson_value~get_json( )
                                        exp = '100000' ).
  ENDMETHOD.

  METHOD get_number.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_number=>create( 123 )->get_number( )
                                        exp = 123 ).
  ENDMETHOD.

  METHOD get_number_as_f.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_number=>create( CONV f( '1E-1' ) )->get_number_as_f( )
                                        exp = CONV f( '1E-1' ) ).
  ENDMETHOD.

  METHOD get_yaml.
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_number=>create( 123 )->zif_yamljson_value~get_yaml( )
                                        exp = 123 ).
  ENDMETHOD.
ENDCLASS.
