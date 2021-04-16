#Include 'Protheus.ch'

Static aTables  := {}
Static lUpdStru := .T.

//--------------------------------------------------------------------------
/*/{Protheus.doc} INSTSXDB
Rotina para instalaÁ„o da Consulta Personalizada.

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  03/04/2014
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------

User Function UPDSXDB()

	Private Titulo   := "CriaÁ„o e atualizaÁ„o tabelas a partir dos SXS"
	Private aSays    := {}
	Private aButtons := {}
	Private oText	 := Nil

	MyOpenSM0()
	
	If ! GetParams()
		Return .F.
	EndIf

	aAdd(aSays," ATUALIZA«√O DAS TABELAS")
	aAdd(aSays," Esta rotina tem como funÁ„o cria todas as tabelas no banco a partir dos SXS.")

	aAdd(aButtons,{ 1,.T.,{|o| MsAguarde({|| AcsTable() },Titulo, "Criando as tabelas ...",.T.) }})
	aAdd(aButtons,{ 2,.T.,{|o| FechaBatch() }})

	FormBatch(Titulo,aSays,aButtons)

Return Nil

//--------------------------------------------------------------------------
/*/{Protheus.doc} AcsTable
Rotina para acessar a estrutura de todas as tabelas

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  16/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------

Static Function AcsTable()

Local lOk    	:= .T.
Local nRegs	 	:= 0
Local nRecX3 	:= 1
Local nRecX2 	:= 1
Local cFileX2  	:= cFileX3 := cSQL := cError := cX3_ARQUIVO := ""
Local aStruX2  	:= { 	{ "X2_CHAVE", "C", 3, 0 }, { "X2_ARQUIVO", "C", 10, 0 } }
Local aStruX3  	:= { 	{ "X3_ARQUIVO", "C", 3, 0 }, { "X3_CAMPO", "C", 10, 0 }, { "X3_TIPO", "C", 1, 0 }, { "X3_TAMANHO", "N", 3, 0 },;
						{ "X3_DECIMAL", "N", 2, 0 }, { "X3_VISUAL", "C", 01, 0 } }
Local cView		:= "SX3" + cEmpAnt + "0DUP" 						
Local cArqCSV	:= ""
Local oTable 	:= Nil

cFileX2 := "SX2" + cEmpAnt + "0_DF"
cFileX3 := "SX3" + cEmpAnt + "0"

If ! MsgYesNo("Verifica Estrutura ?")
	Return .T.
EndIf

If (! MSFile(cFileX2, , "TOPCONN") .Or. ! MSFile(cFileX3, , "TOPCONN")) .Or.;
	MsgYesNo("Atualizar o SX3 ?")
	//-- CriaÁ„o SX2
	If MSFile(cFileX2, , "TOPCONN")
	  	If TcSqlExec("DROP TABLE " + cFileX2) <> 0
	 		DisarmTransaction()
		   	
		   	GrLog(TCSQLError())
			Return
	  	EndIf
	EndIf
	
	DbCreate(cFileX2,aStruX2,"TOPCONN")

	//Popula estrutura do SX2
	cAlsX2	:= CriaTrab(Nil,.F.)
	cArqTrb	:= CriaTrab(Nil,.F.)

	//Abre o SX2 VIA CTREE
	dbUseArea(.T., "CTREECDX", "\System\SX2" + cEmpAnt + "0.DTC", cAlsX2, .T., .T.)
	
	//Seleciona o SX2 criado no banco
	dbUseArea(.T.,"TOPCONN", cFileX2, cArqTrb,.T.,.F.)

	//Importa o X2 da base para o temporario
	APPEND FROM &cAlsX2 VIA "DBFCDX"

	(cArqTrb)->(DbCloseArea())
	
	//-- CriaÁ„o SX3
	If MSFile(cFileX3, , "TOPCONN")
	  	If TcSqlExec("DROP TABLE " + cFileX3) <> 0
	 		DisarmTransaction()
		   	
		   	GrLog(TCSQLError())
			Return
	  	EndIf
	EndIf
	
	//Popula estrutura do SX3
	DbCreate(cFileX3,aStruX3,"TOPCONN")

	cAlsX3	:= CriaTrab(Nil,.F.)
	cArqTrb	:= CriaTrab(Nil,.F.)

	dbUseArea(.T., "CTREECDX", "\System\SX3" + cEmpAnt + "0.DTC", cAlsX3, .T., .T.)
	
	dbUseArea(.T.,"TOPCONN", cFileX3, cArqTrb,.T.,.F.)

	//Seleciona alias temporario
	DbSelectArea(cArqTrb)
	
	//Importa o X3 da base para o temporario
	APPEND FROM &cAlsX3 VIA "DBFCDX"

	(cArqTrb)->(DbCloseArea())
	
	// DbUseArea(.T.,"TOPCONN",cFile,"SX3TOP",.T.,.F.)
	// Append From (cFile) For X3_CONTEXT <> "V"
EndIf

cFileX2 := "%" + cFileX2 + "%"
cFileX3 := "%" + cFileX3 + "%"

// Verifica arquivos em duplicidade no dicion·rio
beginsql alias "QRY
	%noparser%
	
	select X2_ARQUIVO from %Exp:cFileX2% GROUP BY X2_ARQUIVO HAVING COUNT(*) > 1
endsql	

