CLASS zcl_yamljson_boolean DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_yamljson_value.

    CLASS-METHODS create
      IMPORTING value TYPE abap_bool
      RETURNING VALUE(result) TYPE REF TO zcl_yamljson_boolean.

    METHODS get_boolean
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    DATA boolean TYPE abap_bool.
ENDCLASS.


CLASS zcl_yamljson_boolean IMPLEMENTATION.
  METHOD create.
    result = NEW zcl_yamljson_boolean( ).
    result->boolean = value.
  ENDMETHOD.

  METHOD get_boolean.
    result = boolean.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_json.
    result = SWITCH #( boolean WHEN abap_true THEN 'true' ELSE 'false' ).
  ENDMETHOD.

  METHOD zif_yamljson_value~get_type.
    result = zif_yamljson_value=>type-boolean.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_yaml.
    " Arbitrary choice for rendered value (could also be True, TRUE, False, FALSE)
    result = SWITCH #( boolean WHEN abap_true THEN 'true' ELSE 'false' ).
  ENDMETHOD.
ENDCLASS.
