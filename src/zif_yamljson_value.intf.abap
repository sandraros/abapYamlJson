INTERFACE zif_yamljson_value
  PUBLIC.

  TYPES ty_type TYPE i.
  CONSTANTS:
    BEGIN OF type,
      array   TYPE ty_type VALUE 1,
      boolean TYPE ty_type VALUE 2,
      null    TYPE ty_type VALUE 3,
      number  TYPE ty_type VALUE 4,
      object  TYPE ty_type VALUE 5,
      string  TYPE ty_type VALUE 6,
    END OF type.

  METHODS get_type
    RETURNING VALUE(result) TYPE ty_type.

  METHODS get_json
    RETURNING VALUE(result) TYPE string.

  METHODS get_yaml
    RETURNING VALUE(result) TYPE string.

ENDINTERFACE.