nReg := 0
While ! Eof()
	GrLog("AtenÁ„o. Arquivo [" + QRY->X2_ARQUIVO + "] duplicado no SX2 !")
	nReg ++

	DbSkip()
EndDo	

Qry->(DbCloseArea())    

/*If nReg > 0
	EndLog()
	Return
EndIf*/

If TCGetDb() == "ORACLE"

	//Local para salvar arquivo
	cArqCSV	:= cGetFile('', 'Informe o local para gravaÁ„o do arquivo...', 1, 'C:\', .F., nOR( GETF_LOCALHARD, GETF_NETWORKDRIVE, GETF_RETDIRECTORY ),.F., .T.)

	//CabeÁalho do arquivo tempor·rio.
	aCabExcel := {	{"X3_ARQUIVO" 	,"C",03,0},;
                    {"X3_CAMPO"  	,"C",10,0},;
					{"X3_TIPO"   	,"C",01,0},;
					{"X3_TAMANHO"   ,"N",03,0},;
					{"X3_DECIMAL"   ,"N",02,0},;
					{"TIPO_DB"   	,"C",01,0},;
					{"TAMANHO_DB"   ,"N",03,0},;
					{"DECIMAL_DB"   ,"N",02,0} }

	//Alias temporario
	cAlsTemp := CriaTrab(Nil,.F.)

	//Se for oracle o campo no banco È sempre numerico de 22 ent„o precisa fazer o insert deste na tabela top_field e tambÈm de todos campos que s„o data
	
	cAlsRec := CriaTrab(Nil,.F.)
    cAlsQry := CriaTrab(Nil,.F.)
    
    cQuery := " SELECT * FROM SX3000 SX3 "
    cQuery += " WHERE X3_TIPO IN ('N','D') AND NOT EXISTS ( SELECT 1 FROM TOP_FIELD TOP "
    cQuery += " WHERE TOP.FIELD_NAME = X3_CAMPO AND FIELD_TABLE LIKE '%000%' ) "

    If Select(cAlsQry) > 0; (cAlsQry)->(dbCloseArea()); Endif  
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlsQry,.T.,.T.)

    nLinha := 1
    
    While !(cAlsQry)->(Eof())    
        
        PtInternal(1,"Processando linha: " + cValToChar(nLinha))
        
        cArqSX3 := (cAlsQry)->X3_ARQUIVO
        cCpoX3  := (cAlsQry)->X3_CAMPO
        cTpX3   := (cAlsQry)->X3_TIPO
        cTamX3  := cValToChar( (cAlsQry)->X3_TAMANHO )
        cDecX3  := cValToChar( (cAlsQry)->X3_DECIMAL )
        
        //Depois insere novamente a estrutura da tabela
        cQuery := " INSERT INTO TOP_FIELD (FIELD_TABLE, FIELD_NAME, FIELD_TYPE, FIELD_PREC, FIELD_DEC) "
        cQuery += " VALUES ('DEV7TOTVS12." + cArqSX3 + "000'" + ",'" + cCpoX3 + "','P','" +  cTamX3 + "','" + cDecX3 + "')"

        If TcSqlExec(cQuery) < 0
            cTeste := " "
        Else
            TcSqlExec("COMMIT;")
        EndIf

        nLinha++

        (cAlsQry)->(DbSkip())    

	End

	(cAlsQry)->(DbCloseArea())

	//Query para confrontar as divergencias
	cSql := " SELECT sx3.x3_arquivo,  sx3.x3_campo,  sx3.x3_tipo,  sx3.x3_tamanho,  (Case when sx3.x3_decimal > 0 then to_char(sx3.x3_decimal) else '0' end) x3_decimal,  "
	cSql += " Coalesce(CASE  WHEN topfld.field_type = 'P' THEN 'N' END, CASE  WHEN topfld.field_type = 'D' THEN 'D' END, CASE WHEN SX3.X3_TIPO = 'L' THEN 'L' END, "
	cSql += " CASE  WHEN fld.data_type = 'CHAR' THEN 'C' END,  CASE WHEN fld.data_type = 'BLOB' THEN 'M' END, CASE WHEN SX3.X3_TIPO = 'L' THEN 'L' END, CASE WHEN SX3.X3_TIPO = 'M' THEN 'M' END)  AS tipo_db, "
	cSql += " To_Number(Coalesce(topfld.field_prec, TO_CHAR(fld.DATA_LENGTH), '0')) AS tamanho_db,  Coalesce(topfld.field_dec, '0')  AS decimal_db  "
	cSql += " FROM " + StrTran(cFileX2, "%", "") + " sx2 "
	cSql += " join " + StrTran(cFileX3, "%", "") + " sx3 "
	cSql += " ON sx3.x3_arquivo = sx2.x2_chave   "
	cSql += " join user_tables tab  ON trim(tab.table_name) = trim(sx2.x2_arquivo) "
	cSql += " left join USER_TAB_COLUMNS fld   ON fld.table_name = tab.table_name and trim(fld.column_name) = trim(sx3.x3_campo)   "
	cSql += " left join top_field topfld   ON TRIM(Replace(topfld.field_table, 'DEVMXMPROPHIX.','')) = Trim(sx2.x2_arquivo)  AND sx3.x3_campo = topfld.field_name  "
	cSql += " WHERE sx3.x3_visual <> 'V' and sx3.x3_tipo <> "
	cSql += " Trim(Coalesce(CASE  WHEN topfld.field_type = 'P' THEN 'N' END, CASE  WHEN topfld.field_type = 'D' THEN 'D' END, CASE WHEN SX3.X3_TIPO = 'L' THEN 'L' END, "
	cSql += " CASE  WHEN fld.data_type = 'CHAR' THEN 'C' END,  CASE WHEN fld.data_type = 'BLOB' THEN 'M' END, CASE WHEN SX3.X3_TIPO = 'L' THEN 'L' END, CASE WHEN SX3.X3_TIPO = 'M' THEN 'M' END) )  "
	cSql += " OR CASE  WHEN sx3.x3_tipo = 'M' THEN 10  ELSE sx3.x3_tamanho  END <> TO_NUMBER(Coalesce(CASE  WHEN topfld.field_type = 'M' THEN '10'   ELSE topfld.field_prec  END, To_char(fld.DATA_LENGTH), '0'))  OR "
	cSql += " (Case when sx3.x3_decimal > 0 then to_char(sx3.x3_decimal) else '0' end) <> To_Number(Coalesce(topfld.field_dec, '0') ) "

