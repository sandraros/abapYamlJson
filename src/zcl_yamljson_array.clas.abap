CLASS zcl_yamljson_array DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_yamljson_value.

    TYPES ty_array_item  TYPE REF TO zif_yamljson_value.
    TYPES ty_array_items TYPE STANDARD TABLE OF ty_array_item WITH EMPTY KEY.

    METHODS append_item
      IMPORTING item TYPE ty_array_item.

    CLASS-METHODS create
      IMPORTING !value        TYPE ty_array_items OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zcl_yamljson_array.

    METHODS get_items
      RETURNING VALUE(result) TYPE ty_array_items.

  PRIVATE SECTION.
    DATA items TYPE ty_array_items.
ENDCLASS.


CLASS zcl_yamljson_array IMPLEMENTATION.
  METHOD append_item.
    INSERT item INTO TABLE items.
  ENDMETHOD.

  METHOD create.
    result = NEW zcl_yamljson_array( ).
    result->items = value.
  ENDMETHOD.

  METHOD get_items.
    result = items.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_json.
    result = '['
          && concat_lines_of( sep   = ','
                              table = VALUE string_table( FOR <array_item> IN items
                                                          ( <array_item>->get_json( ) ) ) )
          && ']'.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_type.
    result = zif_yamljson_value=>type-array.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_yaml.
    result = concat_lines_of( sep   = |\n|
                              table = VALUE string_table( FOR <array_item> IN items
                                                          ( `- ` && <array_item>->get_yaml( ) ) ) ).
  ENDMETHOD.
ENDCLASS.
