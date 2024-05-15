CREATE OR REPLACE PACKAGE PKG_API_REST IS

    TYPE cursor_type IS REF CURSOR;

    PROCEDURE GetParameter
    (
        cur_out     OUT cursor_type,
        pparam      IN PARAMETROSSISTEMA.NMPARAMETROSISTEMA%TYPE,
        pdescriptor IN PARAMETROSSISTEMA.DCQUALIFICADOR%TYPE
    );
    FUNCTION GetVlParametro
    (
        strParametro   IN ParametrosSistema.NMParametroSistema%TYPE,
        strCalificador IN ParametrosSistema.DCDEscriptorQualificador%TYPE
    ) RETURN ParametrosSistema.VLParametro%TYPE;

END PKG_API_REST;
/
CREATE OR REPLACE PACKAGE BODY PKG_API_REST AS

    FUNCTION GetVlParametro
    (
        strParametro   IN ParametrosSistema.NMParametroSistema%TYPE,
        strCalificador IN ParametrosSistema.DCDEscriptorQualificador%TYPE
    ) RETURN ParametrosSistema.VLParametro%TYPE IS

        strRet ParametrosSistema.VLParametro%TYPE;
    BEGIN

        SELECT VLParametro
          INTO strRet
          FROM ParametrosSistema
         WHERE NMParametroSistema = strParametro
           AND DCDescriptorQualificador = strCalificador;

        RETURN strRet;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;

    END GetVlParametro;

    PROCEDURE GetParameter
    (
        cur_out     OUT cursor_type,
        pparam      IN PARAMETROSSISTEMA.NMPARAMETROSISTEMA%TYPE,
        pdescriptor IN PARAMETROSSISTEMA.DCQUALIFICADOR%TYPE
    ) IS
        vParameter ParametrosSistema.VLParametro%TYPE;
    BEGIN

        vParameter := PKG_API_REST.GetVlParametro(pparam, pdescriptor);

        OPEN cur_out FOR
            SELECT vParameter AS valor
              FROM DUAL;

    END;

END PKG_API_REST;
/