Else
    
    cSQL := "select X3_ARQUIVO as X2_CHAVE "
    cSQL +=   "from ("
    cSQL +=           "select sx3.X3_ARQUIVO, sx3.X3_CAMPO, sx3.X3_TIPO, sx3.X3_TAMANHO, sx3.X3_DECIMAL, "
    cSQL +=                  "coalesce(case when topfld.FIELD_TYPE = 'P' then 'N' else topfld.FIELD_TYPE end, "
    cSQL +=                  "case when typ.name = 'varchar' then 'C' else '' end) as x3_tipo_db, "
    cSQL +=                  "coalesce(topfld.FIELD_PREC, fld.max_length, 0) as x3_tamanho_db, "
    cSQL +=                  "coalesce(topfld.FIELD_DEC, 0) as x3_decimal_db "
    cSQL +=             "from " + StrTran(cFileX2, "%", "") + " sx2 "
    cSQL +=             "join " + StrTran(cFileX3, "%", "") + " sx3 on sx3.X3_ARQUIVO = sx2.X2_CHAVE "
    cSQL +=             "join sys.tables tab on tab.name = sx2.X2_ARQUIVO " 
    cSQL +=        "left join sys.columns fld on fld.object_id = tab.object_id and fld.name = sx3.X3_CAMPO " 
    cSQL +=        "left join sys.systypes typ on typ.xtype = fld.system_type_id "
    cSQL +=        "left join TOP_FIELD topfld on replace(topfld.FIELD_TABLE, 'dbo.', '') = tab.name "
    cSQL +=         "and fld.name = topfld.FIELD_NAME "
    cSQL +=       "where sx3.X3_TIPO <> coalesce(case when topfld.FIELD_TYPE = 'P' then 'N' else topfld.FIELD_TYPE end, "
    cSQL +=             "case when typ.name = 'varchar' then 'C' else '' end) or "
    cSQL +=             "case when sx3.X3_TIPO = 'M' then 10 else sx3.X3_TAMANHO end <> "
    cSQL +=                        "coalesce(case when topfld.FIELD_TYPE = 'M' then 10 else topfld.FIELD_PREC end, " 
    cSQL +=                        "fld.max_length, 0) or "
    cSQL +=                        "sx3.X3_DECIMAL <> coalesce(topfld.FIELD_DEC, 0) "
    cSQL +=  "union all "	   
    cSQL += "select sx2.X2_CHAVE, fld.name, ' ' as X3_TIPO, 0 as X3_TAMANHO, 0 AS X3_DECIMAL, " 
    cSQL +=        "coalesce(case when topfld.FIELD_TYPE = 'P' then 'N' else topfld.FIELD_TYPE end, "
    cSQL +=        "case when typ.name = 'varchar' then 'C' else '' end) as x3_tipo_db, "
    cSQL +=        "coalesce(topfld.FIELD_PREC, fld.max_length, 0) as x3_tamanho_db, "
    cSQL +=        "coalesce(topfld.FIELD_DEC, 0) as x3_decimal_db "
    cSQL +=   "from " + StrTran(cFileX2, "%", "") + " sx2 "
    cSQL +=   "join sys.tables tab on tab.name = sx2.X2_ARQUIVO " 
    cSQL +=   "join sys.columns fld on fld.object_id = tab.object_id and not fld.name in ('R_E_C_N_O_','R_E_C_D_E_L_','D_E_L_E_T_') "  
    cSQL +=   "left join sys.systypes typ on typ.xtype = fld.system_type_id "
    cSQL +=   "left join TOP_FIELD topfld on replace(topfld.FIELD_TABLE, 'dbo.', '') = tab.name "
    cSQL +=    "and fld.name = topfld.FIELD_NAME "
    cSQL +=   "left join " + StrTran(cFileX3, "%", "") + " sx3 on sx3.X3_ARQUIVO = sx2.X2_CHAVE and sx3.X3_CAMPO = fld.name "
    cSQL +=  "where sx3.X3_CAMPO is null) tab "
    cSQL +=  "group by X3_ARQUIVO"

EndIf

//-- Dropar a tabela
TcSqlExec("DROP VIEW " + cView)

