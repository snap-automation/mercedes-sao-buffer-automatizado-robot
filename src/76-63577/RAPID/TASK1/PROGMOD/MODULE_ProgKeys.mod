MODULE MODULE_ProgKeys

    VAR Bool BOOL_FPFechaGarra;
    VAR Bool BOOL_FPAbreGarra;
    VAR Num NUM_RespostaTP;
    VAR Num NUM_IndicacaoAnterior;
    VAR Num NUM_RespostaSimNao; !5 = Sim, todos os outros = Não
    
    !Timeout de Cilindros
    VAR bool timeout_rc1;
    VAR bool timeout_rc2;
    VAR bool timeout_rc3;
    VAR bool timeout_rc4;
    VAR bool timeout_av1;
    VAR bool timeout_av2;
    
    !*****************************************************************************************************************************
    !PROG KEYS: Garante a Segurança do Usuário ao clicar nas ProgKeys
    !*****************************************************************************************************************************
    PROC ValidaProgKeys ()

        !**********************************************************************        
        !Cilindro Trava Cilindros Index
        IF DOutput(VIRTUAL_TravaIndexGarra) = 1 THEN
            !Trava Produto
            SetDO \Sync, DO_Rc_Fixação_Peça, 0;
            SetDO \Sync, DO_Av_Fixação_Peça, 1;
        ENDIF

        !**********************************************************************        
        !Cilindro Destrava Cilindros Index
        IF DOutput(VIRTUAL_DestravaIndexGarra) = 1 THEN
            !Destrava produto na garra
            SetDO \Sync, DO_Av_Fixação_Peça, 0;
            SetDO \Sync, DO_Rc_Fixação_Peça, 1;
        ENDIF

        !**********************************************************************
        !Servo Fechar Garra (Pergunta ao usuário qual o setup correto)
        IF (DOutput(VIRTUAL_FechaGarra) = 1) AND (NOT BOOL_FPFechaGarra) THEN
            
            !Garante Travas Abertas
            IF NOT ValidaTravas() THEN
                MsgBoxOk("Primeiro Retire as Travas!");
                GOTO ret_fechar;
            ENDIF
            
            TPErase;
            TPReadFK NUM_RespostaTP, "FECHAR Garra: Indicar p/ Qual Setup:", "H2", "H4", "H6", "H8", "Cancelar!";
            IF (NUM_RespostaTP = 5) THEN
                TPErase;
                GOTO ret_fechar;
            ENDIF
               
            !Verificar se usuário se confundiu (Validar setup pedido com o último enviado)
            NUM_IndicacaoAnterior := GOutput(PN_GO_Modelo_Produto);
            IF (NUM_RespostaTP <> NUM_IndicacaoAnterior) THEN
               TPReadFK NUM_RespostaSimNao, "FECHAR Garra: Setup Difere de " + GetModelo(NUM_IndicacaoAnterior) + "(Modelo Anterior). Tem Certeza???", "Não tenho Certeza!", "Cancelar!", "Nem Pensar!", "Esqueci!", "Sim, Fechar Garra Tipo " + GetModelo(NUM_RespostaTP);
               IF (NUM_RespostaSimNao <> 5) THEN
                   TPErase;
                   GOTO ret_fechar;
               ENDIF
            ENDIF

            !Perguntar DE NOVO se quer fechar
            TPErase;
            TPReadFK NUM_RespostaSimNao, "Fechando Garra para " + GetModelo(NUM_RespostaTP) + ". Confirma ???", "Não tenho Certeza!", "Cancelar!", "Esqueci!", "Sim, Fechar Garra Tipo " + GetModelo(NUM_RespostaTP), "Nem Pensar!";
            IF (NUM_RespostaSimNao <> 4) THEN
               GOTO ret_fechar;
            ENDIF

            !Se chegou até aqui é pq usuário confirmou. Fechar Garra:
            FecharGarraProgKey(NUM_RespostaTP);


            ret_fechar: !Garante que comando zerou
            SetDO VIRTUAL_FechaGarra, 0;
            
        ENDIF

        !Auxiliar de Pulso
        BOOL_FPFechaGarra := (DOutput(VIRTUAL_FechaGarra) = 1);

        !**********************************************************************
        !Servo Abrir Garra (Pergunta ao usuário qual o setup correto)
        IF (DOutput(VIRTUAL_AbreGarra) = 1) AND (NOT BOOL_FPAbreGarra) THEN
            
            !Garante Travas Abertas
            IF NOT ValidaTravas() THEN
                MsgBoxOk("Primeiro Retire as Travas!");
                GOTO ret_abrir;
            ENDIF
            
            TPErase;
            TPReadFK NUM_RespostaTP, "ABRIR Garra: Indicar p/ Qual Setup:", "H2", "H4", "H6", "H8", "Cancelar!";
            IF (NUM_RespostaTP = 5) THEN
                TPErase;
                GOTO ret_abrir;
            ENDIF
            
            !Pegar Confirmação do Usuário
            TPErase;
            TPReadFK NUM_RespostaSimNao, "Abrindo Garra para " + GetModelo(NUM_RespostaTP) + ". Confirma ???", "Não tenho Certeza!", "Cancelar!", "Nem Pensar!", "Esqueci!", "Sim, Abrir Garra Tipo " + GetModelo(NUM_RespostaTP);
            
            IF (NUM_RespostaSimNao <> 5) THEN
               GOTO ret_abrir;
            ENDIF

            !Se chegou até aqui é pq usuário confirmou. Fechar Garra:
            AbrirGarraProgKey(NUM_RespostaTP);


            ret_abrir: !Garante que comando zerou
            SetDO VIRTUAL_AbreGarra, 0;
            
        ENDIF

        !Auxiliar de Pulso
        BOOL_FPAbreGarra := (DOutput(VIRTUAL_AbreGarra) = 1);

    ENDPROC
    
    !*****************************************************************************************************************************
    !Retorna um texto contendo o nome do tipo para mensagens no TP
    !*****************************************************************************************************************************
    FUNC string GetModelo(Num i)
        TEST i
            CASE 1:
                RETURN "H2 (1)";
            CASE 2:
                RETURN "H4 (2)";
            CASE 3:
                RETURN "H6 (3)";
            CASE 4:
                RETURN "H8 (4)";
            DEFAULT :
                RETURN "?";
        ENDTEST
    ENDFUNC
    
    !*****************************************************************************************************************************
    !Lança Mensagem na Tela e Aguarda Usuário apertar "Ok"
    !*****************************************************************************************************************************
    PROC MsgBoxOk(string pSTR_msg)
        VAR NUM lNUM_RespostaUsuario;
        
        TPErase;
        TPReadFK lNUM_RespostaUsuario, pSTR_msg, stEmpty, stEmpty, stEmpty, stEmpty, "Ok";
    ENDPROC
    
    !*****************************************************************************************************************************
    !Lança Mensagem na Tela e Retorna "true" se usuário apertou "sim"
    !*****************************************************************************************************************************
    FUNC bool MsgBoxSimNao(string pSTR_Msg, string pSTR_Sim, string pSTR_Nao)
        VAR NUM lNUM_RespostaUsuario;
        
        TPErase;
        TPReadFK lNUM_RespostaUsuario, pSTR_Msg, pSTR_Nao, stEmpty, stEmpty, stEmpty, pSTR_Sim;
        
        IF lNUM_RespostaUsuario = 5 THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        ENDIF
        
    ENDFUNC    
            
    !*************************************************************************************************************************
    !Fecha Garra Manual Através de ProgKeys
    !*************************************************************************************************************************
    PROC FecharGarraProgKey(Num f)
        
        !Define Setup
        SetGO PN_GO_Modelo_Produto, f;
        
        WaitTime 0.2;
        
        !Garante que escreveu corretamente
        IF GOutput (PN_GO_Modelo_Produto) <> f THEN
            MsgBoxOk("Erro FecharGarraProgKey: CLP não carregou valor correto para fechamento de garra");
            RETURN;
        ENDIF              
        
        !Comando Fechamento Servos:
        SetDO \Sync, PN_OUT_Solicita_Fecha_Garra, 1;
        SetDO \Sync, PN_OUT_Solicita_Abertura, 0;    
        
        WaitTime 0.2;
        
        WaitDI PN_IN_Garra_Aberta, 0\MaxTime:= 3\TimeFlag:=timeout_av1;
        WaitDI PN_IN_Garra_Fechada, 1\MaxTime:= 3\TimeFlag:=timeout_av2;
        
        !Se não fechou, avisa erro:
        IF (timeout_av1 OR timeout_av2) THEN
            SetDO PN_OUT_Solicita_Fecha_Garra, 0;
            MsgBoxOk("Supervisão Posicionamento Garra: Servos NÃO Fecharam!");
        ENDIF

        !Reset do Comando
        SetDO \Sync, PN_OUT_Solicita_Fecha_Garra, 0;                
	ENDPROC
    
    !*************************************************************************************************************************
    !Fecha Garra Manual Através de ProgKeys
    !*************************************************************************************************************************
    PROC AbrirGarraProgKey(Num f)
        
        !Define Setup
        SetGO PN_GO_Modelo_Produto, f;
        
        WaitTime 0.2;
        
        !Garante que escreveu corretamente
        IF GOutput (PN_GO_Modelo_Produto) <> f THEN
            MsgBoxOk("Erro AbrirGarraProgKey: CLP não carregou valor correto para abertura de garra");
            RETURN;
        ENDIF              
            
        !Comando Abertura Servos:
        SetDO \Sync, PN_OUT_Solicita_Fecha_Garra, 0;
        SetDO \Sync, PN_OUT_Solicita_Abertura, 1;    
        
        WaitTime 0.2;
        
        WaitDI PN_IN_Garra_Aberta, 1\MaxTime:= 5\TimeFlag:=timeout_av1;
        WaitDI PN_IN_Garra_Fechada, 0\MaxTime:= 5\TimeFlag:=timeout_av2;
        
        !Se não abriu, avisa erro:
        IF (timeout_av1 OR timeout_av2) = TRUE THEN
            SetDO PN_OUT_Solicita_Abertura, 0;
            MsgBoxOk("Supervisão Posicionamento Garra: Servos NÃO Abriram!");
        ENDIF

        !Reset do Comando
        SetDO PN_OUT_Solicita_Abertura, 0;                
	ENDPROC

    !*************************************************************************************************************************
    !Fecha Garra Manual Através de ProgKeys
    !*************************************************************************************************************************
    FUNC bool ValidaTravas()
        !Revisa se cilindros estão recuados
        WaitDI DI_Fixa_Peça_1_Av, 0 \MaxTime:= 0.1 \TimeFlag:=timeout_rc1;
        WaitDI DI_Fixa_Peça_2_Av, 0 \MaxTime:= 0.1 \TimeFlag:=timeout_rc2;
        WaitDI DI_Fixa_Peça_1_Rc, 1 \MaxTime:= 0.1 \TimeFlag:=timeout_rc3;
        WaitDI DI_Fixa_Peça_2_Rc, 1 \MaxTime:= 0.1 \TimeFlag:=timeout_rc4;
        
        !Se inconsistente, retorna erro:
        IF (timeout_rc1 OR timeout_rc2 OR timeout_rc3 OR timeout_rc4) THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        ENDIF
        
    ENDFUNC
    
ENDMODULE