CLASS zcl_yamljson_json_parser DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS parse
      IMPORTING json_lexer    TYPE REF TO zcl_yamljson_json_lexer
      RETURNING VALUE(result) TYPE REF TO zif_yamljson_value
      RAISING   zcx_yamljson.
ENDCLASS.


CLASS zcl_yamljson_json_parser IMPLEMENTATION.
  METHOD parse.
    TYPES:
      BEGIN OF ty_stack_level,
        value TYPE REF TO zif_yamljson_value,
      END OF ty_stack_level.
    TYPES ty_stack_levels TYPE STANDARD TABLE OF ty_stack_level WITH EMPTY KEY.

    CONSTANTS json_token_type LIKE zcl_yamljson_json_lexer=>token_type VALUE zcl_yamljson_json_lexer=>token_type.

    DATA(current_level_number) = 1.
    DATA(stack_levels) = VALUE ty_stack_levels( ).
    INSERT INITIAL LINE INTO TABLE stack_levels REFERENCE INTO DATA(current_stack_level).

*    TRY.
*        DATA(json_lexer) = NEW zcl_yamljson_json_lexer( json ).
*      CATCH zcx_yamljson INTO DATA(error).
*        RAISE EXCEPTION TYPE zcx_yamljson
*          EXPORTING previous = error.
*    ENDTRY.

    WHILE json_lexer->is_token_available( ).

      TRY.
          DATA(json_token) = json_lexer->get_next_token( ).
        CATCH zcx_yamljson INTO DATA(error).
          RAISE EXCEPTION TYPE zcx_yamljson
            EXPORTING previous = error.
      ENDTRY.

      DATA(parent_value) = COND #( WHEN current_level_number >= 2 THEN stack_levels[ current_level_number - 1 ]-value ).

      DATA(new_level_number) = current_level_number.
      CASE json_token-type.
        WHEN json_token_type-array_end.
          new_level_number = current_level_number - 1.
        WHEN json_token_type-array_start.
          current_stack_level->value = zcl_yamljson_array=>create( ).
          new_level_number = current_level_number + 1.
        WHEN json_token_type-false.
          current_stack_level->value = zcl_yamljson_boolean=>create( abap_false ).
        WHEN json_token_type-null.
          current_stack_level->value = zcl_yamljson_null=>create( ).
        WHEN json_token_type-number.
          current_stack_level->value = zcl_yamljson_number=>create( CONV decfloat34( json_token-value ) ).
        WHEN json_token_type-object_end.
          new_level_number = current_level_number - 1.
        WHEN json_token_type-object_start.
          current_stack_level->value = zcl_yamljson_object=>create( ).
          new_level_number = current_level_number + 1.
        WHEN json_token_type-string.
          current_stack_level->value = zcl_yamljson_string=>create( json_token-value ).
        WHEN json_token_type-true.
          current_stack_level->value = zcl_yamljson_boolean=>create( abap_true ).
        WHEN OTHERS.
          " Impossible
          ASSERT 0 = 1.
      ENDCASE.

      IF result IS NOT BOUND.
*        result = NEW zcl_yamljson( ).
*        result->value = current_stack_level->value.
        result = current_stack_level->value.
      ENDIF.

      IF     parent_value     IS BOUND
         AND new_level_number >= current_level_number.
        CASE parent_value->get_type( ).
          WHEN zif_yamljson_value=>type-array.
            CAST zcl_yamljson_array( parent_value )->append_item( current_stack_level->value ).
          WHEN zif_yamljson_value=>type-object.
            CAST zcl_yamljson_object( parent_value )->append_property( VALUE #( name  = json_token-name
                                                                                value = current_stack_level->value ) ).
          WHEN OTHERS.
            " Do nothing
        ENDCASE.
      ENDIF.
      IF new_level_number > current_level_number.
        INSERT INITIAL LINE INTO TABLE stack_levels REFERENCE INTO current_stack_level.
      ELSEIF new_level_number < current_level_number.
        DELETE stack_levels INDEX current_level_number.
        current_stack_level = REF #( stack_levels[ new_level_number ] ).
      ENDIF.

      current_level_number = new_level_number.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