If TcSqlExec("CREATE VIEW " + cView + " AS " + cSQL) <> 0
   	GrLog(TCSQLError())

	Return
EndIf

cView := "%" + cView + "%"

cAlsView := CriaTrab(Nil,.F.)

beginsql alias cAlsView
	%noparser%

	select * from %Exp:cView% 
endsql

//APPEND DOS DADOS GERADOS NO DBF CRIADO
dbCreate("TEMP\" + cAlsTemp, aCabExcel, "DBFCDXADS")

__cAlias := CriaTrab(NiL,.F.)

dbUseArea(.T.,"DBFCDXADS","TEMP\" + cAlsTemp , __cAlias,.T.,.F.)

//--------------------------------------------------------------------
// Realizo o append do arquivo da filial para o arquivo consolidado //
//--------------------------------------------------------------------
APPEND FROM &cAlsView VIA "TOPCONN"

( __cAlias )->( dbCloseArea() )

cArqCSV += "Conf_SX3_vs_BD" + StrTran(Time(), ":", "_") + ".xls"

//Faz a copia dos arquivo de relatÛrio
If __copyFile("TEMP\" + cAlsTemp + ".DBF", cArqCSV)
	
	MsgInfo("RelatÛrio gerado com sucesso no caminho: " + cArqCsv)

Else

	MsgInfo("Erro ao copiar arquivo, peÁa para TI verificar se o arquivo existe em pasta, nome: " + cArqPri)

EndIf

FErase("TEMP\" + cAlsTemp + ".DBF") 

(cAlsView)->(DbCloseArea())

If MsgYesNo("RelatÛrio ja foi conferido e deseja atualizar as tabelas no banco?")
	
	 beginsql alias cAlsView
		%noparser%

		select distinct x3_arquivo from %Exp:cView% 
	endsql

	While !(cAlsView)->(Eof())

		X31UPDTABLE( (cAlsView)->X3_ARQUIVO )
		
		(cAlsView)->(DbSkip())

	End

	MsgInfo("AtualizaÁ„o do banco concluida!")

EndIf

Return

Static FUNCTION A370VerFor(cForm)

BEGIN SEQUENCE
	
	xResult := &cForm

END SEQUENCE

Return 


Static Function ChecErro(e)
IF e:gencode > 0
	GrLog(e:Description)
Endif

Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} Load_SX
Rotina para atualizaÁ„o dos dicion·rios de dados

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  05/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------

Static Function Load_SX(cArqDbf, cAlias)

Local bSeek := { || .F. }, nReg := 0

	DbselectArea(cAlias)
	If cAlias == "SX3"
		DbSetOrder(2)	//-- X3_CAMPO
	Else
		DbSetOrder(1)
	EndIf

	If cAlias == "SIX"		//-- Indices
		bSeek := { || ! SIX->(DbSeek(NEW->(INDICE + ORDEM))) }
	ElseIf cAlias == "SX1"	//-- Perguntas
		bSeek := { || ! SX1->(DbSeek(NEW->(X1_GRUPO + X1_ORDEM))) }
	ElseIf cAlias == "SX2"	//-- Tabelas
		bSeek := { || ! SX2->(DbSeek(NEW->X2_CHAVE)) }
	ElseIf cAlias == "SX3"	//-- Campos
		bSeek := { || ! SX3->(DbSeek(NEW->X3_CAMPO)) }
	ElseIf cAlias == "SX5"	//-- Tabelas de Tabelas
		bSeek := { || ! SX5->(DbSeek(NEW->(X5_FILIAL+X5_TABELA+X5_CHAVE) )) }
	ElseIf cAlias == "SX6"	//-- Parametros
		bSeek := { || ! SX6->(DbSeek(NEW->(Left(X6_FIL + Space(Len(SX6->X6_FIL)), Len(SX6->X6_FIL)) + X6_VAR) )) }
	ElseIf cAlias == "SX7"	//-- Gatilhos
		bSeek := { || ! SX7->(DbSeek(NEW->(X7_CAMPO + X7_SEQUENC))) }
	ElseIf cAlias == "SX9"	//-- Relacionamentos
		bSeek := { || ! SX9->(CheckSX9(NEW->X9_DOM, NEW->X9_IDENT)) }
	ElseIf cAlias == "SXA"	//-- Pastas
		bSeek := { || ! SXA->(DbSeek(NEW->(XA_ALIAS + XA_ORDEM))) }
	ElseIf cAlias == "SXB"	//-- Consultas
		bSeek := { || ! SXB->(DbSeek(NEW->(XB_ALIAS + XB_TIPO + XB_SEQ + XB_COLUNA))) }
	ElseIf cAlias == "SXG"	//-- Tamanho dos campos
		bSeek := { || ! SXG->(DbSeek(NEW->(XG_GRUPO))) }
	ElseIf cAlias == "SXV"	//-- Marshup
		bSeek := { || ! SXV->(DbSeek(NEW->(XV_MASHUP+XV_ALIAS))) }
	EndIf

	dbUseArea( .T., "CTREECDX", cArqDbf, "NEW", .T., .F.)
	If Select("NEW") = 0

		GrLog("O arquivo [" + cArqDbf + "] n„o pode ser aberto !")
		
		Return .F.
	EndIf

	While NEW->(!EOF())
		nReg ++
		
		If !isBlind()
			MsProcTxt("Gravando [" + cAlias + "] - Registro: " + AllTrim(Str(nReg)))
			ProcessMessage()		
		EndIf
		ConOut("Gravando [" + cAlias + "] - Registro: " + AllTrim(Str(nReg)))
		
 		SaveReg(cAlias, "NEW", Eval(bSeek), .F.)

   		If cAlias == "SX2"
	   		SX2->X2_ARQUIVO := AllTrim( NEW->X2_CHAVE ) + AllTrim( SM0->M0_CODIGO ) + "0"
	   		If ! Empty(mv_par01)
	   			SX2->X2_ARQUIVO := AllTrim( NEW->X2_CHAVE ) + mv_par01 + "0"
	   		EndIf
	   	EndIf

      	If cAlias == "SX3"
      		If AScan(aTables, SX3->X3_ARQUIVO) == 0
      			If ! SX2->(DbSeek(SX3->X3_ARQUIVO))
      				GrLog("AtenÁ„o. A definiÁ„o da tabela [" + SX3->X3_ARQUIVO + "] n„o est· no pacote !")
      			Else
      				Aadd(aTables, SX3->X3_ARQUIVO)
      			EndIf
      		EndIf

      		If ! Empty(SX3->X3_GRPSXG)
      			UpdSx3Sxg()
      		EndIf
      		
      		If Empty(SX3->X3_PYME)
      			SX3->X3_PYME := "S"
      		EndIf
      		If Empty(SX3->X3_ORTOGRA)
      			SX3->X3_ORTOGRA := "N"
      		EndIf
      		If Empty(SX3->X3_IDXFLD)
      			SX3->X3_IDXFLD := "N"
      		EndIf
      	ElseIf cAlias == "SX1"
      		If ! Empty(SX1->X1_GRPSXG) .And. X1_GSC <> "R"
      			SXG->(DbSeek(SX1->X1_GRPSXG))
      			SX1->X1_TAMANHO := SXG->XG_SIZE
      		EndIf
      	EndIf

	   	(cAlias)->(MsUnLock())

      	If cAlias == "SX3"
      		UpdSx3Aju()
      	EndIf      		

		NEW->(DbSkip())
	EndDo

	NEW->(DbCloseArea())

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} UpdSx3Sxg
Atualiza o campo X3_TAMANHO a partir do XG_SIZE

@author Wagner Mobile Costa
@since  05/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------

Static Function UpdSx3Sxg()

If SXG->(DbSeek(SX3->X3_GRPSXG))
	SX3->X3_TAMANHO := SXG->XG_SIZE
Else
	
	GrLog("O grupo de campos [" + SX3->X3_GRPSXG + "] do campo [" + AllTrim(SX3->X3_CAMPO) + "] n„o existe !")
EndIf

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} UpdSx3Aju
Atualiza o campo X3_TAMANHO dos campos Memos e Reais.

@author Alexandre Florentino
@since  21/09/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function UpdSx3Aju()
If ((SX3->X3_CONTEXT <> "V") .AND. (SX3->X3_TIPO == "M"))
	SX3->(RecLock("SX3", .F.))
    SX3->X3_TAMANHO := 10  			
	SX3->(MsUnLock())	
EndIf

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} LoadData
Rotina para atualizaÁ„o dos dados da tabela

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  05/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------

