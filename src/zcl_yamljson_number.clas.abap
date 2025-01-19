CLASS zcl_yamljson_number DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_yamljson_value.

    CLASS-METHODS create
      IMPORTING !value        TYPE numeric
      RETURNING VALUE(result) TYPE REF TO zcl_yamljson_number.

    METHODS get_number
      RETURNING VALUE(result) TYPE decfloat34.

    METHODS get_number_as_f
      RETURNING VALUE(result) TYPE f.

  PRIVATE SECTION.
    DATA number   TYPE decfloat34.
    DATA number_f TYPE f.
ENDCLASS.


CLASS zcl_yamljson_number IMPLEMENTATION.
  METHOD create.
    result = NEW zcl_yamljson_number( ).
    result->number   = value.
    result->number_f = value.
  ENDMETHOD.

  METHOD get_number.
    result = number.
  ENDMETHOD.

  METHOD get_number_as_f.
    result = number_f.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_json.
    result = |{ number }|.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_type.
    result = zif_yamljson_value=>type-number.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_yaml.
    result = |{ number }|.
  ENDMETHOD.
ENDCLASS.
