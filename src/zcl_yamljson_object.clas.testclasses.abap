*"* use this source file for your ABAP unit test classes

CLASS ltc_app DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS get_json                     FOR TESTING RAISING cx_static_check.

    METHODS get_properties                   FOR TESTING RAISING cx_static_check.
    METHODS get_yaml                     FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_app IMPLEMENTATION.
  METHOD get_json.
    DATA(object_properties) = VALUE zcl_yamljson_object=>ty_object_properties( ( name = 'prop1' value = zcl_yamljson_string=>create( 'text' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_object=>create( object_properties )->zif_yamljson_value~get_json( )
                                        exp = '{"prop1": "text"}' ).
  ENDMETHOD.

  METHOD get_properties.
    DATA(object_properties) = VALUE zcl_yamljson_object=>ty_object_properties( ( name = 'prop1' value = zcl_yamljson_string=>create( 'text' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_object=>create( object_properties )->get_properties( )
                                        exp = object_properties ).
  ENDMETHOD.

  METHOD get_yaml.
    DATA(object_properties) = VALUE zcl_yamljson_object=>ty_object_properties( ( name = 'prop1' value = zcl_yamljson_string=>create( 'text' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = zcl_yamljson_object=>create( object_properties )->zif_yamljson_value~get_yaml( )
                                        exp = 'prop1: text' ).
  ENDMETHOD.
ENDCLASS.