Static Function LoadData(cTab, cFile)

Local nReg   := 0
Local cUnico := ""

	DbSelectArea(cTab)
  	If mv_par03 == 1
	  	If TcSqlExec("DELETE FROM " + RetSqlName(cTab)) <> 0
		   	GrLog(TCSQLError())

			Return
	  	EndIf
	  	
	  	ImpData(cTab, cFile)
	
		SX2->(DbSeek(cTab))
		If .F. // SX2->X2_MODO = "E"
			SX3->(DbSetOrder(1))
			SX3->(DbSeek(cTab))
	  		If TcSqlExec("UPDATE " + RetSqlName(cTab) + " SET " + SX3->X3_CAMPO + " = '01'") <> 0
		   		GrLog(TCSQLError())
			
				Return
	  		EndIf
	  	EndIf
		
		Return
	Else
		DbSelectArea(cTab)
	
		dbUseArea( .T., "CTREECDX", cFile, "NEW", .F., .F.)
		If Select("NEW") = 0
			GrLog("AtenÁ„o. O arquivo [" + cFile + "] n„o pode ser aberto !")
			(cTab)->(DbCloseArea())
			Return
		EndIf
		SX2->(DbSeek(cTab))
		cUnico := AllTrim(SX2->X2_UNICO)
		
		If Empty(cUnico)
			NEW->(DbCloseArea())
			GrLog("AtenÁ„o. A chave unica da tabela [" + cTab + "] n„o foi definida !")
		
			Return
		EndIf
		
		While NEW->(!EOF())
			nReg ++
			
			If !IsBlind()
				MsProcTxt("Gravando [" + cTab + "] - Registro: " + AllTrim(Str(nReg)))
				ProcessMessage()
			EndIf

			cChave := NEW->(&cUnico)
	
	 		SaveReg(cTab, "NEW", ! (cTab)->(DbSeek(cChave)))
	 		If Select("NEW") = 0
	 			Alert("Alias [NEW] n„o aberto ! Tabela [" + cTab + "] !")
	 			Return	
	 		EndIf
	
			NEW->(DbSkip())
		EndDo

		NEW->(DbCloseArea())
		(cTab)->(DbCloseArea())
	EndIf

	TcRefresh(RetSqlName(cTab))

