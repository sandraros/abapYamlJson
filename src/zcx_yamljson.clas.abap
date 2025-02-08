CLASS zcx_yamljson DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS zcx_yamljson TYPE sotr_conc VALUE '1937A9BB56E10006AA9A30000A11447B' ##NO_TEXT.

    DATA text  TYPE string READ-ONLY.
    DATA msgv1 TYPE string READ-ONLY.
    DATA msgv2 TYPE string READ-ONLY.
    DATA msgv3 TYPE string READ-ONLY.
    DATA msgv4 TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING !text     TYPE clike          OPTIONAL
                msgv1     TYPE clike          OPTIONAL
                msgv2     TYPE clike          OPTIONAL
                msgv3     TYPE clike          OPTIONAL
                msgv4     TYPE clike          OPTIONAL
                textid    LIKE textid         OPTIONAL
                !previous TYPE REF TO cx_root OPTIONAL.

    METHODS get_longtext REDEFINITION.

    METHODS get_text     REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.


CLASS zcx_yamljson IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( textid   = textid
                        previous = previous ).
    IF textid IS INITIAL.
      me->textid = zcx_yamljson.
    ENDIF.
    me->text  = text.
    me->msgv1 = msgv1.
    me->msgv2 = msgv2.
    me->msgv3 = msgv3.
    me->msgv4 = msgv4.
  ENDMETHOD.

  METHOD get_longtext.
    result = get_text( ).
  ENDMETHOD.

  METHOD get_text.
    result = text.
    result = replace( val  = result
                      sub  = '&1'
                      with = msgv1 ).
    result = replace( val  = result
                      sub  = '&2'
                      with = msgv2 ).
    result = replace( val  = result
                      sub  = '&3'
                      with = msgv3 ).
    result = replace( val  = result
                      sub  = '&4'
                      with = msgv4 ).
  ENDMETHOD.
ENDCLASS.
