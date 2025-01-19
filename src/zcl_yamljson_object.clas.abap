CLASS zcl_yamljson_object DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_yamljson_value.

    TYPES:
      BEGIN OF ty_object_property,
        name  TYPE string,
        value TYPE REF TO zif_yamljson_value,
      END OF ty_object_property.
    TYPES ty_object_properties TYPE STANDARD TABLE OF ty_object_property WITH EMPTY KEY.

    METHODS append_property
      IMPORTING !property TYPE ty_object_property.

    CLASS-METHODS create
      IMPORTING !properties   TYPE ty_object_properties OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zcl_yamljson_object.

    METHODS get_properties
      RETURNING VALUE(result) TYPE ty_object_properties.

  PRIVATE SECTION.
    DATA properties TYPE ty_object_properties.
ENDCLASS.


CLASS zcl_yamljson_object IMPLEMENTATION.
  METHOD append_property.
    INSERT property INTO TABLE properties.
  ENDMETHOD.

  METHOD create.
    result = NEW zcl_yamljson_object( ).
    result->properties = properties.
  ENDMETHOD.

  METHOD get_properties.
    result = properties.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_json.
    result = '{'
          && concat_lines_of( sep   = ','
                              table = VALUE string_table( FOR <object_property> IN properties
                                                          ( |"{ <object_property>-name }": { <object_property>-value->get_json( ) }| ) ) )
          && '}'.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_type.
    result = zif_yamljson_value=>type-object.
  ENDMETHOD.

  METHOD zif_yamljson_value~get_yaml.
    result = concat_lines_of(
                 sep   = |\n|
                 table = VALUE string_table( FOR <object_property> IN properties
                                             ( |{ <object_property>-name }: { <object_property>-value->get_yaml( ) }| ) ) ).
  ENDMETHOD.
ENDCLASS.