Return Nil

Static Function SaveReg(cAlias, cAliasCp, lInsert, lMsUnLock)
/*/f/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
<Descricao> : FunÁ„o para inserÁ„o de um registro em um alias a partir de outro
<Data> : 02/08/2013
<Parametros> : Nenhum
<Retorno> : Nenhum
<Processo> : Consultas Personalizadas
<Tipo> (Menu,Trigger,Validacao,Ponto de Entrada,Genericas,Especificas ) : E
<Obs> :
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
*/

Local nField := 0, cField := ""

RecLock(cAlias, lInsert)

For nField := 1 To (cAliasCP)->(FCount())
    cField := (cAliasCP)->(FieldName(nField))
    
    //-- N„o altero o compartilhamento das tabelas existentes
    If ! lInsert .And. AllTrim(FieldName(nField)) $ "X2_MODO,X2_MODOUN,X2_MODOEMP"
    	Loop
    EndIf
    
    If (cAlias)->(FieldPos(cField)) > 0 .And. (cAliasCP)->(FieldPos(cField)) > 0 .And. ValType(&(cAliasCp + "->" + cField)) <> "M"
       &(cAlias + "->" + cField) := &(cAliasCp + "->" + cField)
    EndIf
Next

If lMsUnLock
	(cAlias)->(MsUnlock())
EndIf

Return

Static Function RumTxt(cRetornoXML)
/*/f/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
<Descricao> : FunÁ„o para retirar caracteres especiais de uma string
<Data> : 02/08/2013
<Parametros> : Nenhum
<Retorno> : Nenhum
<Processo> : Consultas Personalizadas
<Tipo> (Menu,Trigger,Validacao,Ponto de Entrada,Genericas,Especificas ) : E
<Obs> :
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
*/

cRetornoXML:=StrTran(cRetornoXML,"·","a")
cRetornoXML:=StrTran(cRetornoXML,"¡","A")
cRetornoXML:=StrTran(cRetornoXML,"‡","a")
cRetornoXML:=StrTran(cRetornoXML,"¿","A")
cRetornoXML:=StrTran(cRetornoXML,"„","a")
cRetornoXML:=StrTran(cRetornoXML,"√","A")
cRetornoXML:=StrTran(cRetornoXML,"‚","a")
cRetornoXML:=StrTran(cRetornoXML,"¬","A")
cRetornoXML:=StrTran(cRetornoXML,"‰","a")
cRetornoXML:=StrTran(cRetornoXML,"ƒ","A")
cRetornoXML:=StrTran(cRetornoXML,"È","e")
cRetornoXML:=StrTran(cRetornoXML,"…","E")
cRetornoXML:=StrTran(cRetornoXML,"Î","e")
cRetornoXML:=StrTran(cRetornoXML,"À","E")
cRetornoXML:=StrTran(cRetornoXML,"Í","e")
cRetornoXML:=StrTran(cRetornoXML," ","E")
cRetornoXML:=StrTran(cRetornoXML,"Ì","i")
cRetornoXML:=StrTran(cRetornoXML,"Õ","I")
cRetornoXML:=StrTran(cRetornoXML,"Ô","i")
cRetornoXML:=StrTran(cRetornoXML,"œ","I")
cRetornoXML:=StrTran(cRetornoXML,"Ó","i")
cRetornoXML:=StrTran(cRetornoXML,"Œ","I")
cRetornoXML:=StrTran(cRetornoXML,"˝","y")
cRetornoXML:=StrTran(cRetornoXML,"›","y")
cRetornoXML:=StrTran(cRetornoXML,"ˇ","y")
cRetornoXML:=StrTran(cRetornoXML,"Û","o")
cRetornoXML:=StrTran(cRetornoXML,"”","O")
cRetornoXML:=StrTran(cRetornoXML,"ı","o")
cRetornoXML:=StrTran(cRetornoXML,"’","O")
cRetornoXML:=StrTran(cRetornoXML,"ˆ","o")
cRetornoXML:=StrTran(cRetornoXML,"÷","O")
cRetornoXML:=StrTran(cRetornoXML,"Ù","o")
cRetornoXML:=StrTran(cRetornoXML,"‘","O")
cRetornoXML:=StrTran(cRetornoXML,"Ú","o")
cRetornoXML:=StrTran(cRetornoXML,"“","O")
cRetornoXML:=StrTran(cRetornoXML,"˙","u")
cRetornoXML:=StrTran(cRetornoXML,"⁄","U")
cRetornoXML:=StrTran(cRetornoXML,"˘","u")
cRetornoXML:=StrTran(cRetornoXML,"Ÿ","U")
cRetornoXML:=StrTran(cRetornoXML,"¸","u")
cRetornoXML:=StrTran(cRetornoXML,"‹","U")
cRetornoXML:=StrTran(cRetornoXML,"Á","c")
cRetornoXML:=StrTran(cRetornoXML,"«","C")
cRetornoXML:=StrTran(cRetornoXML,"∫","o")
cRetornoXML:=StrTran(cRetornoXML,"∞","o")
cRetornoXML:=StrTran(cRetornoXML,"™","a")
cRetornoXML:=StrTran(cRetornoXML,"Ò","n")
cRetornoXML:=StrTran(cRetornoXML,"—","N")
cRetornoXML:=StrTran(cRetornoXML,"≤","2")
cRetornoXML:=StrTran(cRetornoXML,"≥","3")
cRetornoXML:=StrTran(cRetornoXML,"í","'")
cRetornoXML:=StrTran(cRetornoXML,"ß","S")
cRetornoXML:=StrTran(cRetornoXML,"±","+")
cRetornoXML:=StrTran(cRetornoXML,"≠","-")
cRetornoXML:=StrTran(cRetornoXML,"¥","'")
cRetornoXML:=StrTran(cRetornoXML,"o","o")
cRetornoXML:=StrTran(cRetornoXML,"µ","u")
cRetornoXML:=StrTran(cRetornoXML,"º","1/4")
cRetornoXML:=StrTran(cRetornoXML,"Ω","1/2")
cRetornoXML:=StrTran(cRetornoXML,"æ","3/4")
cRetornoXML:=StrTran(cRetornoXML,"&","e") 

