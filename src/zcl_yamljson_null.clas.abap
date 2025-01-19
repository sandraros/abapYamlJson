CLASS zcl_yamljson_null DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_yamljson_value.

    CLASS-METHODS create
      RETURNING VALUE(result) TYPE REF TO zcl_yamljson_null.
ENDCLASS.


CLASS zcl_yamljson_null IMPLEMENTATION.
  METHOD create.
    result = NEW zcl_yamljson_null( ).
  ENDMETHOD.

  METHOD zif_yamljson_value~get_json.
    result = 'null'.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_type.
    result = zif_yamljson_value=>type-null.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_yaml.
    " Arbitrary choice for rendered value (could also be Null or NULL)
    result = 'null'.
  ENDMETHOD.
ENDCLASS.
