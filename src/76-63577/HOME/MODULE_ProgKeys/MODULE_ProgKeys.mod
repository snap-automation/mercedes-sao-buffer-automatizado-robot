MODULE MODULE_ProgKeys

    !*****************************************************************************************************************************
    !PROG KEYS: Garante a Segurança do Usuário ao clicar nas ProgKeys
    !*****************************************************************************************************************************
    
    PROC ValidaProgKeys ()

        IF DOutput(VIRTUAL_TravaIndexGarra) = 1 THEN
            SetDO PN_OUT_DO_Cil_NRc, 1;
        ENDIF
        
        IF DOutput(VIRTUAL_DestravaIndexGarra) = 1 THEN
            SetDO PN_OUT_DO_Cil_NRc, 0;
        ENDIF
        
    ENDPROC
ENDMODULE