Return cRetornoXML

//--------------------------------------------------------------------------
/*/{Protheus.doc} UpdStru
Rotina para atualizaÁ„o da estrutura das tabelas

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  04/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function UpdStru

Local nTables := 0, aStru  := {}, aSX3 := {}, aSQL := {}
Local lUpd := .F., cInsert := cInstru := cTable := "", xValue := Nil

SX3->(DbSetOrder(1))
For nTables := 1 To Len(aTables)
   	cTable := aTables[nTables]
	DbSelectArea(cTable)
   	lUpd := .F.
	If Select(aTables[nTables]) > 0
		DbSelectArea(aTables[nTables])
		DbCloseArea()
	EndIf
	SX2->(DbSeek(aTables[nTables]))
	If MSFile(AllTrim(SX2->X2_ARQUIVO), , "TOPCONN")
	    dbUseArea( .T., "TOPCONN", AllTrim(SX2->X2_ARQUIVO), aTables[nTables], .F., .F.)
      	    aStru := DbStruct()
      	    lUpd := .T.
   	EndIf

   	aSX3 := LoadSX3(aTables[nTables])

   	lUpd := CompStru(aStru, aSx3)

   	If ! lUpd
    	    lUpd := CompStru(aSx3, aStru)
  	EndIf
   	aSQL := {}

	If ! lUpdStru
		If lUpd
			GrLog("Tabela: " + AllTrim(SX2->X2_ARQUIVO) + " com diferenÁa entre SX3/Banco")
		EndIf
	ElseIf lUpd
		If Select(aTables[nTables]) > 0
			(aTables[nTables])->(DbCloseArea())
		EndIf
		/*
		dbUseArea( .T., "TOPCONN", AllTrim(SX2->X2_ARQUIVO), aTables[nTables], .F., .F.)
		If Select(aTables[nTables]) == 0
			GrLog("N„o È possÌvel abrir o arquivo [" + AllTrim(SX2->X2_ARQUIVO) + "] em modo exclusivo para alteraÁ„o da estrutura !")

		   	Loop
		EndIf
		*/

		X31UPDTABLE(cTable)
		If __GetX31Error()
			GrLog("Tabela: " + cTable + " Erro: " + __GetX31Trace())
		Else
			GrLog("Tabela: " + cTable + " atualizada estrutura com sucesso !")
		EndIf
   EndIf
Next

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} LoadSX3
Rotina para leitura do SX3 de uma tabela

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  16/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
User Function LoadSX3(cAlias)
Return LoadSX3(cAlias)

Static Function LoadSX3(cAlias)

Local aSX3 := {}

DbSelectArea("SX3")
DbSeek(cAlias)
While X3_ARQUIVO == cAlias .And. ! Eof()
	If SX3->X3_CONTEXT <> "V"
   		Aadd(aSX3, { AllTrim(SX3->X3_CAMPO), SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL })
    EndIf

	DbSkip()
EndDo

Return aSX3

//--------------------------------------------------------------------------
/*/{Protheus.doc} ImpData
Rotina para importaÁ„o de arquivo .DBF para tabela

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  16/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function ImpData(cSX3, cFile)

Local cRDD := RDDSetDefault()

If ! File(cFile)
	Return .T.
EndIf

RDDSetDefault("CTREECDX")

Append From (cFile)

RDDSetDefault(cRdd)

Return .T.

//--------------------------------------------------------------------------
/*/{Protheus.doc} CompStru
Rotina para comparaÁ„o da estrutura x dicion·rio SX3 para definir atualizaÁ„o

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  04/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function CompStru(aCpos1, aCpos2)

Local nPos 		:= 0
Local nCampos 	:= 0
Local lUpd 		:= .F.
Local cNomArq   := ""
//-- Leitura dos campos
For nCampos := 1 To Len(aCpos1)
   //-- Campo da Estrutura n„o localizado no SX3
      
   If (nPos := Ascan(aCpos2, { |x| x[1] == AllTrim(aCpos1[nCampos][1]) })) == 0
      lUpd := .T.
   EndIf

   //-- Campo Localizado
   If nPos > 0
      //-- Tipo Diferente
      If aCpos1[nCampos][2] <> aCpos2[nPos][2]
         lUpd := .T.
      EndIf

      //-- Tamanho Diferente
      If aCpos1[nCampos][3] <> aCpos2[nPos][3]
         lUpd := .T.
      EndIf

      //-- Decimais Diferentes
      If aCpos1[nCampos][4] <> aCpos2[nPos][4]
         lUpd := .T.
      EndIf
   EndIf
Next

If Len(aCpos1) == 0 .Or. Len(aCpos2) == 0
	lUpd := .F.
EndIf

Return lUpd

//--------------------------------------------------------------------------
/*/{Protheus.doc} CheckSX9
Verifica a existencia do registro na tabela SX9

@author unknown programmer (unknown.programmer@unknown.programmer)
@since  04/02/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function CheckSX9(cX9_DOM, cX9_IDENT)

Local lFound := .F., nRecSX9 := 0

DbSelectArea("SX9")
Set Filter to X9_DOM == cX9_DOM .And. X9_IDENT == cX9_IDENT
DbGoTop()

If ! Eof()
	lFound := .T.
EndIf

nRecSX9 := Recno()
Set Filter To

DbSelectArea("SX9")
DbGoto(nRecSX9)

Return lFound

//--------------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Abertura do arquivo SIGAMAT.EMP quando necess·rio

@author Wagner Mobile Costa
@since  29/06/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function MyOpenSM0()

Local aParam := {}

If Select("SM0") > 0
	Return
EndIf

	Set Dele On
	dbUseArea( .T., , 'SIGAMAT.EMP', 'SM0', .T., .F. )
	dbSetIndex( 'SIGAMAT.IND' )
	DbGoTop()

	RpcSetType( 3 )
	RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )
	
	If LastRec() > 1
		Aadd(aParam, {1, "Empresa", Space(2), "@!"	, "", "SM0", "", 002, .F.})
		
		IF ! ParamBox(aParam, "Parametros da rotina",, {|| AllwaysTrue()},,,,,,, .F.)
			Return .F.
		Endif
		SM0->(DbSeek(mv_par01))
		cOEmp := SM0->M0_CODIGO
		cOFil := SM0->M0_CODFIL
		RpcClearEnv()
		RpcSetEnv( cOEmp, cOFil )
	EndIf
	

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} InitLog
InicializaÁ„o do log de procedimentos de manutenÁ„o de base de dados

@author Wagner Mobile Costa
@since  13/09/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function InitLog()

	AutoGrLog("COMPATIBILIZADOR DA BASE DE DADOS")
	AutoGrLog("---------------------------------")
	AutoGrLog("DATA INICIO - "+Dtoc(MsDate()))
	AutoGrLog("HORA - "+Time())
	AutoGrLog("ENVIRONMENT - "+GetEnvServer())
	AutoGrLog("PATCH - "+GetSrvProfString("Startpath",""))
	AutoGrLog("ROOT - "+GetSrvProfString("SourcePath",""))
	AutoGrLog("VERS√O - "+GetVersao())
	AutoGrLog("M”DULO - "+"SIGA"+cModulo)
	AutoGrLog("EMPRESA / FILIAL - "+SM0->M0_CODIGO+"/"+SM0->M0_CODFIL)
	AutoGrLog("NOME EMPRESA - "+Capital(Trim(SM0->M0_NOME)))
	AutoGrLog("NOME FILIAL - "+Capital(Trim(SM0->M0_FILIAL)))
	AutoGrLog("USU¡RIO - "+SubStr(cUsuario,7,15))
	AutoGrLog("")

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} InitLog
ApresentaÁ„o do log de inconsistencias na manutenÁ„o de base de dados

@author Wagner Mobile Costa
@since  13/09/2015
@param  Nil
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function EndLog()

AutoGrLog("DATA FINAL - "+Dtoc(MsDate()))
AutoGrLog("HORA - "+Time())

If !IsBlind()
   MostraErro("", "INSTSXDB")
EndIf

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} InitLog
GeraÁ„o do texto de log com hora de execuÁ„o

@author Wagner Mobile Costa
@since  13/09/2015
@param  cLog = Texto para chamada da funÁ„o AutoGrLog
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function GrLog(cLog)

AutoGrLog(Time() + "-" + cLog)
ConOut(Time() + "-" + cLog)

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} GetParams
Solicita os parametros para execuÁ„o da rotina

@author Wagner Mobile Costa
@since  29/09/2015
@return Nil

/*/
//-------------------------------------------------------------------------
Static Function GetParams

Local _aParam 	:= {}
Local cEmpresa	:= Space(2)
Local cX2_CHAVE 	:= Space(3)
Local nDelDAT		:= 1

	Aadd(_aParam, {1, "Empresa [X2_ARQUIVO] ?", cEmpresa, "@!"	, ""	, ""	, "", 002, .F.})
	aAdd(_aParam ,{1, "Tabela Inicial",cX2_CHAVE,"@",'.T.','','',3,.F.})
	aAdd(_aParam ,{3, "Deleta conte˙do .DAT",nDelDat,{ "Sim", "N„o" },70,,.F.})
	
	IF ! ParamBox(_aParam, "Parametros da rotina",, {|| AllwaysTrue()},,,,,,, .F.)
		Return .F.
	Endif

    SX2->(DbGoTop())
    If ! Empty(mv_par02)
    	SX2->(DbSeek(mv_par02))
    EndIf

Return .T.
