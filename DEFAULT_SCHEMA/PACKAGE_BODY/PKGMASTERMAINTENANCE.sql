CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY "PKGMASTERMAINTENANCE" is
 
--FourPillar Test

Function fncBuildQuery
    (   ParamData   in  Gconst.gClobType%Type)
    return varchar2

    is
    numError            number;
    numAction           number(3);
    numTemp             number(4);
    numCnt              number(4);
    numRecords          number(4);
    varStatusField      varchar2(30);
    varEntity           varchar2(30);
    varValue            varchar2(100);
    varKey              varchar2(2048);
    varQuery            varchar2(4000);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    varFormatString     varchar(100);
    varUserID           varchar(50);
Begin
    numError := 4;
    numTemp := 0;
    numCnt := 0;
    numRecords := 0;
    varQuery := 'select ';
    varKey := ' where ';

    varOperation := 'Extracting parameters for building query';
 --   insert into rtemp(TT,TT2) values ('Inside fncBuildQuery 0','welcome - Extracting parameters for building query');commit;
    varEntity := GConst.fncXMLExtract(xmlType(ParamData), 'Entity', varEntity);
    numAction := GConst.fncXMLExtract(xmlType(ParamData), 'Action', numAction);
    varMessage := 'Building dynamic query for: ' || varEntity;
    varUserID:=Gconst.fncxmlextract(xmlType(ParamData),'UserCode',VarUserID);
    varOperation := 'Extracting Entity fields for : ' || varEntity;
  --insert into rtemp(TT,TT2,TT3) values ('Inside fncBuildQuery 1','numAction: '||numAction||' varEntity: '||varEntity,' ParamData: '||ParamData);commit;

    For curFields in
    (select fldp_column_name, fldp_xml_field,
        fldp_key_no, fldp_data_type,fldp_text_format_code
        from trsystem999
        where fldp_table_synonym = varEntity
        AND FLDP_PROCESS_YN=12400001
        order by fldp_column_id)

    Loop
    numCnt := numCnt +1;
     Glog.log_write('inside loop ' || curFields.fldp_xml_field || ' fldp_key_no:'||curFields.fldp_key_no);
-- insert into rtemp(TT,TT2) values ('Inside fncBuildQuery looping 3','numCnt: '||numCnt );commit;
      if varEntity = 'TRADEDEALREGISTER' and curFields.fldp_xml_field = 'SerialNumber' then
        curFields.fldp_key_no := 0;
      elsif  varEntity = 'DEALCONFIRMATION' and curFields.fldp_xml_field = 'SerialNumber' then
        curFields.fldp_key_no := 0;
      end if;

      if curFields.fldp_xml_field = 'RecordStatus' then
        varStatusField := curFields.fldp_column_name;
      end if;

      if numRecords > 0 then
        varQuery := varQuery || ',';
      end if;

      if ((curFields.fldp_key_no != 0) and (numAction != GConst.ADDSAVE))  then
        -- Changed by Mnajunath Reddy on 25-08-2021 
        begin 
            varValue := GConst.fncReturnParam(ParamData, curFields.fldp_xml_field);
        exception 
          when others then 
            varValue :=null;
        end;
        Glog.log_write('varValue ' ||varValue);
        if (varValue is not null) then
        Glog.log_write('numTemp ' ||numTemp);
         Glog.log_write('varKey ' ||varKey);
            if numTemp > 0 then
              varKey := varKey || ' and ';
            end if;
     Glog.log_write('varKey ' ||varKey);
            varValue := GConst.fncReturnParam(ParamData, curFields.fldp_xml_field);
            varkey := varKey || ' ' || curFields.fldp_column_name || ' = ';

            if curFields.fldp_data_type = 'DATE' then
    --              SELECT   FORMAT_FORMAT_STRING
    --                 into varFormatString
    --              FROM TRGLOBALMAS914 inner join USERMASTER
    --               on FORMAT_PICK_CODE=nvl(USER_FORMAT_CODE,91499999)
    --               where UPPER(User_user_id)=UPPER(varUserId)
    --               and FORMAT_DATA_TYPE=curFields.fldp_text_format_code
    --               and User_record_status not in (10200005,10200006)
    --               and FORMAT_record_status not in (10200005,10200006);

    --            varKey := varKey || ' to_date(' || '''' || substr(varValue,1,10) || '''' || ',';
    --            varKey := varKey || '''' || 'dd/mm/yyyy' || '''' || ')';
                varKey := varKey || ' to_date(' || '''' || varValue || '''' || ',';
                varKey := varKey || '''' || 'YYYYMMDD' || '''' || ')';
                Glog.log_write(varKey);
            elsif curFields.fldp_data_type <> 'NUMBER' then
                varkey := varKey || '''' || varValue || '''';
            else
              varkey := varKey || varValue;
            end if;
            numTemp := numTemp + 1;
        end if;
      end if;

      if curFields.fldp_data_type = 'DATE' then
        varQuery := varQuery || ' to_char(' || curFields.fldp_column_name || ',';
        varQuery := varQuery || '''' || 'dd/mm/yyyy' || '''' || ') as ';
      else
        varQuery := varQuery || curFields.fldp_Column_name || ' as ';
      end if;

      --varQuery := varQuery || '"' || curFields.fldp_column_name || '"';--commented by hari after taking TMM DB
      varQuery := varQuery || '"' || curFields.fldp_xml_field || '"';
      -- varQuery := varQuery || '"' || curFields.fldp_xml_field || '"';
      numRecords := numRecords + 1;
    End Loop;


    varQuery := varQuery || ' from ' || varEntity || varKey;

    varQuery := varQuery || ' and ' || varStatusField || ' not in (';
    varQuery := varQuery || GConst.STATUSINACTIVE || ',' || GConst.STATUSDELETED || ')';
    --    if numAction = GConst.VIEWLOAD then
    --      varQuery := varQuery || ' and ' || varStatusField || ' != ';
    --      varQuery := varQuery || GConst.STATUSAUTHORIZED;
    --    elsif numAction in (GConst.EDITLOAD, GConst.DELETELOAD) then
    --      varQuery := varQuery || ' and ' || varStatusField || ' not in (';
    --      varQuery := varQuery || GConst.STATUSINACTIVE || ',' || GConst.STATUSDELETED || ')';
    --    elsif numAction =  GConst.CONFIRMLOAD then
    --      varQuery := varQuery || ' and ' || varStatusField || ' in ( ';
    --      varQuery := varQuery || GConst.STATUSENTRY || ',' || GConst.STATUSUPDATED || ')';
    --    end if;

    --  For Edit Codes: Everything except inactive
    --  for Delete: same as above
    --  For Confirm: only records with updated status

--insert into temp values ('Inside fncBuildQuery 4',varQuery );commit;
    GLOG.Log_write('Extracting Data for other Loads : ' || varQuery);
       return varQuery;

    Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('BuildQuery', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return varQuery;
End;

Function fncAuditTrail
    ( TableData in clob,
      ImageType in number)
      Return Number
      is
--  Created on 23/04/08

    numError            number;
    numRecords          number;
    numAction           number;
    numSerial           number(12);
    numSc               number(15,6);
    numSp               number(15,6);
    numbc               number(15,6);
    numbp               number(15,6);
    datWorkDate         date;
    varImage            varchar2(10);
    varPattern          varchar2(50);
    varDateStamp        varchar2(25);
    varSource           varchar2(30);
    varTarget           varchar2(50);
    varReference        varchar2(25);
    varTemp             varchar2(1000);
    varQuery            varchar2(4000);
    varUserID              varchar(30);
    varSchema           varchar(25);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    xmlTemp             GConst.gXMLType%Type;
    xmlTemp1            GConst.gXMLType%Type;
    queryCTX            dbms_xmlQuery.ctxHandle;
    clbParam            clob;
    clbError            clob;
    clbProcess          clob;
    varGUID            varchar(50);
    varTERMINALID      varchar(50);
Begin
    numError := 0;
    varOperation := 'Extracting table details';
    xmlTemp := xmlType(TableData);
   --- insert into temp values (xmlTemp,'Audit Trail'); commit;
    varSource := GConst.fncXMLExtract(xmlTemp, 'Entity', varSource);
    numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);
     varUserID := Upper(GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID));
    --- Commented on 24-11-2018 because of date format issues we need to enable the same 
    --datworkdate := gconst.fncxmlextract(xmlTemp,'WorkDate',datworkdate);
    datworkdate := sysdate;
    GLOG.LOG_WRITE('Entered into audit trails '|| numAction  ||' Synonym ' || varSource);
--    if numAction in (GConst.ADDSAVE, GcONST.CONFIRMSAVE) then
--      return numError;
--    end if;
     if numAction in (GConst.DELETESAVE, GcONST.CONFIRMSAVE,GCONST.UNCONFIRMSAVE,GCONST.REJECTSAVE) then
      return numError;
    end if;

    varMessage := 'Creating Audit trail for ' || varSource;
    GLOG.LOG_WRITE(varMessage);
    Begin
      varOperation := 'Checking the audit trail table';
      select audt_audit_id
        into varTarget
        from trsystem015
        where audt_table_id = varSource
        and AUDT_TRIGGER_YN =12400002 --- only those Which are having Trigger No 
        and audt_record_Status not in (10200005,10200006);
      Exception
        when no_data_found then
          numError := -1;
    End;

     varOperation := 'Extracting Schema Name';
    select Licm_DB_schema 
      into varSchema
    from Clouddb_master.trlicense001 where licm_reference_number 
      in (select user_license_reference from usermaster 
          where Upper(user_user_id)=varUserID
          and user_record_status not in (10200005,10200006))
      and licm_record_status not in (10200005,10200006);

    varOperation := 'Setting the Target Schema';
    varTarget := varSchema || '.' ||varTarget;

    if  numError = -1 then
      return 0;
    end if;

    varQuery := fncBuildQuery(TableData);
    varQuery := 'select * ' || substr(varQuery, instr(varQuery, ' from '));

    select fldp_column_name
      into varPattern
      from trsystem999
      where fldp_table_synonym = varSource
      and fldp_xml_field = 'RecordStatus';

      varOperation := 'Post Extracting Pattern Schema';
    varPattern := 'and ' || varPattern || ' not in (10200005,10200006)';
    varQuery := replace(varQuery, varPattern, '');
    varOperation := 'Extracting data in XML';
    GLOG.LOG_WRITE(varQuery);
    dbms_lob.createTemporary (clbParam,  TRUE);
    queryCTX := dbms_xmlQuery.newContext(varQuery);
    dbms_xmlQuery.setDateFormat(queryCTX, 'dd/MM/yyyy');
    clbParam := dbms_xmlQuery.getxml(queryCTX);
    xmlTemp1 := xmlType(clbParam);
    numRecords := dbms_xmlQuery.getNumRowsProcessed(queryCTX);
    dbms_xmlQuery.closeContext(queryCTX);
    dbms_lob.createTemporary (clbError,  TRUE);
    dbms_lob.createTemporary (clbProcess,  TRUE);
--    numSerial := fncGenerateSerial(GConst. SERIALAUDIT);

    numError := GConst.fncSetParam(xmlTemp1, 'Entity', varTarget, 2);
    clbParam := xmlTemp1.getClobval();
    GConst.prcGenericInsert(clbParam, clbError, clbProcess);

    varTemp := substr(varQuery, instr(varQuery, 'where'));
    varQuery := 'update ' || varTarget || ' set ';
--------------------------------------------------------------------------------------------
--  Added to accomodate the second table - trtrn072 in the audit trail for options 13/02/13- TMM
--  the value cannot be taken from the view as figures will not be reflected till session is over
--    if varSource in ('OPTIONHEDGEDEAL','OPTIONTRADEDEAL') then
--        varOperation := 'Getting Strike Rates for Option Deal';
--
--        varReference := GConst.fncXMLExtract(xmlTemp, 'DealNumber', varReference);
--
--        select NVL(bc.cosu_strike_rate,0) BC, NVL(bp.cosu_strike_rate, 0) BP,
--        NVL(sc.cosu_strike_rate,0) SC, NVL(sp.cosu_strike_rate, 0) SP
--        into numBc, numBp, numSc, numSP
--        from trtran071
--        left outer join trtran072 bc
--          on copt_deal_number = bc.cosu_deal_number
--          and bc.cosu_buy_sell = 25300001
--          and bc.cosu_option_type = 32400001
--        left outer join trtran072 bp
--          on copt_deal_number = bp.cosu_deal_number
--          and bp.cosu_buy_sell = 25300001
--          and bp.cosu_option_type  = 32400002
--        left outer join trtran072 sc
--          on copt_deal_number = sc.cosu_deal_number
--          and sc.cosu_buy_sell = 25300002
--          and sc.cosu_option_type = 32400001
--        left outer join trtran072 sp
--          on copt_deal_number = sp.cosu_deal_number
--          and sp.cosu_buy_sell = 25300002
--          and sp.cosu_option_type  = 32400002
--        where copt_deal_number = varReference;
--
--      varQuery := varQuery || ' SC = :4, SP = :5, BC = :6, BP = :7,';
--
--
--    End if;

      varGUID        :=clouddb_global.LogWrite.REQUESTGUID;
      varTERMINALID  :=clouddb_global.LogWrite.Terminal;
------------------------------------------------------------------------------------------
    varQuery := varQuery || ' workdate = :1, DateStamp = :2, ImageType = :3, Entity = :4, UserID=:5, GUID =:6, TERMINALID =:7';

    if ((varTemp is not null) and (trim(varTemp)!='')) then -- incase of add load 
        varQuery := varQuery || varTemp;
        varQuery := varQuery || ' and ';
    else 
        varQuery := varQuery || ' where ';
    end if;

    varQuery := varQuery || ' ImageType is null';

    select to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
      decode(ImageType, GConst.BEFOREIMAGE, 'Before',
        GConst.AFTERIMAGE, 'After', 'Unknown')
      into varDateStamp, varImage
      from dual;
   --insert into temp values (varQuery,varQuery); commit;

    varOperation := 'Updating Audti Trails for ' || varSource;
--    if varSource in ('OPTIONHEDGEDEAL','OPTIONTRADEDEAL') then
--      Execute Immediate varQuery using numSc, numSp, numBc, numBp,datWorkDate, varDateStamp, varImage, varSource,varUserID;
--    else
     GLOG.LOG_WRITE(varQuery);
      Execute Immediate varQuery using datWorkDate,varDateStamp, varImage, varSource,varUserID,varGUID,varTERMINALID;
    --end if;

    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('AuditTrail', numError, varMessage,
                      varOperation, varError);
      GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncAuditTrail');                   
      raise_application_error(-20101, varError);
      return numError;
End fncAuditTrail;

Procedure prcProcessPickup
              ( PickDetails in Clob,
                PickField in varchar2,
                PickValue out nocopy varchar2)
is
    --  created on 04/04/2007
    --  Last Modified on 07/04/2007
      numError            number;
      numRecords          number;
      numAction           number(3);
      numKeyGroup         number(3);
      numKeyNumber        number(5);
      numPickValue        number(8);
      numKeyType          number(8);
      numRecordStatus     number(8);
      varUserID           varchar2(30);
      varPickField        varchar2(30);
      varLongField        varchar2(30);
      varShortField       varchar2(30);
      varEntity           varchar2(30);
      varTerminalID       varchar2(30);
      varShortDescription varchar2(15);
      varLongDescription  varchar2(200);
      varOperation        GConst.gvarOperation%Type;
      varMessage          GConst.gvarMessage%Type;
      varError            GConst.gvarError%Type;
      xmlTemp             xmlType;
      Error_Occurred      Exception;

      numCompanyCode      number;
      numLocationCode     number(8);
      varTemp             varchar(50);
    Begin
      numError := 0;
      xmlTemp := xmlType(PickDetails);

      numError := 1;
      varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
      varOperation := 'Extracting Field Information for: ' || varEntity;
      select a.fldp_pick_group, a.fldp_column_name,
      b.fldp_column_name, c.fldp_column_name
      into numKeyGroup, varPickField, varShortField, varLongField
      from trsystem999 a, trsystem999 b, trsystem999 c
      where a.fldp_table_synonym = b.fldp_table_synonym
      and b.fldp_table_synonym = c.fldp_table_synonym
      and a.fldp_table_synonym = varEntity
      and a.fldp_column_name = PickField
      and b.fldp_xml_field = 'ShortDescription'
      and c.fldp_xml_field = 'LongDescription';

      numError := 2;
      varOperation := 'Extracting Parameters ' ;
      varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
      varTerminalID := Gconst.fncXMLExtract(xmlTemp, 'TerminalID', varTerminalID);
      numAction := NVL(GConst.fncXMLExtract(xmlTemp, 'Action', numAction),0);

      varShortDescription := GConst.fncXMLExtract(xmlTemp, varShortField, varShortDescription);
      varLongDescription := GConst.fncXMLExtract(xmlTemp, varLongField, varLongDescription);
      begin
        numPickValue := NVL(GConst.fncXMLExtract(xmlTemp, varPickField, numPickValue),0);
      exception
      when others then
        numPickValue := 0;
      end ;

      begin
       select fldp_column_name
         into vartemp
        from trsystem999
        where fldp_table_synonym=varEntity
         and fldp_xml_field='CompanyCode';

       numCompanyCode := Gconst.fncXMLExtract(xmlTemp, vartemp, numCompanyCode);
       --if num
       exception
       when others then
         numCompanyCode:=30199999;
      end;

   varOperation:='Extracting Location Code ';

     begin
       select fldp_column_name
         into vartemp
        from trsystem999
        where fldp_table_synonym=varEntity
         and fldp_xml_field='LocationCode';

       numLocationCode := Gconst.fncXMLExtract(xmlTemp, vartemp, numLocationCode);
       --if num
     exception
       when others then
         numLocationCode:=30299999;
     end;



      varMessage := 'Pick Key Value operation: ' ||  numAction || ' for Group: ' || numKeyGroup ;

      select decode(numAction,
          GConst.ADDSAVE, GConst.STATUSENTRY,
          GConst.EDITSAVE, GConst.STATUSUPDATED,
          GConst.CONFIRMSAVE, GConst.STATUSAUTHORIZED,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          Gconst.INACTIVESAVE, Gconst.STATUSINACTIVE,
          GConst.REJECTSAVE,Gconst.STATUSREJECTED,
          GConst.UNCONFIRMSAVE,GConst.STATUSUPDATED)
      into numRecordStatus
      from dual;


      if numAction = GConst.ADDSAVE then
        numError := 2;
        varOperation := 'Generating the next sequence';

        select NVL(max(pick_key_number),0) + 1
        into numKeyNumber
        from PickupMaster
        where pick_key_group = numKeyGroup
        and pick_key_number < 99999;

        numError := 3;
        varOperation := 'Generating and adding pickup value';
        numPickValue := (numKeyGroup *  100000) + numKeyNumber;

        numError := 4;
        varOperation := 'Getting Key Type';

        select pick_key_type
        into numKeyType
        from PickupMaster
        where pick_key_group = numKeyGroup
        and pick_key_number = 0;

      numError := 5;
      varOperation := 'Inserting new value for Pickup' || numRecordStatus;

      insert into PickupMaster (pick_company_code,pick_location_code,pick_key_group, pick_key_number,
        pick_key_value, pick_short_description, pick_long_description,pick_key_type,
        pick_remarks, pick_entry_detail, pick_record_status)
        values(numCompanyCode, numLocationCode,numKeyGroup, numKeyNumber,
        numPickValue, varShortDescription, varLongDescription, numKeyType,
        'Cascaded from master entry', null, numRecordStatus);

      end if;

      if numAction = GConst.EDITSAVE then
          numError := 5;
          varOperation := 'Performing update for edit';

          update PickupMaster
          set pick_short_Description = varShortDescription,
          pick_long_description = varLongDescription,
          pick_record_status = numRecordStatus
          where pick_key_value = numPickValue;

--          numRecords := SQL%ROWCOUNT;
--
--          if numRecords <> 1 then
--            varError := 'Unable to  edit Pickup Record';
--            raise Error_Occurred;
        --  end if;

      end if;

      if numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE,  Gconst.INACTIVESAVE, 
                       GConst.REJECTSAVE,GConst.UNCONFIRMSAVE) then
          numError := 6;
          varOperation := 'Performing update for delete/confirm';

          update PickupMaster
          set pick_record_status = numRecordStatus
          where pick_key_value = numPickValue;

        numRecords := SQL%ROWCOUNT;

        if numRecords <> 1 then
          varError := 'Unable to Delete / confirm Pickup Record';
          raise Error_Occurred;
        end if;

      end if;

      PickValue := numPickValue;
      numError := 0;
      varError := 'Successful Operation';
      Exception
          When Error_Occurred then
            numError := -1;
            varError := GConst.fncReturnError('PickValue', numError, varMessage,
                            varOperation, varError);
            GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.prcProcessPickup');                       
            raise_application_error(-20101, varError);

          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('PickValue', numError, varMessage,
                            varOperation, varError);
            GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.prcProcessPickup');                        
            raise_application_error(-20101, varError);
End;
Function fncIsFieldKey
    (   EntityName in varchar2,
        FieldName in varchar2)
    return number
    is
--  Created by 13/05/2007
    numError            number;
    numTemp             number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

    Begin
        varMessage := 'Checking Key for ' || FieldName || ' Of ' || EntityName;
        numTemp := 0;

        varOperation := 'Extracting key details';

        select fldp_key_no
        into numTemp
        from trsystem999
        where fldp_table_synonym = EntityName
        and fldp_column_name = FieldName;

        return numTemp;

        Exception
            When others then
              numError := SQLCODE;
              varError := SQLERRM;
              varError := GConst.fncReturnError('IsKey', numError, varMessage,
                              varOperation, varError);
              GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncIsFieldKey');                        

              raise_application_error(-20101, varError);
       return numTemp;
End fncIsFieldKey;


--Function fncCurrentAccount
--    (   RecordDetail in GConst.gClobType%Type,
--        ErrorNumber in out nocopy number)
--    return clob
--    is
----  Created on 23/09/2007
--    numError            number;
--    numTemp             number;
--    numStatus           number;
--    numSub              number(3);
--    numAction           number(4);
--    numSerial           number(5);
--    numCompany          number(8);
--    numLocation         number(8);
--    numBank             number(8);
--    numCrdr             number(8);
--    numType             number(8);
--    numHead             number(8);
--    numCurrency         number(8);
--    numVoucher          number(12);
--    numFCY              number(15,4);
--    numRate             number(15,4);
--    numINR              number(15,2);
--    varReference        varchar2(30);
--    varUserID           varchar2(30);
--    varEntity           varchar2(30);
--    varDetail           varchar2(100);
--    varTemp             varchar2(512);
--    varTemp1            varchar2(512);
--    varXPath            varchar2(512);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         date;
--    clbTemp             clob;
--    xmlTemp             xmlType;
--    nodTemp             xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodeMap;
--    nlsTemp             xmlDom.DomNodeList;
--    xlParse             xmlparser.parser;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--Begin
--    varMessage := 'Miscellaneous Updates';
--    dbms_lob.createTemporary (clbTemp,  TRUE);
--    clbTemp := RecordDetail;
--
--    numError := 1;
--    varOperation := 'Extracting Input Parameters';
--    xmlTemp := xmlType(RecordDetail);
--
--    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserID', varUserID);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationCode', numLocation);
--
--    numError := 2;
--    varOperation := 'Creating Document for Master';
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--
--    varXPath := '//CURRENTACCOUNTMASTER/ROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    numSub := xmlDom.getLength(nlsTemp);
--
--    for numSub in 0..xmlDom.getLength(nlsTemp) -1
--    Loop
--      nodTemp := xmlDom.Item(nlsTemp, numSub);
--      nmpTemp:= xmlDom.getAttributes(nodTemp);
--      nodTemp := xmlDom.Item(nmpTemp, 0);
--      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--      varTemp := varXPath || '[@NUM="' || numTemp || '"]/';
--      varTemp1 := varTemp || 'LocalBank';
--      numBank := GConst.fncXMLExtract(xmlTemp,varTemp1,numBank,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'CrdrCode';
--      numCrdr := GConst.fncXMLExtract(xmlTemp,varTemp1,numCrdr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'AccountHead';
--      numHead := GConst.fncXMLExtract(xmlTemp,varTemp1,numHead,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherType';
--      numType := GConst.fncXMLExtract(xmlTemp,varTemp1,numType,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'CurrencyCode';
--      numCurrency := GConst.fncXMLExtract(xmlTemp,varTemp1,numCurrency,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherReference';
--      varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'ReferenceSerial';
--      numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherFcy';
--      numFcy := GConst.fncXMLExtract(xmlTemp,varTemp1,numFcy,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherRate';
--      numRate := GConst.fncXMLExtract(xmlTemp,varTemp1,numRate,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherInr';
--      numInr := GConst.fncXMLExtract(xmlTemp,varTemp1,numInr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherDetail';
--      varDetail := GConst.fncXMLExtract(xmlTemp,varTemp1,varDetail,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'RecordStatus';
--      numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
--
--      varOperation := 'Processing Current Account Transaction';
--
--      if numStatus = GConst.LOTNOCHANGE then
--        NULL;
--      elsif numStatus = GConst.LOTNEW then
--        numVoucher := fncGenerateSerial(Gconst.SERIALCURRENTAC);
--        insert into tftran053 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--	bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--	bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--	bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_record_status)
--        values(numCompany, numLocation, numBank, numVoucher, datWorkDate,
--        numCrdr, numHead, numType, varReference, numSerial, numCurrency,
--        numFcy, numRate, numInr, varDetail, sysdate, GConst.STATUSENTRY);
--      elsif numStatus = GConst.LOTMODIFIED then
--        update tftran053
--          set bcac_voucher_fcy = numFcy,
--          bcac_voucher_rate = numRate,
--          bcac_voucher_inr = numInr,
--          bcac_record_status = GConst.STATUSUPDATED
--          where bcac_voucher_reference = varReference
--          and bcac_reference_serial = numSerial
--          and bcac_account_head = numHead;
--      else
--        select decode(numStatus,
--          GConst.LOTDELETED, GConst.STATUSDELETED,
--          GConst.LOTCONFIRMED, GConst.STATUSAUTHORIZED)
--          into numStatus
--          from dual;
--
--        update tftran053
--          set bcac_record_status = numStatus
--          where bcac_voucher_reference = varReference
--          and bcac_reference_serial = numSerial
--          and bcac_account_head = numHead;
--
--      end if;
--
--    End Loop;
--
--    return clbTemp;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('CurAccount', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return clbTemp;
--End fncCurrentAccount;
--
--
--Procedure prcInsertImage
--    (UpdateType in number,
--     ClobImage  in blob  )
--is
-- numTemp number(4);
--begin
--   select max(icon_icon_id)
--     into numTemp
--     from trsystem025;
--
--   insert into trsystem025
--     values( numTemp+1 ,clobimage);
--
--end prcInsertImage;
Function fncMasterMaintenance
    (   MasterDetail in GConst.gClobType%Type,
        ErrorNumber in out nocopy number)
    return clob
    is
-- Created on 13/05/2007
    numError            number;
    numTemp             number;
    numSub              number;
    numSub1             number;
    numReturn           number;
    numKey              number(2);
    numCode             number(8);
    numCode1            number(8);
    numProcess          number(8);
    numSerialProcess    number(8);
    numAction           number(4);
    numStatus           number(2);
    numRate             number(15,6);
    varProcessYN        varchar2(8);
    varFlag             varchar2(1);
    varDeal             varchar2(30);
    varStatus           varchar2(30);
    varUserID           varchar2(30);
    varEntity           varchar2(30);
    varNode             varchar2(30);
    VarReference        varchar(50);

    --VarTemp             varchar(50);
    VarTemp1            varchar(50);

    varXPath            varchar2(2048);
    varTemp             varchar2(2048);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datTemp             date;
    datToday            date;
    clbTemp             clob;
    insCtx              dbms_xmlsave.ctxType;
    updCtx              dbms_xmlsave.ctxType;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.domNodeList;
    nlsTemp1            xmlDom.domNodeList;
    nmpTemp             xmldom.domNamedNodeMap;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    docTemp             xmlDom.domDocument;
    docOld              xmlDom.domDocument;
    varWhereCond        varchar(4000);
    varDataType         varchar(50);
    varTemp3            varchar(4000);
--    varXMLEntryDetails  varchar2(8000);
    varXMLEntryDetails clob;
    varXMLTEMP          varchar2(8000);
    varXmlField         varchar(50);
    varColumName        varchar(50);
    varQuery            varchar(4000);
    raiseerrorexp       exception;

    nodTemp2            xmlDom.domNode;
    nodFinal1           xmlDom.domNode;
    docFinal1           xmlDom.domDocument;
    nlsTemp2            xmlDom.domNodeList;
    numSub2             number;    
    varX2Path           varchar(2000);
    numConfirmProcessYN        number(8);
    SerialNumber        number(5);
    varQueryMisc            varchar(500);
    varSubtable       varchar(2000);
    BEGIN
        Glog.log_write( 'entered inside the fncMasterMaintenance ' );
--insert into rtemp(TT,TT4) values ('Inside fncMasterMaintenance 0',xmlType(MasterDetail));commit;
        varMessage := 'Master Maintenance';
        dbms_lob.createTemporary (clbTemp,  TRUE);
        varFlag := 'N';
        varDeal := '';

        numError := 1;
        varOperation := 'Extracting Input Parameters';
        xmlTemp := xmlType(MasterDetail);
        varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
        varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
        numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);
        datToday := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datToday);

        GLOG.log_write('You message goes here' || numAction);

        numError := 2;
        varOperation := 'Extracting Field information ' || varEntity;
        select fldp_column_name
          into varStatus
          from trsystem999
          where fldp_table_synonym = varEntity
          and fldp_xml_field = 'RecordStatus';


        if numAction = GConst.EDITSAVE then
          varOperation := 'Checking process plan for updates';
          begin
              select NVL(fldp_edit_action,0)
              into numSerialProcess
              from trsystem999
              where fldp_table_synonym = varEntity
              and fldp_xml_field = 'SerialNumber';

              Exception
              When no_data_found then
              numSerialProcess := 0;
          End;
        End if;

        varMessage := 'Maintenace of: ' || varEntity || ', Action: ' || numAction;
        numError := 3;
        varOperation := 'Creating Document for Master';
        docFinal := xmlDom.newDomDocument(xmlTemp);
        nodFinal := xmlDom.makeNode(docFinal);

        numError := 4;
        varOperation := 'Processing Master Rows';
        varXPath := '//' || varEntity || '/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);


        for numSub in 0..xmlDom.getLength(nlsTemp) -1

        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varXPath := '//' || varEntity || '/ROW[@NUM="' || numTemp || '"]';
          varX2Path:=  varEntity || '/ROW[@NUM="' || numTemp || '"]';
          varOperation := 'Getting Status for processing';

          varWhereCond:='';

--          if numAction  = GConst.ADDSAVE then
--            numStatus := GConst.LOTNEW;
--          else
--            varTemp := varXPath || '/' || varStatus;
--            numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          end if;
         begin 
            varTemp := varXPath || '/' || varStatus;
            numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          exception 
            when others then
                if numAction  = GConst.ADDSAVE then
                   numStatus := GConst.LOTNEW;
                end if;
            end;

          select decode(numStatus,
            GConst.LOTNOCHANGE, 0,
            GConst.LOTNEW, GConst.ADDSAVE,
            GConst.LOTMODIFIED, GConst.EDITSAVE,
            GConst.LOTDELETED, GConst.DELETESAVE,
            GConst.LOTCONFIRMED, GConst.CONFIRMSAVE,
            GConst.LOTREJECTED, GConst.REJECTSAVE,
            GConst.LOTUNCONFIRMED, GConst.UNCONFIRMSAVE,
            Gconst.LOTINACTIVE,Gconst.INACTIVESAVE)
            into numAction
            from dual;

          varOperation:='Incase of Confirm Check the status of Reject /Confirm';
          begin 
            select ECON_CONFIRM_CHECKYN
              into numConfirmProcessYN
             from TRSYSTEM995B
             where ECON_ENTITY_NAME = varEntity
             and ECON_RECORD_STATUS not in (10200005,10200006);
          exception 
             when no_data_found then 
               numConfirmProcessYN:=12400002;
          end;  

          if ((numStatus=GConst.LOTCONFIRMED) and (numConfirmProcessYN=12400002)) then
            varOperation:='Entered Inside Confirm';
                varTemp := '//CONFIRMSTATUSINFO/DROW[@DNUM="1"]/Status';
                numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                Glog.Log_Write(' Status of Confirmation ' ||numStatus);
                if numCode = 2 then 
                    numAction := GConst.REJECTSAVE;
                  else
                     numCode := GConst.CONFIRMSAVE;
                end if;
          end if;

          numError := 5;
          varOperation := 'Preparing context for Edit';
          insCtx := dbms_xmlsave.newContext(varEntity);
          dbms_xmlsave.clearUpdateColumnList(insCtx);

 -- Changed
        if numStatus = GConst.LOTMODIFIED
                  and numSerialProcess = SYSADDSERIAL then
          numError := 6;

          varOperation := 'Marking old record for deletion';
          docOld := GConst.fncWriteTree('MasterEntity', varXPath, docFinal);
          updCtx := dbms_xmlsave.newContext(varEntity);
          dbms_xmlSave.clearUpdateColumnList(updCtx);
        end if;


    GLOG.log_write( 'Extracting Information '|| numAction);
    varOperation := 'Extracting Where Condition';
    if (numAction!=GConst.ADDSAVE) then
         for cur in (select  NVL(nvl(SYPK_KEY_NO,fldp_key_no), 0) numKey,
                                  NVL(decode(numAction,
                                  GConst.ADDSAVE, fldp_add_action,
                                  GConst.EDITSAVE, fldp_edit_action,
                                  GConst.DELETESAVE, fldp_delete_action,
                                  GConst.UNCONFIRMSAVE, fldp_unconfirm_action,
                                  GConst.REJECTSAVE, FLDP_REJECT_ACTION,
                                  GConst.CONFIRMSAVE, fldp_confirm_action,
                                  Gconst.INACTIVESAVE,fldp_INACTIVE_ACTION),0) as numProcess,
                                  fldp_process_yn varProcessYN ,FLDP_DATA_TYPE varDataType,FLDP_XML_FIELD varXmlField,
                                  fldp_column_name ColumnName
                          from trsystem999 left outer join 
                          -- incase from the front end if we are Group level Key and in backed we have indidual keys then 
                          -- we have to populate group keys in trsystem999Pk
                          trsystem999PK 
                          on SYPK_TABLE_SYNONYM=FLDP_TABLE_SYNONYM
                          and SYPK_COLUMN_NAME=FLDP_COLUMN_NAME
                          and SYPK_RECORD_STATUS not in (10200005,10200006)
                          where fldp_table_synonym = varEntity
                         --   and fldp_column_name=varNode
                            and NVL(nvl(SYPK_KEY_NO,fldp_key_no), 0)!=0)
             loop
                 varOperation:= 'Where Caluse Generation';
                 GLOG.log_write( varOperation || ' Key ' || Cur.numKey || ' Action ' || numAction || ' Node ' || cur.ColumnName);
                 varTemp := varXPath || '/' || cur.ColumnName;
                   GLOG.log_write( varOperation || ' ' ||  cur.ColumnName || '  ' || cur.varDataType || ' ' || varTemp);
                   if cur.varDataType in ('VARCHAR2','VARCHAR') then 
                      varTemp3 :=  '''' || GConst.fncGetNodeValue(nodFinal, varTemp) ||'''';
                      varWhereCond:=  nvl(varWhereCond,'') || ' ' || (case when varWhereCond is null then '' else ' and ' end ) || cur.ColumnName ||'=' || varTemp3;
                   elsif  cur.varDataType in ('DATE') then 
                      varTemp3 :=  '''' || GConst.fncxmlextract(xmlTemp,varX2Path|| '/' || cur.ColumnName , datTemp) ||'''';
                      varWhereCond:=  nvl(varWhereCond,'') || ' ' || (case when varWhereCond is null then '' else ' and ' end ) || cur.ColumnName ||'=' || varTemp3;
                   elsif cur.varDataType in ('NUMBER') then 
                      numCode := GConst.fncGetNodeValue(nodFinal, varTemp);
                      GLOG.log_write(varOperation || '  ' || numCode);
                      varWhereCond:= nvl(varWhereCond,'') || ' ' ||(case when varWhereCond is null then '' else ' and ' end ) || cur.ColumnName ||'=' || numCode;
                      GLOG.log_write(varOperation || '  ' || varWhereCond);
                   end if;
        end loop;
      end if;          

      nlsTemp1 := xmlDom.getChildNodes(nodTemp);

---------------------------Check for status and then process
        numError := 6;
        varOperation := 'Processing Nodes';
        for numSub1 in 0..xmlDom.getLength(nlsTemp1) -1
        Loop


          nodTemp := xmlDom.item(nlsTemp1, numSub1);
          varNode := xmlDom.getNodeName(nodTemp);
--          if varNode='EntryDetails' then 
--             Continue;
--          end if;
          GLOG.log_write(varOperation || ' ' || varNode ||' ' || varEntity || ' ' || numAction); 
              -- below where condition to ensure not to send the null values incase if the columns
              -- not ther for Edit
           if (numAction=GConst.EDITSAVE) then
                begin
                 select  NVL(nvl(SYPK_KEY_NO,fldp_key_no), 0),
                          NVL(decode(numAction,
                          GConst.ADDSAVE, fldp_add_action,
                          GConst.EDITSAVE, fldp_edit_action,
                          GConst.DELETESAVE, fldp_delete_action,
                          GConst.UNCONFIRMSAVE, fldp_unconfirm_action,
                          GConst.REJECTSAVE, FLDP_REJECT_ACTION,
                          GConst.CONFIRMSAVE, fldp_confirm_action,
                          Gconst.INACTIVESAVE,fldp_INACTIVE_ACTION),0) as action_type,
                          fldp_process_yn,FLDP_DATA_TYPE,FLDP_XML_FIELD
                    into numKey, numProcess, varProcessYN,
                          varDataType,varXmlField
                   from trsystem999 left outer join 
                  -- incase from the front end if we are Group level Key and in backed we have indidual keys then 
                  -- we have to populate group keys in trsystem999Pk
                  trsystem999PK 
                  on SYPK_TABLE_SYNONYM=FLDP_TABLE_SYNONYM
                  and SYPK_COLUMN_NAME=FLDP_COLUMN_NAME
                  and SYPK_RECORD_STATUS not in (10200005,10200006)
                  where fldp_table_synonym = varEntity
                    and fldp_column_name=varNode
                    and (((Fldp_field_sort is not null)
                    and (nvl(Fldp_field_sort,0) !=0)
                    and (nvl(fldp_tab_number,0) !=0))
                    --and (nvl(FLDP_ENABLE_DISABLE_EDIT,12400002)=12400002))
                    or ((FLDP_EDIT_ACTION is not null) and (numAction=GConst.EDITSAVE))
                    or (nvl(FLDP_KEY_NO,0)!=0));

                    if varXmlField is null then
                        continue;
                    end if;

                 exception
                   when others then 
                     continue;
                   end;
              else

                  numError := 7;
                  varOperation := 'Checking Field attributes :: ' || varNode ;
                  select NVL(nvl(SYPK_KEY_NO,fldp_key_no), 0),
                      NVL(decode(numAction,
                      GConst.ADDSAVE, fldp_add_action,
                      GConst.EDITSAVE, fldp_edit_action,
                      GConst.DELETESAVE, fldp_delete_action,
                      GConst.UNCONFIRMSAVE, fldp_unconfirm_action,
                      GConst.REJECTSAVE, FLDP_REJECT_ACTION,
                      GConst.CONFIRMSAVE, fldp_confirm_action,
                      Gconst.INACTIVESAVE,fldp_INACTIVE_ACTION),0) as action_type,
                      fldp_process_yn,FLDP_DATA_TYPE,FLDP_XML_FIELD
                  into numKey, numProcess, varProcessYN,
                      varDataType,varXmlField
                  from trsystem999 left outer join 
                  -- incase from the front end if we are Group level Key and in backed we have indidual keys then 
                  -- we have to populate group keys in trsystem999Pk
                  trsystem999PK 
                  on SYPK_TABLE_SYNONYM=FLDP_TABLE_SYNONYM
                  and SYPK_COLUMN_NAME=FLDP_COLUMN_NAME
                  and SYPK_RECORD_STATUS not in (10200005,10200006)
                  where fldp_table_synonym = varEntity
                  and fldp_column_name = varNode;
              end if;

         -- GLOG.log_write(varOperation ||  numKey ||  numProcess || varProcessYN || varDataType || varXmlField); 
          --insert into temp values (varNode || ' ' || numkey ,numProcess || varProcessYN);commit;
 ---Modified By Manjunath Reddy 20-jun-2011 To Take care of Options Muitiple Deals Update
         if ((varNode = 'COPT_SERIAL_NUMBER') and (numAction=GConst.EDITSAVE)) then
            numKey:=3;
            numProcess:=0;
            varProcessYN:='Y';
         end if;
  ------------ Code modified on 17/07/2007  to take care all types of updates
  --  For new records all columns are updated
          Glog.log_write( ' Node Name ' || varNode );
          Glog.log_write( ' numSerialProcess ' || numSerialProcess);
          if numStatus = GConst.LOTNEW then
              dbms_xmlsave.setUpdateColumn(insCtx, varNode);
          elsif numStatus = GConst.LOTMODIFIED then
  --  If records are for modification
            if numSerialProcess = SYSADDSERIAL then
  --  if new records are added for updation, update all columns
              dbms_xmlsave.setUpdateColumn(insCtx, varNode);
  --  update key columns for old record

              if numKey > 0 then
                dbms_xmlsave.setKeyColumn(updCtx, varNode);

              End if;
  --  For reords where existing records are updated
            elsif numKey > 0 then
              dbms_xmlsave.setKeyColumn(insCtx, varNode);
            else
              dbms_xmlsave.setUpdateColumn(insCtx, varNode);
            end if;
  --  For actions other than add and modify
          elsif numKey > 0 then
            dbms_xmlsave.setKeyColumn(insCtx, varNode);
  --  For options other than add and edit only related columns are updated
          elsif numProcess <> 0 then
           dbms_xmlsave.setUpdateColumn(insCtx, varNode);
          end if;
  --- added by Manjunath Reddy 07-Apr-2020 

--        if (numKey>0) and (numAction not in (GConst.ADDSAVE)) then 
--      
--         varTemp := varXPath || '/' || varNode;
--           GLOG.log_write( varOperation || ' ' || varTemp || '  ' || varDataType);
--           if varDataType in ('VARCHAR2','VARCHAR') then 
--              varTemp3 :=  '''' || GConst.fncGetNodeValue(nodFinal, varTemp) ||'''';
--              varWhereCond:=  nvl(varWhereCond,'') || ' ' || (case when varWhereCond is null then '' else ' and ' end ) || varNode ||'=' || varTemp3;
--           elsif  varDataType in ('DATE') then 
--              varTemp3 :=  '''' || GConst.fncxmlextract(xmlTemp,varX2Path|| '/' || varNode , datTemp) ||'''';
--              varWhereCond:=  nvl(varWhereCond,'') || ' ' || (case when varWhereCond is null then '' else ' and ' end ) || varNode ||'=' || varTemp3;
--           elsif varDataType in ('NUMBER') then 
--              numCode := GConst.fncGetNodeValue(nodFinal, varTemp);
--              GLOG.log_write(varOperation || '  ' || numCode);
--              varWhereCond:= nvl(varWhereCond,'') || ' ' ||(case when varWhereCond is null then '' else ' and ' end ) || varNode ||'=' || numCode;
--              GLOG.log_write(varOperation || '  ' || varWhereCond);
--           end if;
--        end if;



  --  Only if there is a process to be performed, the function is called
          if numProcess <> 0 then
--  The second record of deal (in swap etc) should not generate a new
--  number - Change made by TMM on 12/03/08
              if varNode = 'DEAL_DEAL_NUMBER' and varFlag = 'Y' then
                numError := GConst.fncSetNodeValue(nodFinal, nodTemp, varDeal);
              elsif varNode = 'COPT_DEAL_NUMBER' and varFlag = 'Y' then
                numError := GConst.fncSetNodeValue(nodFinal, nodTemp, varDeal);
              else
                if ((varXmlField='EntryDetail') or  (varXmlField='EntryDetails')) then 
                    Continue;
                end if;
                --numReturn := GConst.fncProcessNode(nodFinal, nodTemp, numAction);
                 numReturn := fncProcessNode(nodFinal, nodTemp, numAction, numTemp,varWhereCond);
--                 if  (varXmlField='EntryDetail') then
--                       docFinal := xmlDom.makeDocument(nodFinal);
--                    xmlDom.writeToClob(docFinal, clbTemp);
--                    
--                     insert into temp values ( 'After Process Node',clbTemp);  commit;
--                 end if;
                 --insert into temp values (varNode,numReturn); commit;
              end if;
          end if;
          varOperation := 'Checking Deal Entry';
          if ((varNode = 'DEAL_DEAL_NUMBER') or (varNode = 'COPT_DEAL_NUMBER')) then
           nodTemp1 := xmldom.getFirstChild(nodTemp);
           varDeal := xmldom.getNodeValue(nodTemp1);
           varFlag := 'Y';
          end if;
      End Loop;


      varOperation:='Check whether entry details are mapped to the entity' ;   
      Glog.log_write( varOperation || ' Where ' || varWhereCond);
      begin
        select FLDP_COLUMN_NAME
          into varTemp
          from trsystem999
          where fldp_table_synonym = varEntity
          and FLDP_XML_FIELD in('EntryDetails','EntryDetail');
       exception
         when others then
           varTemp:=null;
       end;

     if varTemp is not null then
        varOperation:='Calling the Entry Details Update'  ;  
        Glog.log_write( varOperation || ' Where ' || varWhereCond);
        varTemp:=varXPath || '/' || varTemp;
        Glog.log_write( varOperation || ' Entry Details ' || varTemp);
        nodTemp := xslProcessor.selectSingleNode(nodFinal, varTemp);
        Glog.log_write( 'Extracted Nodes');
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp);
--        if xmlDom.getLength(nlsTemp) != 0 then
           numReturn := fncProcessNode(nodFinal, nodTemp, numAction, numTemp,varWhereCond);
           Glog.log_write( 'After Processing Nodes' || numReturn);
--        end if;
     end if;


      docFinal := xmlDom.makeDocument(nodFinal);
      dbms_lob.createTemporary (clbTemp,  TRUE);

     -- insert into temp values ( 'XML',docFinal);  commit;

      docTemp := GConst.fncWriteTree('MasterEntity', varXPath, docFinal);
      xmlDom.writeToClob(docTemp, clbTemp);
      dbms_xmlsave.setDateFormat(insctx, 'dd/MM/yyyy');
      dbms_xmlsave.setRowTag(insctx, 'ROW');


      numError := 7;
      varOperation := 'Processing Master record ' || insCtx || numTemp ||varXPath;
      Glog.Log_write(varOperation);
--      xmlDom.writeToFile(docFinal, 'XMLDIR1\upd.xml');
 --change here

--      delete from temp ;
--      insert into temp values (insCtx,clbtemp); commit;
--      GLOG.log_write( Varoperation ||'  ' ||  clbtemp);
--     GLOG.log_write(' XML Before Action ' ||clbTemp);
--     GLOG.log_write( 'Insert Statement ' || insCtx);
      if numStatus = GConst.LOTNEW
          or (numStatus = GConst.LOTMODIFIED
          and numSerialProcess = SYSADDSERIAL ) then
        Glog.log_write(' Insert Executed');
        numTemp := dbms_xmlSave.insertXML(insCtx, clbTemp);
        Glog.log_write(' Record Instered');
      else
        Glog.log_write(' Update Executed');
        numTemp := dbms_xmlSave.updateXML(insCtx, clbTemp);
        Glog.log_write(' Updated Sucessfully');
      end if;
---------------------------Check for status and then process
      varOperation := 'Check for status and then process';


      if numStatus = GConst.LOTMODIFIED
          and numSerialProcess = SYSADDSERIAL then

          numError := 8;
          varOperation := 'Updating old record to inactive status';
          nodTemp := xmlDom.makeNode(docOld);
          dbms_xmlsave.setUpdateColumn(updCtx, varStatus);
          varTemp := '//' || varStatus;
          nodTemp1 := xslProcessor.selectSingleNode(nodTemp, varTemp);

          numError := 9;
          varOperation := 'Setting value to record staus';
          numTemp := GConst.fncsetNodeValue(nodFinal, nodTemp1,
                        to_char(GConst.STATUSINACTIVE));
  --        xmlDom.writeToFile(docOld, 'XMLDIR\upd.xml');
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(docOld, clbTemp);
          dbms_xmlsave.setDateFormat(updCtx, 'dd/MM/yyyy');

          numError := 10;
          varOperation := 'Updating old record';
          numTemp := dbms_xmlSave.updateXML(updCtx, clbTemp);


      end if;

    End Loop;
    varOperation := ' Extracting info to update the audit trails' ;
     varTemp3:='';
--     if numAction not in (GConst.ADDSAVE) then
--        varOperation := ' Extracting Entry Details' ;
--        
--        begin
--            select FLDP_COLUMN_NAME 
--              into varColumName
--            from trsystem999
--            where fldp_table_synonym = varEntity
--                and fldp_xml_field = 'EntryDetail';
--        exception
--          when others then
--             varColumName:=null;
--        end;
--        if (varColumName is not null) then
--            GLOG.log_write(varEntity || varColumName);
--    
--            varTemp3:= 'select ' ||  varColumName || ' from ' || varEntity || ' where ' || varWhereCond;
--            GLOG.log_write('Execute Query'||VarTemp3);
--            
--            --insert into temp values ( 'Execute Query',VarTemp3); commit;
--            execute immediate varTemp3 into varXMLEntryDetails;
--            GLOG.log_write('post executing Query '||varXMLEntryDetails);
--        end if;
--    end if;      
--    
--     varOperation:=' Update Audit Trails for Base Tables';
--    if (varXMLEntryDetails is not null or varXMLEntryDetails !='') then
--        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE, GConst.CONFIRMSAVE, GConst.REJECTSAVE, GConst.UNCONFIRMSAVE) then
--              varOperation:=' Update Audit Trails';
----              varTemp3:=replace(varTemp3,'<AuditTrails>',null);
----              varTemp3:=replace(varTemp3,'</AuditTrails>',null);
----              
----   
--        GLOG.log_write(varOperation || '  ' || numAction);
--        docFinal1 := xmlDom.newDomDocument(xmltype(varXMLEntryDetails));
--        nodFinal1 := xmlDom.makeNode(docFinal1);
--
--        numError := 4;
--        varOperation := 'Processing Master Rows';
--        varX2Path := '//AuditTrails';
--        nlsTemp2 := xslProcessor.selectNodes(nodFinal1, varX2Path);
--        for numSub2 in 0..xmlDom.getLength(nlsTemp2) -1
--        Loop
--          GLOG.log_write('Inside Update statement for loop ' || varOperation || '  ' || numAction);
--         varOperation := 'Processing Master Rows';
--          nodTemp2 := xmlDom.item(nlsTemp2, numSub2);
--          varX2Path := '//AuditTrail';
--          varXMLTEMP:=GConst.fncGetNodeValue(nodTemp2, varX2Path);
--           --GLOG.log_write('Inside Update statement of Entry Details ' || to_char(nodTemp2.innerXML));
--              varQuery:='UPDATE ' ||  varEntity|| ' SET ' || varColumName ||' =
--                     APPENDCHILDXML(' || varColumName || ','||
--                     ''''|| 'AuditTrails' ||''''|| ',' || xmltype( ' || ''' || nodTemp2 ||'''' || ')' ||
--
--                      where ' || varWhereCond;
--                     --XMLType(' || '''' || varTemp3 || ''''|| ')) where ' || varWhereCond;
--                     
--                                          --XMLType('|| '''' || 
--                     --nodTemp2.innerXML || ''''|| '))
--                     
--              GLOG.log_write(varOperation || '  ' || varQuery);
--              execute immediate varQuery;
--        end loop;
--        end if;    
--     end if;
    GLOG.log_write('outside Update statement after for loop ' || varOperation || '  ' || numAction);

    dbms_lob.createTemporary (clbTemp,  TRUE);
    xmlDom.writeToClob(docFinal, clbTemp);
--xmlDom.writeToFile(docFinal, 'XMLDIR1\upd.xml');

--Added on 09/03/08 to take care of miscellaneous updates after master processing
    GLOG.log_write('Checking the Table to get the Misce');

    begin 
     select miss_procedure_name 
       into varQueryMisc
       from trsystem995C
       where Miss_record_status not in (10200005,10200006)
       and MISS_SYNONYM_NAME = varEntity;
    exception
      when others then
        varQueryMisc:= null;
    end;

    if varQueryMisc is not null then
        varQueryMisc:= ' begin ' || varQueryMisc || '(:1); end;';
        GLOG.log_write('varQueryMisc ' || varQueryMisc);

        execute immediate varQueryMisc using clbTemp;
    else



 ---kumar.h 12/05/09  updates for Fixed Deposit--------
   if varEntity = 'BUYERSCREDIT' then
      clbTemp := fncMiscellaneousUpdates(clbTemp,SYSBCRFDLIEN ,numError);
   elsif varEntity ='RELATIONTABLE'then
      clbTemp := fncMiscellaneousUpdates(clbTemp,SYSRELATION ,numError);
   elsif ((varEntity ='OPTIONTRADEEXERCISE') or (varEntity ='OPTIONHEDGEEXERCISE' )) then
      varOperation := 'Effecting Cancelation  Options Deal ';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSOPTIONCANCELDEAL, numError);
      --Clbtemp := Pkgmastermaintenance.Fnccurrentaccount(Clbtemp, Numerror);
      -- Numerror:=Pkgfixeddepositproject.Fncgeneratemaildetails1(Clbtemp ) ;
                  -- added by sivadas on 11apr2012 --
    elsif ((varEntity ='OPTIONHEDGEDEAL') or (varEntity ='OPTIONHEDGEDEAL' )) then
      varOperation := 'Effecting Cancelation  Options Deal ';
     -- Clbtemp := Pkgmastermaintenance.Fnccurrentaccount(Clbtemp, Numerror);
      -- numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp ) ;
    Elsif  (Varentity ='HEDGEDEALREGISTER') Then
        --clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);

          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSDEALADJUST, numError);
    Elsif  (Varentity ='EXPOSURETYPEMASTER') Then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
              SYSEXPOSUREMASTER, numError); 
   elsif varEntity ='ORDINVLINKING'then
       varOperation := 'Effecting Order Invoice Linking';
        --dbms_lob.CreateTemporary(clbTemp, True);
        --xmlDom.writeToClob(DocFinal, clbTemp);
        clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                SYSUPDATEORDINVLINK, numError);
   elsif (varEntity ='CURRENCYFUTUREDEALCANCEL' or varEntity ='' or varEntity= 'CURRENCYFUTURETRADDEALCANCEL') then
      varOperation := 'Reversal OF Future Deals';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                   SYSFUTUREREVERSAL, numError);
   elsif varEntity ='CASHFLOWBUDGET' then
      varOperation := 'Update CashFlow Budget Details';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                   SYSCASHFLOWBUDGET, numError);
    elsif varEntity = 'AANDLPOSITION' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSAANDLPOSITION, numError);
    elsif varEntity = 'SVCFUTUREMTMRATE' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSFUTUREMTMUPLOAD, numError);
    elsif varEntity in ('STRESSTESTSENSITIVE') then
      Clbtemp := Pkgmastermaintenance.Fncmiscellaneousupdates(Clbtemp,
        Sysstressinsertsub, Numerror);
    elsif varEntity = 'FOREIGNREMITTANCE' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSCASHDEAL, numError);
    elsif varEntity = 'CURRENCYFUTUREPRODUCT' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,SYSPRODUCTMATURITY, numError);
   elsif varEntity = 'EXPOSURESETTLEMENTNEW' then
--      varOperation := 'Update the Currenct Account Details';
--      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       varOperation := 'Exposure settlement entry';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,SYSEXPOSURESETTLEMENT, numError);       
   elsif varEntity = 'INFLOWOUTFLOWPAYMENTS' then
      varOperation := 'Exposure settlement entry';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp, SYSINFLOWOUTFOWPAYMENTS, numError);  
      --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;  
    elsif varEntity = 'EXPOSURESETTLEMENTADD' then
--      varOperation := 'Update the Currenct Account Details';
--      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       Varoperation := 'Exposure settlement entry';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,SYSEXPOSURESETTLEMENT, numError); 
    elsif VarEntity ='USERMASTER' then
      varOperation := 'Update Company Access detail at User Creation';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        Gconst.UTILUSERUPDATE, numError);    
    elsif VarEntity ='DEALINTEGRATION' then
      varOperation := 'Update License details';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        SYSDEALINTEGRATION, numError);    
    elsif VarEntity ='BRANCHMASTER' then
    varOperation := 'Update Branch Details';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        SYSBRANCHUPDATE, numError); 
    elsif VarEntity ='EMAILSTATEMENTCONFIG' then
    varOperation := 'Update Branch Details';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        SYSEMAILSTATEMENTCONFIG, numError); 
    elsif VarEntity ='SFTPSTATEMENTCONFIG' then
    varOperation := 'Update Branch Details';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        SYSSFTPSTATEMENTCONFIG, numError); 
    elsif VarEntity ='EXPORTREGISTERREVERSAL' then
    varOperation := 'Update Branch Details';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        SYSEXPOSUREREVERSALUPDATE, numError);
     elsif VarEntity ='IMPORTREGISTERREVERSAL' then
    varOperation := 'Update Branch Details';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        SYSEXPOSUREREVERSALUPDATE, numError);
    elsif VarEntity ='FORWARDOPTIONLINKING' then
      varOperation := 'Update Deal Details';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        SYSFORWARDOPTIONLINK, numError); 
    elsif VarEntity ='CASHINHAND' then
      varOperation := 'Cash in Hand';
--     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                        SYSCASHINHAND, numError);   
    Elsif  (Varentity ='HEDGEDEALCANCELLATION') Then
      VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'CDEL_DEAL_NUMBER',VarReference);
      numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILHEDGEDEAL,datToday,1);

 elsif varEntity = 'EMAILCONFIGURATION' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSEMAILCONFIGURATIONPROCESS, numError); 

 elsif varEntity = 'EXPOSUREROLLOVER' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSEXPOSUREROLLOVER, numError);       
-- elsif varEntity = 'HEDGEDEALREGISTER' then 
--        varOperation := 'iNSERT GRID DETAILS';
--        clbTemp := fncMiscellaneousUpdates(clbTemp, SYSFORWARDDEALINSERT, numError);        
elsif varEntity = 'DUEDATEALERTCONFIGURATION' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSDUEDATEALERTCONFIGPROCESS, numError); 
--  elsif varEntity = 'COMPLIANCEALERTCONFIGURATION' then 
--      varOperation := 'Add ,View Email details';
--      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSCOMPLIANCEALERTPROCESS, numError);
elsif varEntity = 'DAILYRATETABLENEW' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSDAILYRATESPROCESS, numError); 
elsif varEntity = 'REPORTCONFIGURATION' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSREPORTCONFIGURATION, numError);       
--    Elsif  (Varentity ='HEDGEDEALCANCELLATION') Then
     --   clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
        --numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp ) ;
  --  Elsif  (Varentity ='HEDGEDEALREGISTER') Then
    --    clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);        
    elsif varEntity ='IMPORTTRADEREGISTER' then 
       Clbtemp := Pkgmastermaintenance.Fncmiscellaneousupdates(Clbtemp, Syspurconcancel, Numerror);  
--    Elsif Varentity='HEDGEDEALREGISTER' Then
--           numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp) ;
  --  elsif varEntity ='IMPORTTRADEREGISTERDETAIL1' then 
     --  numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp) ;
--    elsif varEntity ='IMPORTTRADEREGISTERDETAIL' then 
--       --numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp) ;       
    elsif varEntity ='HEDGEREGISTER' then 
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp, SYSHEDGELINKINGCANCEL, numError);    
    elsif varEntity ='TERMLOAN' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Update Term loan Principal and Interest table';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSTERMLOAN, numError);
    ELSIF VARENTITY = 'DUMMYFILE' THEN
        CLBTEMP := pkgMasterMaintenance.fncMiscellaneousUpdates(CLBTEMP,
        SYSUSERUPDATE, numError);
--    ELSIF VARENTITY = 'COMPANYMASTER' THEN
  --      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--        GConst.SYSCOMPANYUPDATE, numError);
   elsif varEntity ='IRS' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the IRS details';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSIRSPOPULATE, numError);
   elsif varEntity ='CCIRSWAP' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the CC IRS details';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSIRSPOPULATE, Numerror);        
   elsif varEntity = 'CCIRSSETTLEMENT' THEN
      varOperation := 'Passing another entry in CCIRSSettlement';
--      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--        GConst.SYSCCIRSSETTLE, numError);  
   elsif varEntity = 'IRSSETTLEMENT' THEN
      varOperation := 'Passing another entry in IRSSETTLEMENT';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSCCIRSPOPULATE, numError);
   elsif varEntity = 'CCSSETTLEMENT' THEN
      varOperation := 'Passing another entry in CCSSETTLEMENT';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSCCIRSPOPULATE, numError);
    elsif varEntity = 'IRSSETTLEMENTMAINTENANCE' THEN
      varOperation := 'Passing another entry in IRSSETTLEMENT';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        UTILIRS, numError);    
   elsif varEntity = 'CCSSETTLEMENTMAINTENANCE' THEN
      varOperation := 'Passing another entry in IRSSETTLEMENT';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        UTILIRS, numError); 
    elsif varEntity = 'IRSINTERESTREVALUATION' THEN
      varOperation := 'Passing another entry in IRSSETTLEMENT';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSINTERESTREVALUATION, numError);
    elsif varEntity = 'USERLEVELSCREENCONFIG' THEN
      varOperation := 'Passing another entry in SYSUSERLEVELSCREENCONFIG';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSUSERLEVELSCREENCONFIG, numError);
   elsif varEntity ='IRO' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the IRS details';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSIROPOPULATE, numError);  
     elsif varEntity ='HEDGECOMMODITYDEAL' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the Hedge Commodity details';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        SYSCOMHEDGELINKING, numError);    
     elsif varEntity='FUTURESDATA' then
       varOperation := 'Deleting Futures deals';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
       SYSDELETEFUTUREDATA, numError);   
     elsif varEntity = 'BANKCHARGEMASTER' then 
        varOperation := 'Deleting Futures deals';
        clbTemp := fncMiscellaneousUpdates(clbTemp, SYSBANKCHARGEINSERT, numError);  
    elsif varEntity = 'BANKCHARGECONFIG' then 
        varOperation := 'Save, confirm and Delete Bank Charge Config';
        clbTemp := fncMiscellaneousUpdates(clbTemp, SYSBANKCHARGECONFIGPROCESS, numError); 
    elsif varEntity = 'BULKCONFIRMATION' then 
        varOperation := 'confirm and reject bulk vouchers';
        clbTemp := fncMiscellaneousUpdates(clbTemp, SYSBULKCONFIRMATIONPROCESS, numError); 
    elsif varEntity = 'FORWARDROLLOVER' then 
        varOperation := 'Save, Confirm and Delete forward rollover';
        clbTemp := fncMiscellaneousUpdates(clbTemp, SYSFORWARDROLLOVERPROCESS, numError);  
    elsif varEntity = 'FUTUREROLLOVER' then 
        varOperation := 'Save, Confirm and Delete Future rollover';
        clbTemp := fncMiscellaneousUpdates(clbTemp, SYSFUTUREROLLOVERPROCESS, numError);  
    elsif varEntity = 'LOGIN' then 
    varOperation := 'UPDATE IP OF LOGGED IN USER';
    clbTemp := fncMiscellaneousUpdates(clbTemp, SYSLOGINIPUPDATE, numError); 
     elsif varEntity = 'EXCHANGERATE' then 
        varOperation := 'Inserting RBI reference rate';
        clbTemp := fncMiscellaneousUpdates(clbTemp, SYSRBIREFRATE, numError); 
    elsif varEntity = 'DATAUPLOADCONFIG' then
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSDATAUPLOADSPROCESS, numError);         
    elsif varEntity ='DATAUPLOADMASTER' then
        varOperation := 'Calling Procedure to load Data';
        pkgbulkdataload.prcProcessData;
    elsif varEntity ='DROPBOX' then
        varOperation := 'Calling Procedure to load Data';
        pkgbulkdataload.prcProcessData;
    elsif varEntity ='INBOUNDDATAINTERFACE' then
        varOperation := 'Calling Procedure to load Data';
        pkgbulkdataload.prcProcessData;
    elsif varEntity = 'OPTIONTYPECONFIGURATION' then
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSOPTIONTYPECONFIGPROCESS, numError);
    elsif varEntity = 'LOCATIONMASTER' then
      varOperation := 'Add ,Edit and Delete Location details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSLOCATIONMASTERPROCESS, numError);
    elsif varEntity = 'CURRENCYPAIRCONFIGURATION' then
      varOperation := 'Add ,Edit and Delete Currency Pair details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSCURRENCYPAIRCONFIGPROCESS, numError);  
    elsif varEntity = 'BANKMASTER' then
      varOperation := 'Add ,Edit and Delete Bank details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSBANKMASTERPROCESS, numError);
    elsif varEntity = 'CODEMASTER' then
      varOperation := 'Add ,Edit and Delete Bank details';
      numTemp  := GConst.fncXMLExtract(xmltype(clbTemp),'PICK_KEY_GROUP',numTemp);
      if numTemp in (333,338) then
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSCODEMASTERPROCESS, numError);
      end if;

    elsif varEntity ='COPYOVERMASTER' then 
      varOperation := ' Calling Copy Over Procedure from Bulk Upload ' ;
        pkgbulkdataload_prcCopyoverData();
--         elsif varEntity ='TRANBULKCONFIRMATION' then 
--      varOperation := ' Calling TRANBULKCONFIRMATION Procedure from Bulk Upload ' ;
--        MS();
    elsif varEntity ='JOBSCHEDULER' then 
      varOperation := ' Calling Job Creation ' ;
      varReference  := GConst.fncXMLExtract(xmltype(clbTemp),'SJOB_JOB_NUMBER',varReference);
      serialNumber   := GConst.fncXMLExtract(xmltype(clbTemp),'SJOB_SERIAL_NUMBER',numTemp);
      --pkgAlerts.prcCreateJob(varReference,serialNumber);
      IF(numAction=GConst.ADDSAVE) then      
        pkgAlerts.prcCreateJob(varReference,serialNumber);
      ELSIF (numAction=GConst.EDITSAVE) then       
        --serialNumber :=serialNumber-1;
        pkgAlerts.prcDropJob(varReference,serialNumber-1);
        pkgAlerts.prcCreateJob(varReference,serialNumber);
      elsif (numAction=GConst.DELETESAVE) then
       pkgAlerts.prcDropJob(varReference,serialNumber);
      end if;
    elsif varEntity ='REMITTANCES' then 
      varOperation := ' Callign Miscellaneous Updates';
      Glog.log_write('Calling Miscellaneous Updates ' || SYSREMITTANCESMAINTANCE);
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSREMITTANCESMAINTANCE, numError);
      
       elsif varEntity ='RUNACCOUNTINGPROCESS' then
      GLOG.log_write(' RUNACCOUNTINGPROCESS Started ');
      if (numAction=GConst.ADDSAVE) then
      varOperation := ' Calling Procedure prccashfairhedge ' ;  
      varTemp := GConst.fncXMLExtract(xmlTemp, 'AHPM_AMTM_REFERENCENUMBER', varTemp);
      datTemp := GConst.fncXMLExtract(xmlTemp, 'AHPM_EFFECTIVE_DATE', datTemp);
     varReference := GConst.fncXMLExtract(xmlTemp, 'AHPM_REFERENCE_NUMBER', varReference);
     
      GLOG.log_write(' AHPM_AMTM_REFERENCENUMBER ' || varTemp ||' AHPM_EFFECTIVE_DATE '|| datTemp ||' AHPM_REFERENCE_NUMBER '||varReference);
--          if varReference is not null then
--          pkgHedgeAccounting.prcCashFairHedge(datTemp,varReference);
--          else
--          pkgHedgeAccounting.prcCashFairHedge(datTemp);
--          end if;
        if varTemp is not null then
          pkgHedgeAccounting.RunHedgeAccounting(datTemp,varTemp,varReference);
--          else
--          pkgHedgeAccounting.RunHedgeAccounting(datTemp);
          end if;

      else
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSRUNACCOUNTINGPROCESS, numError);
      end if;
    elsif varEntity = 'EMAILCREATION' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSEMAILCREATIONPROCESS, numError); 
     elsif varEntity = 'EMAILTEMPLATES' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSEMAILTEMPLATESPROCESS, numError); 
       elsif varEntity = 'TRANBULKCONFIG' then 
      varOperation := 'Add ,View Email details';
      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSTRANBULKCONFIGPROCESS, numError); 
--    elsif varEntity ='EMAILCONFIGURATION' then 
--      varOperation := 'Add ,View Email details';
--      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSEMAILCREATIONPROCESS, numError);     

    end if;  

    end if;  

    Glog.Log_write('Check the Bank Vouchers configured');

    select count(*)
      into numCode
     from trsystem999E
     where TABS_PROGRAM_UNIT =varEntity
     and TABS_TAB_CODE = 91300101
     and TABS_RECORD_STATUS not in (10200005,10200006);

    if numCode !=0 then 
        Glog.Log_write(' Calling Bank Vouchers ');
        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);        
    end if;



 --   end if;

     For curProcess in
      (select NVL(fldp_key_no, 0),
          NVL(decode(numAction,
          GConst.ADDSAVE, fldp_add_action,
          GConst.EDITSAVE, fldp_edit_action,
          GConst.DELETESAVE, fldp_delete_action,
          GConst.UNCONFIRMSAVE, fldp_unconfirm_action,
          GConst.REJECTSAVE, FLDP_REJECT_ACTION,
          GConst.CONFIRMSAVE, fldp_confirm_action,
          Gconst.INACTIVESAVE,fldp_INACTIVE_ACTION),0) as action_type,
          fldp_process_yn
          from trsystem999
          where fldp_table_synonym = varEntity
          and fldp_data_type!='BLOB')
      Loop


--
--        if curProcess.action_type = GConst.SYSRISKGENERATE then
--          varOperation := 'Generating Risk violations';
--          --numerror := pkgForexProcess.fncRiskPopulate(datToday, GConst.TRADEDEAL);
--          numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);
--        elsif curProcess.action_type = GConst.SYSHEDGERISK then
--          varOperation := 'Generating Hedge Risk violations';
--          --numError := pkgForexProcess.fncHedgeRisk(datToday);
--        elsif curProcess.action_type = GConst.SYSVOUCHERCA then
--          varOperation := 'Inserting Current Account vouchers';
--          dbms_lob.createTemporary (clbTemp,  TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          numError := fncCurrentAccount(clbTemp);
--        elsif curProcess.action_type = GConst.SYSRATECALCULATE then
--          varOperation := 'Calculating Rates';
--          dbms_lob.createTemporary (clbTemp,  TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          numError := pkgForexProcess.fncCalculateRate(clbTemp);
--          numtemp:=0;
--          begin
--            varOperation := 'Getting the Count of the  Rates' || numtemp ;
--           select count(*)
--             into numtemp
--             from trtran012
--             where drat_effective_date=datToday
--             and drat_serial_number= (select max(drat_serial_number)
--                      from trtran012 where drat_effective_date=datToday);
--           exception
--           when others then
--            numtemp :=0;
--          end;
--           if (numtemp=16) then
--              varOperation := 'Getting the Count of the  Rates Temp' || numtemp || datToday;
--              numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);
--           end if;
--          --numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);
--          --numError := pkgForexProcess.fncHedgeRisk(datToday);
--        elsif curProcess.action_type = GConst.SYSRATECALCULATE1 then
--          varOperation := 'Calculating Rates for Windows Services';
--          datTemp := GConst.fncXMLExtract(xmlTemp, 'ROW[@NUM="1"]/RATE_EFFECTIVE_DATE', datTemp);
--          numSub1 := GConst.fncXMLExtract(xmlTemp, 'ROW[@NUM="1"]/RATE_SERIAL_NUMBER', numSub1);
--           numError := pkgForexProcess.fncCalculateRate(datTemp,
--            30400004, 30400003, numSub1);
--          for CurRates in
--          (select rate_effective_date, rate_currency_code, rate_for_currency,
--            rate_serial_number
--            from trsystem009 a
--            where rate_effective_date = datTemp
--            and rate_serial_number = numSub1
--            and not exists
--            (select 'x'
--              from trsystem009 b
--              where b.rate_currency_code = a.rate_currency_code
--              and b.rate_for_currency = a.rate_for_currency
--              and b.rate_effective_date = a.rate_effective_date
--              and b.rate_serial_number = a.rate_serial_number
--              and rate_currency_code = 30400004 and rate_for_currency = 30400003))
--          Loop
--          numError := pkgForexProcess.fncCalculateRate(datTemp,
--            CurRates.rate_currency_code, curRates.rate_for_currency, numSub1);
--          End Loop;
--
--          --dbms_snapshot.refresh('mvewLatestRates');
--         -- numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);

        if curProcess.action_type = SYSLOANCONNECT then
          varOperation := 'Connecting Import/Export to Loans';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSLOANCONNECT, numError);

       --added by kumar.h 12/05/09 for buyers credit
        elsif curProcess.action_type = SYSBCRCONNECT then
          varOperation := 'Connecting Import/Export to Loans';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSBCRCONNECT, numError);
        --added by kumar.h 12/05/09 for IMPORTORDER and EXPORT ORDER
       elsif curProcess.action_type = SYSPURCONNECT then
          varOperation := 'Moving Purchase Order details';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSPURCONNECT, numError);

        --added by kumar.h 12/05/09 for buyers credit
        -- commented by Manjunath Reddy on 01-Jul-2021  
--        elsif curProcess.action_type = SYSEXPORTADJUST then
--          varOperation := 'Effecting Export Adjustment';
--          dbms_lob.createTemporary (clbTemp,  TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                  SYSEXPORTADJUST, numError);
        elsif curProcess.action_type = SYSDEALDELIVERY then
          varOperation := 'Effecting Deal Delivery';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSDEALDELIVERY, numError);
--        elsif curProcess.action_type = GConst.SYSDEALADJUST then
--          varOperation := 'Effecting Deal Adjustment';
--          dbms_lob.CreateTemporary(clbTemp, TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                  GConst.SYSDEALADJUST, numError);

        elsif curProcess.action_type = SYSCOMMDEALREVERSAL then
          varOperation := 'Effecting Commodity Deal Reversal';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSCOMMDEALREVERSAL, numError);

        elsif curProcess.action_type = SYSHOLDINGRATE then
          varOperation := 'Generating Holding Rate for deals';
          varXPath := '//' || varEntity || '/ROW[@NUM="1"]/';

          if varEntity = 'TRADEDEALREGISTER' then
            numCode := to_number(GConst.fncGetNodeValue(nodFinal, varXPath || 'DEAL_BASE_CURRENCY'));
            Dattemp := To_Date(Gconst.Fncgetnodevalue(Nodfinal, Varxpath || 'DEAL_EXECUTE_DATE'), 'dd/mm/yyyy');
            --numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError);
            --numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError, varUserID);
            numCode := to_number(GConst.fncGetNodeValue(nodFinal, varXPath || 'DEAL_OTHER_CURRENCY'));
--            if numCode != GConst.INDIANRUPEE then
--              numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError);
--              numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError, varUserID);
--            end if;

          elsif varEntity = 'TRADEDEALCANCELLATION' then
            varDeal := GConst.fncGetNodeValue(nodFinal, varXPath || 'CDEL_DEAL_NUMBER');
            numSub :=  to_number(GConst.fncGetNodeValue(nodFinal, varXPath || 'CDEL_DEAL_SERIAL'));
            datTemp := to_date(GConst.fncGetNodeValue(nodFinal, varXPath || 'CDEL_CANCEL_DATE'), 'dd/mm/yyyy');

--            varOperation := 'Getting Deal Details';
--            select deal_base_currency, deal_other_currency
--              into numCode, numCode1
--              from trtran001
--              where deal_deal_number = varDeal
--              and deal_serial_number = numSub;
           -- numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError);
            --numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError, varUserID);

--            if numCode1 != GConst.INDIANRUPEE then
--              numRate := pkgForexProcess.fncHoldingRate(numCode1, datTemp, numError);
--              numRate := pkgForexProcess.fncHoldingRate(numCode1, datTemp, numError, varUserID);
--            end if;

          End if;

          varTemp := numRate;

        elsif curProcess.action_type = SYSCANCELDEAL then
          varOperation := 'Effecting Deal Cancellation';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSCANCELDEAL, numError);

--------------Currency Future Manjunath Reddy
--       elsif curProcess.action_type = GConst.SYSFUTUREREVERSAL then
--
--
--          varOperation := 'Effecting Currency Future Deal Reversal';
--          dbms_lob.CreateTemporary(clbTemp, TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                  GConst.SYSFUTUREREVERSAL, numError);
--
--------------Currency Options Manjunath Reddy
       elsif curProcess.action_type = SYSOPTIONMATURITY then

        -- insert into Temp Values('Enter into SYSOPTIONMATURITY ','SYSOPTIONMATURITY');
          varOperation := 'Effecting Options Deal ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSOPTIONMATURITY, numError);

       elsif curProcess.action_type = SYSLINKUPDATETABLES then

        -- insert into Temp Values('Enter into SYSLINKUPDATETABLES ','SYSLINKUPDATETABLES');
          varOperation := 'Effecting Options Deal ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSLINKUPDATETABLES, numError);

       elsif curProcess.action_type = SYSUPDATEDEALNO then --Added by Sivadas on 18DEC2011
          varOperation := 'Effecting Options Deal ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  SYSUPDATEDEALNO, numError);

       elsif curProcess.action_type = SYSEXCHMTMUPDATE then --Added by Sivadas on 18DEC2011
          varOperation := 'updating exchange MTM uploaded file ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
          SYSEXCHMTMUPDATE, numError);

--          elsif curProcess.action_type = GConst.SYSCONTRACTSHCEDULE then
--          varOperation := 'Contract Schedule';
--          dbms_lob.createTemporary (clbTemp,  TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                  GConst.SYSCONTRACTSHCEDULE, numError);
     end if;
    End Loop;

    if numAction IN (GConst.CONFIRMSAVE, GConst.REJECTSAVE) then

    begin 
        select ECON_CONFIRM_CHECKYN
          into numConfirmProcessYN
         from TRSYSTEM995B
         where ECON_ENTITY_NAME = varEntity
         and ECON_RECORD_STATUS not in (10200005,10200006);
    exception 
      when no_data_found then 
        numConfirmProcessYN:=12400002;
    end;  
     varOperation := 'Check to Process the COnfirm Status for the Common Table ';
    if numConfirmProcessYN=12400002 then
        --if varEntity!='BULKCONFIRMATION' then
        varOperation := 'Update confirm status and remarks for all screens on confirm.';
        varXPath := '//CONFIRMSTATUSINFO/DROW[@DNUM="1"]/';

        numTemp := 0;
       -- numCnt := 0;
        varWhereCond := ' where ';

         begin
                   varOperation := 'Extracting status';
                   varTemp1 := GConst.fncXMLExtract(xmlTemp,varXPath || 'Status',varTemp1, Gconst.TYPENODEPATH);
                --   varTemp := GConst.fncXMLExtract(xmlTemp,varXPath || 'Remarks',varTemp, Gconst.TYPENODEPATH);              
                  GLOG.log_write('Confirm Status - ' || varTemp1);
         exception 
                  when others then
                  varTemp1:= '1';
                  --  varTemp:=' ';
         end;
         begin
                   varOperation := 'Extracting remarks';
              --     varTemp1 := GConst.fncXMLExtract(xmlTemp,varXPath || 'Status',varTemp1, Gconst.TYPENODEPATH);
                   varTemp := GConst.fncXMLExtract(xmlTemp,varXPath || 'Remarks',varTemp, Gconst.TYPENODEPATH);              
                  GLOG.log_write('Confirm Status - ' || varTemp);
         exception 
                  when others then
               --   varTemp1:= '1';
                    varTemp:=' ';
         end;
                if varTemp1 = '2' then 
                numCode := GConst.STATUSREJECTED;
                else
                numCode := GConst.STATUSAUTHORIZED;
                end if;
         --   GLOG.log_write(MasterDetail);
       --  if numCode = 10200007 then  
                For curFields in
                (select fldp_column_name, fldp_xml_field,
                    fldp_key_no, fldp_data_type
                    from trsystem999
                   where fldp_table_synonym = varEntity   
                    AND FLDP_PROCESS_YN=12400001
                    and fldp_key_no >0
                    order by fldp_column_id)
                  Loop
                  GLOG.log_write('CONFIRM - ' || curFields.fldp_column_name);
                    if numTemp > 0 then
                      varWhereCond := varWhereCond || ' and ';
                    end if;

                    varTemp3 := GConst.fncReturnParam(MasterDetail, curFields.fldp_column_name);
                    varWhereCond := varWhereCond || ' ' || curFields.fldp_column_name || ' = ';

                    if curFields.fldp_data_type = 'DATE' then
                        varWhereCond := varWhereCond || ' to_date(' || '''' || substr(varTemp3,1,10) || '''' || ',';
                        varWhereCond := varWhereCond || '''' || 'dd/mm/yyyy' || '''' || ')';
                    elsif curFields.fldp_data_type <> 'NUMBER' then
                        varWhereCond := varWhereCond || '''' || varTemp3 || '''';
                    else
                      varWhereCond := varWhereCond || varTemp3;
                    end if;

                    numTemp := numTemp + 1;

               End Loop;
               GLOG.log_write( 'Confirm changes  where cond '||varWhereCond); 
                insert into TRTRAN100 (CONF_KEY_VALUES,CONF_APPROVAL_STATUS,CONF_APPROVAL_REMARKS,CONF_ENTITY_NAME,CONF_USER_ID,CONF_REJECTED_TIMESTAMP)
                     values (varWhereCond, numCode, varTemp, varEntity, varUserID, TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH24:MI:SS:FF3'));
         end if;
    end if;

--   if varEntity!='SCANNEDIMAGES' then
--        varOperation := 'Update Reference number for the Document Attached';
--        begin
--           varOperation := 'Extracting Document GUID number';
--           varReference := GConst.fncXMLExtract(xmlTemp, 'SCANNEDIMAGESREFERENCE', varReference);
--        exception 
--          when others then
--            varReference:=' ';
--        end;
--          -- insert into temp values(varReference||varEntity,'ABC');
--        
--        varOperation := ' Document Reference number' ||varReference ;
--        if (varReference !=' ') then 
--          varOperation := ' Extracting Reference Number 2' ||varReference ;
--          --insert into temp values(varReference||varOperation,'ROW2'); COMMIT;
--           select FLDP_COLUMN_NAME 
--             into varTemp
--           from trsystem999
--            where FLDP_TABLE_SYNONYM = varEntity 
--             and nvl(FLDP_KEY_NO,0) >= 1
--             and FLDP_DATA_TYPE in ('VARCHAR2','NUMBER')
--             and rownum=1
--             order by nvl(FLDP_KEY_NO,999);
--       
--       BEGIN
--           varOperation := ' Extracting Serial Number for '  ;      
--          select FLDP_COLUMN_NAME 
--             into varTemp1
--           from trsystem999
--            where FLDP_TABLE_SYNONYM = varEntity 
--             and nvl(FLDP_KEY_NO,0) >= 1
--             and FLDP_DATA_TYPE ='NUMBER'  
--             and rownum=1;
--             varTemp1:=  GConst.fncXMLExtract(xmlTemp, varTemp1, varReference);
--             EXCEPTION
--              when others then
--            varTemp1:=0;
--        end;
--    --         insert into temp values(varReference,varTemp1);
--      --  commit; 
--           varOperation := 'Extract Reference number for ' || varTemp   ;   
--           varTemp:=  GConst.fncXMLExtract(xmlTemp,varTemp, varReference);
--    --       varOperation := 'Extract Reference number for ' || varTemp1   ;   
--        
--      --       insert into temp values(varReference,varTemp);
--      --  commit; 
--           varOperation := 'Update Reference number in Document Table ' || varTemp1   ;   
--           update tftran101 set IMAG_DOCUMENT_REFERENCE = varTemp
--             -- IMAG_DOCUMENT_SERIAL=varTemp1
--            where IMAG_REFERENCE_NUMBER= varReference;
--             
--        end if;
--    
--   end if;

if varEntity!='SCANNEDIMAGES' then
        varOperation := 'Update Reference number for the Document Attached';
        begin
           varOperation := 'Extracting Document GUID number';
           varReference := GConst.fncXMLExtract(xmlTemp, 'SCANNEDIMAGESREFERENCE', varReference);
        exception 
          when others then
            varReference:=' ';
        end;
          -- insert into temp values(varReference||varEntity,'ABC');

        varOperation := ' Document Reference number' ||varReference ;
       if (varReference !=' ') then 
       varTemp1:=null;
       FOR CurL in (select FLDP_COLUMN_NAME CName,FLDP_DATA_TYPE dataType
           from trsystem999
            where FLDP_TABLE_SYNONYM = varEntity 
             and upper(FLDP_COLUMNS_FORIMAGE)=upper('DocumentReference')
             and FLDP_KEY_NO>0
             order by nvl(FLDP_KEY_NO,999))
       loop
           varOperation := ' Extracting Information' ||varReference ;
            varTemp:=  GConst.fncXMLExtract(xmlTemp,CurL.CName, varReference);
            if (CurL.dataType='DATE') then 
               datTemp:=  GConst.fncXMLExtract(xmlTemp,CurL.CName, datTemp);
               varTemp:=to_char(datTemp,'YYYYMMDD');
            end if;
            -- this is to Check for the First Time 
            if varTemp1 is not null then
                varTemp1:=varTemp1 || ',' || varTemp;
            else 
                varTemp1:=varTemp;
            end if;
       end loop;
-- incase if there is no Document Reference is Configured then it will take the Key Value to 
-- to populate the reference
       if varTemp1 is null then
           FOR CurL in (select FLDP_COLUMN_NAME CName,FLDP_DATA_TYPE dataType
               from trsystem999
                where FLDP_TABLE_SYNONYM = varEntity 
                 --and upper(FLDP_COLUMNS_FORIMAGE)=upper('DocumentReference')
                 and FLDP_KEY_NO>0
                 order by nvl(FLDP_KEY_NO,999))
           loop
               varOperation := ' Extracting Information' ||varReference ;
                varTemp:=  GConst.fncXMLExtract(xmlTemp,CurL.CName, varReference);
                if (CurL.dataType='DATE') then 
                   datTemp:=  GConst.fncXMLExtract(xmlTemp,CurL.CName, datTemp);
                   varTemp:=to_char(datTemp,'YYYYMMDD');
                end if;
                -- this is to Check for the First Time 
                if varTemp1 is not null then
                    varTemp1:=varTemp1 || ',' || varTemp;
                else 
                    varTemp1:=varTemp;
                end if;
           end loop;
        end if;


--          varOperation := ' Extracting Reference Number 2' ||varReference ;
--          --insert into temp values(varReference||varOperation,'ROW2'); COMMIT;
--           select FLDP_COLUMN_NAME 
--             into varTemp
--           from trsystem999
--            where FLDP_TABLE_SYNONYM = varEntity 
--             and nvl(FLDP_KEY_NO,0) >= 1
--             and FLDP_DATA_TYPE in ('VARCHAR2','NUMBER')
--             and rownum=1
--             order by nvl(FLDP_KEY_NO,999);
--       
--       BEGIN
--           varOperation := ' Extracting Serial Number for '  ;      
--          select FLDP_COLUMN_NAME 
--             into varTemp1
--           from trsystem999
--            where FLDP_TABLE_SYNONYM = varEntity 
--             and nvl(FLDP_KEY_NO,0) >= 1
--             and FLDP_DATA_TYPE ='NUMBER'  
--             and rownum=1;
--             varTemp1:=  GConst.fncXMLExtract(xmlTemp, varTemp1, varReference);
--             EXCEPTION
--              when others then
--            varTemp1:=0;
--        end;


    --         insert into temp values(varReference,varTemp1);
      --  commit; 
--           varOperation := 'Extract Reference number for ' || varTemp   ;   
--           varTemp:=  GConst.fncXMLExtract(xmlTemp,varTemp, varReference);
    --       varOperation := 'Extract Reference number for ' || varTemp1   ;   

      --       insert into temp values(varReference,varTemp);
      --  commit; 
           varOperation := 'Update Reference number in Document Table ' || varTemp1   ;   
           update tftran101 set IMAG_DOCUMENT_REFERENCE = varTemp1
             -- IMAG_DOCUMENT_SERIAL=varTemp1
            where IMAG_REFERENCE_NUMBER= varReference;

        end if;

   end if;
     Commit; 


   varOperation:= 'Calling DML Alert';
    prcDMLAlert(clbTemp);

   varOperation:= 'Calling Due Date Alert';
    pkgRiskValidation.prcDueDateAlert(12400002);

   varOperation:= 'Calling Risk Alerts'; 
   begin
    select nvl(EINF_RISK_VALIDATION,12400002)
      into numCode1
     from trsystem995 
     where einf_entity_name=varEntity
     and einf_record_status not in (10200005,10200006);
   exception
    when others then
        varOperation:= 'incase if you there is not entity in 995 then '; 
        numCode1 := 12400002;
   end; 




     if numCode1=12400001 then 
        varOperation:= 'Calling Risk Alerts for Entity ' || varEntity ; 
        PKGRISKVALIDATION.prcRiskPopulateNew(trunc(sysdate),null);
     end if;  

       begin
          select FLDS_TABLE_SYNONYM 
                   into varSubtable
                   from trsystem999_sub
                    where FLDS_TABLE_SYNONYM=varEntity;
        exception
        when others then
        varSubtable :=null;
        end;
   
       begin           
         if varSubtable is not null then
           Misc_subProcess(clbTemp);
        end if;
         exception
            when others then
            numError := '';
            end;

   --PRC_ADD_REMITTANCE_PAYMENT_DATA;




    numError := 0;

    xmlDom.freeDocument(docOld);
    xmlDom.freeDocument(docFinal);
    xmlDom.freeDocument(docTemp);

    ErrorNumber := numError;
    return clbTemp;

    Exception
     when raiseerrorexp then
        rollback;
        ErrorNumber := numError;

      varError := GConst.fncReturnError('MasterMaintain', numError, varMessage,
                      varOperation, varError);
        raise_application_error(-20801,varError);
        return clbTemp;
    When others then
      numError := SQLCODE;
      ErrorNumber := numError;
      varError := SQLERRM;
      varError := GConst.fncReturnError('MasterMaintain', numError, varMessage,
                      varOperation, varError);
       GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncMasterMaintenance');                        

      raise_application_error(-20101, varError);
      return clbTemp;
End fncMasterMaintenance;

--Function fncCompleteUtilization
--    (   ReferenceNumber in varchar2,
--        ReferenceType in number,
--        WorkDate in date,
--        SerialNumber in number default 1)
--    return number
--    is
----  Created on 22/05/08
--    numError            number;
--    numCode             number(8);
--    numAmount           number(15,4);
--    numUtilization      number(15,4);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--Begin
--    numError := 0;
--    varOperation := 'Checking Process Completion for: ' || ReferenceNumber || 'Reverse Type ' || ReferenceType ;
--    numAmount := 0;
--    numUtilization := 0;
--
--    if ReferenceType = GConst.UTILHEDGEDEAL then
--      varOperation := 'Checking Utilization';
--      select deal_base_amount, deal_hedge_trade
--        into numAmount, numCode
--        from trtran001
--        where deal_deal_number = ReferenceNumber
--         and deal_record_status in
--          (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
--
--      select NVL(sum(cdel_cancel_amount),0)
--        into numUtilization
--        from trtran006
--        where cdel_deal_number = ReferenceNumber
--        and cdel_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
--
--      if numAmount = numUtilization then
--          update trtran001
--            set deal_process_complete = GConst.OPTIONYES,
--            deal_complete_date = WorkDate
--            --deal_record_status = GConst.STATUSCOMPLETED
--           --deal_record_status = GConst.STATUSPOSTCANCEL
--            where deal_deal_number = ReferenceNumber;
--
--           if numCode = GConst.HEDGEDEAL and numAmount = numUtilization then
--            update trtran004
--              set hedg_record_status = GConst.STATUSPOSTCANCEL
--              where hedg_deal_number = ReferenceNumber;
--          end if;
--      else
--          update trtran001
--            set deal_process_complete = GConst.OPTIONNO,
--            deal_complete_date = NULL
--            where deal_deal_number = ReferenceNumber;
--
----        update trtran001
----          set deal_record_status = GConst.STATUSCOMPLETED
----          where deal_deal_number = ReferenceNumber;
--      end if;
--
--    elsif ReferenceType = GConst.UTILFCYLOAN then
--      varOperation := 'Checking Utilization';
--      select fcln_sanctioned_fcy
--        into numAmount
--        from trtran005
--        where fcln_loan_number = ReferenceNumber;
--
--      select NVL(sum(trln_adjusted_fcy),0)
--        into numUtilization
--        from trtran007
--        where trln_loan_number = ReferenceNumber
--        and trln_serial_number > 0
--        and trln_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--      varOperation := 'Updating process complete status for Loan';
--      if numAmount = numUtilization then
--        update trtran005
--          set fcln_process_complete = GConst.OPTIONYES,
--          fcln_complete_date = WorkDate
--          where fcln_loan_number = ReferenceNumber;
--      else
--        update trtran005
--          set fcln_process_complete = GConst.OPTIONNO,
--          fcln_complete_date = NULL
--          where fcln_loan_number = ReferenceNumber;
--
----        update trtran005
----          set fcln_record_status = GConst.STATUSCOMPLETED
----          where fcln_loan_number = ReferenceNumber;
--      end if;
--------------- FOR TOI and Newsprint TMM 26/01/14 Checking status inactive-------------------------
--    elsif ReferenceType in (GConst.UTILEXPORTS,GConst.UTILPURCHASED,GConst.UTILCOLLECTION,
--                             GConst.UTILIMPORTS,GConst.UTILIMPORTBILL) then
--      select trad_trade_fcy
--        into numAmount
--        from trtran002
--        where trad_trade_reference = ReferenceNumber
--         and trad_record_status in
--              (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
--
--      select NVL(sum(brel_reversal_fcy),0)
--        into numUtilization
--        from trtran003
--        where brel_trade_reference = ReferenceNumber
--        and brel_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
--
--      varOperation := 'Updating process complete status';
--      if numAmount = numUtilization then
--        update trtran002
--          set trad_process_complete = GConst.OPTIONYES,
--          trad_complete_date = WorkDate
--          where trad_trade_reference = ReferenceNumber;
--      else
--        update trtran002
--          set trad_process_complete = GConst.OPTIONNO,
--          trad_complete_date = null
--          where trad_trade_reference = ReferenceNumber;
--      end if;
--
--    elsif ReferenceType in (Gconst.UTILCOMMODITYDEAL) then
--      select cmdl_lot_numbers
--        into numamount
--        from trtran051
--        where cmdl_deal_number= ReferenceNumber;
--
--      select crev_reverse_lot
--        into numUtilization
--        from trtran053
--        where crev_deal_number= ReferenceNumber
--        and crev_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      if numAmount = numUtilization then
--        update trtran051
--          set cmdl_process_complete=GConst.OPTIONYES,
--          cmdl_complete_date = WorkDate
--          where cmdl_deal_number=ReferenceNumber;
--      else
--        update trtran051
--          set cmdl_process_complete=GConst.OPTIONNO,
--          cmdl_complete_date = null
--          where cmdl_deal_number=ReferenceNumber;
--      end if;
--
--    elsif ReferenceType in (Gconst.UTILBCRLOAN) then
--      varOperation := 'Extracting Buyers Credit Loan Amount ';
--      select bcrd_sanctioned_fcy
--        into numAmount
--        from trtran045
--        where bcrd_buyers_credit = ReferenceNumber;
--
--       select sum(brel_reversal_fcy)
--         into numUtilization
--         from trtran003
--         where brel_trade_reference = ReferenceNumber
--         and brel_record_status in(GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
--
--      varOperation := 'Checking for Buyers Credit Loan closure';
--      if numAmount = numUtilization then
--          update trtran045
--            set bcrd_process_complete = GConst.OPTIONYES,
--            bcrd_completion_date = WorkDate
--            where bcrd_buyers_credit = ReferenceNumber;
--      else
--          update trtran045
--            set bcrd_process_complete = GConst.OPTIONNO,
--            bcrd_completion_date = null
--            Where bcrd_buyers_credit = Referencenumber;
--       end if;
--
-- --Commented aakash 17-May-13 11:03 am
--
----    elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
----     VarOperation :='getting otion hedge deal base amount';
----     begin
----      select copt_base_amount
----        into numamount
----        from trtran071
----        where copt_deal_number= ReferenceNumber
----        and copt_serial_number =SerialNumber;
----     exception
----     when no_data_found then
----       numamount:=0;
----     end;
----     VarOperation :='getting otion hedge deal utlization amount';
----     begin
----      select sum(corv_base_amount)
----        into numUtilization
----        from trtran073
----        where corv_deal_number= ReferenceNumber
----      --  and corv_serial_number =SerialNumber
----        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
----      exception
----      when no_data_found then
----         numUtilization:=0;
----      end;
----      if numAmount <= numUtilization then
----        update trtran071
----          set copt_process_complete=GConst.OPTIONYES,
----          copt_complete_date = WorkDate
----          where copt_deal_number=ReferenceNumber;
----
----         update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
----                cosu_complete_date =workDate
----          where cosu_deal_number =ReferenceNumber;
----          --and copt_serial_number= SerialNumber;
----      else
----        update trtran071
----          set copt_process_complete=GConst.OPTIONNO,
----          copt_complete_date = null
----          where copt_deal_number=ReferenceNumber;
----
----        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
----                cosu_complete_date =null
----          where cosu_deal_number =ReferenceNumber;
----          --and copt_Serial_number= SerialNumber;
----      end if;
----end
----added by aakash/gouri 17-May-13 11:03 am
--elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
--VarOperation :='getting option hedge deal base amount';
--     Begin
--      select copt_base_amount
--        into numamount
--        from trtran071
--        Where Copt_Deal_Number= Referencenumber
--       -- and copt_serial_number =SerialNumber;
--         and copt_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--     exception
--     when no_data_found then
--       numamount:=0;
--     end;
--     VarOperation :='getting option hedge deal utlization amount';
--     begin
--      Select Sum(Corv_Base_Amount)
--        into numUtilization
--        from trtran073
--        where corv_deal_number= ReferenceNumber
--      --  and corv_serial_number =SerialNumber
--        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      exception
--      when no_data_found then
--         numUtilization:=0;
--      End;
--      if numAmount = numUtilization then
--        update trtran071
--          set copt_process_complete=GConst.OPTIONYES,
--          copt_complete_date = WorkDate
--          where copt_deal_number=ReferenceNumber;
--
--         update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
--                cosu_complete_date =workDate
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_serial_number= SerialNumber;
--      else
--        update trtran071
--          set copt_process_complete=GConst.OPTIONNO,
--          copt_complete_date = null
--          where copt_deal_number=ReferenceNumber;
--
--        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
--                cosu_complete_date =null
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_Serial_number= SerialNumber;
--      end if;
----end
--
--    elsif ReferenceType in (Gconst.UTILFUTUREDEAL) then
--      select cfut_lot_numbers
--        into numamount
--        from trtran061
--        where cfut_deal_number= ReferenceNumber
--        and cfut_record_status not in(10200005,10200006);
--
--      select nvl(sum(cfrv_reverse_lot),0)
--        into numUtilization
--        from trtran063
--        where cfrv_deal_number= ReferenceNumber
--        and cfrv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      if numAmount = numUtilization then
--        update trtran061
--          set cfut_process_complete=GConst.OPTIONYES,
--          cfut_complete_date = WorkDate
--          where cfut_deal_number=ReferenceNumber;
--      else
--        update trtran061
--          set cfut_process_complete=GConst.OPTIONNO,
--          cfut_complete_date = null
--          where cfut_deal_number=ReferenceNumber;
--      end if;
--
--
--    end if;
--
--
--    return numError;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := GConst.fncReturnError('CompleteUtil', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return numError;
--End fncCompleteUtilization;


---new update by Manjunath sir as on 22042014
Function fncCompleteUtilization
    (   ReferenceNumber in varchar2,
        ReferenceType in number,
        WorkDate in date,
        SerialNumber in number default 1,
        SubSerialNumber in number default 1)
    return number
    is
--  Created on 22/05/08
    numError            number;
    numFlag             number(1);
    numCode             number(8);
    numAmount           number(15,2);
    numCode1            number(8);
    numCode2            number(8);
    numUtilization      number(15,2);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
Begin
    numError := 0;
    varOperation := 'Checking Process Completion for: ' || ReferenceNumber || 'Reverse Type ' || ReferenceType ;
    numAmount := 0;
    numUtilization := 0;

    if ReferenceType = Gconst.UTILHEDGEDEAL then
      varOperation := 'Checking Utilization 1';
      select (case when CNDI_DIRECT_INDIRECT=12400001 then deal_base_amount else deal_other_amount end),
           deal_hedge_trade
        into numAmount, numCode
        from trtran001 inner join trmaster256
         on deal_currency_pair=CNDI_PICK_CODE
         and cndi_record_Status not in (10200005,10200006)
        where deal_deal_number = ReferenceNumber
         and deal_record_status in
          (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
varOperation := 'Checking Utilization 2';
      select sum(case when CNDI_DIRECT_INDIRECT=12400001 then CDEL_CANCEL_AMOUNT else CDEL_OTHER_AMOUNT end)
        into numUtilization
        from trtran006 inner join trtran001
         on cdel_deal_number= deal_deal_number
         inner join trmaster256
         on deal_currency_pair=CNDI_PICK_CODE
         and cndi_record_Status not in (10200005,10200006)
        where cdel_deal_number = ReferenceNumber
        and deal_record_status not in (10200005,10200006)
        and cdel_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
varOperation := 'Checking Utilization 3';
      if numAmount = numUtilization then
          update trtran001
            set deal_process_complete = GConst.OPTIONYES,
            deal_complete_date = WorkDate
            --deal_record_status = GConst.STATUSCOMPLETED
           --deal_record_status = GConst.STATUSPOSTCANCEL
            where deal_deal_number = ReferenceNumber;
varOperation := 'Checking Utilization 4';
           if numCode = GConst.HEDGEDEAL and numAmount = numUtilization then
            UPDATE trtran004
              SET hedg_record_status = 10200010--GConst.STATUSDELETED
              where hedg_deal_number = ReferenceNumber;
          end if;
      else
      varOperation := 'Checking Utilization 5';
          update trtran001
            set deal_process_complete = GConst.OPTIONNO,
            deal_complete_date = NULL
            where deal_deal_number = ReferenceNumber;

--        update trtran001
--          set deal_record_status = GConst.STATUSCOMPLETED
--          where deal_deal_number = ReferenceNumber;
      end if;

    elsif ReferenceType = Gconst.UTILFCYLOAN then
      varOperation := 'Checking Utilization 6';
      select fcln_sanctioned_fcy
        into numAmount
        from trtran005
        where fcln_loan_number = ReferenceNumber;

      select NVL(sum(trln_adjusted_fcy),0)
        into numUtilization
        from trtran007
        where trln_loan_number = ReferenceNumber
        and trln_serial_number > 0
        and trln_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

      varOperation := 'Updating process complete status for Loan';
      if numAmount = numUtilization then
        update trtran005
          set fcln_process_complete = GConst.OPTIONYES,
          fcln_complete_date = WorkDate
          where fcln_loan_number = ReferenceNumber;
      else
        update trtran005
          set fcln_process_complete = GConst.OPTIONNO,
          fcln_complete_date = NULL
          where fcln_loan_number = ReferenceNumber;

--        update trtran005
--          set fcln_record_status = GConst.STATUSCOMPLETED
--          where fcln_loan_number = ReferenceNumber;
      end if;
------------- FOR TOI and Newsprint TMM 26/01/14 Checking status inactive-------------------------
    elsif ReferenceType in (Gconst.UTILEXPORTS,Gconst.UTILPURCHASED,Gconst.UTILCOLLECTION,
                             Gconst.UTILIMPORTS,Gconst.UTILIMPORTBILL) then
    begin
      select trad_trade_fcy
        into numAmount
        from trtran002
        where trad_trade_reference = ReferenceNumber
         and trad_record_status in
              (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
    exception
     when no_data_found then 
        numAmount:=0;
     end ;

     begin
      select NVL(sum(brel_reversal_fcy),0)
        into numUtilization
        from trtran003
        where brel_trade_reference = ReferenceNumber
        and brel_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
     exception 
       when no_Data_found then 
        numUtilization :=0;
     end ;

      varOperation := 'Updating process complete status';
      if numAmount = numUtilization then
        update trtran002
          set trad_process_complete = GConst.OPTIONYES,
          trad_complete_date = WorkDate
          where trad_trade_reference = ReferenceNumber;
      else
        update trtran002
          set trad_process_complete = GConst.OPTIONNO,
          trad_complete_date = null
          where trad_trade_reference = ReferenceNumber;
      end if;

--    elsif ReferenceType in (Gconst.UTILCOMMODITYDEAL) then
--      select cmdl_lot_numbers
--        into numamount
--        from trtran051
--        where cmdl_deal_number= ReferenceNumber;
--
--      select crev_reverse_lot
--        into numUtilization
--        from trtran053
--        where crev_deal_number= ReferenceNumber
--        and crev_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      if numAmount = numUtilization then
--        update trtran051
--          set cmdl_process_complete=GConst.OPTIONYES,
--          cmdl_complete_date = WorkDate
--          where cmdl_deal_number=ReferenceNumber;
--      else
--        update trtran051
--          set cmdl_process_complete=GConst.OPTIONNO,
--          cmdl_complete_date = null
--          where cmdl_deal_number=ReferenceNumber;
--      end if;
--
--    elsif ReferenceType in (Gconst.UTILBCRLOAN) then
--      varOperation := 'Extracting Buyers Credit Loan Amount ';
--      Begin
--        numFlag := 0;
--    
--        select nvl(sum(bcrd_sanctioned_fcy),0)
--          into numAmount
--          from trtran045
--          where bcrd_buyers_credit = ReferenceNumber;
--      Exception
--        when no_data_found then
--          numFlag := 1;
--        
--          select nvl(sum(trad_trade_fcy),0)
--            into numAmount
--            from trtran002
--            where trad_trade_reference = ReferenceNumber;
--      End;
--
--       select nvl(sum(brel_reversal_fcy),0)
--         into numUtilization
--         from trtran003
--         where brel_trade_reference = ReferenceNumber
--         and brel_record_status in(GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
--
--      varOperation := 'Checking for Buyers Credit Loan closure';
--      if numAmount = numUtilization then
--        if numFlag = 0 then
--          update trtran045
--            set bcrd_process_complete = GConst.OPTIONYES,
--            bcrd_completion_date = WorkDate
--            where bcrd_buyers_credit = ReferenceNumber;
--        else
--          update trtran002
--            set trad_process_complete = GConst.OPTIONYES,
--            trad_complete_date = WorkDate
--            where trad_trade_reference = ReferenceNumber;
--        end if;
--      else
--        if numFlag = 0 then
--          update trtran045
--            set bcrd_process_complete = GConst.OPTIONNO,
--            bcrd_completion_date = null
--            Where bcrd_buyers_credit = Referencenumber;
--        else
--          update trtran002
--            set trad_process_complete = GConst.OPTIONNO,
--            trad_complete_date =  null
--            where trad_trade_reference = ReferenceNumber;
--        end if;
--
--       end if;

 --Commented aakash 17-May-13 11:03 am

--    elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
--     VarOperation :='getting otion hedge deal base amount';
--     begin
--      select copt_base_amount
--        into numamount
--        from trtran071
--        where copt_deal_number= ReferenceNumber
--        and copt_serial_number =SerialNumber;
--     exception
--     when no_data_found then
--       numamount:=0;
--     end;
--     VarOperation :='getting otion hedge deal utlization amount';
--     begin
--      select sum(corv_base_amount)
--        into numUtilization
--        from trtran073
--        where corv_deal_number= ReferenceNumber
--      --  and corv_serial_number =SerialNumber
--        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      exception
--      when no_data_found then
--         numUtilization:=0;
--      end;
--      if numAmount <= numUtilization then
--        update trtran071
--          set copt_process_complete=GConst.OPTIONYES,
--          copt_complete_date = WorkDate
--          where copt_deal_number=ReferenceNumber;
--
--         update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
--                cosu_complete_date =workDate
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_serial_number= SerialNumber;
--      else
--        update trtran071
--          set copt_process_complete=GConst.OPTIONNO,
--          copt_complete_date = null
--          where copt_deal_number=ReferenceNumber;
--
--        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
--                cosu_complete_date =null
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_Serial_number= SerialNumber;
--      end if;
--end
--added by aakash/gouri 17-May-13 11:03 am
elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
VarOperation :='getting option hedge deal base amount';
     Begin
      select copt_base_amount,OPTI_UNWIND_LEGWISE
        into numamount,numCode1
        from trtran071 inner join trmaster323
        on OPTI_PICK_CODE=COPT_DEAL_TYPE
        and OPTI_RECORD_status not in (10200005,10200006)
        Where Copt_Deal_Number= Referencenumber
       -- and copt_serial_number =SerialNumber;
         and copt_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
     exception
     when no_data_found then
       numamount:=0;
     end;
     VarOperation :='getting option hedge deal utlization amount';
     begin
      Select Sum(Corv_Base_Amount)
        into numUtilization
        from trtran073
        where corv_deal_number= ReferenceNumber
      --  and corv_serial_number =SerialNumber
        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
      exception
      when no_data_found then
         numUtilization:=0;
      End;
      if numAmount = numUtilization then
         if numCode1=12400001 then 
            update trtran072A set COSM_PROCESS_COMPLETE=GConst.OPTIONYES,
                   COSM_complete_date = WorkDate
            where COSM_DEAL_NUMBER=ReferenceNumber
              and COSM_SERIAL_NUMBER= SerialNumber
              and COSM_SUBSERIAL_NUMBER=subserialNumber;
        end if; 

        begin 
        select nvl(count(*),0)
          into numCode2
        from trtran072A 
        where COSM_PROCESS_COMPLETE=GConst.OPTIONNO
          and COSM_RECORD_STATUS not in (10200005,10200006);
        exception
          when no_data_found then
             numCode2:=0;
        end;

         IF ((numCode1=12400002) or (numCode2=0)) then
                update trtran072A set COSM_PROCESS_COMPLETE=GConst.OPTIONYES,
                       COSM_complete_date = WorkDate
                where COSM_DEAL_NUMBER=ReferenceNumber;

                 update trtran071 set copt_process_complete=GConst.OPTIONYES,
                      copt_complete_date = WorkDate
                      where copt_deal_number=ReferenceNumber;

                update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
                    cosu_complete_date =workDate
                where cosu_deal_number =ReferenceNumber;
          END IF;

      else
        update trtran071
          set copt_process_complete=GConst.OPTIONNO,
          copt_complete_date = null
          where copt_deal_number=ReferenceNumber;

        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
                cosu_complete_date =null
          where cosu_deal_number =ReferenceNumber;

        update trtran072A set COSM_PROCESS_COMPLETE=GConst.OPTIONNO,
                   COSM_complete_date = null
            where COSM_DEAL_NUMBER=ReferenceNumber
              and COSM_SERIAL_NUMBER= SerialNumber
              and COSM_SUBSERIAL_NUMBER=subserialNumber;   
          --and copt_Serial_number= SerialNumber;
      end if;
--end

    elsif ReferenceType in (GCONST.UTILFUTUREDEAL) then
      select cfut_lot_numbers
        into numamount
        from trtran061
        where cfut_deal_number= ReferenceNumber
        and cfut_record_status not in(10200005,10200006);

      select nvl(sum(cfrv_reverse_lot),0)
        into numUtilization
        from trtran063
        where cfrv_deal_number= ReferenceNumber
        and cfrv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
      if numAmount = numUtilization then
        update trtran061
          set cfut_process_complete=GConst.OPTIONYES,
          cfut_complete_date = WorkDate
          where cfut_deal_number=ReferenceNumber;
      else
        update trtran061
          set cfut_process_complete=GConst.OPTIONNO,
          cfut_complete_date = null
          where cfut_deal_number=ReferenceNumber;
      end if;

--   elsif ReferenceType in (Gconst.UTILMUTUALFUND) then
--     VarOperation := 'Update the Process Complete for the Mutual Funds';
--
--      select sum(MFTR_TRANSACTION_Quantity)
--       into numamount
--        from trtran048
--      where mftr_reference_number =ReferenceNumber
--        and mftr_record_status not in (10200005,10200006);
--
--      select sum(MFcl_TRANSACTION_Quantity)
--        into numUtilization
--        from trtran049
--       where mfcl_reference_number =ReferenceNumber
--         and mfcl_record_status not in (10200005,10200006);
--
--      if numAmount = numUtilization then
--        update trtran048
--          set mftr_process_complete=GConst.OPTIONYES,
--              mftr_complete_date = WorkDate
--          where mftr_reference_number=ReferenceNumber;
--      else
--        update trtran048
--          set mftr_process_complete=GConst.OPTIONNO,
--              mftr_complete_date = null
--          where mftr_reference_number=ReferenceNumber;
--      end if;
--   elsif ReferenceType in (Gconst.UTILFIXEDDEPOSIT) then
--     VarOperation := 'Update the Process Complete to Fixed deposit';
--
--       select sum(FDRF_DEPOSIT_AMOUNT)
--         into numamount
--        from trtran047
--      where FDRF_FD_NUMBER =ReferenceNumber
--        and FDRF_SR_NUMBER=SerialNumber
--        and FDRF_record_status not in (10200005,10200006);
--
--      select sum(FDCL_DEPOSIT_AMOUNT)
--        into numUtilization
--        from trtran047a
--       where FDCL_FD_number =ReferenceNumber
--       and FDCL_SR_NUMBER=SerialNumber
--         and FDCL_record_status not in (10200005,10200006);
--
--      if numAmount = numUtilization then
--        update trtran047
--          set FDRF_process_complete=GConst.OPTIONYES,
--              FDRF_complete_date = WorkDate
--          where FDRF_FD_NUMBER=ReferenceNumber
--             and FDRF_SR_NUMBER=SerialNumber;
--      else
--          update trtran047
--          set FDRF_process_complete=GConst.OPTIONNO,
--              FDRF_complete_date = null
--          where FDRF_FD_NUMBER=ReferenceNumber
--             and FDRF_SR_NUMBER=SerialNumber;
--      end if;
--   elsif ReferenceType in (Gconst.UTILFRA) then 
--   
--     VarOperation := 'Update the Process Complete for FRA';
--       select sum(IFRA_NOTIONAL_AMOUNT)
--         into numamount
--        from trtran090
--      where IFRA_FRA_NUMBER =ReferenceNumber
--       -- and FDRF_SR_NUMBER=SerialNumber
--        and IFRA_record_status not in (10200005,10200006);
--
--      select sum(IFRS_NOTIONAL_AMOUNT)
--         into numUtilization
--        from trtran090a
--      where IFRS_FRA_NUMBER =ReferenceNumber
--       -- and FDRF_SR_NUMBER=SerialNumber
--        and IFRS_record_status not in (10200005,10200006);
--        
--     if numAmount >= numUtilization then
--        update trtran090
--          set IFRA_process_complete=GConst.OPTIONYES,
--              IFRA_complete_date = WorkDate
--          where IFRA_FRA_NUMBER=ReferenceNumber;
--      else
--        update trtran090
--          set IFRA_process_complete=GConst.OPTIONNO,
--              IFRA_complete_date = null
--          where IFRA_FRA_NUMBER=ReferenceNumber;
--      end if;      
   end if;


    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('CompleteUtil', numError, varMessage,
                      varOperation, varError);
      GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncCompleteUtilization');                   
      raise_application_error(-20101, varError);
      return numError;
End fncCompleteUtilization;

Function FNCGENERATERELATION
(         MAINENTITY IN NUMBER,
          ENTITYRELATION IN NUMBER,
          ACTION IN NUMBER)
          RETURN NUMBER          
          is  

        numError            number;
        varOperation        GConst.gvarOperation%Type;
        varMessage          GConst.gvarMessage%Type;
        varError            GConst.gvarError%Type;
         numSerial           number(5):=0;
BEGIN
  varOperation:= 'Miscellanious update for mater.';
  varMessage := 'Updating Relation table';
  GLOG.log_write( 'Parameters for  FNCGENERATERELATION ' || MAINENTITY || ENTITYRELATION || ACTION ); 
  numError := 0;

   IF ACTION in (GConst.ADDSAVE) then

   GLOG.log_write(' Checking for the Serial Number in Add load also because some cases we are deleting and Adding the Data');
     begin
      SELECT COUNT(*)
      INTO numSerial 
      FROM TRSYSTEM008 
      WHERE EREL_MAIN_ENTITY=MAINENTITY
      AND EREL_ENTITY_RELATION = ENTITYRELATION
      and EREL_ENTITY_TYPE=SUBSTR(MAINENTITY,1,3)
     and EREL_RELATION_TYPE=SUBSTR(ENTITYRELATION,1,3);
    Exception
              When no_data_found then
              numSerial := 0;
   End;   

    Insert into TRSYSTEM008
     (EREL_COMPANY_CODE,EREL_MAIN_ENTITY,EREL_ENTITY_RELATION,EREL_ENTITY_TYPE,
       EREL_RELATION_TYPE,EREL_CREATE_DATE,EREL_ADD_DATE,EREL_ENTRY_DETAIL,EREL_RECORD_STATUS,erel_serial_number) 
    values(30199999,MAINENTITY,ENTITYRELATION,SUBSTR(MAINENTITY,1,3),
      SUBSTR(ENTITYRELATION,1,3),sysdate,sysdate,null,10200001,numSerial+1);

  ELSIF ACTION in (GConst.EDITSAVE) then

  begin
      SELECT COUNT(*)
      INTO numSerial 
      FROM TRSYSTEM008 
      WHERE EREL_MAIN_ENTITY=MAINENTITY
      AND EREL_ENTITY_RELATION = ENTITYRELATION
      and EREL_ENTITY_TYPE=SUBSTR(MAINENTITY,1,3)
     and EREL_RELATION_TYPE=SUBSTR(ENTITYRELATION,1,3);
    Exception
              When no_data_found then
              numSerial := 0;
   End;   

   GLOG.log_write( 'edit ' || numserial ); 
  varOperation:= 'updating record status.';
     Update TRSYSTEM008 SET EREL_RECORD_STATUS = 10200006  
     WHERE EREL_ENTITY_RELATION = ENTITYRELATION 
     --AND EREL_MAIN_ENTITY= MAINENTITY
     and EREL_ENTITY_TYPE=SUBSTR(MAINENTITY,1,3)
     and EREL_RELATION_TYPE=SUBSTR(ENTITYRELATION,1,3)
     AND EREL_RECORD_STATUS NOT IN (10200005,10200006);

    varOperation:= 'Inserting record .';
   Insert into TRSYSTEM008(EREL_COMPANY_CODE,EREL_MAIN_ENTITY,EREL_ENTITY_RELATION,EREL_ENTITY_TYPE,
             EREL_RELATION_TYPE,EREL_CREATE_DATE,EREL_ADD_DATE,EREL_ENTRY_DETAIL,EREL_RECORD_STATUS,EREL_SERIAL_NUMBER) 
       values(30199999,MAINENTITY,ENTITYRELATION,SUBSTR(MAINENTITY,1,3),SUBSTR(ENTITYRELATION,1,3),
             sysdate,sysdate,null,10200001,numSerial+1);


  ELSIF ACTION in (GConst.DELETESAVE) then
    Update TRSYSTEM008
    SET EREL_RECORD_STATUS = 10200006
    WHERE EREL_ENTITY_RELATION = ENTITYRELATION 
     AND EREL_MAIN_ENTITY= MAINENTITY
     and EREL_ENTITY_TYPE=SUBSTR(MAINENTITY,1,3)
     and EREL_RELATION_TYPE=SUBSTR(ENTITYRELATION,1,3)
     AND EREL_RECORD_STATUS NOT IN (10200005,10200006);
    END IF;
    RETURN numError;

--  IF ACTION in (GConst.ADDSAVE) then
--    Insert into TRSYSTEM008(EREL_COMPANY_CODE,EREL_MAIN_ENTITY,EREL_ENTITY_RELATION,EREL_ENTITY_TYPE,EREL_RELATION_TYPE,EREL_CREATE_DATE,EREL_ADD_DATE,EREL_ENTRY_DETAIL,EREL_RECORD_STATUS) 
--    values(30199999,MAINENTITY,ENTITYRELATION,SUBSTR(MAINENTITY,1,3),SUBSTR(ENTITYRELATION,1,3),sysdate,sysdate,null,10200001);
--    
--    ELSIF ACTION in (GConst.EDITSAVE) then
--    Update TRSYSTEM008
--    SET EREL_ENTITY_RELATION = ENTITYRELATION   
--    WHERE EREL_ENTITY_RELATION = ENTITYRELATION   
--      AND EREL_MAIN_ENTITY= MAINENTITY
--     and EREL_ENTITY_TYPE=SUBSTR(MAINENTITY,1,3)
--     and EREL_RELATION_TYPE=SUBSTR(ENTITYRELATION,1,3)
--     AND EREL_RECORD_STATUS NOT IN (10200005,10200006);
--    
--    ELSIF ACTION in (GConst.DELETESAVE) then
--    Update TRSYSTEM008
--    SET EREL_RECORD_STATUS = 10200006
--    WHERE EREL_ENTITY_RELATION = ENTITYRELATION 
--     AND EREL_MAIN_ENTITY= MAINENTITY
--     and EREL_ENTITY_TYPE=SUBSTR(MAINENTITY,1,3)
--     and EREL_RELATION_TYPE=SUBSTR(ENTITYRELATION,1,3)
--     AND EREL_RECORD_STATUS NOT IN (10200005,10200006);
--    END IF;
--    RETURN numError;   
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('Relation table ', numError, varMessage,
                          varOperation, varError);
          GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.FNCGENERATERELATION');                   

          raise_application_error(-20101, varError);
          --RETURN numError;   

END FNCGENERATERELATION;

Function forwardSettlement
    (   RecordDetail in GConst.gClobType%Type)
    return number
    is
--  created by TMM on 31/01/2014
    numError            number;
    numTemp             number;
    numAction           number(4);
    numSerial           number(5):=0;
    numLocation         number(8);
    numCompany          number(8);
    numReversal         number(8);
    numImportExport     number(8);    
    numReverseAmount    number(15,2);
    numDealReverse      number(15,2);
    numBillReverse      number(15,2);
    numCashDeal         number(15,2);
    numPandL            number(15,2);
    numFcy              number(15,2);
    numSpot             number(15,6);
    numPremium          number(15,6);
    numMargin           number(15,6);
    numFinal            number(15,6);
    numCashRate         number(15,6);
    varCompany          varchar2(15);
    varEntity           varchar2(25);
    varVoucher          varchar2(25);
    varTradeReference   varchar2(25);
    varDealReference    varchar2(25);
    varReference        varchar2(25);
    varXPath            varchar2(1024);
    varTemp             varchar2(1024);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         Date;
    datReference        Date;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    numLocalBank        number(8);
    numCompanyCode      number(8);
    numReverseSerial    number(5);
    numCurrencyCode     NUMBER(8);
    numTradeSerial      NUMBER(5):=0;
    userID              varchar2(15);
    numBuySell          number(8);
    numLOBCode          number(8);
    numRecordStatus     number(1);
    numRefSerial        number(5);
    numRevSerial        number(5);
    numTemp1            number(5):= 0;
    numintOutlayRate    number(15,6);
    numIntoutlay        number(15,2);
    clbTemp             clob;
    datTemp             date;

  Begin
    varMessage := 'Entering Bill Settlement Process';
    numError := 0;
    numDealReverse := 0;
    numBillReverse := 0;
    numCashDeal := 0;


    varOperation := 'Extracting Parameters';
    xmlTemp := xmlType(RecordDetail);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    Numlocation := Gconst.Fncxmlextract(Xmltemp, 'LocationId', Numlocation);
    userID      := GConst.fncXMLExtract(xmlTemp, 'UserCode', userID);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyId', numCompany);
    varEntity :=  gconst.fncxmlextract(xmltemp, 'CommandSet/Entity', varEntity);


--        numCashRate :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashRate', numCashRate);
--        numCashDeal :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashAmount', numCashDeal); 
--        datReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/ReferenceDate', datReference);  -- Pass this value from XML
--        numBuySell := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BuySell', numBuySell);  -- Pass this value from XML
--        numLocalBank := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BankCode', numLocalBank); 
--        numCurrencyCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CurrencyCode', numCurrencyCode); 
--        numLOBCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/LobCode', numLOBCode); 
--        varTradeReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/TradeReference', varTradeReference); 
--    END IF;

         varOperation := 'Extracting Parameters CurrencyCode ' || numCurrencyCode;
          
        if varEntity = 'BILLREALISATION' then -- LOB code will comming in Main XML only
          numLOBCode := gconst.fncxmlextract(xmltemp, 'BNKC_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'BREL_REALIZATION_NUMBER', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'BREL_INVOICE_NUMBER', varTradeReference);
        elsif varEntity = 'IMPORTREALIZE' then
          numLOBCode := gconst.fncxmlextract(xmltemp, 'SPAY_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'SPAY_SHIPMENT_SERIAL', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'SPAY_SHIPMENT_NUMBER', varTradeReference);
        elsif varEntity = 'IMPORTADVICE' then
          numLOBCode := gconst.fncxmlextract(xmltemp, 'IADP_LOB_CODE', numLOBCode);
          numTradeSerial := 0;
          varTradeReference := gconst.fncxmlextract(xmltemp, 'IADP_ADVANCE_REFERENCE', varTradeReference);
         elsif varEntity = 'LOANCLOSURE' then
          numLOBCode := gconst.fncxmlextract(xmltemp, 'INTC_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'INTC_INTEREST_NUMBER', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'INTC_LOAN_REFERENCE', varTradeReference);
        elsif varEntity = 'PSCFCLOAN' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'INLN_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'INLN_PSLOAN_NUMBER', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'INLN_INVOICE_NUMBER', varTradeReference);
        elsif varEntity = 'PACKINGCREDITAPPLICATION' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'PKCR_LOB_CODE', numLOBCode);
          numTradeSerial := 0;
          varTradeReference := gconst.fncxmlextract(xmltemp, 'PKCR_PKGCREDIT_NUMBER', varTradeReference);     
        elsif varEntity = 'FOREIGNREMITTANCE' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'REMT_LOB_CODE', numLOBCode);
          numTradeSerial := 0;
          varTradeReference := gconst.fncxmlextract(xmltemp, 'REMT_REMITTANCE_REFERENCE', varTradeReference);   
--    GLOG.log_write(' RUNACCOUNTINGPROCESS Before ' || varEntity);
--     elsif varEntity ='RUNACCOUNTINGPROCESS' then
--      GLOG.log_write(' RUNACCOUNTINGPROCESS Started ');
--      if (numAction=GConst.ADDSAVE) then
--      varOperation := ' Calling Procedure prccashfairhedge ' ;  
--      varTemp := GConst.fncXMLExtract(xmlTemp, 'AHPM_AMTM_REFERENCENUMBER', varTemp);
--      datTemp := GConst.fncXMLExtract(xmlTemp, 'AHPM_EFFECTIVE_DATE', datTemp);
--     varReference := GConst.fncXMLExtract(xmlTemp, 'AHPM_REFERENCE_NUMBER', varReference);
--     
--      GLOG.log_write(' AHPM_AMTM_REFERENCENUMBER ' || varTemp ||' AHPM_EFFECTIVE_DATE '|| datTemp ||' AHPM_REFERENCE_NUMBER '||varReference);
----          if varReference is not null then
----          pkgHedgeAccounting.prcCashFairHedge(datTemp,varReference);
----          else
----          pkgHedgeAccounting.prcCashFairHedge(datTemp);
----          end if;
--        if varTemp is not null then
--          pkgHedgeAccounting.RunHedgeAccounting(datTemp,varTemp,varReference);
----          else
----          pkgHedgeAccounting.RunHedgeAccounting(datTemp);
--          end if;
--
--      else
--      clbTemp := fncMiscellaneousUpdates(clbTemp, SYSRUNACCOUNTINGPROCESS, numError);
--      end if;

        elsif varEntity = 'EXPORTADVANCE' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'EADV_LOB_CODE', numLOBCode);
          Numtradeserial := 0;
          Vartradereference := Gconst.Fncxmlextract(Xmltemp, 'EADV_ADVANCE_REFERENCE', Vartradereference);  
        elsif varEntity = 'IRSSETTLEMENT' then 
         -- numLOBCode := gconst.fncxmlextract(xmltemp, 'EADV_LOB_CODE', numLOBCode);
          Numtradeserial := Gconst.Fncxmlextract(Xmltemp, 'IIRM_LEG_SERIAL', Numtradeserial);
          Vartradereference := Gconst.Fncxmlextract(Xmltemp, 'IIRM_IRS_NUMBER', Vartradereference);
          If Numaction=Gconst.Editsave Then
              numAction:=GConst.ADDSAVE ;
              end if;
        end if;

    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);          
    varXPath := '//FORWARDSETTLEMENTS/CASHSETTLEMENT';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    if xmlDom.getLength(nlsTemp) > 0 then

        numCashRate :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashRate', numCashRate);
        numCashDeal :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashAmount', numCashDeal); 
        datReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/ReferenceDate', datReference);  -- Pass this value from XML
        numBuySell := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BuySell', numBuySell);  -- Pass this value from XML
        numLocalBank := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BankCode', numLocalBank); 
        numCurrencyCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CurrencyCode', numCurrencyCode); 
        --numLOBCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/LobCode', numLOBCode); 
       -- varTradeReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/TradeReference', varTradeReference); 

        --end loop;


--        insert into temp values(numBuySell,'chandra1');
--        insert into temp values(numLocalBank,'chandra2');
        varOperation := 'Extracting Parameters Location ' || numLocation;
--        numLocation := nvl(himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLocation),0);--Mapping Required in Trade finance
--            varOperation := 'Extracting Parameters numCompany ' || numCompany;
--        numCompany := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numCompany);
--        varOperation := 'Extracting Parameters numBuySell ' || numBuySell;
--        numBuySell := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numBuySell);
--        numLocalBank := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLocalBank);
--        varOperation := 'Extracting Parameters numCurrencyCode ' || numCurrencyCode;
--        numCurrencyCode := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numCurrencyCode);
--        varOperation := 'Extracting Parameters numLOBCode ' || numLOBCode;
--        numLOBCode := nvl(himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLOBCode),0);--Mapping Required in Trade finance
        varCompany := PKGRETURNCURSOR.fncGetdescription(numCompany,2);
--        docFinal := xmlDom.newDomDocument(xmlTemp);
--        nodFinal := xmlDom.makeNode(docFinal);
        varOperation := 'Checking for Deal Delivery, if any';
        Varxpath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        if xmlDom.getLength(nlsTemp) = 0 then
          GOto Cash_Deal;
        END IF;
    end if;

   --insert into temp values(varXPath,'chandra');
    Varxpath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM]';
   Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
      Varxpath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM="';
     -- insert into temp values(varXPath,'chandra');
    for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
        nodTemp := xmlDom.item(nlsTemp, numSub);
        nmpTemp := xmlDom.getAttributes(nodTemp);
        nodTemp1 := xmlDom.item(nmpTemp, 0);
        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
        varTemp := varXPath || numTemp || '"]/DealNumber';
        varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || numTemp || '"]/SpotRate';
        numSpot := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
        varTemp := varXPath || numTemp || '"]/Premium';
        numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/MarginRate';
        numMargin := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/FinalRate';
        numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
        varTemp := varXPath || numTemp || '"]/ReverseAmount';
        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/RecordStatus';
        numRecordStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/ReverseSerial';
        numRevSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

        varTemp := varXPath || numTemp || '"]/IntoutlayRate';
        numintOutlayRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/IntOutply';

        numIntoutlay := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        numDealReverse := numDealReverse + numReverseAmount;
       -- insert into temp values(numFinal,numReverseAmount);
            varOperation := 'Before Select ';
        IF numAction  IN(GConst.ADDSAVE, GConst.EDITSAVE) THEN
          select
            case
            when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
              round(numReverseAmount * (deal_forward_rate - numPremium))
            when numFinal != deal_exchange_rate then
              decode(deal_buy_sell, GConst.PURCHASEDEAL,
                Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
                Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
            else 0
            end
            into numPandL
            from trtran001
            where deal_deal_number = varDealReference
             and Deal_Record_status not in (10200005,10200006);
         End If;    
           varOperation := 'After  Select '|| numAction || varDealReference;
        if numAction = GConst.ADDSAVE then
          varOperation := 'Inserting Hedge Deal Delivery';
          insert into trtran006(cdel_company_code, cdel_deal_number,
            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,cdel_int_outlay,cdel_intoutlay_rate)
            select deal_company_code, deal_deal_number,
            deal_serial_number,
            (select NVL(max(cdel_reverse_serial),0) + 1
              from trtran006
              where cdel_deal_number = varDealReference),
            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial,
            Numpandl,Varvoucher ,Numspot,Numpremium,Nummargin,Numserial,Numintoutlay,Numintoutlayrate
            from trtran001
            Where Deal_Deal_Number = Vardealreference;

          varOperation := 'After  Insert into 001 ' || varDealReference;
          Numerror := Fnccompleteutilization(Vardealreference,Gconst.Utilhedgedeal,Datworkdate);
          Varoperation := 'After  Process Complete ' || Vardealreference;
          If Numpandl != 0 Then
          varOperation := 'Checking for pandl ' || varDealReference || Numpandl;
              select CDEL_REVERSE_SERIAL into numTemp1
                From Trtran006
              where cdel_deal_number = varDealReference
                    and cdel_trade_reference = varTradeReference
                    and Cdel_Trade_Serial = numTradeSerial;

            varOperation := 'Inserting Current Account voucher for PL';
            varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
              GConst.TRANSACTIONCREDIT),24900049,24800051,
              deal_deal_number,numTemp1, 
              deal_base_currency, 0,
              0, numPandL, 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1;    
            varOperation := 'Inserting INterest OutLay';
            if numIntoutlay <> 0 then
              varOperation := 'Inserting INterest OutLay';
              varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, deal_location_code, deal_counter_party, varVoucher,
                deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
                deal_deal_number,numTemp1, 
                deal_base_currency, 0,
                0, numIntoutlay, 'Deal Reversal No: ' ||
                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                (select lbnk_account_number
                  from trmaster306
                  where lbnk_pick_code = deal_counter_party)
                from trtran001
                where deal_deal_number = varDealReference
                and deal_serial_number = 1;   
            end if;
            varOperation := 'Inserting Interest Current';

            varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
              GConst.TRANSACTIONDEBIT),24900030,24800051,
              deal_deal_number,numTemp1,
              deal_base_currency, 0,
              0, (numPandL - numIntoutlay), 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1;  

          else
            varVoucher := NULL;
          end if;

      elsif numAction = GConst.EDITSAVE then
        if numRecordStatus = 1 then
           varOperation := 'Inserting Hedge Deal Delivery';
          insert into trtran006(cdel_company_code, cdel_deal_number,
            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,cdel_int_outlay,cdel_intoutlay_rate)
            select deal_company_code, deal_deal_number,
            deal_serial_number,
            (select NVL(max(cdel_reverse_serial),0) + 1
              from trtran006
              where cdel_deal_number = varDealReference),
            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial,
            numPandL,varVoucher ,numSpot,numPremium,numMargin,numSerial,numIntoutlay,numintOutlayRate
            from trtran001
            where deal_deal_number = varDealReference;

            varOperation := 'Inserting Hedge Deal Delivery after insert';
          numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);
          varOperation := 'Inserting Hedge Deal Delivery after fncCompleteUtilization';  

          if numPandL != 0 then
              select CDEL_REVERSE_SERIAL into numTemp1
                from trtran006
              where cdel_deal_number = varDealReference
                    and cdel_trade_reference = varTradeReference
                    and Cdel_Trade_Serial = numTradeSerial;
            varOperation := 'Inserting C/A voucher for PL';

            varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);

            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
              GConst.TRANSACTIONCREDIT),24900049,24800051,
              deal_deal_number,numTemp1,
              deal_base_currency, 0,
              0, numPandL, 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1; 

            varOperation := 'Inserting Interest Outlay voucher for PL' || numIntoutlay;   
            if numIntoutlay <> 0 then
              varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, deal_location_code, deal_counter_party, varVoucher,
                deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
                deal_deal_number,numTemp1, 
                deal_base_currency, 0,
                0, numIntoutlay, 'Deal Reversal No: ' ||
                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                (select lbnk_account_number
                  from trmaster306
                  where lbnk_pick_code = deal_counter_party)
                from trtran001
                where deal_deal_number = varDealReference
                and deal_serial_number = 1;   
            end if;              
            varOperation := 'Inserting C/A voucher for PL' || numIntoutlay;  

            varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
              GConst.TRANSACTIONDEBIT),24900030,24800051,
              deal_deal_number,numTemp1,
              deal_base_currency, 0,
              0, (numPandL - numIntoutlay), 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1;  

          else
            varVoucher := NULL;
          end if;
        elsif  numRecordStatus = 2 then
--            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
--              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
--              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--              AND DEAL_DEAL_TYPE != 25400001
--              AND CDEL_REVERSE_SERIAL = numRevSerial
--              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          if numPandL != 0 then
              SELECT NVL(COUNT(*),0) INTO numRefSerial FROM TRTRAN008  WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                  AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                  AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
              IF numRefSerial > 0 THEN
              ----Currenct account entry Update
                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = (numPandL - numIntoutlay),
                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                    AND BCAC_ACCOUNT_HEAD = 24900030
                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
                ---Proft loss head entry update                                                    
                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = numPandL,
                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                    AND BCAC_ACCOUNT_HEAD = 24900049
                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
                ---Interest Outlay Entry Update                                                    
                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = numIntoutlay,
                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                    AND BCAC_ACCOUNT_HEAD = 24900079
                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;                                                                    
              ELSE
                select CDEL_REVERSE_SERIAL into numTemp1
                  from trtran006
                where cdel_deal_number = varDealReference
                      and cdel_trade_reference = varTradeReference
                      and Cdel_Trade_Serial = numTradeSerial;

                varOperation := 'Inserting Currenct Account voucher for PL';
                varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
                insert into trtran008 (bcac_company_code, bcac_location_code,
                  bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                  bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                  bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                  bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                  bcac_create_date, bcac_local_merchant, bcac_record_status,
                  bcac_record_type, bcac_account_number)
                select numCompany, deal_location_code, deal_counter_party, varVoucher,
                  deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
                  GConst.TRANSACTIONCREDIT),24900049,24800051,
                  deal_deal_number,numTemp1,
                  deal_base_currency, 0,
                  0, numPandL, 'Deal Reversal No: ' ||
                  deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                  (select lbnk_account_number
                    from trmaster306
                    where lbnk_pick_code = deal_counter_party)
                  from trtran001
                  where deal_deal_number = varDealReference
                  and deal_serial_number = 1;    
                if numIntoutlay <> 0 then
                  varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
                  insert into trtran008 (bcac_company_code, bcac_location_code,
                    bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                    bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                    bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                    bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                    bcac_create_date, bcac_local_merchant, bcac_record_status,
                    bcac_record_type, bcac_account_number)
                  select numCompany, deal_location_code, deal_counter_party, varVoucher,
                    deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
                    deal_deal_number,numTemp1, 
                    deal_base_currency, 0,
                    0, numIntoutlay, 'Deal Reversal No: ' ||
                    deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                    (select lbnk_account_number
                      from trmaster306
                      where lbnk_pick_code = deal_counter_party)
                    from trtran001
                    where deal_deal_number = varDealReference
                    and deal_serial_number = 1;   
                end if;                  
                varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
                insert into trtran008 (bcac_company_code, bcac_location_code,
                  bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                  bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                  bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                  bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                  bcac_create_date, bcac_local_merchant, bcac_record_status,
                  bcac_record_type, bcac_account_number)
                select numCompany, deal_location_code, deal_counter_party, varVoucher,
                  deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
                  GConst.TRANSACTIONDEBIT),24900030,24800051,
                  deal_deal_number,numTemp1,
                  deal_base_currency, 0,
                  0, (numPandL -numIntoutlay), 'Deal Reversal No: ' ||
                  deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                  (select lbnk_account_number
                    from trmaster306
                    where lbnk_pick_code = deal_counter_party)
                  from trtran001
                  where deal_deal_number = varDealReference
                  and deal_serial_number = 1;                
              END IF;
          end if;
          UPDATE TRTRAN006 SET CDEL_CANCEL_AMOUNT = numReverseAmount,
                               CDEL_CANCEL_RATE = numFinal,
                               CDEL_PROFIT_LOSS = numPandL,
                               CDEL_FORWARD_RATE = numPremium,
                               CDEL_INT_OUTLAY = numIntoutlay,
                               cdel_intoutlay_rate = numintOutlayRate,
                               CDEL_RECORD_STATUS = 10200004 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);
        elsif  numRecordStatus = 3 then
--            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
--              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
--              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--              AND DEAL_DEAL_TYPE != 25400001
--              AND CDEL_REVERSE_SERIAL = numRevSerial
--              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200006 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                  AND BCAC_REFERENCE_SERIAL = numRevSerial;
          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);        
        end if;
      elsif numAction = GConst.DELETESAVE then
--            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
--              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
--              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--              AND DEAL_DEAL_TYPE != 25400001
--              AND CDEL_REVERSE_SERIAL = numRevSerial              
--              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200006 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                AND BCAC_REFERENCE_SERIAL = numRevSerial;
          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);  

      elsif numAction = GConst.CONFIRMSAVE then
          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200003 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                AND BCAC_REFERENCE_SERIAL = numRevSerial;
          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200003 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;

      end if;
      End Loop;
<<Cash_Deal>>
        if numAction = GConst.ADDSAVE then
          if numCashDeal > 0 then
            varOperation := 'Inserting Cash Deal';
            varDealReference := varCompany || '/FWD/' || fncGenerateSerial(SERIALDEAL,numCompany);
            insert into trtran001
              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
              deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
              deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
              deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
              deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
              deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
              deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
              deal_bo_remark,deal_location_code)
            values ( numCompany, varDealReference, 1, datWorkDate, 26000001,numBuySell,
              25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
              Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
              NULL, varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
              to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
              null,null,null,0,numCashRate,
              0,33399999,0,0,33899999, NULL,
              'Cash Delivery ' || varTradeReference,numLocation);

            varOperation := 'Inserting Cash Deal Cancellation';
            insert into trtran006
              (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
              cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
              cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
              cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
              cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
              cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
            select deal_company_code, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
              datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
              0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
              null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
              deal_bo_remark
              from trtran001
              where deal_deal_number = varDealReference;

  --         begin 
  --           select nvl(HEDG_TRADE_SERIAL,1) +1
  --           into  numserial 
  --            from trtran004 
  --            where hedg_trade_reference=varTradeReference;
  --         exception 
  --           when no_data_found then
  --             numserial:=1;
  --         end ;
  --          varOperation := 'Inserting Hedge record';
  --          insert into trtran004
  --          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
  --            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
  --            hedg_create_date,hedg_entry_detail,hedg_record_status,
  --            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
  --          values(numCompany,varTradeReference,varDealReference,
  --          1, numCashDeal,0, Round(numCashDeal * numCashRate),
  --          sysdate,NULL,10200012, 32200001,12400002,numserial);

        End if;
        if numCashDeal > 0 or numDealReverse > 0 then
          INSERT INTO TRTRAN003
          (BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,BREL_USER_REFERENCE,
          BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,
          BREL_PERIOD_CODE,BREL_TRADE_PERIOD,BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,
          BREL_ENTRY_DETAIL,BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE)
          Select Numcompany,Vartradereference,Numtradeserial,Sysdate,'Exposure Settlement',Datreference,
          25899999,Numcashdeal+Numdealreverse,Nvl(Numcashrate,Numfinal),Nvl(Numcashrate,Numfinal)*(Numcashdeal+Numdealreverse),0,
          0,sysdate,sysdate,sysdate,null,10200001,NumLocalBank,null,numLocation from dual;
        end if;  
      ELSif numAction = GConst.EDITSAVE then
      begin
        SELECT CDEL_DEAL_NUMBER INTO varReference FROM TRTRAN006,TRTRAN001
        WHERE CDEL_TRADE_REFERENCE = varTradeReference  
        AND CDEL_TRADE_SERIAL = numTradeSerial
        AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
        AND DEAL_DEAL_TYPE = 25400001
        AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
        if numCashDeal > 0 then  
          UPDATE TRTRAN006 SET CDEL_CANCEL_AMOUNT = numCashDeal,
                               CDEL_CANCEL_RATE = numCashRate,
                               CDEL_SPOT_RATE = numCashRate,
                               CDEL_RECORD_STATUS = 10200004 WHERE CDEL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN001 SET DEAL_BASE_AMOUNT = numCashDeal,
                               DEAL_EXCHANGE_RATE = numCashRate,
                               DEAL_SPOT_RATE = numCashRate,
                               DEAL_RECORD_STATUS = 10200004 WHERE DEAL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN003 SET BREL_REVERSAL_FCY = (numCashDeal+numDealReverse),
                               BREL_REVERSAL_RATE = numCashRate,
                               BREL_RECORD_STATUS = 10200004 WHERE BREL_TRADE_REFERENCE = varTradeReference
                                                                 AND  BREL_REVERSE_SERIAL = numTradeSerial;
        end if;                                                                 
        exception
        when no_data_found then 
          if numCashDeal > 0 then
            varOperation := 'Inserting Cash Deal';
            varDealReference := varCompany || '/FWD/' || fncGenerateSerial(SERIALDEAL,numCompany);
            insert into trtran001
              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
              deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
              deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
              deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
              deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
              deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
              deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
              deal_bo_remark,deal_location_code)
            values ( numCompany, varDealReference, 1, datWorkDate, 26000001,numBuySell,
              25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
              Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
              NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
              to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
              null,null,null,0,numCashRate,0,33399999,0,0,33899999, NULL,
              'Cash Delivery ' || varTradeReference,numLocation);

            varOperation := 'Inserting Cash Deal Cancellation';
            insert into trtran006
              (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
              cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
              cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
              cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
              cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
              cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
            select deal_company_code, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
              datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
              0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
              null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
              deal_bo_remark
              from trtran001
              where deal_deal_number = varDealReference;
        End if;
--        if numCashDeal > 0 or numDealReverse > 0 then
--          INSERT INTO TRTRAN003
--          (BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,BREL_USER_REFERENCE,
--          BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,
--          BREL_PERIOD_CODE,BREL_TRADE_PERIOD,BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,
--          BREL_ENTRY_DETAIL,BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE)
--          SELECT numCompany,varTradeReference,numTradeSerial,SYSDATE,'Exposure Settlement',datReference,
--          25899999,numCashDeal+numDealReverse,numCashRate,numCashRate*(numCashDeal+numDealReverse),0,
--          0,sysdate,sysdate,sysdate,null,10200001,NumLocalBank,null,numLocation from dual; 
--        end if;  
      end;  
      ELSif numAction = GConst.DELETESAVE then
        begin
          SELECT CDEL_DEAL_NUMBER INTO varReference FROM TRTRAN006,TRTRAN001
          WHERE CDEL_TRADE_REFERENCE = varTradeReference  
          AND CDEL_TRADE_SERIAL = numTradeSerial
          AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
          AND DEAL_DEAL_TYPE = 25400001
          AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;

          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN001 SET DEAL_RECORD_STATUS = 10200006 WHERE DEAL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN003 SET BREL_RECORD_STATUS = 10200006 WHERE BREL_TRADE_REFERENCE = varTradeReference

                                                                 AND  BREL_REVERSE_SERIAL = numTradeSerial;
        exception
        when no_data_found then 
          varTradeReference := '';
        end; 
      end if;
      return numError;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('forwardSettlement', numError, varMessage,
                          varOperation, varError);
          GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.forwardSettlement');                       
          raise_application_error(-20101, varError);
          RETURN numError;
End forwardSettlement;

---manjunath sir modification ends
Function fncBillSettlement
    (   RecordDetail in GConst.gClobType%Type)
    return number
    is
--  created by TMM on 31/01/2014
    numError            number;
    numTemp             number;
    numAction           number(4);
    numSerial           number(5);
    numLocation         number(8);
    numCompany          number(8);
    numReversal         number(8);
    numImportExport     number(8);    
    numReverseAmount    number(15,2);
    numDealReverse      number(15,2);
    numBillReverse      number(15,2);
    numCashDeal         number(15,2);
    numPandL            number(15,2);
    numFcy              number(15,2);
    numSpot             number(15,6);
    numPremium          number(15,6);
    numMargin           number(15,6);
    numFinal            number(15,6);
    numCashRate         number(15,6);
    varCompany          varchar2(15);
    varEntity           varchar2(25);
    varVoucher          varchar2(25);
    varTradeReference   varchar2(25);
    varDealReference    varchar2(25);
    varReference        varchar2(25);
    varXPath            varchar2(1024);
    varTemp             varchar2(1024);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         Date;
    datReference        Date;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    numLocalBank        number(8);
    numCompanyCode      number(8);
    numReverseSerial    number(5);
    numCurrencyCode     NUMBER(8);
    numTradeSerial      NUMBER(5);
    clbTemp             clob;

  Begin
    varMessage := 'Entering Bill Settlement Process';
    numError := 0;
    numDealReverse := 0;
    numBillReverse := 0;
    numCashDeal := 0;

    varOperation := 'Extracting Parameters';
    xmlTemp := xmlType(RecordDetail);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);

varOperation := 'Extracting Parameters' || numLocation;

    numCompany := GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE', numCompany);
    varTradeReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTradeReference);
    numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
    numReversal := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numReversal);
    varOperation := 'Extracting Parameters BREL_REVERSAL_TYPE ' || numReversal;

    datReference := GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datReference);
    numBillReverse := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numBillReverse);
    numCashRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numCashRate);
    varOperation := 'Extracting Parameters BREL_REVERSAL_RATE ' || numCashRate;
    numCompanyCode :=  GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE',numCompanyCode);
    numReverseSerial:=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numReverseSerial); 
    numLocalBank := GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numLocalBank); 
    varOperation := 'Extracting Parameters BREL_LOCAL_BANK ' || numLocalBank;
    numCurrencyCode := Gconst.fncXMLExtract(xmlTemp, 'TradeCurrencyCode', numCurrencyCode); 
    numImportExport := gconst.fncxmlextract(xmltemp, 'ImportExport', numImportExport);
    numTradeSerial := gconst.fncxmlextract(xmltemp, 'TradeSerial', numTradeSerial);
    varCompany := pkgReturnCursor.fncGetDescription(numCompany,2);

     varOperation := 'Extracting Parameters CurrencyCode ' || numCurrencyCode;

    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);
    IF numImportExport = 25900073 THEN
      numTradeSerial := 0;
    --  SELECT nvl(MAX(INTC_INTEREST_NUMBER)+1,0) INTO numTradeSerial FROM himatsingkatf_prod.tftran051 WHERE INTC_LOAN_REFERENCE = varTradeReference;
    end if; 
    if numReversal not in (GConst.BILLREALIZE,GConst.BILLINWARDREMIT,
      GConst.BILLIMPORTREL,GConst.BILLOUTWARDREMIT,GConst.BILLLOANCLOSURE) then
      Goto Trade_reversal;
    End if;

    varOperation := 'Checking for Deal Delivery, if any';
    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

    if xmlDom.getLength(nlsTemp) = 0 then
      numCashDeal := numBillReverse;
      GOto Cash_Deal;
    END IF;
    DELETE FROM temp;
    --insert into temp values (numTradeSerial,'Chandra');commit;
<<Deal_Reversal>>
    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="';
      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
        nodTemp := xmlDom.item(nlsTemp, numSub);
        nmpTemp := xmlDom.getAttributes(nodTemp);
        nodTemp1 := xmlDom.item(nmpTemp, 0);
        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
        varTemp := varXPath || numTemp || '"]/DealNumber';
        varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || numTemp || '"]/SpotRate'; --Updated From cygnet
        numSpot := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
-- Node Name changed from FrwRate to Premium for TOI by TMM 31/01/14
        varTemp := varXPath || numTemp || '"]/Premium';
        numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/MarginRate';
        numMargin := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/FinalRate';
        numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
        varTemp := varXPath || numTemp || '"]/ReverseNow';
        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        numDealReverse := numDealReverse + numReverseAmount;

        select
          case
          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
            round(numReverseAmount * (deal_forward_rate - numPremium))
          when numFinal != deal_exchange_rate then
            decode(deal_buy_sell, GConst.PURCHASEDEAL,
              Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
              Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
          else 0
          end
          into numPandL
          from trtran001
          where deal_deal_number = varDealReference;

        if numPandL > 0 then
          varOperation := 'Inserting voucher for PL';
          clbTemp := pkgMasterMaintenance.fncCurrentAccount(RecordDetail, numError);          
--          varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
--          insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type, bcac_account_number)
--          select numCompany, numLocation, deal_counter_party, varVoucher,
--            deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--            GConst.TRANSACTIONCREDIT),GConst.ACEXCHANGE,
--            decode(deal_buy_sell,GConst.PURCHASEDEAL,
--            GConst.EVENTPURCHASE, GConst.EVENTSALE),
--            deal_deal_number, 1, deal_base_currency, numReverseAmount,
--            numFinal, Round(numReverseAmount *  numFinal), 'Deal Reversal No: ' ||
--            deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002,
--            (select lbnk_account_number
--              from trmaster306
--              where lbnk_pick_code = deal_counter_party)
--            from trtran001
--            where deal_deal_number = varDealReference
--            and deal_serial_number = 1;
        else
          varVoucher := NULL;
        end if;

        varOperation := 'Inserting entries to Hedge Table, if necessary';
        select count(*)
          into numTemp
          from trtran004
          where hedg_trade_reference = varTradeReference
          and hedg_deal_number = varDealReference
          and hedg_record_status between 10200001 and 10200004;
-- Deal was not dynamically linked in the realization screen
        if numtemp = 0 then
          insert into trtran004
          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
            hedg_create_date,hedg_entry_detail,hedg_record_status,
            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
          values(numCompany,varTradeReference,varDealReference,
            (select NVL(max(hedg_deal_serial),0) + 1
            from trtran004
            where hedg_deal_number = varDealReference),
          numReverseAmount,0, Round(numReverseAmount * numFinal),
          sysdate,NULL,10200012, 32200001,12400002,numTradeSerial);
        END IF;

        varOperation := 'Inserting Hedge Deal Delivery';
        insert into trtran006(cdel_company_code, cdel_deal_number,
          cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
          cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
          cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
          cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
          cdel_entry_detail, cdel_record_status, cdel_trade_reference,
          Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
          cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL) -- Updated from Cygnet
          select deal_company_code, deal_deal_number,
          deal_serial_number,
          (select NVL(max(cdel_reverse_serial),0) + 1
            from trtran006
            where cdel_deal_number = varDealReference),
          datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
          numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
          Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
          SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
          varVoucher ,numSpot,numPremium,numMargin,numSerial
          from trtran001
          where deal_deal_number = varDealReference;

        numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);

      End Loop;

      numCashDeal := numBillReverse - numDealReverse;

<<Cash_Deal>>

      if numCashDeal > 0 then
          varOperation := 'Inserting Cash Deal';
          varDealReference := varCompany || '/FWD/' || fncGenerateSerial(SERIALDEAL,numCompany);
          insert into trtran001
            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
            deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
            deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
            deal_bo_remark)
          values ( numCompanyCode, varDealReference, 1, datWorkDate, 26000001,decode(sign(25800050 - numReversal),-1,25300002,25300001),
            25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
            Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
            NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
            null,null,null,0,numCashRate,0,33399999,0,0,33899999, NULL,
            'Cash Delivery ' || varTradeReference);

--            from trtran002
--            where trad_trade_reference = varTradeReference;

          varOperation := 'Inserting Cash Deal Cancellation';
          insert into trtran006
            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
          select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
            datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
            0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
            null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
            deal_bo_remark
            from trtran001
            where deal_deal_number = varDealReference;

         begin 
           select nvl(Max(HEDG_TRADE_SERIAL),1) +1
           into  numserial 
            from trtran004 
            where hedg_trade_reference=varTradeReference;
         exception 
           when no_data_found then
             numserial:=1;
         end ;
          varOperation := 'Inserting Hedge record';
          insert into trtran004
          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
            hedg_create_date,hedg_entry_detail,hedg_record_status,
            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
          values(numCompany,varTradeReference,varDealReference,
          1, numCashDeal,0, Round(numCashDeal * numCashRate),
          sysdate,NULL,10200012, 32200001,12400002,numserial);

      End if;



<<Trade_Reversal>>

--        if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL) then
--          numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,
             GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL,GCONST.BILLAMENDMENT) then
             --Changed by Manjunath Reddy to include Export cancel and import cancel for process complete
          numError := fncCompleteUtilization(varTradeReference,Gconst.UTILEXPORTS,datWorkDate);

          if  numReversal in (GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL) then              
              update trtran004     
                set hedg_record_status = GConst.STATUSPOSTCANCEL
                where hedg_trade_reference = varTradeReference
                and hedg_record_Status not in (10200005,10200006);
          end if;

--      varOperation := 'Checking for PSCFC Details';
--      Begin
--        numFcy := 0;
--        varReference := '';
--   --     varReference := GConst.fncXMLExtract(xmlTemp, 'LoanNumber', varReference);
--        numFcy := GConst.fncXMLExtract(xmlTemp, '//PSCFCDetails/SanctionedFcy', 
--                        numFcy, GConst.TYPENODEPATH);
--        
--      Exception
--        when others then
--          numFcy := 0;
--          varReference := '';
--      End;
--      
--      if numFcy > 0 then
--        
--        if numAction = GConst.ADDSAVE then
--          varReference := PkgReturnCursor.fncGetDescription(GConst.LOANPSCFC, GConst.PICKUPSHORT);
--          varReference := varReference || '/' || fncGenerateSerial(GConst.SERIALLOAN);
--          
--          varOperation := 'Inserting PSCFC Record';
--          insert into trtran005(fcln_company_code, fcln_loan_number,
--          fcln_loan_type, fcln_local_bank, fcln_bank_reference, fcln_sanction_date,
--          fcln_noof_days, fcln_currency_code, fcln_sanctioned_fcy,
--          fcln_conversion_rate, fcln_sanctioned_inr, fcln_reason_code,
--          fcln_maturity_from, fcln_maturity_to, fcln_loan_remarks,
--          Fcln_Libor_Rate,Fcln_Rate_Spread,Fcln_Interest_Rate, -- Updated From Cygnet
--          fcln_create_date, fcln_entry_detail, fcln_record_status,fcln_process_complete) -- Updated From Cygnet
--          values(numCompany, varReference, GConst.LOANPSCFC,
--          Gconst.Fncxmlextract(Xmltemp, 'BREL_LOCAL_BANK', Numfcy),
--          GConst.fncXMLExtract(xmlTemp, 'BankReference', varReference),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionDate', datWorkDate),
--          GConst.fncXMLExtract(xmlTemp, 'NoofDays', numError),
--          (select trad_trade_currency
--            from trtran002
--            where trad_trade_reference = varTradeReference),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
--          GConst.REASONEXPORT,
--          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datWorkDate),
--          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datWorkDate),
--          'PSCFC From Bill Trade Reference ' || varTradeReference,
--          GConst.fncXMLExtract(xmlTemp, 'LiborRate', numSpot), -- Updated From Cygnet
--          GConst.fncXMLExtract(xmlTemp, 'SpreadRate', numSpot),
--          GConst.fncXMLExtract(xmlTemp, 'InterestRate', numSpot),
--          sysdate, null, GConst.STATUSENTRY,
--          12400002); -- End updated cygnet
--          
--          varOperation := 'Inserting Loan Connect';
--          insert into trtran010(loln_company_code, loln_loan_number,      -- Updated from cygnet
--          loln_trade_reference, loln_serial_number, loln_adjusted_date, 
--          Loln_Adjusted_Fcy, Loln_Adjusted_Rate, Loln_Adjusted_Inr,
--          loln_create_date, loln_entry_detail, loln_record_status)        --End Updated Cygnet
--          values(numCompany, varReference, varTradeReference, 0, datWorkDate,
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
--          sysdate, null, GConst.STATUSENTRY);
--          
--        End if;

--    End if;          
        elsif numReversal = GConst.BILLLOANCLOSURE then
          numError := fncCompleteUtilization(varTradeReference,Gconst.UTILBCRLOAN,datWorkDate);
        end if;
--      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,GConst.BILLLOANCLOSURE) then
--          --prcbillsettlement(recorddetail,numreversal);
--          himatsingkatf_prod.pkgTreasury.prcBillSettlement(RecordDetail,numImportExport);
--      end if;

      return numError;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
                          varOperation, varError);
          GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncBillSettlement');                 
          raise_application_error(-20101, varError);
          RETURN numError;
End fncBillSettlement;

--Function fncExposuresettlement
--    (   RecordDetail in GConst.gClobType%Type)
--    return number
--    is
----  created by TMM on 31/01/2014
--    numError            number;
--    numTemp             number;
--    numTemp1            NUMBER;
--    numAction           number(4);
--    numSerial           number(5);
--    numLocation         number(8);
--    numCompany          number(8);
--    numReversal         number(8);
--    numImportExport     number(8);    
--    numReverseAmount    number(15,2);
--    numDealReverse      number(15,2);
--    numBillReverse      number(15,2);
--    numCashDeal         number(15,2);
--    numPandL            number(15,2);
--    numFcy              number(15,2);
--    numSpot             number(15,6);
--    numPremium          number(15,6);
--    numMargin           number(15,6);
--    numFinal            number(15,6);
--    numCashRate         number(15,6);
--    numRefrate          number(15,6);
--    numEDAmount         number(15,2);
--    varCompany          varchar2(15);
--    varBatch            varchar2(25);
--    varEntity           varchar2(25);
--    varVoucher          varchar2(25);
--    varTradeReference   varchar2(25);
--    varDealReference    varchar2(25);
--    varReference        varchar2(25);
--    varBatchNo          varchar2(30);
--    varXPath            varchar2(1024);
--    varTemp             varchar2(1024);
--    varTemp1             varchar2(1024);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datTemp         Date;
--    datWorkDate         Date;
--    datReference        Date;
--    xmlTemp             xmlType;
--    nlsTemp             xmlDom.DomNodeList;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--    nodTemp             xmlDom.domNode;
--    nodTemp1            xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodemap;
--    numLocalBank        number(8);
--    numCompanyCode      number(8);
--    numReverseSerial    number(5);
--    numCurrencyCode     NUMBER(8);
--    numOtherCurrency    Number(8);
--    numCurrencyPair     Number(8);
--    numTradeSerial      NUMBER(5);
--    numPortfolio        number(8);
--    numSubportfolio     number(8);
--    numCount            number(3);
--    numcode             number(8,0);  
--    clbTemp             clob;
--    CurrencyPair        number(8);
--    numDirectIndirect   number(8);
--
--  Begin
--    varMessage := 'Entering fncExposuresettlement Settlement Process';
--    numError := 0;
--    numDealReverse := 0;
--    numBillReverse := 0;
--    numCashDeal := 0;
--
--    varOperation := 'Extracting Parameters';
--    xmlTemp := xmlType(RecordDetail);
--    
--      
--      
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);
--    
--    BEGIN
--        datTemp := GConst.fncXMLExtract(xmlTemp, 'BEXP_TRANSACTION_DATE', datTemp); 
--    EXCEPTION 
--    when no_data_found then
--        datTemp := sysdate;
--    end ;
--    
--    varBatchNo := GConst.fncXMLExtract(xmlTemp, 'BEXP_DELIVERY_BATCH', varBatchNo);
--    GLOG.log_write('FOR numAction: '|| numAction || ' varBatchNo -' ||varBatchNo); 
--    if numAction = GConst.DELETESAVE then
--      GLOG.log_write('FOR DELETESAVE: '|| varBatchNo);  
----      begin  
----        for cur_in in(select * from trtran003  where BREL_DELIVERY_BATCH = varBatchNo)
----        loop          
----         GLOG.log_write('UPDATE PROCESS COMPLETE FOR : '|| cur_in.BREL_TRADE_REFERENCE);  
----           numError := fncCompleteUtilization(cur_in.BREL_TRADE_REFERENCE, Gconst.UTILEXPORTS, datWorkDate);                                                                             
----        end loop;
----      end;
--
--      UPDATE TRTRAN003
--      SET BREL_DELIVERY_BATCH = null
--      WHERE BREL_DELIVERY_BATCH = varBatchNo;
--        
--      update trtran004 set hedg_record_status = 10200006        
--      where hedg_batch_number = varBatchNo;
--      
--      update trtran006 set cdel_record_status = 10200006 
--      where cdel_batch_number = varBatchNo;
--      
--      update trtran008 set bcac_record_status = 10200006 
--      WHERE BCAC_BATCH_NO = varBatchNo;
--      
--      begin  
--            for cur_in in(select * from trtran006  where cdel_batch_number = varBatchNo)
--            loop              
--                  varOperation := 'Update Process Complete for Deal : '||cur_in.cdel_deal_number;
--                
--                  update trtran001 
--                  set deal_process_complete = 12400002,
--                  deal_complete_date = null 
--                  where deal_deal_number = cur_in.cdel_deal_number 
--                  and DEAL_DEAL_TYPE != 25400001;                                                                                      
--            end loop;
--      end;
----      begin  
----        for cur_in in(select * from trtran006  where cdel_batch_number = varBatchNo)
----        loop
----          
----          varOperation := 'Settlement entry delete';
----          select max(BREL_REVERSE_SERIAL) into numSerial from trtran003;
----          if numSerial < 10000 then
----            numSerial := 10000;
----          end if;
------          update trtran001 set deal_record_status = 10200006 
------                          where deal_deal_number = cur_in.cdel_deal_number 
------                          and DEAL_DEAL_TYPE = 25400001;
----          update trtran001 set deal_record_status = 10200006, 
----                            deal_process_complete = 12400002,
----                            deal_complete_date = null 
----                          where deal_deal_number = cur_in.cdel_deal_number 
----                          and DEAL_DEAL_TYPE != 25400001; 
------          update trtran002 set trad_process_complete = 12400002,
------                               trad_complete_date = null 
------                          where trad_trade_reference = cur_in.cdel_trade_reference;
------          update trtran003 set  BREL_REVERSE_SERIAL = numSerial + 1 where  brel_trade_reference = cur_in.cdel_trade_reference
------                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;    
----                                                                            
------          update trtran003 set  BREL_BATCH_NUMBER = ''  where  brel_trade_reference = cur_in.cdel_trade_reference
------                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;
----
------          update trtran045 set bcrd_process_complete = 12400002,
------                               bcrd_completion_date = null 
------                          where bcrd_buyers_credit = cur_in.cdel_trade_reference;                                                                                      
----        end loop;
----      end;
----      varoperation:='Populate the entire batch details again so that user can take care of this same using add mode 
----                    incase of any changes in the remittace then they ahve take care from previous screen';
--      
----      INSERT INTO TRTRAN003(
----            BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,  BREL_REVERSE_SERIAL,
----            BREL_ENTRY_DATE,  BREL_USER_REFERENCE,  BREL_REFERENCE_DATE,
----            BREL_REVERSAL_TYPE, BREL_REVERSAL_FCY, BREL_REVERSAL_RATE,
----            BREL_REVERSAL_INR,  BREL_PERIOD_CODE,  BREL_TRADE_PERIOD,
----            BREL_MATURITY_FROM,   BREL_MATURITY_DATE,  BREL_CREATE_DATE,
----            BREL_RECORD_STATUS,   BREL_LOCAL_BANK,
----            BREL_REVERSE_REFERENCE, BREL_LOCATION_CODE,  BREL_BATCH_NUMBER,
----            BREL_TRADE_CURRENCY,   BREL_LOCAL_CURRENCY,   BREL_IMPORT_EXPORT,
----            BREL_USER_PORTFOLIO,  BREL_OTHER_CURRENCY_YESNO,  BREL_PRODUCT_CATEGORY,
----            BREL_REMARKS,  BREL_TRANSACTION_DATE,   BREL_SUB_PORTFOLIO )
----      select BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,  
----            (select nvl(max(sub.BREL_REVERSE_SERIAL),0) from TRTRAN003 sub
----             where sub.BREL_DELIVERY_BATCH=varBatchNo
----             and sub.BREL_TRADE_REFERENCE=m.BREL_TRADE_REFERENCE)+1 ,
----            BREL_ENTRY_DATE,  BREL_USER_REFERENCE,  BREL_REFERENCE_DATE,
----            BREL_REVERSAL_TYPE, BREL_REVERSAL_FCY, BREL_REVERSAL_RATE,
----            BREL_REVERSAL_INR,  BREL_PERIOD_CODE,  BREL_TRADE_PERIOD,
----            BREL_MATURITY_FROM,   BREL_MATURITY_DATE,  sysdate,
----              BREL_RECORD_STATUS,   BREL_LOCAL_BANK,
----            BREL_REVERSE_REFERENCE, BREL_LOCATION_CODE,  BREL_BATCH_NUMBER,
----            BREL_TRADE_CURRENCY,   BREL_LOCAL_CURRENCY,   BREL_IMPORT_EXPORT,
----            BREL_USER_PORTFOLIO,  BREL_OTHER_CURRENCY_YESNO,  BREL_PRODUCT_CATEGORY,
----            BREL_REMARKS,  BREL_TRANSACTION_DATE,   BREL_SUB_PORTFOLIO
----        from TRTRAN003 M
----        where BREL_DELIVERY_BATCH=varBatchNo
----        and brel_record_Status not in (10200005,10200006);
--        
--     --varoperation:='Update the Record stauts for Remittance of the Batch';
--       --update trtran003 set BREL_RECORD_STATUS = 10200006 where BREL_DELIVERY_BATCH=varBatchNo;
--      
--    else
--    GLOG.log_write('FOR ADDSAVE: '|| varBatchNo);  
--      --To update exposures delivery batch in trtran0003 
--    varOperation := 'Extracting REMITTANCESETTLEMENT RECORDS ' || varBatchNo;
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);       
--    varOperation := 'Before Loop';
--    varXPath := '//REMITTANCESETTLEMENT/DROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    if xmlDom.getLength(nlsTemp) > 0 then
--        varXPath := '//REMITTANCESETTLEMENT/DROW[@DNUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT');  
--            varOperation := 'Inside Loop REMITTANCESETTLEMENT';
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodtemp1 := xmldom.item(nmptemp, 0);
--            
--            numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT numtemp: '|| numtemp);  
--            varTemp := varXPath || numTemp || '"]/TradeReference';
--            varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--            
--            varTemp := varXPath || numTemp || '"]/BatchNumber';
--            varTemp1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--            
--            varTemp := varXPath || numTemp || '"]/GroupByLink';
--            numcode := GConst.fncGetNodeValue(nodFinal, varTemp);
----    
----            varTemp := varXPath || numTemp || '"]/ReverseSerial';
----            numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);                
----            
----            varTemp := varXPath || numTemp || '"]/CompanyCode';
----            numCompanyCode := To_Number(Gconst.Fncgetnodevalue(Nodfinal, numCompanyCode));
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT before update : '|| numtemp);  
--            if numcode = 12400001 then 
--                UPDATE TRTRAN003
--                SET BREL_DELIVERY_BATCH = varBatchNo
--                WHERE BREL_BATCH_NUMBER = varTemp1 and BREL_RECORD_STATUS not in (10200005,10200006);
--            else
--                UPDATE TRTRAN003
--                SET BREL_DELIVERY_BATCH = varBatchNo
--                WHERE BREL_TRADE_REFERENCE = varTradeReference and BREL_RECORD_STATUS not in (10200005,10200006);
--            end if;
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT after update : '|| numtemp);  
----            and BREL_REVERSE_SERIAL = numTradeSerial
----            and BREL_COMPANY_CODE = numCompanyCode;
--        End loop;
--    end if;
--    
--    GLOG.log_write('FOR ADDSAVE CASHSETTLEMENT: '|| varBatchNo); 
--      varOperation := 'Extracting CASHSETTLEMENT records ' || varBatchNo;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);       
--      varOperation := 'Before Loop';
--      varXPath := '//CASHSETTLEMENT/DROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--            varXPath := '//CASHSETTLEMENT/DROW[@DNUM="';
--            for numSub in 0..xmlDom.getLength(nlsTemp) -1
--              Loop
--               GLOG.log_write('Inside Loop CASHSETTLEMENT');  
--                varOperation := 'Inside Loop CASHSETTLEMENT';
--                nodTemp := xmlDom.item(nlsTemp, numSub);
--                nmpTemp := xmlDom.getAttributes(nodTemp);
--                nodtemp1 := xmldom.item(nmptemp, 0);
--               
--                GLOG.log_write('Inside Loop CASHSETTLEMENT numtemp: '|| numtemp); 
--                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--                varTemp := varXPath || numTemp || '"]/TradeRefNo';
--                varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--                
--                varTemp := varXPath || numTemp || '"]/TradeSerial';
--                numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);                
--                
--                varTemp := varXPath || numTemp || '"]/CashRate';
--                numCashRate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--                
--                varTemp := varXPath || numTemp || '"]/CashFcy';
--                numCashDeal := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                
--                varTemp := varXPath || numTemp || '"]/ImpExp';
--                numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                
--                varTemp := varXPath || numTemp || '"]/BatchNo';
--                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);  
----- Becuase we sending the CashCurrency as currency Pair we ahve commented below                 
----                varTemp := varXPath || numTemp || '"]/TradeCurrency';
----                numCurrencyCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
----                
----                varTemp := varXPath || numTemp || '"]/OtherCurrency';
----                numOtherCurrency := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                
-- --               begin
--                    --varTemp := varXPath || numTemp || '"]/CashCurrencyPair';
--                    varTemp := varXPath || numTemp || '"]/CashCurrency';
--                    numCurrencyPair := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                    
--                  select CNDI_DIRECT_INDIRECT,CNDI_BASE_CURRENCY,CNDI_OTHER_CURRENCY
--                     into numDirectIndirect,numCurrencyCode,numOtherCurrency
--                   from trmaster256
--                    where CNDI_PICK_CODE=numCurrencyPair
--                      and CNDI_RECORD_STATUS not in (10200005,10200006);
--                      
----                exception
----                when others then
----                   select CNDI_DIRECT_INDIRECT,CNDI_PICK_CODE
----                     into numDirectIndirect,numCurrencyPair
----                   from trmaster256
----                    where CNDI_Base_currency=numCurrencyCode
----                      and CNDI_OTHER_CURRENCY=numOtherCurrency
----                      and CNDI_RECORD_STATUS not in (10200005,10200006);
----                end;
--                
--               -- select 
--                numSerial := 1;--GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--          
--                begin
--                 SELECT DISTINCT BREL_LOCAL_BANK,
--                  BREL_PRODUCT_CATEGORY,BREL_SUB_PORTFOLIO, BREL_COMPANY_CODE 
--                  into  numLocalBank,numPortfolio,numSubportfolio,numCompany
--                  FROM TRTRAN003 
--                  --WHERE BREL_BATCH_NUMBER = varTradeReference
--                  where (BREL_TRADE_REFERENCE=varTradeReference OR BREL_BATCH_NUMBER = varTradeReference)
--                  AND BREL_RECORD_STATUS NOT IN(10200005,10200006);
----                  select TRAD_TRADE_CURRENCY,TRAD_LOCAL_BANK,
----                         TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE,TRAD_COMPANY_CODE
----                    into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
----                  from trtran002 where trad_trade_reference = varTradeReference 
----                  and trad_record_status between 10200001 and 10200004
----                  UNION ALL
----                  select BCRD_CURRENCY_CODE,BCRD_LOCAL_BANK,
----                         BCRD_PRODUCT_CATEGORY,BCRD_SUBPRODUCT_CODE,BCRD_COMPANY_CODE
----                  from trtran045 where BCRD_BUYERS_CREDIT = varTradeReference 
----                  and BCRD_RECORD_STATUS between 10200001 and 10200004                  
----                  UNION ALL
----                  select DISTINCT TLON_CURRENCY_CODE,TLON_LOCAL_BANK,
----                         33399999,33899999,TLON_COMPANY_CODE
----                  from TRTRAN081 where TLON_LOAN_NUMBER = varTradeReference 
----                  and TLON_RECORD_STATUS between 10200001 and 10200004;                    
--                exception when no_data_found then
--                   numCurrencyCode := 0;
--                   numLocalBank := 0;
--                   numPortfolio := 0;
--                   numSubportfolio :=0;
--                   numCompany := 0;
--                end ;
--              -- IF numAction = GConst.EDITSAVE then
--                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
--                  varDealReference := 'CASH' || fncGenerateSerial(SERIALDEAL,numCompany);                  
--                  varOperation := 'Inserting Cash deal to main table';
--                  insert into trtran001
--                    (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--                    deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
--                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
--                    deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--                    deal_bo_remark,DEAL_CURRENCY_PAIR)
--                  values (numCompany, varDealReference, 1, datWorkDate, 26000001,case when numImportExport < 25900050 then 25300002 else 25300001 end,
--                    25200002,25400001,NumLocalBank,numCurrencyCode, numOtherCurrency,numCashRate, 1, (case when numDirectIndirect =12400001 then numCashDeal else
--                          round(numCashDeal/numCashRate,2) end),
--                    --Round(numCashRate * numCashDeal)
--                    (case when numDirectIndirect =12400001 then Round(numCashRate * numCashDeal) else numCashDeal end)
--                    ,0,0,datWorkDate,datWorkDate,null, 'System',
--                    NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--                    null,null,null,0,numCashRate,0,numPortfolio,0,0,numSubportfolio, NULL,
--                    'Cash Delivery ' || varTradeReference, numCurrencyPair);              
--                  varOperation := 'Inserting Cash Deal Cancellation';
--                 insert into trtran006
--                    (cdel_company_code,CDEL_LOCATION_CODE,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
--                  select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number, 1, 1, varTradeReference, NumTradeSerial,
--                    datTemp, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--                    deal_bo_remark,varBatchNo
--                    from trtran001
--                    where deal_deal_number = varDealReference;              
--                  begin 
--                   select nvl(MAX(HEDG_TRADE_SERIAL),1) +1
--                   into  numserial 
--                    from trtran004 
--                    where hedg_trade_reference=varTradeReference;
--                  exception 
--                   when no_data_found then
--                     numserial:=1;
--                  end ;
--                  varOperation := 'Inserting Cash deal Linking details';
----                  insert into trtran004
----                  (hedg_company_code,hedg_trade_reference,hedg_deal_number,
----                    hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
----                    hedg_create_date,hedg_entry_detail,hedg_record_status,
----                    hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
----                    HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
----                  values(numCompany,varTradeReference,varDealReference,
----                  1, numCashDeal,0, Round(numCashDeal * numCashRate),
----                  sysdate,NULL,10200012, 32200001,12400002,numserial,varBatchNo,datWorkDate);
--                  varOperation := 'After linking Cash deal Linking details';                
--                  --numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--               -- END IF;
--              End loop;
--      end if;
--      
--      GLOG.log_write('FOR ADDSAVE FORWARDSETTLEMENT: '|| varBatchNo); 
--     varOperation := 'Extracting FORWARDSETTLEMENT records ' || varBatchNo;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);
--      varXPath := '//FORWARDSETTLEMENT/DROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--        varXPath := '//FORWARDSETTLEMENT/DROW[@DNUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--        GLOG.log_write('Inside Loop FORWARDSETTLEMENT');  
--         varOperation := 'Inside Loop FORWARDSETTLEMENT';
--          nodTemp := xmlDom.item(nlsTemp, numSub);
--          nmpTemp := xmlDom.getAttributes(nodTemp);
--          nodTemp1 := xmlDom.item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--          
--          GLOG.log_write('Inside Loop FORWARDSETTLEMENT numtemp: '|| numtemp); 
--          varTemp := varXPath || numTemp || '"]/DealNumber';
--          varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--                  
--          varTemp := varXPath || numTemp || '"]/TradeRefNo';           
--          varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--          
--          varTemp := varXPath || numTemp || '"]/TradeSerial';
--          numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);     
--                
--          varTemp := varXPath || numTemp || '"]/ImpExp';
--          numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          
--          varTemp := varXPath || numTemp || '"]/BatchNo';
--          varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);      
--          
--          varTemp := varXPath || numTemp || '"]/ForwardRate';
--          numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));          
--          
--          varTemp := varXPath || numTemp || '"]/EDBenefit';
--          numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          
--          varTemp := varXPath || numTemp || '"]/EDAmount';
--          numEDAmount := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));     
--          
--          varTemp := varXPath || numTemp || '"]/ForwardFcy';
--          numReverseAmount := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--          
--          varTemp := varXPath || numTemp || '"]/ReferenceRate';
--          numRefrate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp)); 
--          
--          numSerial := 1;--GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--          varOperation := 'select Statement to get values for DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
--                       DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE for ' ||varDealReference;
--                select DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
--                       DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE,deal_Currency_pair
--                  into  numCurrencyCode,numLocalBank,numPortfolio,
--                      numSubportfolio,numCompany,numCurrencypair
--                from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
--                and DEAL_record_status between 10200001 and 10200004;
--                
--                varOperation := 'select numPandL ' ||varDealReference;
--          select
--            case
--  --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--  --            round(numReverseAmount * (deal_forward_rate - numPremium))
--            when numFinal != deal_exchange_rate then
--              decode(deal_buy_sell, GConst.PURCHASEDEAL,
--                Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--                Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--            else 0
--            end
--            into numPandL
--            from trtran001
--            where deal_deal_number = varDealReference;
--            numPandL := numEDAmount;
--          varOperation := 'Inserting entries to Hedge Table, if necessary';
----          BEGIN
----            SELECT NVL(max(HEDG_TRADE_SERIAL),0) +1
----            INTO numTradeSerial
----            FROM trtran004
----            WHERE hedg_trade_reference=varTradeReference;
----          EXCEPTION
----          WHEN no_data_found THEN
----            numTradeSerial:=1;
----          END ;
----          BEGIN
----            SELECT NVL(max(hedg_deal_serial),0) +1
----            INTO numSerial
----            FROM trtran004
----            WHERE hedg_deal_number=varDealReference;
----          EXCEPTION
----          WHEN no_data_found THEN
----            numSerial:=1;
----          END ;   
--          
--          
----            insert into trtran004
----            (hedg_company_code,hedg_trade_reference,hedg_deal_number,
----              hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
----              hedg_create_date,hedg_entry_detail,hedg_record_status,
----              hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
----              HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
----            values(numCompany,varTradeReference,varDealReference,
----            numSerial, numReverseAmount,0, Round(numReverseAmount * numFinal),
----            sysdate,NULL,10200012, 32200001,12400002,numTradeSerial,varBatchNo,datWorkDate);
--            
--          select CNDI_DIRECT_INDIRECT
--            into numDirectIndirect
--           from trmaster256
--           where CNDI_RECORD_STATUS not in (10200005,10200006)
--             and CNDI_PICK_CODE =numCurrencypair;
--            
--          varOperation := 'FORWARDSETTLEMENT Inserting Hedge Deal Delivery';
--          insert into trtran006(cdel_company_code,CDEL_LOCATION_CODE, cdel_deal_number,
--            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
--            CDEL_BATCH_NUMBER,cdel_cashflow_date,CDEL_REFERENCE_RATE)
--            select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number,
--            deal_serial_number,
--            (select NVL(max(cdel_reverse_serial),0) + 1
--              from trtran006
--              where cdel_deal_number = varDealReference),
--            datTemp, deal_hedge_trade, Gconst.Dealdelivery,
--            (case when numDirectIndirect=12400001 then  numReverseAmount
--              else round(numReverseAmount/numFinal,2) end)
--            , numFinal,
--            --Round(numReverseAmount * numFinal),
--            (case when numDirectIndirect=12400001 then round(numReverseAmount*numFinal,2) 
--              else numReverseAmount end),
--            1,
--            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
--            varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datTemp,numRefrate
--            -- Changed by MR on 08-12-2021 insted datWorkDate changed to DatTemp
--            from trtran001
--            where deal_deal_number = varDealReference;
--            if numPandL != 0 then
--               varOperation := 'calling  prcEDCVoucherPosting ';
--               
--        prcEDCVoucherPosting(varDealReference,numReverseAmount,numFinal,numPandL,numAction);
--                   
--                varOperation := 'complete prcEDCVoucherPosting ';
--                   
--           
----              select CDEL_REVERSE_SERIAL into numTemp1
----                from trtran006
----              where cdel_deal_number = varDealReference
----                    and cdel_trade_reference = varTradeReference
----                    and Cdel_Trade_Serial = numTradeSerial;
--
--             begin
--              select nvl(max(CDEL_REVERSE_SERIAL),1)
--                into numTemp1
--                from trtran006
--              where cdel_deal_number = varDealReference;
--            exception 
--             when others then
--               numTemp1:=1;
--            end;
--
--              varOperation := 'Inserting Current Account voucher for PL';
----              varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----              insert into trtran008 (bcac_company_code, bcac_location_code,
----                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                bcac_create_date, bcac_local_merchant, bcac_record_status,
----                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----              select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
----                GConst.TRANSACTIONCREDIT),24900049,24800051,
----                deal_deal_number,numTemp1, 
----                deal_base_currency, 0,
----                0, numPandL, 'Deal Reversal No: ' ||
----                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                (select lbnk_account_number
----                  from trmaster306
----                  where lbnk_pick_code = deal_counter_party),varBatchNo
----                from trtran001
----                where deal_deal_number = varDealReference
----                and deal_serial_number = 1;    
----              varOperation := 'Inserting Interest Current';
----              varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----              insert into trtran008 (bcac_company_code, bcac_location_code,
----                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                bcac_create_date, bcac_local_merchant, bcac_record_status,
----                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----              select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
----                GConst.TRANSACTIONDEBIT),24900030,24800051,
----                deal_deal_number,numTemp1,
----                deal_base_currency, 0,
----                0, (numPandL), 'Deal Reversal No: ' ||
----                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                (select lbnk_account_number
----                  from trmaster306
----                  where lbnk_pick_code = deal_counter_party),varBatchNo
----                from trtran001
----                where deal_deal_number = varDealReference
----                and deal_serial_number = 1;  
--              
--            else
--              varVoucher := NULL;
--            end if;  
--            GLog.log_write('Calling Complete Utlization for the Reference Number ' || varDealReference || ' Util Type ' || Gconst.UTILHEDGEDEAL || ' Date ' || datWorkDate);
--            numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);
--            --numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate)
--        End Loop;
--        numTradeSerial := 0;
--      end if;
--      
--      GLOG.log_write('FOR ADDSAVE CROSSFORWARDSETTLEMENT: '|| varBatchNo); 
--      varOperation := 'Extracting CROSSFORWARDSETTLEMENT records ' || varBatchNo;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);       
--      varOperation := 'Before Loop';
--      varXPath := '//CROSSFORWARDSETTLEMENT/DROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--            varXPath := '//CROSSFORWARDSETTLEMENT/DROW[@DNUM="';
--            for numSub in 0..xmlDom.getLength(nlsTemp) -1
--              Loop
--                GLOG.log_write('Inside Loop CROSSFORWARDSETTLEMENT');  
--                varOperation := 'Inside Loop CROSSFORWARDSETTLEMENT';
--                nodTemp := xmlDom.item(nlsTemp, numSub);
--                nmpTemp := xmlDom.getAttributes(nodTemp);
--                nodtemp1 := xmldom.item(nmptemp, 0);
--                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--                varTradeReference := '';
--                
--                GLOG.log_write('Inside Loop CROSSFORWARDSETTLEMENT numtemp: '|| numtemp); 
--                varTemp := varXPath || numTemp || '"]/CImpExp';
--                numImportExport := GConst.fncGetNodeValue(nodFinal, varTemp);
----            
----                varTemp := varXPath || numTemp || '"]/CEXPSerial';
----                numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);
----            
--                varTemp := varXPath || numTemp || '"]/CBatchNo';
--                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);
--                
--                varTemp := varXPath || numTemp || '"]/CDealNumber';
--                varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--                
--                varTemp := varXPath || numTemp || '"]/CForwardRate';
--                numFinal := Gconst.Fncgetnodevalue(Nodfinal, Vartemp);
--                
--                varTemp := varXPath || numTemp || '"]/CForwardFcy';
--                numReverseAmount := GConst.fncGetNodeValue(nodFinal, varTemp);
--                
--                varTemp := varXPath || numTemp || '"]/DealType';
--                varTemp1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--                
--                varTemp := varXPath || numTemp || '"]/CEDBenefit';
--                numPremium := GConst.fncGetNodeValue(nodFinal, varTemp);
--                
--                varTemp := varXPath || numTemp || '"]/CEDAmount';
--                numEDAmount := GConst.fncGetNodeValue(nodFinal, varTemp);
--          
--                varTemp := varXPath || numTemp || '"]/TradeCurrency';
--                numCurrencyCode := GConst.fncGetNodeValue(nodFinal, varTemp);
--                
--                varTemp := varXPath || numTemp || '"]/OtherCurrency';
--                numOtherCurrency := GConst.fncGetNodeValue(nodFinal, varTemp);
--          
--                  select CNDI_DIRECT_INDIRECT,CNDI_PICK_CODE
--                    into numDirectIndirect,numCurrencyPair
--                   from trmaster256
--                    where CNDI_BASE_CURRENCY=numCurrencyCode
--                      and CNDI_OTHER_CURRENCY=numOtherCurrency
--                      and CNDI_RECORD_STATUS not in (10200005,10200006);
--                      
--                numSerial := 2; -- For Cross currency  To identify in Queries 
--                varOperation := 'Before Batch No DealType';
--                if varTemp1 = 'Other' then
--                  varOperation := 'After Batch No';
--                      select DEAL_COUNTER_PARTY,DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE,deal_currency_pair
--                        into  numLocalBank,numPortfolio,numSubportfolio,numCompany,numCurrencyPair
--                      from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
--                      and DEAL_record_status between 10200001 and 10200004;
--                  select
--                  case
--        --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--        --            round(numReverseAmount * (deal_forward_rate - numPremium))
--                  when numFinal != deal_exchange_rate then
--                    decode(deal_buy_sell, GConst.PURCHASEDEAL,
--                      Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--                      Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--                  else 0
--                  end
--                  into numPandL
--                  from trtran001
--                  where deal_deal_number = varDealReference;
--                  numPandL:=numEDAmount;
--                 -- delete from temp;commit;
--               --   insert into temp values('varDealReference',varDealReference);commit;
--                varOperation:='CROSSFORWARDSETTLEMENT Extracting Maximum Serial Number';
--                 
--                  select NVL(max(cdel_reverse_serial),0) + 1
--                   into numTemp1
--                    from trtran006
--                    where cdel_deal_number = varDealReference;
--                    
--
--                    
--                varOperation := 'CROSSFORWARDSETTLEMENT Inserting Hedge Deal Delivery';
--                insert into trtran006(cdel_company_code,CDEL_LOCATION_CODE, cdel_deal_number,
--                  cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--                  cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--                  cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--                  cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--                  cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--                  Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--                  cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
--                  CDEL_BATCH_NUMBER,cdel_cashflow_date)
--                  select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number,
--                  deal_serial_number,numTemp1,
--                  datTemp, deal_hedge_trade, Gconst.Dealdelivery,
--                  (case when numDirectIndirect =12400001 then numReverseAmount
--                    else round(numReverseAmount/numFinal) end)
--                  , numFinal,
--                  (case when numDirectIndirect =12400001 then numReverseAmount*numFinal
--                    else numReverseAmount end)
--                  --Round(numReverseAmount * numFinal)
--                  , 1,
--                  Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                  SYSDATE, NULL, Gconst.Statusentry, varTradeReference, 1, numPandL,
--                  varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datTemp
--                  -- cahnged by MR
--                  from trtran001
--                  where deal_deal_number = varDealReference;
--                  if numPandL != 0 then
--                  
----                    select CDEL_REVERSE_SERIAL into numTemp1
----                      from trtran006
----                    where cdel_deal_number = varDealReference
----                          and cdel_trade_reference = varTradeReference
----                          and Cdel_Trade_Serial = numTradeSerial;
--      
--                    varOperation := 'Inserting Current Account voucher for PL';
----                    varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----                    insert into trtran008 (bcac_company_code, bcac_location_code,
----                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                      bcac_create_date, bcac_local_merchant, bcac_record_status,
----                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
----                      GConst.TRANSACTIONCREDIT),24900049,24800051,
----                      deal_deal_number,numTemp1, 
----                      deal_base_currency, 0,
----                      0, numPandL, 'Deal Reversal No: ' ||
----                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                      (select lbnk_account_number
----                        from trmaster306
----                        where lbnk_pick_code = deal_counter_party),varBatchNo
----                      from trtran001
----                      where deal_deal_number = varDealReference
----                      and deal_serial_number = 1;    
----                    varOperation := 'Inserting Interest Current';
----                    varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----                    insert into trtran008 (bcac_company_code, bcac_location_code,
----                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                      bcac_create_date, bcac_local_merchant, bcac_record_status,
----                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
----                      GConst.TRANSACTIONDEBIT),24900030,24800051,
----                      deal_deal_number,numTemp1,
----                      deal_base_currency, 0,
----                      0, (numPandL), 'Deal Reversal No: ' ||
----                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                      (select lbnk_account_number
----                        from trmaster306
----                        where lbnk_pick_code = deal_counter_party),varBatchNo
----                      from trtran001
----                      where deal_deal_number = varDealReference
----                      and deal_serial_number = 1;  
--                    
--                  else
--                    varVoucher := NULL;
--                  end if;           
--                  numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);
--               else
--                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
--                  varDealReference := 'CASH' || fncGenerateSerial(SERIALDEAL,numCompany);
--                                    
--                  begin
--                      varTemp := varXPath || numTemp || '"]/CashCurrencyPair';
--                      numCurrencyPair := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                  exception
--                  when others then
--                    numCurrencyPair:=0;
--                  end;
--                
--                  varOperation := 'Inserting Cash deal to main table';
--                  insert into trtran001
--                    (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--                    deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
--                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
--                    deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--                    deal_bo_remark,DEAL_CURRENCY_PAIR)
--                  values (numCompany, varDealReference, 1, datWorkDate, 26000001,numImportExport,--case when numImportExport < 25900050 then 25300002 else 25300001 end,
--                    25200002,25400001,NumLocalBank,numCurrencyCode, numOtherCurrency,numFinal, 1, 
--                    --numReverseAmount,
--                    (case when numDirectIndirect=12400001 then numReverseAmount else round (numReverseAmount/numFinal,2) end),
--                    (case when numDirectIndirect=12400001 then Round(numFinal * numReverseAmount) else (numReverseAmount) end),
--                    0,0,datWorkDate,datWorkDate,null, 'System',
--                    NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--                    null,null,null,0,numFinal,0,numPortfolio,0,0,numSubportfolio, NULL,
--                    'Cash Delivery ' || varTradeReference, numCurrencyPair);              
--                  varOperation := 'Inserting Cash Deal Cancellation';
--                  insert into trtran006
--                    (cdel_company_code,CDEL_LOCATION_CODE,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
--                  select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
--                    datTemp, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,numPremium,numPandL,33500001,null,null,deal_bank_reference,
--                    deal_bo_remark,varBatchNo
--                    from trtran001
--                    where deal_deal_number = varDealReference;              
--               end if;   
--              End loop;
--      end if;
--    end if;
--    return numError;
--Exception
--        When others then
--          numError := SQLCODE;
--          varError := SQLERRM;
--          varError := GConst.fncReturnError('fncExposuresettlement', numError, varMessage,
--                          varOperation, varError);
--           GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncExposuresettlement');           
--          raise_application_error(-20101, varError);
--          RETURN numError;
--End fncExposuresettlement;

--Function fncExposuresettlement
--    (   RecordDetail in GConst.gClobType%Type)
--    return number
--    is
----  created by TMM on 31/01/2014
--    numError            number;
--    numTemp             number;
--    numTemp1            NUMBER;
--    numAction           number(4);
--    numSerial           number(5);
--    numLocation         number(8);
--    numCompany          number(8);
--    numReversal         number(8);
--    numImportExport     number(8);    
--    numReverseAmount    number(15,2);
--    numDealReverse      number(15,2);
--    numBillReverse      number(15,2);
--    numCashDeal         number(15,2);
--    numPandL            number(15,2);
--    numFcy              number(15,2);
--    numSpot             number(15,6);
--    numPremium          number(15,6);
--    numMargin           number(15,6);
--    numFinal            number(15,6);
--    numCashRate         number(15,6);
--    numRefrate          number(15,6);
--    numEDAmount         number(15,2);
--    varCompany          varchar2(15);
--    varLocation         varchar2(15);
--    varBatch            varchar2(25);
--    varEntity           varchar2(25);
--    varVoucher          varchar2(25);
--    varTradeReference   varchar2(25);
--    varDealReference    varchar2(25);
--    varReference        varchar2(25);
--    varBatchNo          varchar2(30);
--    varXPath            varchar2(1024);
--    varTemp             varchar2(1024);
--    varTemp1             varchar2(1024);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datTemp         Date;
--    datWorkDate         Date;
--    datReference        Date;
--    xmlTemp             xmlType;
--    nlsTemp             xmlDom.DomNodeList;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--    nodTemp             xmlDom.domNode;
--    nodTemp1            xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodemap;
--    numLocalBank        number(8);
--    numCompanyCode      number(8);
--    numLocationCode     number(8);
--    numReverseSerial    number(5);
--    numCurrencyCode     NUMBER(8);
--    numOtherCurrency    Number(8);
--    numCurrencyPair     Number(8);
--    numTradeSerial      NUMBER(5);
--    numPortfolio        number(8);
--    numSubportfolio     number(8);
--    numCount            number(3);
--    numcode             number(8,0);  
--    clbTemp             clob;
--    CurrencyPair        number(8);
--    numDirectIndirect   number(8);
--
--  Begin
--    varMessage := 'Entering fncExposuresettlement Settlement Process';
--    numError := 0;
--    numDealReverse := 0;
--    numBillReverse := 0;
--    numCashDeal := 0;
--
--    varOperation := 'Extracting Parameters';
--    xmlTemp := xmlType(RecordDetail);
--
--
--
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);
--
--    BEGIN
--        datTemp := GConst.fncXMLExtract(xmlTemp, 'BEXP_TRANSACTION_DATE', datTemp); 
--    EXCEPTION 
--    when no_data_found then
--        datTemp := sysdate;
--    end ;
--
--    varBatchNo := GConst.fncXMLExtract(xmlTemp, 'BEXP_DELIVERY_BATCH', varBatchNo);
--    GLOG.log_write('FOR numAction: '|| numAction || ' varBatchNo -' ||varBatchNo); 
--    if numAction = GConst.DELETESAVE then
--      GLOG.log_write('FOR DELETESAVE: '|| varBatchNo);  
----      begin  
----        for cur_in in(select * from trtran003  where BREL_DELIVERY_BATCH = varBatchNo)
----        loop          
----         GLOG.log_write('UPDATE PROCESS COMPLETE FOR : '|| cur_in.BREL_TRADE_REFERENCE);  
----           numError := fncCompleteUtilization(cur_in.BREL_TRADE_REFERENCE, Gconst.UTILEXPORTS, datWorkDate);                                                                             
----        end loop;
----      end;
--
--      UPDATE TRTRAN003
--      SET BREL_DELIVERY_BATCH = null
--      WHERE BREL_DELIVERY_BATCH = varBatchNo;
--
--      update trtran004 set hedg_record_status = 10200006        
--      where hedg_batch_number = varBatchNo;
--
--      update trtran006 set cdel_record_status = 10200006 
--      where cdel_batch_number = varBatchNo;
--
--      update trtran008 set bcac_record_status = 10200006 
--      WHERE BCAC_BATCH_NO = varBatchNo;
--
--      begin  
--            for cur_in in(select * from trtran006  where cdel_batch_number = varBatchNo)
--            loop              
--                  varOperation := 'Update Process Complete for Deal : '||cur_in.cdel_deal_number;
--
--                  update trtran001 
--                  set deal_process_complete = 12400002,
--                  deal_complete_date = null 
--                  where deal_deal_number = cur_in.cdel_deal_number 
--                  and DEAL_DEAL_TYPE != 25400001;                                                                                      
--            end loop;
--      end;
----      begin  
----        for cur_in in(select * from trtran006  where cdel_batch_number = varBatchNo)
----        loop
----          
----          varOperation := 'Settlement entry delete';
----          select max(BREL_REVERSE_SERIAL) into numSerial from trtran003;
----          if numSerial < 10000 then
----            numSerial := 10000;
----          end if;
------          update trtran001 set deal_record_status = 10200006 
------                          where deal_deal_number = cur_in.cdel_deal_number 
------                          and DEAL_DEAL_TYPE = 25400001;
----          update trtran001 set deal_record_status = 10200006, 
----                            deal_process_complete = 12400002,
----                            deal_complete_date = null 
----                          where deal_deal_number = cur_in.cdel_deal_number 
----                          and DEAL_DEAL_TYPE != 25400001; 
------          update trtran002 set trad_process_complete = 12400002,
------                               trad_complete_date = null 
------                          where trad_trade_reference = cur_in.cdel_trade_reference;
------          update trtran003 set  BREL_REVERSE_SERIAL = numSerial + 1 where  brel_trade_reference = cur_in.cdel_trade_reference
------                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;    
----                                                                            
------          update trtran003 set  BREL_BATCH_NUMBER = ''  where  brel_trade_reference = cur_in.cdel_trade_reference
------                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;
----
------          update trtran045 set bcrd_process_complete = 12400002,
------                               bcrd_completion_date = null 
------                          where bcrd_buyers_credit = cur_in.cdel_trade_reference;                                                                                      
----        end loop;
----      end;
----      varoperation:='Populate the entire batch details again so that user can take care of this same using add mode 
----                    incase of any changes in the remittace then they ahve take care from previous screen';
--
----      INSERT INTO TRTRAN003(
----            BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,  BREL_REVERSE_SERIAL,
----            BREL_ENTRY_DATE,  BREL_USER_REFERENCE,  BREL_REFERENCE_DATE,
----            BREL_REVERSAL_TYPE, BREL_REVERSAL_FCY, BREL_REVERSAL_RATE,
----            BREL_REVERSAL_INR,  BREL_PERIOD_CODE,  BREL_TRADE_PERIOD,
----            BREL_MATURITY_FROM,   BREL_MATURITY_DATE,  BREL_CREATE_DATE,
----            BREL_RECORD_STATUS,   BREL_LOCAL_BANK,
----            BREL_REVERSE_REFERENCE, BREL_LOCATION_CODE,  BREL_BATCH_NUMBER,
----            BREL_TRADE_CURRENCY,   BREL_LOCAL_CURRENCY,   BREL_IMPORT_EXPORT,
----            BREL_USER_PORTFOLIO,  BREL_OTHER_CURRENCY_YESNO,  BREL_PRODUCT_CATEGORY,
----            BREL_REMARKS,  BREL_TRANSACTION_DATE,   BREL_SUB_PORTFOLIO )
----      select BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,  
----            (select nvl(max(sub.BREL_REVERSE_SERIAL),0) from TRTRAN003 sub
----             where sub.BREL_DELIVERY_BATCH=varBatchNo
----             and sub.BREL_TRADE_REFERENCE=m.BREL_TRADE_REFERENCE)+1 ,
----            BREL_ENTRY_DATE,  BREL_USER_REFERENCE,  BREL_REFERENCE_DATE,
----            BREL_REVERSAL_TYPE, BREL_REVERSAL_FCY, BREL_REVERSAL_RATE,
----            BREL_REVERSAL_INR,  BREL_PERIOD_CODE,  BREL_TRADE_PERIOD,
----            BREL_MATURITY_FROM,   BREL_MATURITY_DATE,  sysdate,
----              BREL_RECORD_STATUS,   BREL_LOCAL_BANK,
----            BREL_REVERSE_REFERENCE, BREL_LOCATION_CODE,  BREL_BATCH_NUMBER,
----            BREL_TRADE_CURRENCY,   BREL_LOCAL_CURRENCY,   BREL_IMPORT_EXPORT,
----            BREL_USER_PORTFOLIO,  BREL_OTHER_CURRENCY_YESNO,  BREL_PRODUCT_CATEGORY,
----            BREL_REMARKS,  BREL_TRANSACTION_DATE,   BREL_SUB_PORTFOLIO
----        from TRTRAN003 M
----        where BREL_DELIVERY_BATCH=varBatchNo
----        and brel_record_Status not in (10200005,10200006);
--
--     --varoperation:='Update the Record stauts for Remittance of the Batch';
--       --update trtran003 set BREL_RECORD_STATUS = 10200006 where BREL_DELIVERY_BATCH=varBatchNo;
--
--    else
--    GLOG.log_write('FOR ADDSAVE: '|| varBatchNo);  
--      --To update exposures delivery batch in trtran0003 
--    varOperation := 'Extracting REMITTANCESETTLEMENT RECORDS ' || varBatchNo;
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);       
--    varOperation := 'Before Loop';
--    varXPath := '//REMITTANCESETTLEMENT/DROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    if xmlDom.getLength(nlsTemp) > 0 then
--        varXPath := '//REMITTANCESETTLEMENT/DROW[@DNUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT');  
--            varOperation := 'Inside Loop REMITTANCESETTLEMENT';
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodtemp1 := xmldom.item(nmptemp, 0);
--
--            numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT numtemp: '|| numtemp);  
--            varTemp := varXPath || numTemp || '"]/TradeReference';
--            varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--            varTemp := varXPath || numTemp || '"]/BatchNumber';
--            varTemp1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--            varTemp := varXPath || numTemp || '"]/GroupByLink';
--            numcode := GConst.fncGetNodeValue(nodFinal, varTemp);
----    
----            varTemp := varXPath || numTemp || '"]/ReverseSerial';
----            numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);                
----            
----            varTemp := varXPath || numTemp || '"]/CompanyCode';
----            numCompanyCode := To_Number(Gconst.Fncgetnodevalue(Nodfinal, numCompanyCode));
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT before update : '|| numtemp);  
--            if numcode = 12400001 then 
--                UPDATE TRTRAN003
--                SET BREL_DELIVERY_BATCH = varBatchNo
--                WHERE BREL_BATCH_NUMBER = varTemp1 and BREL_RECORD_STATUS not in (10200005,10200006);
--            else
--                UPDATE TRTRAN003
--                SET BREL_DELIVERY_BATCH = varBatchNo
--                WHERE BREL_TRADE_REFERENCE = varTradeReference and BREL_RECORD_STATUS not in (10200005,10200006);
--            end if;
--            GLOG.log_write('Inside Loop REMITTANCESETTLEMENT after update : '|| numtemp);  
----            and BREL_REVERSE_SERIAL = numTradeSerial
----            and BREL_COMPANY_CODE = numCompanyCode;
--        End loop;
--    end if;
--
--    GLOG.log_write('FOR ADDSAVE CASHSETTLEMENT: '|| varBatchNo); 
--      varOperation := 'Extracting CASHSETTLEMENT records ' || varBatchNo;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);       
--      varOperation := 'Before Loop';
--      varXPath := '//CASHSETTLEMENT/DROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--            varXPath := '//CASHSETTLEMENT/DROW[@DNUM="';
--            for numSub in 0..xmlDom.getLength(nlsTemp) -1
--              Loop
--               GLOG.log_write('Inside Loop CASHSETTLEMENT');  
--                varOperation := 'Inside Loop CASHSETTLEMENT';
--                nodTemp := xmlDom.item(nlsTemp, numSub);
--                nmpTemp := xmlDom.getAttributes(nodTemp);
--                nodtemp1 := xmldom.item(nmptemp, 0);
--
--                GLOG.log_write('Inside Loop CASHSETTLEMENT numtemp: '|| numtemp); 
--                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--                varTemp := varXPath || numTemp || '"]/TradeRefNo';
--                varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/TradeSerial';
--                numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);                
--
--                varTemp := varXPath || numTemp || '"]/CashRate';
--                numCashRate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--
--                varTemp := varXPath || numTemp || '"]/CashFcy';
--                numCashDeal := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--                varTemp := varXPath || numTemp || '"]/ImpExp';
--                numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--                varTemp := varXPath || numTemp || '"]/BatchNo';
--                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);  
----- Becuase we sending the CashCurrency as currency Pair we ahve commented below                 
----                varTemp := varXPath || numTemp || '"]/TradeCurrency';
----                numCurrencyCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
----                
----                varTemp := varXPath || numTemp || '"]/OtherCurrency';
----                numOtherCurrency := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
-- --               begin
--                    --varTemp := varXPath || numTemp || '"]/CashCurrencyPair';
--                    varTemp := varXPath || numTemp || '"]/CashCurrency';
--                    numCurrencyPair := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--                  select CNDI_DIRECT_INDIRECT,CNDI_BASE_CURRENCY,CNDI_OTHER_CURRENCY
--                     into numDirectIndirect,numCurrencyCode,numOtherCurrency
--                   from trmaster256
--                    where CNDI_PICK_CODE=numCurrencyPair
--                      and CNDI_RECORD_STATUS not in (10200005,10200006);
--
----                exception
----                when others then
----                   select CNDI_DIRECT_INDIRECT,CNDI_PICK_CODE
----                     into numDirectIndirect,numCurrencyPair
----                   from trmaster256
----                    where CNDI_Base_currency=numCurrencyCode
----                      and CNDI_OTHER_CURRENCY=numOtherCurrency
----                      and CNDI_RECORD_STATUS not in (10200005,10200006);
----                end;
--
--               -- select 
--                numSerial := 1;--GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--
--                begin
--                 SELECT DISTINCT BREL_LOCAL_BANK,
--                  BREL_PRODUCT_CATEGORY,BREL_SUB_PORTFOLIO, BREL_COMPANY_CODE,BREL_LOCATION_CODE 
--                  into  numLocalBank,numPortfolio,numSubportfolio,numCompany,numLocationCode
--                  FROM TRTRAN003 
--                  --WHERE BREL_BATCH_NUMBER = varTradeReference
--                  where (BREL_TRADE_REFERENCE=varTradeReference OR BREL_BATCH_NUMBER = varTradeReference)
--                  AND BREL_RECORD_STATUS NOT IN(10200005,10200006);
----                  select TRAD_TRADE_CURRENCY,TRAD_LOCAL_BANK,
----                         TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE,TRAD_COMPANY_CODE
----                    into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
----                  from trtran002 where trad_trade_reference = varTradeReference 
----                  and trad_record_status between 10200001 and 10200004
----                  UNION ALL
----                  select BCRD_CURRENCY_CODE,BCRD_LOCAL_BANK,
----                         BCRD_PRODUCT_CATEGORY,BCRD_SUBPRODUCT_CODE,BCRD_COMPANY_CODE
----                  from trtran045 where BCRD_BUYERS_CREDIT = varTradeReference 
----                  and BCRD_RECORD_STATUS between 10200001 and 10200004                  
----                  UNION ALL
----                  select DISTINCT TLON_CURRENCY_CODE,TLON_LOCAL_BANK,
----                         33399999,33899999,TLON_COMPANY_CODE
----                  from TRTRAN081 where TLON_LOAN_NUMBER = varTradeReference 
----                  and TLON_RECORD_STATUS between 10200001 and 10200004;                    
--                exception when no_data_found then
--                   numCurrencyCode := 0;
--                   numLocalBank := 0;
--                   numPortfolio := 0;
--                   numSubportfolio :=0;
--                   numCompany := 0;
--                   numLocationCode :=0;
--                end ;
--              -- IF numAction = GConst.EDITSAVE then
--                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
--                  varDealReference := 'CASH' || fncGenerateSerial(SERIALDEAL,numCompany);   
--                  varLocation:= pkgReturnCursor.fncGetDescription(numLocationCode,2);
--                  varOperation := 'Inserting Cash deal to main table';
--                  insert into trtran001
--                    (deal_company_code,DEAL_LOCATION_CODE,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--                    deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
--                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
--                    deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--                    deal_bo_remark,DEAL_CURRENCY_PAIR)
--                  values (numCompany,numLocationCode, varDealReference, 1, datWorkDate, 26000001,case when numImportExport < 25900050 then 25300002 else 25300001 end,
--                    25200002,25400001,NumLocalBank,numCurrencyCode, numOtherCurrency,numCashRate, 1, (case when numDirectIndirect =12400001 then numCashDeal else
--                          round(numCashDeal/numCashRate,2) end),
--                    --Round(numCashRate * numCashDeal)
--                    (case when numDirectIndirect =12400001 then Round(numCashRate * numCashDeal) else numCashDeal end)
--                    ,0,0,datWorkDate,datWorkDate,null, 'System',
--                    NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--                    null,null,null,0,numCashRate,0,numPortfolio,0,0,numSubportfolio, NULL,
--                    'Cash Delivery ' || varTradeReference, numCurrencyPair);              
--                  varOperation := 'Inserting Cash Deal Cancellation';
--                 insert into trtran006
--                    (cdel_company_code,CDEL_LOCATION_CODE,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
--                  select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number, 1, 1, varTradeReference, NumTradeSerial,
--                    datTemp, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--                    deal_bo_remark,varBatchNo
--                    from trtran001
--                    where deal_deal_number = varDealReference;              
--                  begin 
--                   select nvl(MAX(HEDG_TRADE_SERIAL),1) +1
--                   into  numserial 
--                    from trtran004 
--                    where hedg_trade_reference=varTradeReference;
--                  exception 
--                   when no_data_found then
--                     numserial:=1;
--                  end ;
--                  varOperation := 'Inserting Cash deal Linking details';
----                  insert into trtran004
----                  (hedg_company_code,hedg_trade_reference,hedg_deal_number,
----                    hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
----                    hedg_create_date,hedg_entry_detail,hedg_record_status,
----                    hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
----                    HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
----                  values(numCompany,varTradeReference,varDealReference,
----                  1, numCashDeal,0, Round(numCashDeal * numCashRate),
----                  sysdate,NULL,10200012, 32200001,12400002,numserial,varBatchNo,datWorkDate);
--                  varOperation := 'After linking Cash deal Linking details';                
--                  --numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--               -- END IF;
--              End loop;
--      end if;
--
--      GLOG.log_write('FOR ADDSAVE FORWARDSETTLEMENT: '|| varBatchNo); 
--     varOperation := 'Extracting FORWARDSETTLEMENT records ' || varBatchNo;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);
--      varXPath := '//FORWARDSETTLEMENT/DROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--        varXPath := '//FORWARDSETTLEMENT/DROW[@DNUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--        GLOG.log_write('Inside Loop FORWARDSETTLEMENT');  
--         varOperation := 'Inside Loop FORWARDSETTLEMENT';
--          nodTemp := xmlDom.item(nlsTemp, numSub);
--          nmpTemp := xmlDom.getAttributes(nodTemp);
--          nodTemp1 := xmlDom.item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--
--          GLOG.log_write('Inside Loop FORWARDSETTLEMENT numtemp: '|| numtemp); 
--          varTemp := varXPath || numTemp || '"]/DealNumber';
--          varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--          varTemp := varXPath || numTemp || '"]/TradeRefNo';           
--          varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--          varTemp := varXPath || numTemp || '"]/TradeSerial';
--          numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);     
--
--          varTemp := varXPath || numTemp || '"]/ImpExp';
--          numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--          varTemp := varXPath || numTemp || '"]/BatchNo';
--          varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);      
--
--          varTemp := varXPath || numTemp || '"]/ForwardRate';
--          numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));          
--
--          varTemp := varXPath || numTemp || '"]/EDBenefit';
--          numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--          varTemp := varXPath || numTemp || '"]/EDAmount';
--          numEDAmount := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));     
--
--          varTemp := varXPath || numTemp || '"]/ForwardFcy';
--          numReverseAmount := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--
--          varTemp := varXPath || numTemp || '"]/ReferenceRate';
--          numRefrate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp)); 
--
--          numSerial := 1;--GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--          varOperation := 'select Statement to get values for DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
--                       DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE for ' ||varDealReference;
--                select DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
--                       DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE,deal_Currency_pair
--                  into  numCurrencyCode,numLocalBank,numPortfolio,
--                      numSubportfolio,numCompany,numCurrencypair
--                from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
--                and DEAL_record_status between 10200001 and 10200004;
--
--                varOperation := 'select numPandL ' ||varDealReference;
--          select
--            case
--  --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--  --            round(numReverseAmount * (deal_forward_rate - numPremium))
--            when numFinal != deal_exchange_rate then
--              decode(deal_buy_sell, GConst.PURCHASEDEAL,
--                Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--                Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--            else 0
--            end
--            into numPandL
--            from trtran001
--            where deal_deal_number = varDealReference;
--            numPandL := numEDAmount;
--          varOperation := 'Inserting entries to Hedge Table, if necessary';
----          BEGIN
----            SELECT NVL(max(HEDG_TRADE_SERIAL),0) +1
----            INTO numTradeSerial
----            FROM trtran004
----            WHERE hedg_trade_reference=varTradeReference;
----          EXCEPTION
----          WHEN no_data_found THEN
----            numTradeSerial:=1;
----          END ;
----          BEGIN
----            SELECT NVL(max(hedg_deal_serial),0) +1
----            INTO numSerial
----            FROM trtran004
----            WHERE hedg_deal_number=varDealReference;
----          EXCEPTION
----          WHEN no_data_found THEN
----            numSerial:=1;
----          END ;   
--
--
----            insert into trtran004
----            (hedg_company_code,hedg_trade_reference,hedg_deal_number,
----              hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
----              hedg_create_date,hedg_entry_detail,hedg_record_status,
----              hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
----              HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
----            values(numCompany,varTradeReference,varDealReference,
----            numSerial, numReverseAmount,0, Round(numReverseAmount * numFinal),
----            sysdate,NULL,10200012, 32200001,12400002,numTradeSerial,varBatchNo,datWorkDate);
--
--          select CNDI_DIRECT_INDIRECT
--            into numDirectIndirect
--           from trmaster256
--           where CNDI_RECORD_STATUS not in (10200005,10200006)
--             and CNDI_PICK_CODE =numCurrencypair;
--
--          varOperation := 'FORWARDSETTLEMENT Inserting Hedge Deal Delivery';
--          insert into trtran006(cdel_company_code,CDEL_LOCATION_CODE, cdel_deal_number,
--            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
--            CDEL_BATCH_NUMBER,cdel_cashflow_date,CDEL_REFERENCE_RATE)
--            select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number,
--            deal_serial_number,
--            (select NVL(max(cdel_reverse_serial),0) + 1
--              from trtran006
--              where cdel_deal_number = varDealReference),
--            datTemp, deal_hedge_trade, Gconst.Dealdelivery,
--            (case when numDirectIndirect=12400001 then  numReverseAmount
--              else round(numReverseAmount/numFinal,2) end)
--            , numFinal,
--            --Round(numReverseAmount * numFinal),
--            (case when numDirectIndirect=12400001 then round(numReverseAmount*numFinal,2) 
--              else numReverseAmount end),
--            1,
--            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
--            varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datTemp,numRefrate
--            -- Changed by MR on 08-12-2021 insted datWorkDate changed to DatTemp
--            from trtran001
--            where deal_deal_number = varDealReference;
--            if numPandL != 0 then
--               varOperation := 'calling  prcEDCVoucherPosting ';
--
--        prcEDCVoucherPosting(varDealReference,numReverseAmount,numFinal,numPandL,numAction);
--
--                varOperation := 'complete prcEDCVoucherPosting ';
--
--
----              select CDEL_REVERSE_SERIAL into numTemp1
----                from trtran006
----              where cdel_deal_number = varDealReference
----                    and cdel_trade_reference = varTradeReference
----                    and Cdel_Trade_Serial = numTradeSerial;
--
--             begin
--              select nvl(max(CDEL_REVERSE_SERIAL),1)
--                into numTemp1
--                from trtran006
--              where cdel_deal_number = varDealReference;
--            exception 
--             when others then
--               numTemp1:=1;
--            end;
--
--              varOperation := 'Inserting Current Account voucher for PL';
----              varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----              insert into trtran008 (bcac_company_code, bcac_location_code,
----                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                bcac_create_date, bcac_local_merchant, bcac_record_status,
----                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----              select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
----                GConst.TRANSACTIONCREDIT),24900049,24800051,
----                deal_deal_number,numTemp1, 
----                deal_base_currency, 0,
----                0, numPandL, 'Deal Reversal No: ' ||
----                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                (select lbnk_account_number
----                  from trmaster306
----                  where lbnk_pick_code = deal_counter_party),varBatchNo
----                from trtran001
----                where deal_deal_number = varDealReference
----                and deal_serial_number = 1;    
----              varOperation := 'Inserting Interest Current';
----              varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----              insert into trtran008 (bcac_company_code, bcac_location_code,
----                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                bcac_create_date, bcac_local_merchant, bcac_record_status,
----                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----              select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
----                GConst.TRANSACTIONDEBIT),24900030,24800051,
----                deal_deal_number,numTemp1,
----                deal_base_currency, 0,
----                0, (numPandL), 'Deal Reversal No: ' ||
----                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                (select lbnk_account_number
----                  from trmaster306
----                  where lbnk_pick_code = deal_counter_party),varBatchNo
----                from trtran001
----                where deal_deal_number = varDealReference
----                and deal_serial_number = 1;  
--
--            else
--              varVoucher := NULL;
--            end if;  
--            GLog.log_write('Calling Complete Utlization for the Reference Number ' || varDealReference || ' Util Type ' || Gconst.UTILHEDGEDEAL || ' Date ' || datWorkDate);
--            numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);
--            --numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate)
--        End Loop;
--        numTradeSerial := 0;
--      end if;
--
--      GLOG.log_write('FOR ADDSAVE CROSSFORWARDSETTLEMENT: '|| varBatchNo); 
--      varOperation := 'Extracting CROSSFORWARDSETTLEMENT records ' || varBatchNo;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);       
--      varOperation := 'Before Loop';
--      varXPath := '//CROSSFORWARDSETTLEMENT/DROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--            varXPath := '//CROSSFORWARDSETTLEMENT/DROW[@DNUM="';
--            for numSub in 0..xmlDom.getLength(nlsTemp) -1
--              Loop
--                GLOG.log_write('Inside Loop CROSSFORWARDSETTLEMENT');  
--                varOperation := 'Inside Loop CROSSFORWARDSETTLEMENT';
--                nodTemp := xmlDom.item(nlsTemp, numSub);
--                nmpTemp := xmlDom.getAttributes(nodTemp);
--                nodtemp1 := xmldom.item(nmptemp, 0);
--                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--                varTradeReference := '';
--
--                GLOG.log_write('Inside Loop CROSSFORWARDSETTLEMENT numtemp: '|| numtemp); 
--                varTemp := varXPath || numTemp || '"]/CImpExp';
--                numImportExport := GConst.fncGetNodeValue(nodFinal, varTemp);
----            
----                varTemp := varXPath || numTemp || '"]/CEXPSerial';
----                numTradeSerial := GConst.fncGetNodeValue(nodFinal, varTemp);
----            
--                varTemp := varXPath || numTemp || '"]/CBatchNo';
--                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/CDealNumber';
--                varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/CForwardRate';
--                numFinal := Gconst.Fncgetnodevalue(Nodfinal, Vartemp);
--
--                varTemp := varXPath || numTemp || '"]/CForwardFcy';
--                numReverseAmount := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/DealType';
--                varTemp1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/CEDBenefit';
--                numPremium := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/CEDAmount';
--                numEDAmount := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/TradeCurrency';
--                numCurrencyCode := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                varTemp := varXPath || numTemp || '"]/OtherCurrency';
--                numOtherCurrency := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--                  select CNDI_DIRECT_INDIRECT,CNDI_PICK_CODE
--                    into numDirectIndirect,numCurrencyPair
--                   from trmaster256
--                    where CNDI_BASE_CURRENCY=numCurrencyCode
--                      and CNDI_OTHER_CURRENCY=numOtherCurrency
--                      and CNDI_RECORD_STATUS not in (10200005,10200006);
--
--                numSerial := 2; -- For Cross currency  To identify in Queries 
--                varOperation := 'Before Batch No DealType';
--                if varTemp1 = 'Other' then
--                  varOperation := 'After Batch No';
--                      select DEAL_COUNTER_PARTY,DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE,deal_currency_pair
--                        into  numLocalBank,numPortfolio,numSubportfolio,numCompany,numCurrencyPair
--                      from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
--                      and DEAL_record_status between 10200001 and 10200004;
--                  select
--                  case
--        --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--        --            round(numReverseAmount * (deal_forward_rate - numPremium))
--                  when numFinal != deal_exchange_rate then
--                    decode(deal_buy_sell, GConst.PURCHASEDEAL,
--                      Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--                      Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--                  else 0
--                  end
--                  into numPandL
--                  from trtran001
--                  where deal_deal_number = varDealReference;
--                  numPandL:=numEDAmount;
--                 -- delete from temp;commit;
--               --   insert into temp values('varDealReference',varDealReference);commit;
--                varOperation:='CROSSFORWARDSETTLEMENT Extracting Maximum Serial Number';
--
--                  select NVL(max(cdel_reverse_serial),0) + 1
--                   into numTemp1
--                    from trtran006
--                    where cdel_deal_number = varDealReference;
--
--
--
--                varOperation := 'CROSSFORWARDSETTLEMENT Inserting Hedge Deal Delivery';
--                insert into trtran006(cdel_company_code,CDEL_LOCATION_CODE, cdel_deal_number,
--                  cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--                  cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--                  cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--                  cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--                  cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--                  Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--                  cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
--                  CDEL_BATCH_NUMBER,cdel_cashflow_date)
--                  select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number,
--                  deal_serial_number,numTemp1,
--                  datTemp, deal_hedge_trade, Gconst.Dealdelivery,
--                  (case when numDirectIndirect =12400001 then numReverseAmount
--                    else round(numReverseAmount/numFinal) end)
--                  , numFinal,
--                  (case when numDirectIndirect =12400001 then numReverseAmount*numFinal
--                    else numReverseAmount end)
--                  --Round(numReverseAmount * numFinal)
--                  , 1,
--                  Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                  SYSDATE, NULL, Gconst.Statusentry, varTradeReference, 1, numPandL,
--                  varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datTemp
--                  -- cahnged by MR
--                  from trtran001
--                  where deal_deal_number = varDealReference;
--                  if numPandL != 0 then
--
----                    select CDEL_REVERSE_SERIAL into numTemp1
----                      from trtran006
----                    where cdel_deal_number = varDealReference
----                          and cdel_trade_reference = varTradeReference
----                          and Cdel_Trade_Serial = numTradeSerial;
--
--                    varOperation := 'Inserting Current Account voucher for PL';
----                    varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----                    insert into trtran008 (bcac_company_code, bcac_location_code,
----                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                      bcac_create_date, bcac_local_merchant, bcac_record_status,
----                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
----                      GConst.TRANSACTIONCREDIT),24900049,24800051,
----                      deal_deal_number,numTemp1, 
----                      deal_base_currency, 0,
----                      0, numPandL, 'Deal Reversal No: ' ||
----                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                      (select lbnk_account_number
----                        from trmaster306
----                        where lbnk_pick_code = deal_counter_party),varBatchNo
----                      from trtran001
----                      where deal_deal_number = varDealReference
----                      and deal_serial_number = 1;    
----                    varOperation := 'Inserting Interest Current';
----                    varVoucher := varCompany || '/VOC/' || fncGenerateSerial(SERIALCURRENT);
----                    insert into trtran008 (bcac_company_code, bcac_location_code,
----                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
----                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
----                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
----                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
----                      bcac_create_date, bcac_local_merchant, bcac_record_status,
----                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
----                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
----                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
----                      GConst.TRANSACTIONDEBIT),24900030,24800051,
----                      deal_deal_number,numTemp1,
----                      deal_base_currency, 0,
----                      0, (numPandL), 'Deal Reversal No: ' ||
----                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
----                      (select lbnk_account_number
----                        from trmaster306
----                        where lbnk_pick_code = deal_counter_party),varBatchNo
----                      from trtran001
----                      where deal_deal_number = varDealReference
----                      and deal_serial_number = 1;  
--
--                  else
--                    varVoucher := NULL;
--                  end if;           
--                  numError := fncCompleteUtilization(varDealReference,Gconst.UTILHEDGEDEAL,datWorkDate);
--               else
--                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
--                  varDealReference := 'CASH' || fncGenerateSerial(SERIALDEAL,numCompany);
--
--                  begin
--                      varTemp := varXPath || numTemp || '"]/CashCurrencyPair';
--                      numCurrencyPair := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                  exception
--                  when others then
--                    numCurrencyPair:=0;
--                  end;
--
--                  varOperation := 'Inserting Cash deal to main table';
--                  insert into trtran001
--                    (deal_company_code,DEAL_LOCATION_CODE,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--                    deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
--                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
--                    deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--                    deal_bo_remark,DEAL_CURRENCY_PAIR)
--                  values (numCompany,numLocationCode, varDealReference, 1, datWorkDate, 26000001,numImportExport,--case when numImportExport < 25900050 then 25300002 else 25300001 end,
--                    25200002,25400001,NumLocalBank,numCurrencyCode, numOtherCurrency,numFinal, 1, 
--                    --numReverseAmount,
--                    (case when numDirectIndirect=12400001 then numReverseAmount else round (numReverseAmount/numFinal,2) end),
--                    (case when numDirectIndirect=12400001 then Round(numFinal * numReverseAmount) else (numReverseAmount) end),
--                    0,0,datWorkDate,datWorkDate,null, 'System',
--                    NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--                    null,null,null,0,numFinal,0,numPortfolio,0,0,numSubportfolio, NULL,
--                    'Cash Delivery ' || varTradeReference, numCurrencyPair);              
--                  varOperation := 'Inserting Cash Deal Cancellation';
--                  insert into trtran006
--                    (cdel_company_code,CDEL_LOCATION_CODE,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
--                  select deal_company_code,DEAL_LOCATION_CODE, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
--                    datTemp, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,numPremium,numPandL,33500001,null,null,deal_bank_reference,
--                    deal_bo_remark,varBatchNo
--                    from trtran001
--                    where deal_deal_number = varDealReference;              
--               end if;   
--              End loop;
--      end if;
--    end if;
--    return numError;
--Exception
--        When others then
--          numError := SQLCODE;
--          varError := SQLERRM;
--          varError := GConst.fncReturnError('fncExposuresettlement', numError, varMessage,
--                          varOperation, varError);
--           GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncExposuresettlement');           
--          raise_application_error(-20101, varError);
--          RETURN numError;
--End fncExposuresettlement;

Function fncLoanDeal
    (   RecordDetail in GConst.gClobType%Type,
        TradeReference in varchar2)
    return number
    is
--  Created on 21/05/08m
    numError            number;
    numTemp             number;
    numAction           number(4);
    numSerial           number(5);
    numSerial1          number(5);    
    numsubserial        number(5);
    numStatus           number(8);
    numCompany          number(8);
    numLocation         number(8);
    numCode             number(8);
    numCode1            number(8);
    numCode2            number(8);
    numCode4            number(8);
    numFcy              number(15,4);
    Numfcy1             Number(15,4);
--Updated From cygnet
    Numamount1          Number(15,4); -- ishwarachandra
    Numutilization1     Number(15,4);
--
    numInr              number(15,2);
    numRate             number(15,6);
    numRate1            number(15,6);
    Numrate2            Number(15,6);
    numCashRate         number(15,6);
 --Updated from Cygnet
    Numfinalrate        Number(15,6);
    numBaseRate         number(15,6);
    numBaseRate1        number(15,6);
    numBaseRate2        number(15,6);
    Numbasefinalrate    Number(15,6);
--
    numReversed         number(15,4);
    numPL               number(15,2);
    numRateInr          number(15,2);
    numDealReverse      number(15,2);
    numBillReverse      number(15,2);
    varReference        varchar2(25);
    varReference1       varchar2(25);
    varReference2       varchar2(25);
    varTrade            varchar2(25);
    varEntity           varchar2(30);
    varXPath            varchar2(1024);
    varTemp             varchar2(1024);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         Date;
    datMaturity         date;
    datTemp             date;
    datReference        date;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;

    clbTemp             clob;
Begin
    numError := 0;

    xmlTemp := xmlType(RecordDetail);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);
    varTrade := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTrade);
    numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', varTrade);
    datReference := GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datReference);
    numBillReverse := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numBillReverse);
    numCashRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);

    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

    varOperation := 'Checking for Deal Delivery';
    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numDealReverse := 0;

    if xmlDom.getLength(nlsTemp) > 0 then
      varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/DealNumber';
          varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varTrade := GConst.fncGetNodeValue(nodFinal, varTemp);
--          varTemp := varXPath || numTemp || '"]/HedgedBase';
--          Numfcy1 := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
          varTemp := varXPath || numTemp || '"]/SpotRate'; --Updated From cygnet
          Numrate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
  --Updated from Cygnet
  -- Node Name changed from FrwRate to Premium for TOI by TMM 31/01/14
          varTemp := varXPath || numTemp || '"]/Premium';
          numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

          varTemp := varXPath || numTemp || '"]/MarginRate';
          numRate2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

          varTemp := varXPath || numTemp || '"]/FinalRate';
          Numfinalrate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
 --
          varTemp := varXPath || numTemp || '"]/ReverseNow';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          numDealReverse := numDealReverse + numFcy;
          varTemp := varXPath || numTemp || '"]/SerialNumber';
          numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/SubserialNumber';
          numsubserial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/HedgingWith';
          numcode2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

        if numcode2=Gconst.ForwardContract then
           if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--Updated from Cygnet
                if numBillReverse > numDealReverse then
                  prcCashDealEntry(datWorkDate,varTrade,numCashRate,numBillReverse - numDealReverse ,datWorkDate);
                End if;

                select deal_spot_rate,deal_forward_rate,
                       deal_margin_rate,deal_exchange_rate
                  into numBaseRate, numBaseRate1,
                       numBaseRate2, numbaseFinalRate
                  from trtran001
                  Where Deal_Deal_Number = Varreference;
--
                if numCode = GConst.INDIANRUPEE then
                  numInr := Round(numFcy * numRate);
                  numFcy1 := 0.00;
                else
                  numFcy1 := Round(numFcy * numRate);
                  numInr := Round(numFcy * numRate1);
                end if;
 -- For Early Delivery the premium / discount is taken as Profit / Loss
-- Added by TMM on 30/05/13
                if datMaturity > datReference then
                  numPL := Round(numFcy * numRate1);
                elsif numFinalRate != numBaseFinalRate then -- Updated from Cygnet
                  If Numcode1 = Gconst.Purchasedeal Then
                    numPL := Round(numFCY * numBaseFinalRate) - Round(numFCY * numFinalRate); -- Updated From Cygnet
                  Elsif Numcode1 = Gconst.Saledeal Then
                    numPL := Round(numFCY * numFinalRate) - Round(numFCY * numBaseFinalRate); -- Updated from Cygnet
                  end if;
                else
                  numPL := 0;
                End if;

                if numStatus = GConst.LOTNEW then

                  if numPl != 0 then
                    varOperation := 'Inserting voucher for PL';
                    varReference1 := 'CA/VOC/' || fncGenerateSerial(SERIALCURRENT);
                    insert into trtran008 (bcac_company_code, bcac_location_code,
                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                      bcac_create_date, bcac_local_merchant, bcac_record_status,
                      bcac_record_type, bcac_account_number)
                    select numCompany, numLocation, deal_counter_party, varReference1,
                      datMaturity, decode(sign(numPL), -1, GConst.TRANSACTIONDEBIT,
                      GConst.TRANSACTIONCREDIT),GConst.ACEXCHANGE,
                      decode(numCode1,GConst.PURCHASEDEAL,
                      GConst.EVENTPURCHASE, GConst.EVENTSALE),
                      varReference, 0, deal_base_currency, deal_base_amount,
                      numRate, deal_amount_local, 'Deal Reversal No: ' ||
                      deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002,
                      (select lbnk_account_number
                        from trmaster306
                        where lbnk_pick_code = deal_counter_party)
                      from trtran001
                      where deal_deal_number = varReference
                      and deal_serial_number = numSerial;
                  end if;

                  varOperation := 'Inserting Hedge Deal Delivery';
                  insert into trtran006(cdel_company_code, cdel_deal_number,
                    cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
                    cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
                    cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
                    cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
                    cdel_entry_detail, cdel_record_status, cdel_trade_reference,
                    Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
                    cdel_spot_rate,cdel_forward_rate,cdel_margin_rate) -- Updated from Cygnet
                  values(numCompany, varReference, 1,
                    (select NVL(max(cdel_reverse_serial),0) + 1
                      from trtran006
                      where cdel_deal_number = varReference),
                    Datworkdate, Gconst.Hedgedeal, Gconst.Dealdelivery,
                    numFcy, numFinalRate, numFcy1, numRate1, numInr, -- Updated From Cygnet
                    to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
                    Sysdate, Null, Gconst.Statusentry, Vartrade, Numserial,
                    numPL, varReference1,numrate,numrate1,numrate2); --Updated From Cygnet
                elsif numAction = GConst.LOTMODIFIED then
                  if numFcy > 0 then
                    varOperation := 'Updating Hedge Deal Delivery';
                    update trtran006
                      set cdel_cancel_amount = numFcy,
                      cdel_other_amount = numFcy1,
                      cdel_cancel_rate = numRate,
                      cdel_local_rate = numRate1,
                      cdel_cancel_inr = numInr
                      where cdel_trade_reference = varTrade
                      and cdel_trade_serial = numSerial;
                  else
                    varOperation := 'Deleting Hedge Deal Delivery';
                    update trtran006
                      set cdel_record_status = GConst.STATUSDELETED
                      where cdel_trade_reference = varTrade
                      and cdel_trade_serial = numSerial;
                  end if;
                end if;

                numError := fncCompleteUtilization(varReference,  GConst.UTILHEDGEDEAL,
                                datWorkDate);
           -- End Loop;

          elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
              varOperation := 'Processing for Delete / Confirm';
              select decode(numAction,
                GConst.DELETESAVE, GConst.STATUSDELETED,
                GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
                into numStatus
                from dual;

              update trtran006
                set cdel_record_status = numStatus
                where cdel_trade_reference = varTrade
                and cdel_trade_serial = numSerial;
          End if;

      elsif numcode2= Gconst.OptionContract then
        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
            if numStatus = GConst.LOTNEW then
                  varOperation := 'Inserting Hedge Deal Delivery';
                  insert into trtran073(corv_company_code, corv_deal_number,
                    corv_serial_number, corv_subserial_number,corv_reverse_serial,
                    corv_exercise_date,corv_exercise_type,  corv_base_amount,
                    corv_exercise_rate, corv_other_amount, corv_wash_rate,
                    corv_time_stamp, corv_create_date,
                    corv_record_status, corv_trade_reference,
                    corv_trade_serial)
                  values(numCompany, varReference,
                    numserial1,numsubserial,
                    (select NVL(max(corv_reverse_serial),0) + 1
                      from trtran073
                      where corv_deal_number = varReference),
                    datWorkDate,  GConst.DEALDELIVERY,
                    numFcy, numRate, numFcy1, numRate1,
                    to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
                    sysdate,  GConst.STATUSENTRY, varTrade, numSerial);
                elsif numAction = GConst.LOTMODIFIED then
                  if numFcy > 0 then
                    varOperation := 'Updating Hedge Deal Delivery';
                    update trtran073
                      set corv_base_amount = numFcy,
                      corv_other_amount = numFcy1,
                      corv_exercise_rate = numRate,
                      --cdel_local_rate = numRate1,
                      --cdel_cancel_inr = numInr
                      corv_record_status =10200004
                      where corv_trade_reference = varTrade
                      and corv_trade_serial = numSerial;
                  else
                    varOperation := 'Deleting Hedge Deal Delivery';
                    update trtran073
                      set corv_record_status = GConst.STATUSDELETED
                      where corv_trade_reference = varTrade
                      and corv_trade_serial = numSerial;
                  end if;
                end if;

                numError := fncCompleteUtilization(varReference,  GConst.UTILOPTIONHEDGEDEAL,
                                datWorkDate,numSerial1);
         --   End Loop;

          elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
              varOperation := 'Processing for Delete / Confirm';
              select decode(numAction,
                GConst.DELETESAVE, GConst.STATUSDELETED,
                GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
                into numStatus
                from dual;

              update trtran073
                set corv_record_status = numStatus
                where corv_trade_reference = varTrade
                and corv_trade_serial = numSerial;
         End if;
     end if;
   end loop;
  End if;

    --------------- Added By Manjunath Reddy For Reversing OF CrossCurrency Deals


    varOperation := 'Checking for Deal Delivery';
    varXPath := '//CommandSet/CrossDealDetails/ReturnFields/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

    if xmlDom.getLength(nlsTemp) > 0 then
 --     numRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);
      varXPath := '//CommandSet/CrossDealDetails/ReturnFields/ROWD[@NUM="';


      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/DealNumber';
          varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varTrade := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/HedgedBase';
          numFcy1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/BaseRate';
          numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/REVERSEAMOUNT';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numtemp || '"]/DeliveryFrom';
          varReference2 := GConst.fncGetNodeValue(nodFinal, varTemp);

          select pkgReturnCursor.fncRollover(deal_deal_number,2),
            pkgReturnCursor.fncRollover(deal_deal_number,4),
            deal_maturity_date,
            deal_other_currency, deal_buy_sell
            into numRate2, numRate1, datMaturity, numCode, numCode1
            from trtran001
            where deal_deal_number = varReference;

          if numCode = GConst.INDIANRUPEE then
            numInr := Round(numFcy * numRate);
            numRateInr:= numRate;
            numFcy1 := 0.00;
          else
            numFcy1 := Round(numFcy * numRate);
            numInr := Round(numFcy * numRate1);
            numRateInr:= numRate1;
          end if;

          if numRate != numRate2 then

            if numCode1 = GConst.PURCHASEDEAL then
              numPL := Round(numFCY * numRate) - Round(numFCY * numRate2);
            elsif numCode1 = GConst.SALEDEAL then
              numPL := Round(numFCY * numRate2) - Round(numFCY * numRate);
            end if;
          else
            numPL := 0;
          End if;

          if numStatus = GConst.LOTNEW then


            varOperation := 'Inserting Hedge Deal Delivery';
            insert into trtran006(cdel_company_code, cdel_deal_number,
              cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
              cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
              cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
              cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
              cdel_entry_detail, cdel_record_status, cdel_trade_reference,
              cdel_trade_serial, cdel_profit_loss, cdel_pl_voucher,
              cdel_delivery_from, cdel_delivery_serial)
            values(numCompany, varReference, 1,
              (select NVL(max(cdel_reverse_serial),0) + 1
                from trtran006
                where cdel_deal_number = varReference),
              datWorkDate, GConst.HEDGEDEAL, GConst.DEALDELIVERY,
              numFcy, numRate, numFcy1, numRate1, numInr,
              to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
              sysdate, null, GConst.STATUSENTRY, varTrade, numSerial,
              numPL, varReference1,varReference2,1);

            varOperation := 'Inserting Bills Send For Collection';

            varOperation := 'Selecting particulars of Trade Reference';
            select trad_company_code, trad_buyer_seller, trad_trade_currency,
              trad_product_code, trad_product_description,
              trad_import_export
              into numCompany, numCode, numCode1, numCode2,
              varTemp,  numCode4
              from TradeRegister
              where trad_trade_reference = varTrade;

            varOperation := 'Getting Serial Number';
            varReference1 := pkgReturnCursor.fncGetDescription(GConst.TRADECOLLECTION, GConst.PICKUPSHORT);
            --Here I am Hard Coding To Bill Send For Collection
            varReference1 := varReference1 || '/' || fncGenerateSerial(SERIALTRADE);


             varOperation := 'Inserting Trade Order Details into Bill Relization table';
              insert into trtran003 (brel_company_code, brel_trade_reference,
                 brel_reverse_serial, brel_entry_date, brel_user_reference,
                 brel_reference_date, brel_reversal_type,brel_reversal_fcy,
                 brel_reversal_rate, brel_reversal_inr,brel_period_code,
                 brel_trade_period,brel_maturity_from,brel_maturity_date,
                 brel_create_date,brel_record_status,brel_local_bank)
                 values (numCompany,varTrade,
                     (select nvl(max(brel_reverse_serial),0)+1
                        from trtran003
                         where brel_trade_reference=varTrade),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
                 GConst.BILLCOLLECTION,numFcy,numRateInr,numInr,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                 sysdate,GConst.STATUSENTRY,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY));

          varOperation := 'Inserting Bill realization Details into Bill Relization table';
              insert into trtran003 (brel_company_code, brel_trade_reference,
                 brel_reverse_serial, brel_entry_date, brel_user_reference,
                 brel_reference_date, brel_reversal_type,brel_reversal_fcy,
                 brel_reversal_rate, brel_reversal_inr,brel_period_code,
                 brel_trade_period,brel_maturity_from,brel_maturity_date,
                 brel_create_date,brel_record_status,brel_local_bank)
                 values (numCompany,varReference1,
                     (select nvl(max(brel_reverse_serial),0)+1
                        from trtran003
                        where brel_trade_reference=varReference1),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
                 GConst.BILLCOLLECTION,numFcy,numRateInr,numInr,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                 sysdate,GConst.STATUSENTRY,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY));


            varOperation := 'Adding record for Bill Realization';

              insert into TradeRegister(trad_company_code, trad_trade_reference,
                trad_reverse_reference, trad_reverse_serial, trad_import_export,
                trad_entry_date, trad_user_reference, trad_reference_date,
                trad_buyer_seller, trad_trade_currency, trad_product_code,
                 trad_trade_fcy, trad_trade_rate,
                trad_trade_inr, trad_period_code, trad_trade_period,
                trad_maturity_from, trad_maturity_date, trad_local_bank,
                trad_create_date, trad_entry_detail, trad_record_status, trad_process_complete)
                values(numCompany, varReference1, varTrade,
                (select nvl(max(trad_reverse_serial),0)+1
                        from trtran002
                        where trad_reverse_reference=varTrade), GConst.BILLCOLLECTION,
                GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
                numCode, numCode1, numCode2,
                numFcy,numRateInr,numInr,
                GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
                GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
                sysdate, null, GConst.STATUSENTRY, GConst.OPTIONNO);

                numError := fncCompleteUtilization(varTrade, Gconst.UTILEXPORTS,
                              datWorkDate);


          elsif numAction = GConst.LOTMODIFIED then
            if numFcy > 0 then
              varOperation := 'Updating Hedge Deal Delivery';
              update trtran006
                set cdel_cancel_amount = numFcy,
                cdel_other_amount = numFcy1,
                cdel_cancel_rate = numRate,
                cdel_local_rate = numRate1,
                cdel_cancel_inr = numInr,
                cdel_delivery_from = varReference2,
                cdel_delivery_serial=1
                where cdel_trade_reference = varTrade
                and cdel_trade_serial = numSerial;

              varOperation := 'Updating Relization Of Cross Delivery';
              update trtran003
                set brel_reversal_fcy=numFcy,
                brel_reversal_rate=numRateInr,
                brel_reversal_inr=numInr,
                brel_record_status=Gconst.STATUSUPDATED,
                brel_user_reference=GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp)
                where brel_trade_reference=varTrade
                and brel_reverse_serial=numSerial;
              varOperation := 'Updating Relization Of Cross Delivery';
              update trtran003
                set brel_reversal_fcy=numFcy,
                brel_reversal_rate=numRateInr,
                brel_reversal_inr=numInr,
                brel_record_status=Gconst.STATUSUPDATED,
                brel_user_reference=GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp)
                where brel_trade_reference=GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTemp)
                and brel_reverse_serial=numSerial;

              update traderegister
                set trad_trade_fcy=numFcy,
                trad_trade_rate=numRateInr,
                trad_trade_inr =numinr,
                trad_record_status=Gconst.STATUSUPDATED
                where trad_trade_reference= GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTemp)
                and trad_reverse_serial = numserial;

            else
              varOperation := 'Deleting Hedge Deal Delivery';
              update trtran006
                set cdel_record_status = GConst.STATUSDELETED
                where cdel_trade_reference = varTrade
                and cdel_trade_serial = numSerial;
            end if;
          end if;

          numError := fncCompleteUtilization(varReference,  GConst.UTILHEDGEDEAL,
                          datWorkDate);
      End Loop;

    elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        select decode(numAction,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
          into numStatus
          from dual;

        update trtran006
          set cdel_record_status = numStatus
          where cdel_trade_reference = varTrade
          and cdel_trade_serial = numSerial;
    End if;

  End if;

    return numError;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('LoanDeal', numError, varMessage,
                          varOperation, varError);
           GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.fncLoanDeal');                        
          raise_application_error(-20101, varError);
          return numError;
End fncLoanDeal;





Function fncMiscellaneousUpdates
    (   RecordDetail in GConst.gClobType%Type,
        EditType in number,
        ErrorNumber in out nocopy number)
    return clob
    is
--created on 20/09/07
    numError            number;
    numTemp             number;
    numTemp1            number;
    numStatus           number;
    numSub              number(3);
    numSub1             number(3);
    numSerial           number(5);
    numSerial1          number(5);
    numSerial2          number(5);
    numAction           number(4);
    numCompany          number(8);
    numLocation         number(8);
    numCode             number(8);
    numCode1            number(8);
    numCode2            number(8);
    numCode3            number(8);
    numCode4            number(8);
    numKeyValue         number(8);
    numKeyNumber        number(8);


    numCross            number(15,2);
    numFCY              number(15,2);
    numFCY1             number(15,2);
    numFCY2             number(15,2);
    numFCY3             number(15,2);
    numFcy4             number(15,2);
    numFcy5             number(15,2);
    numFcy6             number(15,2);
    numINR              number(15,2);
    numRate             number(15,6);
    numRate1            number(15,6);
    numRate2            number(15,6);
    numRate3            number(15,6);
    numRateSr           number(15);
    numRenewalDepositAmt number(15,2);
    numRenewalInterestRate  number(6,2);
    numRenewalMaturityAmount number(15,2);
    datRenewalMaturityDate  date;
    numRenewalPeriodicalInterest number(15,2);
    numrenewalintamt  NUMBER(15,2);
    numpnlamt         NUMBER(15,2);
    numpramt          number(15,2);    
    numsrno           number(3);
    varReference        varchar2(30);
    varReferenceNo       varchar2(30);
    varReference1       varchar2(30);
    varUserID           varchar2(30);
    varEntity           varchar2(30);
    varRelease          varchar2(50);
    varTemp             varchar2(4000);
    varTemp1            varchar2(4000);
    varTemp3            varchar2(4000);
    varTemp4            varchar2(4000);
    varTemp5            varchar2(4000);
    varTemp6            varchar2(4000);
    varTemp7            varchar2(4000);
    varXPath            varchar2(4000);
    varXPath1           varchar2(4000);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         date;
    datTemp             date;
    datTemp1            date;
    datTemp2            date;
    datTemp3            date;
    clbTemp             clob;
    clbError            clob;
    clbProcess          clob;
    xmlTemp             xmlType;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    nmpTemp1            xmldom.domNamedNodemap;
    nlsTemp             xmlDom.DomNodeList;
    nlsTemp1            xmlDom.DomNodeList;
    xlParse             xmlparser.parser;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    mail_body           varchar2(4000);
    varsubject          varchar2(1000);
    fromuser            varchar2(100);
    error_occured       Exception;

    numcode5         number(8);
    numcode6         number(8);
    numcode7         number(8);
    numcode8         number(8);
    numcode9         number(8);
    numcode10        number(8);
    numcode11        number(8);
    numcode12        number(8);
    numcode13        number(15,2);
    numcode14        number(15,2);
    numCode15        number(8);
    varTemp2            varchar2(512);
    numPeriodType    number(8);
    numPercentType   number(8);
    numMinAmount     number(15,2);
    numMaxAmount     number(15,2);
    numCharges       number(15,3);
    numAmountUpto    number(15,2);
    numAmountFrom    number(15,2); 
    numPeriodUpto    number(15);
    numCurrency    number(8);
    varSanctionApplied  VARCHAR2(30 BYTE);
    numChargeEvent  number(8);
    intLoop         number(5);

    Begin
    varMessage := 'Miscellaneous Updates for ' || EditType;
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := RecordDetail;

    numError := 1;
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(RecordDetail);

    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyId', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);

    numError := 2;
    varOperation := 'Creating Document for Master';
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

   -- insert into temp values(varoperation || '-1' ,varoperation);

--
--    if EditType = GConst.SYSCASHDEAL then
--      varOperation := 'Extracting Parameters for Foreign Remittance';
--      varReference := GConst.fncXMLExtract(xmlTemp, 'REMT_REMITTANCE_REFERENCE', varReference);
--      numCode := GConst.fncXMLExtract(xmlTemp, 'REMT_COMPANY_CODE', varReference);
--      varTemp :=  'BCCL/FRW/H/';
--      varTemp := varTemp  || Gconst.fncGenerateSerial(GConst.SERIALDEAL, numCode);
--
--
--      if numAction = GConst.ADDSAVE then
--          varOperation := 'Inserting Cash Deal';
--          insert into trtran001
--            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--            deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--            cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--            deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--          select remt_company_code, varTemp, 1, datWorkDate, 26000001, decode(remt_remittance_type, 33900001, 25300002,25300001),25200002,
--            25400001, remt_local_bank, remt_currency_code, 30400003, remt_exchange_rate, 1, remt_remittance_fcy,
--            remt_remittance_inr, 0,0,datWorkDate,datWorkDate,null, 'System',
--            NULL, 0,0,0,0,varReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,remt_create_date,remt_entry_detail, 10200001,
--            remt_remittance_details,null,null,0,remt_exchange_rate,0, 0,
--            0,0,remt_remittance_purpose + 9100000,0,0,0,remt_bank_reference,
--            decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance'),null,null,null,null
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--          varOperation := 'Inserting Cash Deal Cancellation';
--          insert into trtran006
--            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
--          select remt_company_code, varTemp, 1, 1, varReference, 1,
--            datWorkDate, 26000001,27000002,remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr, 0,
--            0,0,0,0,0,0,'System',varReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), remt_create_date,
--            remt_entry_detail, 10200001, null,null,1,0,remt_exchange_rate,0,0,0,33500001,null,null,remt_bank_reference,
--            decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance')
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--          varOperation := 'Inserting Underlying Entry';
--          insert into trtran002
--            (trad_company_code,trad_trade_reference,trad_reverse_reference,trad_reverse_serial,trad_import_export,
--            trad_local_bank,trad_entry_date,trad_user_reference,trad_reference_date,trad_buyer_seller,trad_trade_currency,
--            trad_product_code,trad_product_description,trad_trade_fcy,trad_trade_rate,trad_trade_inr,trad_period_code,
--            trad_trade_period,trad_tenor_code,trad_tenor_period,trad_maturity_from,trad_maturity_date,trad_maturity_month,
--            trad_process_complete,trad_complete_date,trad_trade_remarks,trad_create_date,trad_entry_detail,
--            trad_record_status,trad_vessel_name,trad_port_name,trad_beneficiary,trad_usance,trad_bill_date,
--            trad_contract_no,trad_app,trad_transaction_type,trad_product_quantity,trad_product_rate,trad_term,
--            trad_voyage,trad_link_batchno,trad_link_date,trad_lc_beneficiary,trad_forward_rate,trad_margin_rate,
--            trad_final_rate,trad_spot_rate)
--          select remt_company_code, remt_remittance_reference,remt_remittance_reference, 1,
--            decode(remt_remittance_type, 33900001, 25300002,25300001),
--            remt_local_bank, datWorkDate, remt_remittance_reference,datWorkDate, remt_beneficiary_code, remt_currency_code,
--            remt_remittance_purpose, remt_remittance_details, remt_remittance_fcy, remt_exchange_rate,
--            remt_remittance_inr, 25500001,0,25500001,0,datWorkDate, datWorkDate,datWorkDate,
--            12400001, datWorkDate, decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance'),
--            remt_create_date, remt_entry_detail, 10200001, null, null, null, null, null,
--            null,null,null,null,null,null,null,null,null,null,0,0,remt_exchange_rate,remt_exchange_rate
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--          varOperation := 'Inserting underlying reversal entry';
--          insert into trtran003
--            (brel_company_code,brel_trade_reference,brel_reverse_serial,brel_entry_date,brel_user_reference,
--            brel_reference_date,brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,brel_reversal_inr,
--            brel_period_code,brel_trade_period,brel_maturity_from,brel_maturity_date,brel_create_date,
--            brel_entry_detail,brel_record_status,brel_local_bank,brel_reverse_reference)
--          select remt_company_code, remt_remittance_reference, 1, datWorkdate, remt_bank_reference,
--            datWorkDate, decode(remt_remittance_type, 33900001,25800011,25800056),
--            remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr,
--            25500001,0,datWorkDate, datWorkDate, remt_create_date,
--            remt_entry_detail, 10200001, remt_local_bank, remt_remittance_reference
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--      End if;
--
--    End if;
--manjunath sir modified on 12052014
----Added by Ishwarachandra ---For new rate upload
-- if EditType = SYSRATEUPLOAD then
--  varOperation := 'Updating Rate Serial Number ';
--  datTemp1 := GConst.fncXMLExtract(xmlTemp, 'DRAT_EFFECTIVE_DATE', datTemp1);
--  VarReference := GConst.fncXMLExtract(xmlTemp, 'DRAT_RATE_TIME', VarReference);
--  update trtran013 set drat_ratesr_number =  to_char(drat_effective_date,'ddmmyyyy')||lpad(DRAT_SERIAL_NUMBER,3,0)
--                                            where drat_ratesr_number is null
--                                            and DRAT_EFFECTIVE_DATE = datTemp1;
--  varOperation := 'Selecting Rate Serial Number ';        
----  SELECT MAX(DRAT_SERIAL_NUMBER),
----    DRAT_RATESR_NUMBER INTO numCode4,numRateSr
----  FROM trtran013
----  WHERE DRAT_EFFECTIVE_DATE = datTemp1
----  GROUP BY DRAT_RATESR_NUMBER; 
--  SELECT 
--    DRAT_RATESR_NUMBER INTO numRateSr
--  FROM trtran013
--  WHERE DRAT_EFFECTIVE_DATE = datTemp1
--  and DRAT_RATE_TIME = VarReference
--  and DRAT_SERIAL_NUMBER = (select MAX(DRAT_SERIAL_NUMBER) from trtran013a b
--                              where DRAT_EFFECTIVE_DATE = datTemp1
--                              and DRAT_RATE_TIME = VarReference);
--  varOperation := 'Inserting Rate into trtran013a ';
--  varXPath     := '//RATEUPLOADNEW/ROW';
--  nlsTemp      := xslProcessor.selectNodes(nodFinal, varXPath);
--  varOperation := 'Update Reverse Reference ' || varXPath;
--  FOR numTemp IN 1..xmlDom.getLength(nlsTemp)
--  LOOP
--    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/BidRate';
--    varoperation :='Extracting Data from XML' || varTemp;
--    numRate      := GConst.fncXMLExtract(xmlTemp, varTemp, numRate, Gconst.TYPENODEPATH);
--    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/AskRate';
--    varoperation :='Extracting Data from XML' || varTemp;
--    numRate1     := GConst.fncXMLExtract(xmlTemp, varTemp, numRate1, Gconst.TYPENODEPATH);
--    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/CurrencyCode';
--    varoperation :='Extracting Data from XML' || varTemp;
--    numCode      := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);
--    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/ForCurrency';
--    varoperation :='Extracting Data from XML' || varTemp;
--    numCode1     := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);
--    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/ContractMonth';
--    varoperation :='Extracting Data from XML' || varTemp;
--    datTemp      := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp, Gconst.TYPENODEPATH);
--    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/ForwardMonth';
--    varoperation :='Extracting Data from XML' || varTemp;
--    numCode2     := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);
--    if numCode2 = 0 then
--      INSERT
--      INTO TRTRAN013A (DRAD_CURRENCY_CODE, DRAD_FOR_CURRENCY, 
--                       DRAD_RATESR_NUMBER, DRAD_BID_RATE, DRAD_ASK_RATE, 
--                       DRAD_CONTRACT_MONTH, DRAD_FORWARD_MONTHNO)
--      SELECT numCode,numCode1,numRateSr,numRate,numRate1,datTemp,numCode2 from dual;
--    else
--      select DRAD_BID_RATE, DRAD_ASK_RATE INTO numRate2,numRate3 from trtran013a where DRAD_CURRENCY_CODE = numCode 
--                                          and DRAD_FOR_CURRENCY = numCode1
--                                          and DRAD_RATESR_NUMBER = numRateSr 
--                                          and DRAD_FORWARD_MONTHNO = 0;
--      INSERT INTO TRTRAN013A (DRAD_CURRENCY_CODE, DRAD_FOR_CURRENCY, 
--                       DRAD_RATESR_NUMBER, DRAD_BID_RATE, DRAD_ASK_RATE, 
--                       DRAD_CONTRACT_MONTH, DRAD_FORWARD_MONTHNO)
--      SELECT numCode,numCode1,numRateSr,numRate2 + (numRate/100),numRate3 + (numRate1/100),datTemp,numCode2 from dual;
--    end if;
--  END LOOP;
--  BEGIN----For USD - USD Rate for 12 month
--  SELECT nvl(COUNT(*),0) INTO numSerial FROM TRTRAN013A WHERE DRAD_CURRENCY_CODE = 30400004 
--                                                 AND DRAD_FOR_CURRENCY = 30400004
--                                                 AND DRAD_RATESR_NUMBER = numRateSr;
--  IF numSerial = 0 THEN
--    INSERT
--    INTO TRTRAN013A
--      ( DRAD_CURRENCY_CODE,DRAD_FOR_CURRENCY,DRAD_RATESR_NUMBER,DRAD_BID_RATE,
--        DRAD_ASK_RATE,DRAD_CONTRACT_MONTH,DRAD_FORWARD_MONTHNO)
--    SELECT 30400004,30400004,numRateSr,1,1,datTemp,rownum + (-1)
--    FROM TRTRAN013A WHERE DRAD_RATESR_NUMBER = numRateSr
--    AND ROWNUM <=13;
--  END IF;
--  EXCEPTION
--    WHEN OTHERS THEN
--      INSERT
--      INTO TRTRAN013A
--        (DRAD_CURRENCY_CODE,DRAD_FOR_CURRENCY,DRAD_RATESR_NUMBER,DRAD_BID_RATE,
--         DRAD_ASK_RATE,DRAD_CONTRACT_MONTH,DRAD_FORWARD_MONTHNO)
--      SELECT 30400004,30400004,numRateSr,1,1,datTemp,rownum + (-1)
--      FROM TRTRAN013A
--      WHERE DRAD_RATESR_NUMBER = numRateSr AND ROWNUM <=13;
--  END;  
-- END IF;
 if EditType = SYSCASHDEAL then
      varOperation := 'Extracting Parameters for Foreign Remittance';
      numCode := GConst.fncXMLExtract(xmlTemp, 'REMT_COMPANY_CODE', varReference);
      varReference := GConst.fncXMLExtract(xmlTemp, 'REMT_REMITTANCE_REFERENCE', varReference);

      Begin
        varReference1 := NVL(GConst.fncXMLExtract(xmlTemp, 'REMT_REFERENCE_NUMBER', varReference1),'0');
      Exception
        when others then
          varReference1 := '0';
      End;

     -- varTemp :=  'BCCL/FRW/H/';
      varTemp :=  'FWDC'   || fncGenerateSerial(SERIALDEAL, numCode);


      if numAction = GConst.ADDSAVE then
          varOperation := 'Inserting Cash Deal';
           insert into trtran001
            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
            deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
            deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
            deal_bo_remark)
          select remt_company_code, varTemp, 1, datWorkDate, 26000001, decode(remt_remittance_type, 33900001, 25300002,25300001),25200002,
            25400001, remt_local_bank, remt_currency_code, 30400003, remt_exchange_rate, 1, remt_remittance_fcy,
            remt_remittance_inr, 0,0,remt_maturity_date,remt_maturity_date,null, 'System',
            NULL, varReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,remt_create_date,remt_entry_detail, 10200001,
            remt_remittance_details,null,null,remt_forward_rate,remt_spot_rate,remt_margin_rate,
            remt_product_category,0,0,remt_product_subcategory,remt_bank_reference,
            decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance')
            from trtran008A
            where remt_remittance_reference = varReference;


          varOperation := 'Inserting Cash Deal Cancellation';
           insert into trtran006
            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
          select remt_company_code, varTemp, 1, 1, varReference, 1,
            datWorkDate, 26000001,27000002,remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr, 0,
            0,0,0,0,0,0,'System',varReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), remt_create_date,
            remt_entry_detail, 10200001, null,null,1,0,remt_forward_rate,remt_spot_rate,remt_margin_rate,0,33500001,
            null,null,remt_bank_reference,decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance')
            from trtran008A
            where remt_remittance_reference = varReference;


          varOperation := 'Inserting Underlying Entry';
          insert into trtran002
            (trad_company_code,trad_trade_reference,trad_reverse_reference,trad_reverse_serial,trad_import_export,
            trad_local_bank,trad_entry_date,trad_user_reference,trad_reference_date,trad_buyer_seller,trad_trade_currency,
            trad_product_code,trad_product_description,trad_trade_fcy,trad_trade_rate,trad_trade_inr,trad_period_code,
            trad_trade_period,trad_tenor_code,trad_tenor_period,trad_maturity_from,trad_maturity_date,
            trad_process_complete,trad_complete_date,trad_trade_remarks,trad_create_date,trad_entry_detail,
            trad_record_status,trad_vessel_name,trad_port_name,trad_beneficiary,trad_usance,trad_bill_date,
            trad_contract_no,trad_app,trad_transaction_type,trad_product_quantity,trad_product_rate,trad_term,
            trad_voyage,trad_link_batchno,trad_link_date,trad_lc_beneficiary,trad_forward_rate,trad_margin_rate,
            trad_spot_rate,trad_product_category,trad_subproduct_code)
          select remt_company_code, remt_remittance_reference,remt_remittance_reference, 1,
            decode(remt_remittance_type, 33900001, 25900025,25900087),
            remt_local_bank, datWorkDate, remt_remittance_reference,datWorkDate, remt_beneficiary_code, remt_currency_code,
            remt_remittance_purpose, remt_remittance_details, remt_remittance_fcy, remt_exchange_rate,
            remt_remittance_inr, 25500001,0,25500001,0,datWorkDate, datWorkDate,
            12400001, datWorkDate, decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance'),
            remt_create_date, remt_entry_detail, 10200001, null, null, null, null, null,
            null,null,null,null,null,null,null,null,null,null,remt_forward_rate,remt_margin_rate,remt_spot_rate,
            remt_product_category, remt_product_subcategory
            from trtran008A
            where remt_remittance_reference = varReference;

          varOperation := 'Inserting underlying reversal entry';
          insert into trtran003
            (brel_company_code,brel_trade_reference,brel_reverse_serial,brel_entry_date,brel_user_reference,
            brel_reference_date,brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,brel_reversal_inr,
            brel_period_code,brel_trade_period,brel_maturity_from,brel_maturity_date,brel_create_date,
            brel_entry_detail,brel_record_status,brel_local_bank,brel_reverse_reference)
          select remt_company_code, remt_remittance_reference, 1, datWorkdate, remt_bank_reference,
            datWorkDate, decode(remt_remittance_type, 33900001,25800011,25800056),
            remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr,
            25500001,0,datWorkDate, datWorkDate, remt_create_date,
            remt_entry_detail, 10200001, remt_local_bank, remt_remittance_reference
            from trtran008A
            where remt_remittance_reference = varReference;

          varOperation := 'Inserting Hedge record';
          insert into trtran004
            (hedg_company_code,hedg_trade_reference,hedg_deal_number,
            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
            hedg_create_date,hedg_entry_detail,hedg_record_status,
            hedg_hedging_with,hedg_multiple_currency)
          select remt_company_code, remt_remittance_reference, varTemp,
            1, remt_remittance_fcy,0,remt_remittance_inr,
            sysdate,NULL,10200001, 32200001,12400002
            from trtran008A
            where remt_remittance_reference = varReference;
-- Removed because of does not required for Olam
--        if varReference1 != '0' then
--           varOperation := 'Inserting Trade reversal entry';
--          insert into trtran003
--            (brel_company_code,brel_trade_reference,brel_reverse_serial,brel_entry_date,brel_user_reference,
--            brel_reference_date,brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,brel_reversal_inr,
--            brel_period_code,brel_trade_period,brel_maturity_from,brel_maturity_date,brel_create_date,
--            brel_entry_detail,brel_record_status,brel_local_bank,brel_reverse_reference)
--          select remt_company_code, varReference1, 1, datWorkdate, remt_bank_reference,
--            datWorkDate, decode(remt_remittance_type, 33900001,25800011,25800056),
--            remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr,
--            25500001,0,datWorkDate, datWorkDate, remt_create_date,
--            remt_entry_detail, 10200001, remt_local_bank, remt_remittance_reference
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--             numError := fncCompleteUtilization(varReference1,GConst.UTILEXPORTS,datWorkDate);
--        End if;

      elsif numAction = GConst.DELETESAVE then
        varOperation := 'Deleting the Cash Deal Entry';
        update trtran001
          set deal_record_status = Gconst.STATUSDELETED
          where deal_dealer_remarks = varReference;

        varOperation := 'Deleting the Trade Deal Entry';
        update trtran002
          set trad_record_status = Gconst.STATUSDELETED
          where trad_trade_reference = varReference;

        varOperation := 'Deleting the Deal Realization Entry';
        update trtran003
          set brel_record_status = Gconst.STATUSDELETED
          where brel_trade_reference = varReference;

        varOperation := 'Deleting the Hedge Entry';
        update trtran004
          set hedg_record_status = Gconst.STATUSDELETED
          where hedg_trade_reference = varReference;

        if varReference1 != '0' then
            varOperation := 'Deleting Trade reversal entry';
            update trtran003
              set brel_record_status = Gconst.STATUSDELETED
              where brel_trade_reference = varReference1;

              numError := fncCompleteUtilization(varReference1,GConst.UTILEXPORTS,datWorkDate);
        End if;

      End if;

    End if;

   if EditType = SYSEXPOSUREMASTER then
        varOperation := 'Extracting Fileds From EXPOSURE TYPE MASTER';
        numcode := GConst.fncXMLExtract(xmlTemp, 'EXTY_CONSIDER_EXPOSURE', numcode);
        numcode2 := GConst.fncXMLExtract(xmlTemp, 'EXTY_ALLOW_LINKING', numcode2);
        numcode1 := GConst.fncXMLExtract(xmlTemp, 'EXTY_PICK_CODE', numcode1);
        numCode3:=GConst.fncXMLExtract(xmlTemp, 'EXTY_INFLOW_OUTFLOW', numcode3);

--        17300001	Outflow
--17300002	Inflow
        if (numAction= GConst.ADDSAVE) then
            numStatus:= FNCGENERATERELATION(numCode3, numCode1, numAction);
        elsif (numAction= GConst.EDITSAVE) then
             numStatus:=  FNCGENERATERELATION(numCode3, numCode1, GConst.DELETESAVE);
             numStatus:=  FNCGENERATERELATION(numCode3, numCode1, numAction);
        end if;


        if ((numcode=12400001)) then -- for Exposure
           numStatus:=  FNCGENERATERELATION(24700001, numCode1, GConst.DELETESAVE);
           numStatus:=  FNCGENERATERELATION(24700001, numCode1, GConst.ADDSAVE);
           -- for the inflow outflow
        elsif ((numAction = GConst.EDITSAVE) and (numcode=12400002)) then
           --numStatus:=  FNCGENERATERELATION(numCode3, numCode1, GConst.DELETESAVE);  
           numStatus:=  FNCGENERATERELATION(24700001, numCode1, GConst.DELETESAVE);
        end if;

        if numcode2=12400001 then  -- Allowing Linking saparate Type
           numStatus:=  FNCGENERATERELATION(24700003, numCode1, GConst.DELETESAVE);
           numStatus:=  FNCGENERATERELATION(24700003, numCode1, GConst.ADDSAVE);
        elsif ((numAction= GConst.EDITSAVE) and (numcode2=12400002)) then
           numStatus:=  FNCGENERATERELATION(24700003, numCode1, GConst.DELETESAVE);
        end if;

--        if ((numcode=12400001)) then -- for Exposure
--           numStatus:=  FNCGENERATERELATION(24700001, numCode1, numAction);
--           numStatus:=  FNCGENERATERELATION(numCode3, numCode1, numAction);
--           -- for the inflow outflow
--        elsif ((numAction= GConst.EDITSAVE) and (numcode=12400002)) then
--            numStatus:=  FNCGENERATERELATION(numCode3, numCode1, GConst.DELETESAVE);
--        end if;
--        
--        if numcode2=12400001 then  -- Allowing Linking saparate Type
--           numStatus:=  FNCGENERATERELATION(24700003, numCode1, numAction);
--            numStatus:=  FNCGENERATERELATION(numCode3, numCode1, numAction);
--        elsif ((numAction= GConst.EDITSAVE) and (numcode2=12400002)) then
--           numStatus:=  FNCGENERATERELATION(24700003, numCode1, GConst.DELETESAVE);
--        end if;

        numcode4 := GConst.fncXMLExtract(xmlTemp, 'EXTY_CONSIDER_FORSETTLEMENT', numcode4);

        if numcode4=12400001 then  -- Conside Settlement 
           numStatus:=  FNCGENERATERELATION(24700002, numCode1, GConst.DELETESAVE);
           numStatus:=  FNCGENERATERELATION(24700002, numCode1, GConst.ADDSAVE);
        elsif ((numAction= GConst.EDITSAVE) and (numcode4=12400002)) then
           numStatus:=  FNCGENERATERELATION(24700002, numCode1, GConst.DELETESAVE);
        end if;

--        if numAction = GConst.ADDSAVE  then 
--            INSERT INTO TRSYSTEM008(EREL_COMPANY_CODE,EREL_MAIN_ENTITY,EREL_ENTITY_RELATION,EREL_ENTITY_TYPE,
--                EREL_RELATION_TYPE,EREL_CREATE_DATE,EREL_ADD_DATE,EREL_ENTRY_DETAIL,EREL_RECORD_STATUS)
--            VALUES(30199999,(case when numcode = 17300001 then 91900003 else 91900001 end),numcode1,919,
--                   259,sysdate,sysdate,null,10200001);
--        end if;                   
    end if;

if EditType = SYSCASHFLOWBUDGET then
    varOperation := 'Extracting Fileds For Cash Flow Budget Details';
    numcode := GConst.fncXMLExtract(xmlTemp, 'CBUS_APPROVAL_STATUS', numcode);
    dattemp := GConst.fncXMLExtract(xmlTemp, 'CBUS_EFFECTIVE_DATE', dattemp);
    varReference := GConst.fncXMLExtract(xmlTemp, 'CBUS_SYSTEM_REFERENCE', varReference);

    if numAction = GConst.DELETESAVE  then     
        UPDATE TRTRAN150A
        SET CBUD_RECORD_STATUS = 10200006
        WHERE CBUD_SYSTEM_REFERENCE = varReference;
    else
--        if numAction = GConst.CONFIRMSAVE  then     
--            UPDATE TRTRAN150A
--            SET CBUD_RECORD_STATUS = 10200003
--            WHERE CBUD_SYSTEM_REFERENCE = varReference;
--        end if; 
        docFinal := xmlDom.newDomDocument(xmlTemp);
        nodFinal := xmlDom.makeNode(docFinal);       
        varOperation := 'Before Loop';
        varXPath := '//CASHFLOWBUDGETDETAILS/DROW';
        varXPath1 := 'CASHFLOWBUDGETDETAILS/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

        if xmlDom.getLength(nlsTemp) > 0 then
            varXPath := '//CASHFLOWBUDGETDETAILS/DROW[@DNUM="';
            varXPath1:='CASHFLOWBUDGETDETAILS/DROW[@DNUM="';
            for numSub in 0..xmlDom.getLength(nlsTemp) -1
            Loop
                varOperation := 'Inside Loop';
                nodTemp := xmlDom.item(nlsTemp, numSub);
                nmpTemp := xmlDom.getAttributes(nodTemp);
                nodtemp1 := xmldom.item(nmptemp, 0);                       
                GLOG.log_write(varOperation);
                numtemp := to_number(xmldom.getnodevalue(nodtemp1));

                varTemp := varXPath || numTemp || '"]/SystemReference';
                varReference := GConst.fncGetNodeValue(nodFinal, varTemp);

                varTemp := varXPath || numTemp || '"]/SerialNumber';
                numSerial := GConst.fncGetNodeValue(nodFinal, varTemp);                

                varTemp := varXPath1 || numTemp || '"]/TransactionDate';
                datTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp1);
                --datTemp1 := to_date(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));

                varTemp := varXPath1 || numTemp || '"]/DueDate';
                datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2);
                --datTemp2 := to_date(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));

                varTemp := varXPath || numTemp || '"]/ExchangeRate';
                numRate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));

                varTemp := varXPath || numTemp || '"]/AmountFCY';
                numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

                varTemp := varXPath || numTemp || '"]/AmountLCY';
                numFCY2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

                varTemp := varXPath || numTemp || '"]/CompanyCode';
                numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

                varTemp := varXPath || numTemp || '"]/CurrencyCode';
                numCode2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

                varTemp := varXPath || numTemp || '"]/CashFlowCode';
                numCode3 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

                begin
                    varTemp := varXPath || numTemp || '"]/UserRemarks';
                    varTemp1 := GConst.fncGetNodeValue(nodFinal, varTemp);  
                exception
                when others then 
                    varTemp1 := '';
                end;

                if numAction = GConst.CONFIRMSAVE then 
                    numcode5 := 10200003;
                else 
                    varTemp := varXPath || numTemp || '"]/RecordStatus';
                    numCode4 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

                    begin
                        if numCode4 = 1 then
                            numcode5 := 10200001;
                        elsif numCode4 = 2 then
                            numcode5 := 10200004;
                        end if;
                    exception  
                    when others then  
                        numcode5 := 10200004;                            
                    end;
                end if;

                vartemp2 := null;
                --To Add Budget Details in TRTRAN161 and Add/Update exposures in trtran002
                pkgbulkdataload_PrcInsertToActualOrBudgetTable(numCode1, dattemp, numCode3, 
                numCode2, TO_CHAR(datTemp2, 'MON'), numFCY1, varReference, numSerial, varTemp1, 
                numcode, numcode5, 12400002, vartemp2);

                if vartemp2 is not null then
                    raise_application_error(-20101, vartemp2);
                end if;
            End loop;
        end if;
    end if;  
end if;

    if EditType = SYSUSERLEVELSCREENCONFIG then
        varOperation := 'Extracting Fileds For SYSUSERLEVELSCREENCONFIG' ;
        varReference := GConst.fncXMLExtract(xmlTemp, 'USCF_PROGRAM_UNIT', varReference);
        vartemp1 := GConst.fncXMLExtract(xmlTemp, 'USCF_USER_ID', vartemp1);
        numcode5 := GConst.fncXMLExtract(xmlTemp, 'USCF_GROUP_CODE', numcode5);

        if numAction = GConst.DELETESAVE then 
            UPDATE TRSYSTEM999IA
            SET USCF_RECORD_STATUS = 10200006,
            USCF_ADD_DATE = sysdate
            WHERE USCF_USER_ID = vartemp1 and USCF_PROGRAM_UNIT = varReference;
        ELSE
            varXPath := '//RowDetails/DROW';
            nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
            for numTemp in 1..xmlDom.getLength(nlsTemp)
            Loop
                varOperation := 'Inside Loop USERLEVELSCREENCONFIG';
                GLOG.log_write(varOperation);  

                varTemp := varXPath || '[@DNUM="' || numTemp || '"]/XMLField';
                vartemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, vartemp2, Gconst.TYPENODEPATH);

                begin
                    varTemp := varXPath || '[@DNUM="' || numTemp || '"]/DefaultValue';
                    vartemp3 := GConst.fncXMLExtract(xmlTemp, varTemp, vartemp3, Gconst.TYPENODEPATH);
                exception
                when others then
                    vartemp3 := null;
                end;

                varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ShowYN';
                numcode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numcode1, Gconst.TYPENODEPATH);

                varTemp := varXPath || '[@DNUM="' || numTemp || '"]/EditableADDLOADYN';
                numcode3 := GConst.fncXMLExtract(xmlTemp, varTemp, numcode1, Gconst.TYPENODEPATH);

                varTemp := varXPath || '[@DNUM="' || numTemp || '"]/EditableOTHERYN';
                numcode4 := GConst.fncXMLExtract(xmlTemp, varTemp, numcode1, Gconst.TYPENODEPATH);

                varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecordStatus';
                numcode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numcode2, Gconst.TYPENODEPATH);

                SELECT nvl(max(USCF_SERIAL_NUMBER),0) + 1 into numserial
                from TRSYSTEM999IA
                where USCF_USER_ID = vartemp and USCF_PROGRAM_UNIT = varReference;

                if numcode2 = 1 then
                    INSERT INTO TRSYSTEM999IA(USCF_GROUP_CODE,USCF_USER_ID,USCF_PROGRAM_UNIT,USCF_SERIAL_NUMBER,
                    USCF_XML_FIELD,USCF_SHOW_YN,USCF_DEFAULT_VALUE,USCF_EDITABLEADD_YN,USCF_EDITABLE_YN,
                    USCF_RECORD_STATUS,USCF_CREATE_DATE,USCF_ADD_DATE,USCF_ENTRY_DETAILS)
                    VALUES(numcode5,vartemp1,varReference,numserial,vartemp2,numcode1,vartemp3,
                    numcode3,numcode4,10200001,sysdate,sysdate,null);
                else 
                    update TRSYSTEM999IA
                    set USCF_SHOW_YN = numcode1,
                    USCF_EDITABLEADD_YN=numcode3,
                    USCF_EDITABLE_YN=numcode4,
                    USCF_DEFAULT_VALUE = vartemp3,
                    USCF_RECORD_STATUS = 10200004,
                    USCF_ADD_DATE = sysdate
                    where USCF_USER_ID = vartemp1 and USCF_PROGRAM_UNIT = varReference 
                    and USCF_XML_FIELD = vartemp2;
                end if;
            End loop;
        end if;
    end if;

    if EditType = SYSCCIRSPOPULATE then
         varOperation := 'Extracting Fileds For IRS CCS MAturity Schedule Details' ;

         varTemp := '//ROW[@NUM="1"]/IIRS_IRS_NUMBER';        
         varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH);

         if (numAction = GConst.ADDSAVE or numAction = GConst.EDITSAVE) then            
              varOperation := 'Extracting Parameters';
              docFinal := xmlDom.newDomDocument(xmlTemp);
              nodFinal := xmlDom.makeNode(docFinal);       
              varOperation := 'Before Loop';

              varXPath := '//MATURITYDETAILS/DROW';
              nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

              varOperation := 'Delete Existing Maturity Schedule ' || varXPath;    
              UPDATE TRTRAN091BB 
              SET IIRM_RECORD_STATUS = 10200005
              WHERE IIRM_IRS_NUMBER = varReference;

              UPDATE TRTRAN091C
              SET IIRN_RECORD_STATUS = 10200005
              WHERE IIRN_IRS_NUMBER = varReference;

              varOperation := 'Add new Maturity Schedule ' || varXPath;              
              for numTemp in 1..xmlDom.getLength(nlsTemp)
              Loop

                  SELECT nvl(max(IIRM_SERIAL_NUMBER),0) + 1
                  INTO numSerial1
                  FROM TRTRAN091BB 
                  WHERE IIRM_IRS_NUMBER = varReference;                  
                  Glog.log_write('varReference:' || varReference || ' numSerial1 ' || numSerial1 );

                  varoperation :='Extracting Data from XML to insert into TRTRAN091BB';

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/SystemReference';
                  varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH); 

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/LegSerial';
                  numSerial := GConst.fncXMLExtract(xmlTemp, varTemp, numSerial, Gconst.TYPENODEPATH);                        

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/IntStartDate';
                  datTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp1, Gconst.TYPENODEPATH);    

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/SettlementDate';  
                  datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2, Gconst.TYPENODEPATH);    

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/IntEndDate';  
                  datTemp3 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp3, Gconst.TYPENODEPATH);    

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/IntFixingDate';  
                  datTemp := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp, Gconst.TYPENODEPATH);    
--                 
                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecordStatus';  
                  numCode := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);  

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ProcessComplete';  
                  numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);  

                  begin
                    if numcode = 1 then
                        numcode1 := 10200001;
                    ELSIF numcode = 2 then
                        numcode1 := 10200004;
                    end if;
                  exception  
                  when others then  
                       numcode1 := 10200004;                            
                  end;

                  Glog.log_write('varReference ' || varReference || ' numSerial ' || numSerial 
                  || ' numSerial1 ' || numSerial1 ||' datTemp1 ' || datTemp1 
                  || ' datTemp3 ' || datTemp3 ||' datTemp ' || datTemp 
                  || ' datTemp2 ' || datTemp2 ||' numfcy ' || numfcy ||' numcode1 ' 
                  || numcode1 || ' numCode2 ' || numCode2);

                  insert into TRTRAN091BB (IIRM_IRS_NUMBER,IIRM_LEG_SERIAL,IIRM_SERIAL_NUMBER,IIRM_INTSTART_DATE,IIRM_INTEND_DATE,
                                           IIRM_INTFIXING_DATE,IIRM_SETTLEMENT_DATE,IIRM_AMOUNT_FCY,IIRM_ADD_DATE,IIRM_CREATE_DATE,
                                           IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE)
                  values (varReference,numSerial,numSerial1,datTemp1,datTemp3,
                          datTemp,datTemp2,numfcy,sysdate,sysdate,numcode1,numCode2);   
              end loop;
         end if;

         if (numAction = GConst.CONFIRMSAVE) then    
         UPDATE TRTRAN091BB 
         SET IIRM_RECORD_STATUS = 10200003
         WHERE IIRM_IRS_NUMBER = varReference AND IIRM_RECORD_STATUS NOT IN (10200005,10200006);                        

--              varOperation := 'Extracting Parameters';
--              docFinal := xmlDom.newDomDocument(xmlTemp);
--              nodFinal := xmlDom.makeNode(docFinal);       
--              varOperation := 'Before Loop';
--                            
--              varXPath := '//MATURITYDETAILS/DROW';
--              nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--              varOperation := 'Update Maturity Schedule ' || varXPath;
--              for numTemp in 1..xmlDom.getLength(nlsTemp)
--              Loop
--                  varoperation :='Extracting Data from XML';
--                  
--                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/SystemReference';
--                  varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH); 
--                                          
--                  UPDATE TRTRAN091BB 
--                  SET IIRM_RECORD_STATUS = 10200003
--                  WHERE IIRM_IRS_NUMBER = varReference AND IIRM_RECORD_STATUS NOT IN (10200005,10200006);                        
--              end loop;            
         end if;   
     end if;

   if EditType = UTILIRS then
       varOperation := 'Extracting Fileds For UTILIRS' ;
        varReference := GConst.fncXMLExtract(xmlTemp, 'IIRU_IRS_NUMBER', varReference);
        numCode2 := GConst.fncXMLExtract(xmlTemp, 'IIRU_UNWIND_UTILIZE', numCode2);
        datTemp := GConst.fncXMLExtract(xmlTemp, 'IIRU_SETTLEMENT_DATE', datTemp);        
        numcode3 := GConst.fncXMLExtract(xmlTemp, 'IIRU_LEG1_SERIAL', numCode3);        
        numcode10 := GConst.fncXMLExtract(xmlTemp, 'IIRU_LEG1_SUBSERIAL', numCode10);        
        numFcy := GConst.fncXMLExtract(xmlTemp, 'IIRU_NET_CASHFLOW', numFcy);

        if numAction in (GConst.ADDSAVE) then 
              IF numCode2 = 81000003 THEN --Unwind/cancel
                    UPDATE TRTRAN091BB SET IIRM_PROCESS_COMPLETE = 12400001,
                                           IIRM_COMPLETE_DATE = datTemp
                                          --IIRM_UNWIND_UTILIZE = numCode2
                                        WHERE IIRM_IRS_NUMBER = varReference
                                          AND IIRM_PROCESS_COMPLETE = 12400002;
                                          --AND IIRM_COMPLETE_DATE IS NULL;
                    UPDATE TRTRAN091 SET IIRS_PROCESS_COMPLETE = 12400001,
                                         IIRS_COMPLETE_DATE = datTemp 
                                        WHERE IIRS_IRS_NUMBER = varReference;
            ELSE --Settlement 
                    SELECT IIRS_SETTLEMENT_TYPE
                    INTO numcode
                    FROM trtran091 
                    WHERE IIRS_IRS_NUMBER = varReference;

                    if numcode = 81600001 then
                        UPDATE TRTRAN091BB 
                        SET IIRM_PROCESS_COMPLETE = 12400001,
                        IIRM_COMPLETE_DATE = datTemp
                        --IIRM_UNWIND_UTILIZE = numCode2
                        WHERE IIRM_IRS_NUMBER = varReference
                        AND IIRM_SETTLEMENT_DATE = datTemp;
                    else
                        UPDATE TRTRAN091BB 
                        SET IIRM_PROCESS_COMPLETE = 12400001,
                        IIRM_COMPLETE_DATE = datTemp
                        --IIRM_UNWIND_UTILIZE = numCode2
                        WHERE IIRM_IRS_NUMBER = varReference
                        AND IIRM_LEG_SERIAL = numCode3 and IIRM_SERIAL_NUMBER = numCode10;
                    end if;                                                  
                  END IF;

              SELECT DISTINCT IIRL_CURRENCY_CODE
              INTO numcode5
              FROM TRTRAN091A
              WHERE IIRL_IRS_NUMBER = varReference;

              SELECT IIRS_COUNTER_PARTY
              INTO numcode6
              FROM TRTRAN091
              WHERE IIRS_IRS_NUMBER = varReference;

              numError := fncCompleteUtilization(varReference||'_'||numcode3|| '_' ||numcode10, Gconst.UTILEXPORTS, datWorkDate);
--              begin
--              select nvl(max(trad_serial_number),0)+1
--                into numSerial
--                from trtran002
--                where trad_trade_reference =varReference||'_'||numcode3|| '_' ||numcode10;
--              exception 
--                when others then
--                 numSerial:=1;
--              end;

--              INSERT INTO TRTRAN002
--                (TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,trad_serial_number,TRAD_REVERSE_SERIAL,TRAD_IMPORT_EXPORT,
--                TRAD_LOCAL_BANK,TRAD_ENTRY_DATE,TRAD_USER_REFERENCE,  TRAD_REFERENCE_DATE,
--                TRAD_BUYER_SELLER,TRAD_TRADE_CURRENCY,TRAD_PRODUCT_CODE,TRAD_TRADE_FCY,
--                TRAD_TRADE_RATE,TRAD_TRADE_INR,TRAD_PERIOD_CODE,TRAD_TRADE_PERIOD,TRAD_TENOR_CODE,TRAD_TENOR_PERIOD,
--                TRAD_MATURITY_FROM,TRAD_MATURITY_DATE,TRAD_PROCESS_COMPLETE,TRAD_COMPLETE_DATE,
--                TRAD_CREATE_DATE,TRAD_ENTRY_DETAIL,TRAD_RECORD_STATUS,TRAD_SUBPRODUCT_CODE,
--                TRAD_PRODUCT_CATEGORY,TRAD_LOCATION_CODE,TRAD_LOCAL_CURRENCY)
--              SELECT IIRS_COMPANY_CODE,varReference||'_'||numcode3|| '_' ||numcode10,numSerial,
--                numcode3,decode(SIGN(numFcy),-1,25900098,25900032),IIRS_COUNTER_PARTY,datTemp,IIRS_USER_REFERENCE,datTemp,
--                0,numcode5,24200001,abs(numFcy),0,0,0,0,25500001,0,
--                datTemp,datTemp,12400001,datTemp,sysdate,null,10200001,
--                IIRS_SUB_PORTFOLIO,IIRS_PORTFOLIO,IIRS_LOCATION_CODE,30400003 
--              from trtran091 
--              WHERE IIRS_IRS_NUMBER = varReference;
--        
--              INSERT INTO TRTRAN003
--                (BREL_COMPANY_CODE,BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,
--                BREL_USER_REFERENCE,BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,
--                BREL_REVERSAL_RATE,BREL_REVERSAL_INR,BREL_PERIOD_CODE,BREL_TRADE_PERIOD,
--                BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,BREL_ENTRY_DETAIL,
--                BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE,
--                BREL_BATCH_NUMBER,BREL_TRADE_CURRENCY,BREL_LOCAL_CURRENCY,
--                --BREL_USER_ID,
--                --BREL_TRANSACTION_NATURE,
--                BREL_TRANSACTION_DATE)
--              SELECT TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,
--                numcode3,datTemp,TRAD_USER_REFERENCE,datTemp,
--                TRAD_IMPORT_EXPORT,TRAD_TRADE_FCY,0,0,25500001,0,
--                datTemp,datTemp,SYSDATE,NULL,10200001,TRAD_LOCAL_BANK,
--                NULL,TRAD_LOCATION_CODE,'Link/' || Gconst.fncGenerateSerial(Gconst.SERIALFRWDLINKBATCHNO),
--                TRAD_TRADE_CURRENCY,TRAD_LOCAL_CURRENCY,
--                --varUserID,--24199999,
--                datTemp 
--              FROM TRTRAN002 WHERE TRAD_TRADE_REFERENCE = varReference||'_'||numcode3|| '_' ||numcode10
--              AND trad_serial_number = numSerial;

      ELSIF numAction in (GConst.DELETESAVE) then
          IF numCode2 = 81000003 THEN --Unwind/cancel
            UPDATE TRTRAN091BB 
            SET IIRM_PROCESS_COMPLETE = 12400002,
                IIRM_COMPLETE_DATE = ''
                --IIRM_UNWIND_UTILIZE = '',
                --IIRM_SPOT_RATE = 0,
                --IIRM_CONVERTED_AMOUNT = 0,
                --IIRM_NET_CASHFLOW = 0,
                --IIRS_SPOT_AMOUNT = 0                                
              WHERE IIRM_IRS_NUMBER = varReference
              AND IIRM_SETTLEMENT_DATE = datTemp;
              --AND IIRM_UNWIND_UTILIZE = 81000003;

            UPDATE TRTRAN091G
            SET IIRU_NET_CASHFLOW=0,
                IIRU_NET_EXRATE=0,
                IIRU_NET_CASHFLOWLCY=0
            WHERE IIRU_IRS_NUMBER = varReference;

            UPDATE TRTRAN091 
                SET IIRS_PROCESS_COMPLETE = 12400002,
                    IIRS_COMPLETE_DATE = '' 
                WHERE IIRS_IRS_NUMBER = varReference;
          ELSE --Settlement 
                SELECT IIRS_SETTLEMENT_TYPE
                    INTO numcode
                    FROM trtran091 
                    WHERE IIRS_IRS_NUMBER = varReference;

           if numcode = 81600001 then
               UPDATE TRTRAN091BB 
                SET IIRM_PROCESS_COMPLETE = 12400002,
                    IIRM_COMPLETE_DATE = ''
                    --IIRM_UNWIND_UTILIZE = '',
                    --IIRM_SPOT_RATE = 0,
                    --IIRM_CONVERTED_AMOUNT = 0,
                    --IIRM_NET_CASHFLOW = 0,
                    --IIRS_SPOT_AMOUNT = 0                                
                  WHERE IIRM_IRS_NUMBER = varReference
                       AND IIRM_SETTLEMENT_DATE = datTemp;

                  UPDATE TRTRAN091G
                    SET IIRU_NET_CASHFLOW=0,
                        IIRU_NET_EXRATE=0,
                        IIRU_NET_CASHFLOWLCY=0
                    WHERE IIRU_IRS_NUMBER = varReference
                        and IIRU_SETTLEMENT_DATE = datTemp;
           ELSE     
               UPDATE TRTRAN091BB 
                    SET IIRM_PROCESS_COMPLETE = 12400002,
                        IIRM_COMPLETE_DATE = ''
                        --IIRM_UNWIND_UTILIZE = '',
                        --IIRM_SPOT_RATE = 0,
                        --IIRM_CONVERTED_AMOUNT = 0,
                        --IIRM_NET_CASHFLOW = 0,
                        --IIRS_SPOT_AMOUNT = 0                                
                      WHERE IIRM_IRS_NUMBER = varReference
                        AND IIRM_LEG_SERIAL = numCode3 and IIRM_SERIAL_NUMBER = numCode10;

                     UPDATE TRTRAN091G
                    SET IIRU_NET_CASHFLOW=0,
                        IIRU_NET_EXRATE=0,
                        IIRU_NET_CASHFLOWLCY=0
                    WHERE IIRU_IRS_NUMBER = varReference
                        and IIRU_SETTLEMENT_DATE = datTemp 
                        and IIRU_LEG1_SERIAL = numcode3
                        and IIRU_LEG1_SUBSERIAL = numcode10;
                end if;


          END IF;
--          --------------Deleting Settlement Entry from trtran002,003,006,001,004c
--          SELECT NVL(COUNT(*),0)  
--            INTO  numcode11 
--          FROM TRTRAN003 
--          WHERE BREL_TRADE_REFERENCE = varReference||'-'||numcode3||numcode10
--          AND BREL_REVERSE_SERIAL = numcode3
--          AND BREL_RECORD_STATUS NOT IN(10200005,10200006);
--          
--          IF numcode11 > 0 THEN
--            UPDATE TRTRAN002 SET TRAD_RECORD_STATUS = 10200006
--            WHERE TRAD_TRADE_REFERENCE = varReference||'-'||numcode3||numcode10
--            AND TRAD_REVERSE_SERIAL = numcode3;
--            
--             SELECT BREL_DELIVERY_BATCH 
--              INTO varTemp1 
--            FROM TRTRAN003 
--            WHERE BREL_TRADE_REFERENCE = varReference||'-'||numcode3||numcode10
--            AND BREL_REVERSE_SERIAL = numcode3
--            AND BREL_RECORD_STATUS NOT IN(10200005,10200006);
----            SELECT BREL_BATCH_NUMBER 
----              INTO varTemp1 
----            FROM TRTRAN003 
----            WHERE BREL_TRADE_REFERENCE = varReference||'-'||numcode3||numcode10
----            AND BREL_REVERSE_SERIAL = numcode3
----            AND BREL_RECORD_STATUS NOT IN(10200005,10200006);
--  
--            UPDATE TRTRAN003 SET BREL_RECORD_STATUS = 10200006
--            WHERE BREL_TRADE_REFERENCE = varReference||'-'||numcode3||numcode10
--            AND BREL_REVERSE_SERIAL = numcode3;
--            
--            UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200006
--            WHERE BCAC_VOUCHER_REFERENCE = varReference
--            AND BCAC_REFERENCE_SERIAL = numcode3;
--            
--            UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006
--            WHERE CDEL_TRADE_REFERENCE = varTemp1;
--            --Incase cross currency settlement
--            UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006
--            WHERE CDEL_BATCH_NUMBER = varTemp1;
--            
--            FOR CUR_IN IN(SELECT * FROM TRTRAN006 WHERE CDEL_BATCH_NUMBER = varTemp1 
--                          AND CDEL_RECORD_STATUS NOT IN(10200005,10200006))
--            LOOP
--            
--              UPDATE TRTRAN001 SET DEAL_RECORD_STATUS = 10200006 
--              WHERE DEAL_DEAL_NUMBER = CUR_IN.CDEL_DEAL_NUMBER
--              AND DEAL_DEAL_TYPE = 25400001;
--  
--              UPDATE TRTRAN001 SET DEAL_PROCESS_COMPLETE = 12400002 
--              WHERE DEAL_COMPLETE_DATE = ''
--              AND DEAL_DEAL_TYPE != 25400001;
--            
--            END LOOP;
--            
----            UPDATE TRTRAN004c SET UTLS_RECORD_STATUS = 10200006
----            WHERE UTLS_BATCH_NUMBER = varTemp1;          
--          END IF;

        END IF;
      End if; 

--added by supriya on 16/08/2021-----------

if EditType = SYSINTERESTREVALUATION then
varOperation := 'Extract from IRSINTERESTREVALUATION and insert/update TRTRAN002';
GLOG.log_write(varOperation);  

    varXPath := '//IRSINTERESTREVALUATION/ROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    for numTemp in 1..xmlDom.getLength(nlsTemp)
    Loop
        varOperation := 'Inside Loop IRSINTERESTREVALUATION';
        GLOG.log_write(varOperation);  

        varTemp := varXPath || '[@NUM="' || numTemp || '"]/IIRM_IRS_NUMBER';
        varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH);

        varTemp := varXPath || '[@NUM="' || numTemp || '"]/IIRM_LEG_SERIAL';
        numcode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numcode1, Gconst.TYPENODEPATH);

        varTemp := varXPath || '[@NUM="' || numTemp || '"]/IIRM_SERIAL_NUMBER';
        numSerial := GConst.fncXMLExtract(xmlTemp, varTemp, numSerial, Gconst.TYPENODEPATH);

        varTemp := varXPath || '[@NUM="' || numTemp || '"]/IIRM_AMOUNT_FCY';
        numFcy := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy, Gconst.TYPENODEPATH);

        varTemp := varXPath || '[@NUM="' || numTemp || '"]/IIRM_FINAL_RATE';
        numRate := GConst.fncXMLExtract(xmlTemp, varTemp, numRate, Gconst.TYPENODEPATH);

        varTemp := varXPath || '[@NUM="' || numTemp || '"]/IIRM_SETTLEMENT_DATE';
        datTemp := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp, Gconst.TYPENODEPATH);

            numcode3 := 0; numFCY1 := 0;

            SELECT DISTINCT IIRL_CURRENCY_CODE
            INTO numcode5
            FROM TRTRAN091A
            WHERE IIRL_IRS_NUMBER = varReference;
            GLOG.log_write('Inside Loop IRSINTERESTREVALUATION numcode5 : '|| numcode5);  

            SELECT IIRS_SETTLEMENT_TYPE 
            INTO numcode2
            FROM TRTRAN091
            WHERE IIRS_IRS_NUMBER = varReference;        
            GLOG.log_write('Inside Loop IRSINTERESTREVALUATION numcode2 : '|| numcode2);  

            select count(*)
            into numcode3
            from trtran002
            where ((numcode2 = 81600001 and TRAD_TRADE_REFERENCE = varReference || '_1_' || numSerial)
            or (numcode2 = 81600002 and TRAD_TRADE_REFERENCE = varReference || '_' || numcode1 || '_' || numSerial));
            GLOG.log_write('Inside Loop IRSINTERESTREVALUATION numcode3 : '|| numcode3);   

            if numcode2 = 81600001 then   
                SELECT Receipt - Payment
                into numFCY1
                FROM (select sum(case when IIRM_LEG_SERIAL = 1 then IIRM_AMOUNT_FCY else 0 end) Receipt,
                     sum(case when IIRM_LEG_SERIAL = 2 then IIRM_AMOUNT_FCY else 0 end) Payment from trtran091bb
                     where IIRM_IRS_NUMBER = varReference AND IIRM_SETTLEMENT_DATE = datTemp
                     group by IIRM_IRS_NUMBER,IIRM_SETTLEMENT_DATE);
            else
                SELECT IIRM_AMOUNT_FCY 
                into numFCY1
                FROM trtran091bb 
                where IIRM_IRS_NUMBER = varReference AND IIRM_SETTLEMENT_DATE = datTemp and IIRM_LEG_SERIAL = numcode1;
            end if;
            GLOG.log_write('Inside Loop IRSINTERESTREVALUATION numFCY1 : '|| numFCY1);  

            if ((numcode2 = 81600001 and  numcode1 != 2 and numcode3 = 0) or (numcode2 = 81600002 and numcode3 = 0) )then                
                GLOG.log_write('Inside Loop IRSINTERESTREVALUATION before insert : '|| varReference || '_' || numcode1 || '_' || numSerial);  
                INSERT INTO TRTRAN002
                    (TRAD_COMPANY_CODE, TRAD_TRADE_REFERENCE, trad_serial_number, TRAD_REVERSE_SERIAL, TRAD_IMPORT_EXPORT,
                    TRAD_LOCAL_BANK, TRAD_ENTRY_DATE, TRAD_USER_REFERENCE, TRAD_REFERENCE_DATE,
                    TRAD_BUYER_SELLER, TRAD_TRADE_CURRENCY, TRAD_PRODUCT_CODE, TRAD_TRADE_FCY,
                    TRAD_TRADE_RATE, TRAD_TRADE_INR, TRAD_PERIOD_CODE, TRAD_TRADE_PERIOD, TRAD_TENOR_CODE, TRAD_TENOR_PERIOD,
                    TRAD_MATURITY_FROM, TRAD_MATURITY_DATE, TRAD_PROCESS_COMPLETE, TRAD_COMPLETE_DATE,
                    TRAD_CREATE_DATE, TRAD_ENTRY_DETAIL, TRAD_RECORD_STATUS, TRAD_SUBPRODUCT_CODE,
                    TRAD_PRODUCT_CATEGORY, TRAD_LOCATION_CODE, TRAD_LOCAL_CURRENCY)
                SELECT IIRS_COMPANY_CODE, varReference || '_' || numcode1 || '_' || numSerial, numSerial,
                    numcode1, decode(SIGN(numFCY1), -1, 25900098, 25900032), IIRS_COUNTER_PARTY, datTemp, IIRS_USER_REFERENCE, datTemp,
                    0, numcode5, 24200001, abs(numFCY1), numRate, 0, 0, 0, 25500005, 0,
                    datTemp, datTemp, 12400002, null, sysdate, null, 10200001,
                    IIRS_SUB_PORTFOLIO,IIRS_PORTFOLIO,IIRS_LOCATION_CODE, 30400003 
                    from trtran091 
                    WHERE IIRS_IRS_NUMBER = varReference;

                INSERT INTO TRTRAN003
                    (BREL_COMPANY_CODE,BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,
                    BREL_USER_REFERENCE,BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,
                    BREL_REVERSAL_RATE,BREL_REVERSAL_INR,BREL_PERIOD_CODE,BREL_TRADE_PERIOD,
                    BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,BREL_ENTRY_DETAIL,
                    BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE,
                    BREL_BATCH_NUMBER,BREL_TRADE_CURRENCY,BREL_LOCAL_CURRENCY,
                    BREL_TRANSACTION_DATE)
                SELECT TRAD_COMPANY_CODE, TRAD_TRADE_REFERENCE,
                    numcode1, datTemp, TRAD_USER_REFERENCE, datTemp,
                    TRAD_IMPORT_EXPORT, TRAD_TRADE_FCY, TRAD_TRADE_RATE, 0, 25500005, 0,
                    datTemp, datTemp, SYSDATE, NULL, 10200001, TRAD_LOCAL_BANK,
                    NULL, TRAD_LOCATION_CODE, 'Link/' || Gconst.fncGenerateSerial(SERIALFRWDLINKBATCHNO),
                    TRAD_TRADE_CURRENCY, TRAD_LOCAL_CURRENCY, datTemp 
                    FROM TRTRAN002 WHERE TRAD_TRADE_REFERENCE = varReference || '_' || numcode1 || '_' || numSerial
                    AND trad_serial_number = numSerial;
            else
                GLOG.log_write('Inside Loop IRSINTERESTREVALUATION before update : '|| varReference || '_' || numcode1 || '_' || numSerial);  
                update TRTRAN002
                set
                TRAD_TRADE_FCY = numFCY1,
                TRAD_TRADE_RATE = numRate
                where ((numcode2 = 81600001 and TRAD_TRADE_REFERENCE = varReference || '_1_' ||numSerial) or
                (numcode2 = 81600002 and TRAD_TRADE_REFERENCE = varReference || '_' || numcode1 || '_' || numSerial))
                and trad_serial_number = numSerial;   
            end if;
        End loop;
END IF;

     if EditType = SYSPRODUCTMATURITY then
           varOperation := 'Extracting Fileds For Maturity Dates' ;
           numCode := GConst.fncXMLExtract(xmlTemp, 'CPRO_PICK_CODE', numCode);
           datTemp := GConst.fncXMLExtract(xmlTemp, 'CPRO_EFFECTIVE_DATE', datTemp);

            if numAction = GConst.DELETESAVE then
              update TRMASTER503A set CPRM_RECORD_STATUS = 10200006 where CPRM_EFFECTIVE_DATE = datTemp
              and CPRM_PRODUCT_CODE = numCode;
            end if;
         if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
            if numAction = GConst.EDITSAVE then
              begin
                varXPath := '//MATURITYDATEPOPULATE/ROW';
                varTemp := varXPath || '[@NUM="' || 1 || '"]/FCMaturityDate';
                datTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp1, Gconst.TYPENODEPATH);
                delete from TRMASTER503A where CPRM_EFFECTIVE_DATE = datTemp and CPRM_PRODUCT_CODE = numCode;
              exception
               when others then
               datTemp1 := '';
              end;
            end if; 
          varXPath := '//MATURITYDATEPOPULATE/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;
          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/FCMaturityDate';
              varoperation :='Extracting Data from XML' || varTemp;
              datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2, Gconst.TYPENODEPATH);
            insert into TRMASTER503A(CPRM_PRODUCT_CODE,  CPRM_MATURITY_DATE ,CPRM_EFFECTIVE_DATE,CPRM_RECORD_STATUS)
               values           (numCode,datTemp2,datTemp,10200001);
          end loop;            
         end if;   
     end if;

     if EditType = SYSEXPOSURESETTLEMENT then
        numError := fncExposuresettlement(RecordDetail);

     end if;

    if EditType = SYSINFLOWOUTFOWPAYMENTS then     
        varOperation := 'Extracting INFLOWOUTFOWPAYMENTS RECORDS ';
        varTemp := '//ROW[@NUM="1"]/BREL_BATCH_NUMBER';        
        varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH);
        GLOG.log_write('INFLOWOUTFOWPAYMENTS '|| numAction || ' varReference -' ||varReference);  
        begin  
            for cur_in in(select * from trtran003  where BREL_BATCH_NUMBER = varReference)
            loop 
                GLOG.log_write('INFLOWOUTFOWPAYMENTS inside loop numAction'|| numAction || ' BREL_TRADE_REFERENCE -' ||cur_in.BREL_TRADE_REFERENCE); 
                numError := fncCompleteUtilization(cur_in.BREL_TRADE_REFERENCE, Gconst.UTILEXPORTS, datWorkDate);
            end loop;
        end;    
    end if;

    --added by supriya on 14/06/2021
    if EditType = SYSBRANCHUPDATE then    
        BEGIN
            numcode := GConst.fncXMLExtract(xmlTemp, 'BRNH_BANK_CODE', numcode); 
            numcode1 := GConst.fncXMLExtract(xmlTemp, 'BRNH_PICK_CODE ', numcode1); 
        EXCEPTION 
        when no_data_found then
            numcode := 0;
            numcode1 := 0;
        end;

        if (numAction = GConst.DELETESAVE) then
            UPDATE TRMASTER306B
            SET ACCT_RECORD_STATUS = 10200006
            WHERE ACCT_BANK_CODE = numcode and ACCT_BRANCH_CODE = numcode1;
        elsif (numAction = GConst.CONFIRMSAVE) then
            UPDATE TRMASTER306B
            SET ACCT_RECORD_STATUS = 10200003
            WHERE ACCT_BANK_CODE = numcode and ACCT_BRANCH_CODE = numcode1;
     elsif (numAction = GConst.INACTIVESAVE) then
            UPDATE TRMASTER306A
            SET BRNH_RECORD_STATUS = 10200005
            WHERE BRNH_BANK_CODE = numcode and BRNH_PICK_CODE = numcode1;            
             
             UPDATE TRMASTER306B
            SET ACCT_ACCOUNT_STATUS = 14400004
            WHERE ACCT_BANK_CODE = numcode and ACCT_BRANCH_CODE = numcode1;
        else
            varOperation := 'Extracting Parameters for Add Save';
            docFinal := xmlDom.newDomDocument(xmlTemp);
            nodFinal := xmlDom.makeNode(docFinal);       
            varOperation := 'Before Loop';

            varXPath := '//BRANCHDETAILS/DROW';
            nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
            for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop
            varoperation :='Extracting Data from XML';            
            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/AccountNumber';
            varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH); 

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ReferenceNumber';
            varReferenceNo := GConst.fncXMLExtract(xmlTemp, varTemp, varReferenceNo, Gconst.TYPENODEPATH); 

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/AccountType';
            numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/AccountStatus';
            numCode3 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode3, Gconst.TYPENODEPATH);

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ConcentrationAccount';
            numCode4 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode4, Gconst.TYPENODEPATH);

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecordStatus';
            numCode5 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode5, Gconst.TYPENODEPATH);

            GLOG.log_write('BRANCHDETAILS '|| numAction || ' AccountNumber -' ||varReference);  

            if numCode5 = 1  then 
                varReferenceNo := 'ACCT' || fncGenerateSerial(SERIALACCOUNTNUMBER,numCompany);
                INSERT INTO TRMASTER306B(ACCT_ACCOUNT_NUMBER,ACCT_ACCOUNT_TYPE,ACCT_BANK_CODE,ACCT_BRANCH_CODE,
                                         ACCT_CONCENTRATION_ACCOUNT,ACCT_ACCOUNT_STATUS,ACCT_CREATE_DATE,ACCT_RECORD_STATUS,ACCT_REFERENCE_NUMBER)
                VALUES(varReference,numCode2,numcode,numcode1,numCode4,numCode3,sysdate,10200001,varReferenceNo);

            elsif numCode5 = 2 then
            GLOG.log_write('numCode5 '|| numCode5 ||'ACCT_ACCOUNT_STATUS--' ||numCode3  ||' ACCT_CONCENTRATION_ACCOUNT --' || numCode4|| ' varReferenceNo -' ||varReferenceNo); 
                UPDATE TRMASTER306B
                SET ACCT_ACCOUNT_STATUS = numCode3,
                ACCT_ACCOUNT_NUMBER=varReference,
                ACCT_CONCENTRATION_ACCOUNT = numCode4,
                ACCT_RECORD_STATUS = 10200004
                WHERE ACCT_REFERENCE_NUMBER = varReferenceNo;
            end if;
        end loop;  
    end if;
end if;

    --added by supriya on 15/09/2021
    if EditType = SYSDEALINTEGRATION then    
        BEGIN
            vartemp := GConst.fncXMLExtract(xmlTemp, 'DEAL_REFERENCE_NUMBER', vartemp); 
        EXCEPTION 
        when no_data_found then
            vartemp:= null;
        end;

        if (numAction = GConst.ADDSAVE) then               
            UPDATE CLOUDDB_MASTER.TRCONFIG008
            SET DEAL_LICENSE_NUMBER = (select PRMC_LICENSE_REFERENCE 
                                        from trsystem051)
            WHERE DEAL_REFERENCE_NUMBER = vartemp;
        end if;
    end if;

     --added by supriya on 02/07/2021
    if EditType = SYSEMAILSTATEMENTCONFIG then    
    varOperation := 'Extracting Fileds For SYSEMAILSTATEMENTCONFIG' ;
    begin
        numcode1 := GConst.fncXMLExtract(xmlTemp, 'EMIL_SOURCE_TYPE ', numcode1); 
    EXCEPTION 
    when no_data_found then
        numcode1 := 0;
    end;
    begin
        vartemp := GConst.fncXMLExtract(xmlTemp, 'EMIL_EMAIL_ID', vartemp); 
    EXCEPTION 
    when no_data_found then
        vartemp := 0;
    end;
    begin
        numserial := GConst.fncXMLExtract(xmlTemp, 'EMIL_SERIAL_NUMBER ', numserial); 
    EXCEPTION 
    when no_data_found then
        numserial := 0;
    end;
    begin
        vartemp1 := GConst.fncXMLExtract(xmlTemp, 'EMIL_PASSWORD', vartemp1); 
    EXCEPTION 
    when no_data_found then
        vartemp1 := 0;
    end; 
    begin
        vartemp2 := GConst.fncXMLExtract(xmlTemp, 'EMIL_SMTP_SERVER ', vartemp2); 
    EXCEPTION 
    when no_data_found then
        vartemp2 := 0;
    end;
    begin
        numcode3 := GConst.fncXMLExtract(xmlTemp, 'EMIL_MAIL_TYPE', numcode3); 
    EXCEPTION 
    when no_data_found then
        numcode3 := 0;
    end;   

    select USER_LICENSE_REFERENCE
    into vartemp3
    from clouddb_global.TRSYSTEM022
    where upper(USER_USER_ID) = upper(varUserID);
    GLOG.log_write('vartemp3 - ' || vartemp3);   

    GLOG.log_write('varUserID - ' || varUserID || ' numcode3 - '|| numcode3 || ' vartemp2 - ' ||vartemp2 ||' vartemp1 - '|| vartemp1 || ' numserial - ' ||numserial ||' vartemp - '|| vartemp || ' numcode1 - ' ||numcode1 ); 
        if (numAction = GConst.EDITSAVE) then
            UPDATE clouddb_master.TRCONFIG005
            SET EMIL_PASSWORD = vartemp1,
            EMIL_SMTP_SERVER = vartemp2,
            EMIL_EMAIL_ID = vartemp,
            EMIL_MAIL_TYPE = numcode3,
            EMIL_RECORD_STATUS = 10200004
            WHERE EMIL_LICENSE_NUMBER = vartemp3 and EMIL_SOURCE_TYPE = numcode1 AND EMIL_SERIAL_NUMBER = numserial;

        elsif (numAction = GConst.CONFIRMSAVE) then
            UPDATE clouddb_master.TRCONFIG005
            SET EMIL_RECORD_STATUS = 10200003
            WHERE EMIL_LICENSE_NUMBER = vartemp3 and EMIL_SOURCE_TYPE = numcode1 AND EMIL_SERIAL_NUMBER = numserial;

        elsif (numAction = GConst.UNCONFIRMSAVE) then
            UPDATE clouddb_master.TRCONFIG005
            SET EMIL_RECORD_STATUS = 10200004
            WHERE EMIL_LICENSE_NUMBER = vartemp3 and EMIL_SOURCE_TYPE = numcode1 AND EMIL_SERIAL_NUMBER = numserial;

        elsif (numAction = GConst.ADDSAVE) then

            varOperation := 'Extracting Parameters for Add Save';
            insert into clouddb_master.TRCONFIG005(EMIL_LICENSE_NUMBER,EMIL_SOURCE_TYPE,EMIL_EMAIL_ID,
                        EMIL_SERIAL_NUMBER,EMIL_PASSWORD,EMIL_SMTP_SERVER,EMIL_MAIL_TYPE,EMIL_RECORD_STATUS,
                        EMIL_CREATE_DATE,EMIL_ADD_DATE,EMIL_ENTRY_DETAILS)
            values(vartemp3,numcode1,vartemp,numserial,vartemp1,vartemp2,numcode3,
                   10200001,sysdate,sysdate,null);
        end if;
    end if;



    --added by supriya on 02/07/2021
    if EditType = SYSSFTPSTATEMENTCONFIG then    
    varOperation := 'Extracting Fileds For SYSSFTPSTATEMENTCONFIG' ;
    begin
        numcode1 := GConst.fncXMLExtract(xmlTemp, 'SFTP_SOURCE_TYPE ', numcode1);
    EXCEPTION 
    when no_data_found then
        numcode1 := 0;
    end;
    begin
        vartemp := GConst.fncXMLExtract(xmlTemp, 'SFTP_USER_ID', vartemp); 
    EXCEPTION 
    when no_data_found then
        vartemp := 0;
    end;
    begin
        numserial := GConst.fncXMLExtract(xmlTemp, 'SFTP_SERIAL_NUMBER ', numserial); 
    EXCEPTION 
    when no_data_found then
        numserial := 0;
    end;
    begin
        vartemp1 := GConst.fncXMLExtract(xmlTemp, 'SFTP_PASSWORD', vartemp1); 
    EXCEPTION 
    when no_data_found then
        vartemp1 := 0;
    end; 
    begin
        vartemp2 := GConst.fncXMLExtract(xmlTemp, 'SFTP_FILE_PATH', vartemp2); 
    EXCEPTION 
    when no_data_found then
        vartemp2 := 0;
    end; 

    select USER_LICENSE_REFERENCE
    into vartemp3
    from clouddb_global.TRSYSTEM022
    where upper(USER_USER_ID) = upper(varUserID);

    GLOG.log_write('vartemp3 - ' || vartemp3 || ' varUserID - ' || varUserID || ' numcode1 - '|| numcode1 || ' vartemp - ' ||vartemp ||' numserial - '|| numserial || ' vartemp1 - ' ||vartemp1 );     
        if (numAction = GConst.EDITSAVE) then
            UPDATE clouddb_master.TRCONFIG006
            SET SFTP_PASSWORD = vartemp1,
            SFTP_USER_ID = vartemp,
            SFTP_FILE_PATH = vartemp2,
            SFTP_RECORD_STATUS = 10200004
            WHERE SFTP_LICENSE_NUMBER = vartemp3 and SFTP_SOURCE_TYPE = numcode1 AND SFTP_SERIAL_NUMBER = numserial;

        elsif (numAction = GConst.CONFIRMSAVE) then
            UPDATE clouddb_master.TRCONFIG006
            SET SFTP_RECORD_STATUS = 10200003
            WHERE SFTP_LICENSE_NUMBER = vartemp3 and SFTP_SOURCE_TYPE = numcode1 AND SFTP_SERIAL_NUMBER = numserial;

        elsif (numAction = GConst.UNCONFIRMSAVE) then
            UPDATE clouddb_master.TRCONFIG006
            SET SFTP_RECORD_STATUS = 10200004
            WHERE SFTP_LICENSE_NUMBER = vartemp3 and SFTP_SOURCE_TYPE = numcode1 AND SFTP_SERIAL_NUMBER = numserial;

        elsif (numAction = GConst.ADDSAVE) then

            varOperation := 'Extracting Parameters for Add Save';
            insert into clouddb_master.TRCONFIG006(SFTP_LICENSE_NUMBER,SFTP_SOURCE_TYPE,
                        SFTP_USER_ID,SFTP_SERIAL_NUMBER,SFTP_PASSWORD,SFTP_FILE_PATH,
                        SFTP_RECORD_STATUS,SFTP_CREATE_DATE,SFTP_ADD_DATE,SFTP_ENTRY_DETAILS)
            values(vartemp3,numcode1,vartemp,numserial,vartemp1,vartemp2,
                   10200001,sysdate,sysdate,null);
        end if;
    end if;

    --added by supriya on 23/06/2021
    if EditType = SYSEXPOSUREREVERSALUPDATE then    
        BEGIN
            vartemp := GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_REFERENCE', vartemp); 
            vartemp1 := GConst.fncXMLExtract(xmlTemp, 'TRAD_REVERSE_REFERENCE', vartemp1); 

            select count(*) + 1
            into numserial
            from TRTRAN003
            where BREL_TRADE_REFERENCE = vartemp1;
        EXCEPTION 
        when no_data_found then
            vartemp := null;
        end;

        if (numAction = GConst.ADDSAVE) then
            if vartemp1 is not null then
                insert into TRTRAN003 (BREL_COMPANY_CODE,BREL_LOCATION_CODE,BREL_TRADE_REFERENCE,BREL_REVERSE_REFERENCE,
                              BREL_REVERSE_SERIAL,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,
                              BREL_TRADE_PERIOD,BREL_PERIOD_CODE,BREL_MATURITY_DATE,BREL_LOCAL_BANK,BREL_TRADE_CURRENCY,
                              BREL_LOCAL_CURRENCY,BREL_PRODUCT_CATEGORY,BREL_SUB_PORTFOLIO,BREL_REFERENCE_DATE,
                              BREL_IMPORT_EXPORT,BREL_BATCH_NUMBER,BREL_RECORD_STATUS,
                              BREL_USER_REFERENCE,BREL_ENTRY_DATE,BREL_CREATE_DATE,BREL_REMARKS)
                select TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,vartemp1,vartemp,numserial,
                       TRAD_IMPORT_EXPORT,TRAD_TRADE_FCY,TRAD_TRADE_RATE,TRAD_TRADE_INR,                       
                       TRAD_TENOR_PERIOD,TRAD_TENOR_CODE,TRAD_MATURITY_DATE,TRAD_LOCAL_BANK,TRAD_TRADE_CURRENCY,
                       TRAD_LOCAL_CURRENCY,TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE,TRAD_REFERENCE_DATE,
                       (case when TRAD_IMPORT_EXPORT between 25900001 and 25900050 then 31700001 else 31700002 end),
                       'NA',10200001,TRAD_USER_REFERENCE,TRAD_ENTRY_DATE,datWorkDate,TRAD_TRADE_REMARKS
                from TRTRAN002 where TRAD_TRADE_REFERENCE = vartemp;   
            end if;    
        elsif (numAction = GConst.DELETESAVE) then
            UPDATE TRTRAN003
            SET BREL_RECORD_STATUS = 10200006
            WHERE BREL_TRADE_REFERENCE = vartemp1 AND BREL_REVERSE_REFERENCE = vartemp;
        elsif (numAction = GConst.EDITSAVE) then
            UPDATE TRTRAN003
            SET (BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,BREL_RECORD_STATUS,
                              BREL_USER_REFERENCE,BREL_REMARKS) = 
            (SELECT TRAD_TRADE_FCY,TRAD_TRADE_RATE,TRAD_TRADE_INR,10200004,
                   TRAD_USER_REFERENCE,TRAD_TRADE_REMARKS
             FROM TRTRAN002
             WHERE TRAD_TRADE_REFERENCE = vartemp AND TRAD_REVERSE_REFERENCE = vartemp1)
            WHERE BREL_TRADE_REFERENCE = vartemp1 AND BREL_REVERSE_REFERENCE = vartemp;
        end if;    

        numError := fncCompleteUtilization(vartemp1, Gconst.UTILEXPORTS, datWorkDate);
    end if;

      if EditType = SYSCASHINHAND then
           varOperation := 'Extracting Fileds For Cash Pool Details' ;
           --varReference := GConst.fncXMLExtract(xmlTemp, 'LBBL_REFERENCE_NUMBER', varReference);
           if (numAction = GConst.ADDSAVE) then

              varOperation := 'Extracting Parameters';
              docFinal := xmlDom.newDomDocument(xmlTemp);
              nodFinal := xmlDom.makeNode(docFinal);       
              varOperation := 'Before Loop';

              varXPath := '//CASHPOOLDETAILS/DROW';
              nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
              varOperation := 'Delete Previous Entry For AsonDate ' || varXPath;
              for numTemp in 1..xmlDom.getLength(nlsTemp)
              Loop
                  varoperation :='Extracting Data from XML';

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ReferenceNumber';
                  varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH); 

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/AsonDate';
                  datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2, Gconst.TYPENODEPATH);    

                  UPDATE trtran151
                  SET LBBL_RECORD_STATUS = 10200005
                  WHERE LBBL_ASON_DATE = datTemp2 
                  AND LBBL_REFERENCE_NUMBER != varReference
                  AND LBBL_RECORD_STATUS != 10200003;

              end loop;

              varXPath := '//CASHPOOLDETAILS/DROW';
              nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
              varOperation := 'Update Reverse Reference ' || varXPath;
              for numTemp in 1..xmlDom.getLength(nlsTemp)
              Loop
                  varoperation :='Extracting Data from XML';

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ReferenceNumber';
                  varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH); 

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/SerialNumber';
                  numSerial := GConst.fncXMLExtract(xmlTemp, varTemp, numSerial, Gconst.TYPENODEPATH);  

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/AsonDate';
                  datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2, Gconst.TYPENODEPATH);    

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ToAccount';
                  varTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp1, Gconst.TYPENODEPATH);    

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/FromAccount';  
                  varTemp3 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp3, Gconst.TYPENODEPATH);    

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/TransferAmount';  
                  numFCY := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY, Gconst.TYPENODEPATH);           

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecordStatus';  
                  numCode := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);  

                  insert into trtran151A (POOL_REFERENCE_NUMBER,POOL_SERIAL_NUMBER,POOL_FROM_ACCOUNT,
                                          POOL_TO_ACCOUNT,POOL_TRANSFER_AMOUNT,POOL_RECORD_STATUS)
                  values (varReference,numSerial,varTemp3,varTemp1,numFCY,10200001);

--                  begin
--                        if numcode = 1 then
--                            numcode1 := 10200001;
--                        ELSIF numcode = 2 then
--                            numcode1 := 10200004;
--                        end if;
--                  exception  
--                  when others then  
--                       numcode1 := 10200004;                            
--                  end;
--                        

                end loop;            
             end if;

           if (numAction = GConst.CONFIRMSAVE) then

              varOperation := 'Extracting Parameters';
              docFinal := xmlDom.newDomDocument(xmlTemp);
              nodFinal := xmlDom.makeNode(docFinal);       
              varOperation := 'Before Loop';

              varXPath := '//CASHPOOLDETAILS/DROW';
              nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
              varOperation := 'Update Reverse Reference ' || varXPath;
              for numTemp in 1..xmlDom.getLength(nlsTemp)
              Loop
                  varoperation :='Extracting Data from XML';

                  varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ReferenceNumber';
                  varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH); 

                  UPDATE trtran151A 
                  SET POOL_RECORD_STATUS = 10200003
                  WHERE POOL_REFERENCE_NUMBER = varReference;

                end loop;            
             end if;   
      end if;

-- if EditType = SYSEMAILCONFIGURATIONPROCESS then
--
--        varOperation := 'Email Configuration Details, Getting ReferenceNumber';
--        varTemp := '//ROW[@NUM="1"]/TREM_REFERENCE_NUMBER';
--        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
--        varXPath := '//EditedItems/DROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--          begin
--             select nvl(max(TRED_SERIAL_NUMBER),0)+1
--               into numSerial
--              from TRSYSTEM967A
--              where TRED_REFERENCE_NUMBER=varReference;
--          exception 
--            when no_data_found  then 
--            Numserial:=1;
--          end;
--          
--        varOperation := 'Users Entering Into Main loop ' || varXPath;
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath; 
--          varoperation :='Extracting Data from XML' || varTemp;
--          
--
--
--              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
--              
--           varoperation :='Extracting Data from XML' || varTemp;
--           
--            update TRSYSTEM967A set TRED_RECORD_STATUS=10200006
--            where TRED_REFERENCE_NUMBER=varReference
--            AND TERD_XML_FIELD=varTemp1;
--          
--            insert into TRSYSTEM967A (TERD_XML_FIELD,TRED_RECORD_STATUS,TRED_SERIAL_NUMBER,TRED_REFERENCE_NUMBER)          
--            values (varTemp1,10200001,Numserial,varReference);
-- End Loop;
-- end if;
--    if EditType = SYSEMAILCONFIGURATIONPROCESS then
-- 
--        varOperation := 'Email Configuration Details, Getting ReferenceNumber';
--        varTemp := '//ROW[@NUM="1"]/TREM_REFERENCE_NUMBER';
--        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
--        varXPath := '//EditedItems/DROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--          begin
--             select nvl(max(TRED_SERIAL_NUMBER),0)+1
--               into numSerial
--              from TRSYSTEM967A
--              where TRED_REFERENCE_NUMBER=varReference;
--          exception 
--            when no_data_found  then 
--            numSerial:=1;
--          end;
--          
--        varOperation := 'Users Entering Into Main loop ' || varXPath;
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath; 
--          varoperation :='Extracting Data from XML' || varTemp;
--              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
--              
--           varoperation :='Extracting Data from XML' || varTemp; 
--         if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then 
--          update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
--                    where TRED_REFERENCE_NUMBER=varReference
--                    AND TERD_XML_FIELD=varTemp1;
--            insert into TRSYSTEM967A (TERD_XML_FIELD,TRED_RECORD_STATUS,TRED_SERIAL_NUMBER,TRED_REFERENCE_NUMBER)          
--            values (varTemp1,10200001,numSerial,varReference);
--         end if;
-- 
--         if (numAction = GConst.CONFIRMSAVE) then 
--          update TRSYSTEM967A set TRED_RECORD_STATUS=10200003
--                    where TRED_REFERENCE_NUMBER=varReference
--                    AND TERD_XML_FIELD=varTemp1;
--          end if;
--         
--           if numAction = GConst.DELETESAVE then
--                      update TRSYSTEM967A set TRED_RECORD_STATUS=10200006
--                    where TRED_REFERENCE_NUMBER=varReference
--                    AND TERD_XML_FIELD=varTemp1;
--           end if;
--   End Loop;
-- end if;

--  if EditType = SYSEMAILCONFIGURATIONPROCESS then
-- 
--        varOperation := 'Email Configuration Details, Getting ReferenceNumber';
--        varTemp := '//ROW[@NUM="1"]/TREM_REFERENCE_NUMBER';
--        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
--        numSerial:= GConst.fncXMLExtract(xmlTemp,'TREM_SERIAL_NUMBER',numSerial);
--        
--     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
--        varXPath := '//EditedItems/DROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--        
--        varOperation := 'Users Entering Into Main loop ' || varXPath;
--        
--         update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
--                    where TRED_REFERENCE_NUMBER=varReference;
--                    
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath;
--          varoperation :='Extracting Data from XML' || varTemp;
--              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
--               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
--               varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnDisplayName',varTemp4, Gconst.TYPENODEPATH);
--               numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);
--               begin
--               varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Condition',varTemp3, Gconst.TYPENODEPATH);
--                exception 
--                when others  then 
--                varTemp3 := null;
--              end;
----              select nvl(max(TRED_SERIAL_NUMBER),0)+1
----            into numSerial
----              from TRSYSTEM967A
----              where TRED_REFERENCE_NUMBER=varReference;
----                    AND TERD_XML_FIELD=varTemp1;
--           varoperation :='Extracting Data from XML' || varTemp;
--         
----          update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
----                    where TRED_REFERENCE_NUMBER=varReference
----                     AND TERD_XML_FIELD=varTemp1;
--                    
--            insert into TRSYSTEM967A (TERD_XML_FIELD,TRED_RECORD_STATUS,TRED_SERIAL_NUMBER,TRED_REFERENCE_NUMBER,
--            TRED_SYNONYM_NAME,TRED_CONDITION,TERD_LABEL_NAME,TRED_ORDER_BY)          
--            values (varTemp1,10200001,numSerial,varReference,varTemp2,varTemp3,varTemp4,numCode1);
--             End Loop;
--         end if;
-- 
--         if (numAction = GConst.CONFIRMSAVE) then
--          update TRSYSTEM967A set TRED_RECORD_STATUS=10200003
--                    where TRED_REFERENCE_NUMBER=varReference;
--          end if;
--         
--           if numAction = GConst.DELETESAVE then
--                      update TRSYSTEM967A set TRED_RECORD_STATUS=10200006
--                    where TRED_REFERENCE_NUMBER=varReference;
--           end if;
-- 
--   Glog.log_Write(' Check whether the Email configuration is for the Event Type Scheduler if yes then insert into Alert Creation');
--        varTemp := '//ROW[@NUM="1"]/TREM_EMAIL_TRIGGER_EVENT';
--        numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode,Gconst.TYPENODEPATH);
--        
--        if numCode= 35700004 then ---schedules 
--        
--            varOperation:=' Extracting PickCodes values';
--              select nvl(max(pick_key_value),18100100)+1, 
--                     nvl(max(Pick_key_number),100)+1
--               into numKeyValue, numKeyNumber
--               from trmaster001
--               where pick_key_group=181
--                and pick_key_number>100;
--               
--             varOperation:=' Insert into Pick table';  
--          
--                insert into trmaster001 (PICK_KEY_GROUP,PICK_KEY_NUMBER, PICK_KEY_VALUE,PICK_LONG_DESCRIPTION,
--                                         PICK_SHORT_DESCRIPTION, PICK_KEY_TYPE
--                                         , PICK_COMPANY_CODE, PICK_LOCATION_CODE,
--                                         PICK_ADD_DATE, PICK_CREATE_DATE, PICK_RECORD_STATUS)
--                        values (181,numKeyNumber,numKeyValue,
--                          GConst.fncXMLExtract(xmlTemp,'TREM_EMAIL_SUBJECT',varTemp) || 
--                          varReference,
--                          varReference,10100003,
--                          30199999,30299999,sysdate,sysdate,10200001);
--                          
--              varOperation:=' Insert into Job Master Table';      
--              
--               insert into trmaster181 (MJOB_SHORT_DESCRIPTION, MJOB_LONG_DESCRIPTION, 
--                               MJOB_PICK_CODE, MJOB_PROGRAM_TORUN,
--                               MJOB_JOB_TYPE, MJOB_JOB_RUNFROM,MJOB_RECORD_STATUS) 
--                      values (varReference,
--                              GConst.fncXMLExtract(xmlTemp,'TREM_EMAIL_SUBJECT',varTemp) || 
--                              varReference,
--                              numKeyValue,'PKGALERTS.PRCREPORTEMAILALERT',10100003,18300001,10200001);
--
--              varOperation:=' Insert into Parameter Table';      
--                
--               insert into trmaster181A (JPAR_PICK_CODE,JPAR_SERIAL_NUMBER,
--                            JPAR_PARAMETER_NAME,JPAR_PARAMETER_VALUE,
--                           JPAR_PARAMETER_ORDER,JPAR_RECORD_STATUS,JPAR_CREATE_DATE)
--                     values (numKeyValue,1,'ALERTREFERENCE',
--                     varReference,1,10200001,sysdate);
--          if (numAction = GConst.DELETESAVE) then
--          
--             varOperation:=' Extract Pick code from Master for ' || varReference;
--               select pick_key_value 
--                  into numcode1
--                from trmaster001
--                where pick_short_description =varReference
--                 and pick_record_Status not in (10200005,10200006);
--                 
--             varOperation:='Update Record status to Delete in Pick Code' || numcode1;
--
--                update trmaster001 set pick_Record_Status =10200006 
--                where pick_key_value =numcode1;
--                
--              varOperation:='Update Record status to Delete in Job Master' || numcode1;
--              
--                update trmaster181 set MJOB_RECORD_STATUS=10200006
--                  where MJOB_PICK_CODE=numcode1;
--                  
--              varOperation:='Update Record status to Delete in Job Parameters' || numcode1;   
--              
--                 update trmaster181A set JPAR_RECORD_STATUS=10200006
--                  where JPAR_PICK_CODE=numcode1; 
--          end if;
--
--             
--            
--        end if;
-- end if;
--if EditType = SYSEMAILCONFIGURATIONPROCESS then
-- 
--        varOperation := 'Email Configuration Details, Getting ReferenceNumber';
--        varTemp := '//ROW[@NUM="1"]/TREM_REFERENCE_NUMBER';
--        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
--        numSerial:= GConst.fncXMLExtract(xmlTemp,'TREM_SERIAL_NUMBER',numSerial);
--        
--     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
--        varXPath := '//EditedItems/DROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--        
--        varOperation := 'Users Entering Into Main loop ' || varXPath;
--        
--         update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
--                    where TRED_REFERENCE_NUMBER=varReference;
--                    
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath;
--          varoperation :='Extracting Data from XML' || varTemp;
--              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
--               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
--               varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnDisplayName',varTemp4, Gconst.TYPENODEPATH);
--               numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);
--               begin
--               varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Condition',varTemp3, Gconst.TYPENODEPATH);
--                exception 
--                when others  then 
--                varTemp3 := null;
--              end;
----              select nvl(max(TRED_SERIAL_NUMBER),0)+1
----            into numSerial
----              from TRSYSTEM967A
----              where TRED_REFERENCE_NUMBER=varReference;
----                    AND TERD_XML_FIELD=varTemp1;
--           varoperation :='Extracting Data from XML' || varTemp;
--         
----          update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
----                    where TRED_REFERENCE_NUMBER=varReference
----                     AND TERD_XML_FIELD=varTemp1;
--                    
--            insert into TRSYSTEM967A (TERD_XML_FIELD,TRED_RECORD_STATUS,TRED_SERIAL_NUMBER,TRED_REFERENCE_NUMBER,
--            TRED_SYNONYM_NAME,TRED_CONDITION,TERD_LABEL_NAME,TRED_ORDER_BY)          
--            values (varTemp1,10200001,numSerial,varReference,varTemp2,varTemp3,varTemp4,numCode1);
--             End Loop;
--            
--        varXPath := '//DocRefItems/DROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--        
--         update TRSYSTEM967B set TREA_RECORD_STATUS=10200005
--            where TREA_REFERENCE_NUMBER=varReference;
--            
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath;
--          varoperation :='Extracting Data from XML' || varTemp;
--              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
--               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
--                numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);
----              select nvl(max(TRED_SERIAL_NUMBER),0)+1
----            into numSerial
----              from TRSYSTEM967A
----              where TRED_REFERENCE_NUMBER=varReference;
----                    AND TERD_XML_FIELD=varTemp1;
--           varoperation :='Extracting Data from XML' || varTemp;
--         
----          update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
----                    where TRED_REFERENCE_NUMBER=varReference
----                     AND TERD_XML_FIELD=varTemp1;
--                    
--            insert into TRSYSTEM967B (TREA_REFERENCE_NUMBER,TREA_SERIAL_NUMBER,TREA_ATTACHEMENT_COLUMN,TREA_SYNONYM_NAME,
--            TREA_ORDER_BY,TREA_RECORD_STATUS)          
--            values (varReference,numSerial,varTemp1,varTemp2,numCode1,10200001);
--             End Loop; 
--             
--         end if;
-- 
--         if (numAction = GConst.CONFIRMSAVE) then
--          update TRSYSTEM967A set TRED_RECORD_STATUS=10200003
--                    where TRED_REFERENCE_NUMBER=varReference;
--        update TRSYSTEM967B set TREA_RECORD_STATUS=10200003
--                    where TREA_REFERENCE_NUMBER=varReference;
--          end if;
--         
--           if numAction = GConst.DELETESAVE then
--                      update TRSYSTEM967A set TRED_RECORD_STATUS=10200006
--                    where TRED_REFERENCE_NUMBER=varReference;
--                    
--                    update TRSYSTEM967B set TREA_RECORD_STATUS=10200006
--                    where TREA_REFERENCE_NUMBER=varReference;
--           end if;
-- 
--   Glog.log_Write(' Check whether the Email configuration is for the Event Type Scheduler if yes then insert into Alert Creation');
--        varTemp := '//ROW[@NUM="1"]/TREM_EMAIL_TRIGGER_EVENT';
--        numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode,Gconst.TYPENODEPATH);
--        
--        if numCode= 35700004 then ---schedules 
--        
--            varOperation:=' Extracting PickCodes values';
--              select nvl(max(pick_key_value),18100100)+1, 
--                     nvl(max(Pick_key_number),100)+1
--               into numKeyValue, numKeyNumber
--               from trmaster001
--               where pick_key_group=181
--                and pick_key_number>100;
--               
--             varOperation:=' Insert into Pick table';  
--          
--                insert into trmaster001 (PICK_KEY_GROUP,PICK_KEY_NUMBER, PICK_KEY_VALUE,PICK_LONG_DESCRIPTION,
--                                         PICK_SHORT_DESCRIPTION, PICK_KEY_TYPE
--                                         , PICK_COMPANY_CODE, PICK_LOCATION_CODE,
--                                         PICK_ADD_DATE, PICK_CREATE_DATE, PICK_RECORD_STATUS)
--                        values (181,numKeyNumber,numKeyValue,
--                          GConst.fncXMLExtract(xmlTemp,'TREM_EMAIL_SUBJECT',varTemp) || 
--                          varReference,
--                          varReference,10100003,
--                          30199999,30299999,sysdate,sysdate,10200001);
--                          
--              varOperation:=' Insert into Job Master Table';      
--              
--               insert into trmaster181 (MJOB_SHORT_DESCRIPTION, MJOB_LONG_DESCRIPTION, 
--                               MJOB_PICK_CODE, MJOB_PROGRAM_TORUN,
--                               MJOB_JOB_TYPE, MJOB_JOB_RUNFROM,MJOB_RECORD_STATUS) 
--                      values (varReference,
--                              GConst.fncXMLExtract(xmlTemp,'TREM_EMAIL_SUBJECT',varTemp) || 
--                              varReference,
--                              numKeyValue,'PKGALERTS.PRCREPORTEMAILALERT',10100003,18300001,10200001);
--
--              varOperation:=' Insert into Parameter Table';      
--                
--               insert into trmaster181A (JPAR_PICK_CODE,JPAR_SERIAL_NUMBER,
--                            JPAR_PARAMETER_NAME,JPAR_PARAMETER_VALUE,
--                           JPAR_PARAMETER_ORDER,JPAR_RECORD_STATUS,JPAR_CREATE_DATE)
--                     values (numKeyValue,1,'ALERTREFERENCE',
--                     varReference,1,10200001,sysdate);
--          if (numAction = GConst.DELETESAVE) then
--          
--             varOperation:=' Extract Pick code from Master for ' || varReference;
--               select pick_key_value 
--                  into numcode1
--                from trmaster001
--                where pick_short_description =varReference
--                 and pick_record_Status not in (10200005,10200006);
--                 
--             varOperation:='Update Record status to Delete in Pick Code' || numcode1;
--
--                update trmaster001 set pick_Record_Status =10200006 
--                where pick_key_value =numcode1;
--                
--              varOperation:='Update Record status to Delete in Job Master' || numcode1;
--              
--                update trmaster181 set MJOB_RECORD_STATUS=10200006
--                  where MJOB_PICK_CODE=numcode1;
--                  
--              varOperation:='Update Record status to Delete in Job Parameters' || numcode1;   
--              
--                 update trmaster181A set JPAR_RECORD_STATUS=10200006
--                  where JPAR_PICK_CODE=numcode1; 
--          end if;
--
--             
--            
--        end if;
-- end if;

if EditType = SYSEMAILCONFIGURATIONPROCESS then

        varOperation := 'Email Configuration Details, Getting ReferenceNumber';
        varTemp := '//ROW[@NUM="1"]/TREM_REFERENCE_NUMBER';
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
        numSerial:= GConst.fncXMLExtract(xmlTemp,'TREM_SERIAL_NUMBER',numSerial);

     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//EditedItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

        varOperation := 'Users Entering Into Main loop ' || varXPath;

         update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
                    where TRED_REFERENCE_NUMBER=varReference;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
               varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnDisplayName',varTemp4, Gconst.TYPENODEPATH);
               numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);
               begin
               varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Condition',varTemp3, Gconst.TYPENODEPATH);
                exception 
                when others  then 
                varTemp3 := null;
              end;
--              select nvl(max(TRED_SERIAL_NUMBER),0)+1
--            into numSerial
--              from TRSYSTEM967A
--              where TRED_REFERENCE_NUMBER=varReference;
--                    AND TERD_XML_FIELD=varTemp1;
           varoperation :='Extracting Data from XML' || varTemp;

--          update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
--                    where TRED_REFERENCE_NUMBER=varReference
--                     AND TERD_XML_FIELD=varTemp1;

            insert into TRSYSTEM967A (TERD_XML_FIELD,TRED_RECORD_STATUS,TRED_SERIAL_NUMBER,TRED_REFERENCE_NUMBER,
            TRED_SYNONYM_NAME,TRED_CONDITION,TERD_LABEL_NAME,TRED_ORDER_BY)          
            values (varTemp1,10200001,numSerial,varReference,varTemp2,varTemp3,varTemp4,numCode1);
             End Loop;

            update TRSYSTEM967A a set TRED_ORDER_BY = (select RowNo from 
                                                       (select rownum RowNo, TRED_REFERENCE_NUMBER,TERD_XML_FIELD
                                                        from TRSYSTEM967A sub 
                                                        where TRED_REFERENCE_NUMBER=varReference
                                                          and TRED_RECORD_STATUS=10200001
                                                          order by TRED_ORDER_BY) sub1
                                                          where a.TRED_REFERENCE_NUMBER=sub1.TRED_REFERENCE_NUMBER
                                                          and a.TERD_XML_FIELD= sub1.TERD_XML_FIELD)
              where  TRED_REFERENCE_NUMBER=varReference
                and TRED_RECORD_STATUS=10200001;

        varXPath := '//DocRefItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

         update TRSYSTEM967B set TREA_RECORD_STATUS=10200005
            where TREA_REFERENCE_NUMBER=varReference;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
                numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);
--              select nvl(max(TRED_SERIAL_NUMBER),0)+1
--            into numSerial
--              from TRSYSTEM967A
--              where TRED_REFERENCE_NUMBER=varReference;
--                    AND TERD_XML_FIELD=varTemp1;
           varoperation :='Extracting Data from XML' || varTemp;

--          update TRSYSTEM967A set TRED_RECORD_STATUS=10200005
--                    where TRED_REFERENCE_NUMBER=varReference
--                     AND TERD_XML_FIELD=varTemp1;

            insert into TRSYSTEM967B (TREA_REFERENCE_NUMBER,TREA_SERIAL_NUMBER,TREA_ATTACHEMENT_COLUMN,TREA_SYNONYM_NAME,
            TREA_ORDER_BY,TREA_RECORD_STATUS)          
            values (varReference,numSerial,varTemp1,varTemp2,numCode1,10200001);
             End Loop; 

         end if;

         if (numAction = GConst.CONFIRMSAVE) then
          update TRSYSTEM967A set TRED_RECORD_STATUS=10200003
                    where TRED_REFERENCE_NUMBER=varReference;
        update TRSYSTEM967B set TREA_RECORD_STATUS=10200003
                    where TREA_REFERENCE_NUMBER=varReference;
          end if;

           if numAction = GConst.DELETESAVE then
                      update TRSYSTEM967A set TRED_RECORD_STATUS=10200006
                    where TRED_REFERENCE_NUMBER=varReference;

                    update TRSYSTEM967B set TREA_RECORD_STATUS=10200006
                    where TREA_REFERENCE_NUMBER=varReference;
           end if;

   Glog.log_Write(' Check whether the Email configuration is for the Event Type Scheduler if yes then insert into Alert Creation');
        varTemp := '//ROW[@NUM="1"]/TREM_EMAIL_TRIGGER_EVENT';
        numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode,Gconst.TYPENODEPATH);

        if numCode= 35700004 then ---schedules 

            varOperation:=' Extracting PickCodes values';
              select nvl(max(pick_key_value),18100100)+1, 
                     nvl(max(Pick_key_number),100)+1
               into numKeyValue, numKeyNumber
               from trmaster001
               where pick_key_group=181
                and pick_key_number>100;

             varOperation:=' Insert into Pick table';  

                insert into trmaster001 (PICK_KEY_GROUP,PICK_KEY_NUMBER, PICK_KEY_VALUE,PICK_LONG_DESCRIPTION,
                                         PICK_SHORT_DESCRIPTION, PICK_KEY_TYPE
                                         , PICK_COMPANY_CODE, PICK_LOCATION_CODE,
                                         PICK_ADD_DATE, PICK_CREATE_DATE, PICK_RECORD_STATUS)
                        values (181,numKeyNumber,numKeyValue,
                          GConst.fncXMLExtract(xmlTemp,'TREM_EMAIL_SUBJECT',varTemp) || 
                          varReference,
                          varReference,10100003,
                          30199999,30299999,sysdate,sysdate,10200001);

              varOperation:=' Insert into Job Master Table';      

               insert into trmaster181 (MJOB_SHORT_DESCRIPTION, MJOB_LONG_DESCRIPTION, 
                               MJOB_PICK_CODE, MJOB_PROGRAM_TORUN,
                               MJOB_JOB_TYPE, MJOB_JOB_RUNFROM,MJOB_RECORD_STATUS) 
                      values (varReference,
                              GConst.fncXMLExtract(xmlTemp,'TREM_EMAIL_SUBJECT',varTemp) || 
                              varReference,
                              numKeyValue,'PKGALERTS.PRCREPORTEMAILALERT',10100003,18300001,10200001);

              varOperation:=' Insert into Parameter Table';      

               insert into trmaster181A (JPAR_PICK_CODE,JPAR_SERIAL_NUMBER,
                            JPAR_PARAMETER_NAME,JPAR_PARAMETER_VALUE,
                           JPAR_PARAMETER_ORDER,JPAR_RECORD_STATUS,JPAR_CREATE_DATE)
                     values (numKeyValue,1,'ALERTREFERENCE',
                     varReference,1,10200001,sysdate);
          if (numAction = GConst.DELETESAVE) then

             varOperation:=' Extract Pick code from Master for ' || varReference;
               select pick_key_value 
                  into numcode1
                from trmaster001
                where pick_short_description =varReference
                 and pick_record_Status not in (10200005,10200006);

             varOperation:='Update Record status to Delete in Pick Code' || numcode1;

                update trmaster001 set pick_Record_Status =10200006 
                where pick_key_value =numcode1;

              varOperation:='Update Record status to Delete in Job Master' || numcode1;

                update trmaster181 set MJOB_RECORD_STATUS=10200006
                  where MJOB_PICK_CODE=numcode1;

              varOperation:='Update Record status to Delete in Job Parameters' || numcode1;   

                 update trmaster181A set JPAR_RECORD_STATUS=10200006
                  where JPAR_PICK_CODE=numcode1; 
          end if;



        end if;
 end if;

if EditType = SYSTRANBULKCONFIGPROCESS then

        varOperation := 'Bulk Conf Configuration Details, Getting ReferenceNumber';
        varTemp := '//ROW[@NUM="1"]/MTRX_REFERENCE_NUMBER';
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
        numSerial:= GConst.fncXMLExtract(xmlTemp,'MTRX_SERIAL_NUMBER',numSerial);

     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//EditedItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

        varOperation := 'Users Entering Into Main loop ' || varXPath;

         update TRSYSTEM963A set MTXC_RECORD_STATUS=10200005
                    where MTXC_REFERENCE_NUMBER=varReference;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
               varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnDisplayName',varTemp4, Gconst.TYPENODEPATH);
               numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);
               numCode := GConst.fncXMLExtract(xmlTemp,varTemp || 'PrimaryKey',numCode, Gconst.TYPENODEPATH);
               begin
               varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Condition',varTemp3, Gconst.TYPENODEPATH);
                exception 
                when others  then 
                varTemp3 := null;
              end;

           varoperation :='Extracting Data from XML' || varTemp; 

            insert into TRSYSTEM963A (MTXC_XML_FIELD,MTXC_RECORD_STATUS,MTXC_SERIAL_NUMBER,MTXC_REFERENCE_NUMBER,
            MTXC_SYNONYM_NAME,MTXC_CONDITION,MTXC_LABEL_NAME,MTXC_ORDER_BY,MTXC_PRIMARY_KEY)          
            values (varTemp1,10200001,numSerial,varReference,varTemp2,varTemp3,varTemp4,numCode1,numCode);
             End Loop;

            update TRSYSTEM963A a set MTXC_ORDER_BY = (select RowNo from 
                                                       (select rownum RowNo, MTXC_REFERENCE_NUMBER,MTXC_XML_FIELD
                                                        from TRSYSTEM963A sub 
                                                        where MTXC_REFERENCE_NUMBER=varReference
                                                          and MTXC_RECORD_STATUS=10200001
                                                          order by MTXC_ORDER_BY) sub1
                                                          where a.MTXC_REFERENCE_NUMBER=sub1.MTXC_REFERENCE_NUMBER
                                                          and a.MTXC_XML_FIELD= sub1.MTXC_XML_FIELD)
              where  MTXC_REFERENCE_NUMBER=varReference
                and MTXC_RECORD_STATUS=10200001;

        varXPath := '//DocRefItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

         end if;

         if (numAction = GConst.CONFIRMSAVE) then
          update TRSYSTEM963A set MTXC_RECORD_STATUS=10200003
                    where MTXC_REFERENCE_NUMBER=varReference;

          end if;

           if numAction = GConst.DELETESAVE then
                      update TRSYSTEM963A set MTXC_RECORD_STATUS=10200006
                    where MTXC_REFERENCE_NUMBER=varReference;

           end if;

   Glog.log_Write(' Check whether the Email configuration is for the Event Type Scheduler if yes then insert into Alert Creation');
       -- varTemp := '//ROW[@NUM="1"]/TREM_EMAIL_TRIGGER_EVENT';
       -- numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode,Gconst.TYPENODEPATH);


 end if;


   if EditType = SYSEMAILTEMPLATESPROCESS then

    varOperation := 'Email Templates Details, Getting ReferenceNumber';
    GLOG.log_write(varOperation); 
    varTemp := '//ROW[@NUM="1"]/TEMP_TEMPLATE_REFERENCE';
    varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
    numSerial:= GConst.fncXMLExtract(xmlTemp,'TEMP_SERIAL_NUMBER',numSerial);

      GLOG.log_write(numSerial); 
 if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
    varXPath := '//EditedItems/DROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);

    varOperation := 'Users Entering Into Main loop ' || varXPath;

     update TRSYSTEM965A set TEMD_RECORD_STATUS=10200005
                where TEMD_TEMPLATE_REFERENCE=varReference;

--        numSerial:=0;    
--        GLOG.log_write('lOOP START'); 
    for numSub in 0..xmlDom.getLength(nlsTemp) -1
    Loop
      nodTemp := xmlDom.Item(nlsTemp, numSub);
      nmpTemp:= xmlDom.getAttributes(nodTemp);
      nodTemp := xmlDom.Item(nmpTemp, 0);
      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
      varTemp := varXPath;
      varoperation :='Extracting Data from XML' || varTemp;
          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
          varoperation :='Extracting Data from XML' || varTemp;
           varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
           varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
           varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnDisplayName',varTemp4, Gconst.TYPENODEPATH);
           numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);

           -- GLOG.log_write(varTemp1);
--           begin
--           varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Condition',varTemp3, Gconst.TYPENODEPATH);
--            exception 
--            when others  then 
--            varTemp3 := null;
--          end;
--              select nvl(max(TEMD_SERIAL_NUMBER),0)+1
--            into numSerial
--              from TRSYSTEM965A
--              where TEMD_TEMPLATE_REFERENCE=varReference;
--                    AND TERD_XML_FIELD=varTemp1;
       varoperation :='Extracting Data from XML' || varTemp;

--          update TRSYSTEM965A set TEMD_RECORD_STATUS=10200005
--                    where TEMD_TEMPLATE_REFERENCE=varReference
--                     AND TERD_XML_FIELD=varTemp1;
             --   numSerial:=numSerial+1;
             --    GLOG.log_write(to_char(numSerial));
        insert into TRSYSTEM965A (TEMD_XML_FIELD,TEMD_RECORD_STATUS,TEMD_SERIAL_NUMBER,TEMD_TEMPLATE_REFERENCE,
        TEMD_SYNONYM_NAME,TEMD_LABEL_NAME,TEMD_ORDER_BY)          
        values (varTemp1,10200001,numSerial,varReference,varTemp2,varTemp4,numCode1);
       --  GLOG.log_write('rOW INSERTED');

         End Loop;

     update TRSYSTEM965A a set TEMD_ORDER_BY = (select RowNo from (select rownum RowNo, TEMD_TEMPLATE_REFERENCE ReferenceNo,
                                                    sub1.TEMD_XML_FIELD XMLField from
                                                   (select  TEMD_TEMPLATE_REFERENCE,TEMD_XML_FIELD
                                                    from TRSYSTEM965A sub 
                                                    where TEMD_TEMPLATE_REFERENCE=varReference
                                                      and TEMD_RECORD_STATUS=10200001
                                                      order by TEMD_ORDER_BY)sub1)sub
                                                      where a.TEMD_TEMPLATE_REFERENCE=sub.ReferenceNo
                                                      and a.TEMD_XML_FIELD= sub.XMLField)
          where  TEMD_TEMPLATE_REFERENCE=varReference
            and TEMD_RECORD_STATUS=10200001;

--    varXPath := '//DocRefItems/DROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    numSub := xmlDom.getLength(nlsTemp);
--    
--    -- update TRSYSTEM967B set TREA_RECORD_STATUS=10200005
--     --   where TREA_REFERENCE_NUMBER=varReference;
--        
--    for numSub in 0..xmlDom.getLength(nlsTemp) -1
--    Loop
--      nodTemp := xmlDom.Item(nlsTemp, numSub);
--      nmpTemp:= xmlDom.getAttributes(nodTemp);
--      nodTemp := xmlDom.Item(nmpTemp, 0);
--      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--      varTemp := varXPath;
--      varoperation :='Extracting Data from XML' || varTemp;
--          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
--          varoperation :='Extracting Data from XML' || varTemp;
--           varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'XMLField',varTemp1, Gconst.TYPENODEPATH);
--           varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SynonymName',varTemp2, Gconst.TYPENODEPATH);
--            numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SortOrder',numCode1, Gconst.TYPENODEPATH);
----              select nvl(max(TEMD_SERIAL_NUMBER),0)+1
----            into numSerial
----              from TRSYSTEM965A
----              where TEMD_TEMPLATE_REFERENCE=varReference;
----                    AND TERD_XML_FIELD=varTemp1;
--       varoperation :='Extracting Data from XML' || varTemp;
--     
----          update TRSYSTEM965A set TEMD_RECORD_STATUS=10200005
----                    where TEMD_TEMPLATE_REFERENCE=varReference
----                     AND TERD_XML_FIELD=varTemp1;
--                
--      --  insert into TRSYSTEM967B (TREA_REFERENCE_NUMBER,TREA_SERIAL_NUMBER,TREA_ATTACHEMENT_COLUMN,TREA_SYNONYM_NAME,
--       -- TREA_ORDER_BY,TREA_RECORD_STATUS)          
--     --   values (varReference,numSerial,varTemp1,varTemp2,numCode1,10200001);
--         End Loop; 
--         
     end if;

     if (numAction = GConst.CONFIRMSAVE) then
      update TRSYSTEM965A set TEMD_RECORD_STATUS=10200003
                where TEMD_TEMPLATE_REFERENCE=varReference;
   -- update TRSYSTEM967B set TREA_RECORD_STATUS=10200003
   --             where TREA_REFERENCE_NUMBER=varReference;
      end if;

       if numAction = GConst.DELETESAVE then
                  update TRSYSTEM965A set TEMD_RECORD_STATUS=10200006
                where TEMD_TEMPLATE_REFERENCE=varReference;

               -- update TRSYSTEM967B set TREA_RECORD_STATUS=10200006
               -- where TREA_REFERENCE_NUMBER=varReference;
       end if;
end if;

 if EditType = SYSEMAILCREATIONPROCESS then

        varOperation := 'Email Creation Details, Getting ReferenceNumber';
        varTemp := '//ROW[@NUM="1"]/EMIL_PICK_CODE';
        numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode,Gconst.TYPENODEPATH);
     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//KEYCOLUMNDETAILS/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

        varOperation := 'Users Entering Into Main loop ' || varXPath;

         update TRMASTER148A set EMIC_RECORD_STATUS=10200005
                    where EMIC_PICK_CODE=numCode;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ProgUnitColumn',varTemp1, Gconst.TYPENODEPATH);
               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ParentColumn',varTemp2, Gconst.TYPENODEPATH);
            --   varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnDisplayName',varTemp4, Gconst.TYPENODEPATH);
--               begin
--               varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Condition',varTemp3, Gconst.TYPENODEPATH);
--                exception 
--                when others  then 
--                varTemp3 := null;
--              end;
              select nvl(max(EMIC_SERIAL_NUMBER),0)+1
            into numSerial
              from TRMASTER148A
              where EMIC_PICK_CODE=numCode;
           varoperation :='Extracting Data from XML' || varTemp;   

            insert into TRMASTER148A (EMIC_PICK_CODE,EMIC_PROGRAM_COLUMN,EMIC_PARENT_COLUMN,EMIC_SERIAL_NUMBER,EMIC_RECORD_STATUS,
            EMIC_ADD_DATE,EMIC_CREATE_DATE)          
            values (numCode,varTemp1,varTemp2,numSerial,10200001,sysdate,sysdate);
             End Loop;
         end if;

         if (numAction = GConst.CONFIRMSAVE) then
          update TRMASTER148A set EMIC_RECORD_STATUS=10200003
                    where EMIC_PICK_CODE=numCode;
          end if;

           if numAction = GConst.DELETESAVE then
                      update TRMASTER148A set EMIC_RECORD_STATUS=10200006
                    where EMIC_PICK_CODE=numCode;
           end if;

 end if;

if EditType = SYSEXPOSUREROLLOVER then

        varOperation := 'Exposure Rollover Details, Getting ReferenceNumber';
        varTemp := '//ROW[@NUM="1"]/EXPR_REFERENCE_NUMBER';
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
         varTemp1 := '//ROW[@NUM="1"]/EXPR_SERIAL_NUMBER';
         numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);         
         varTemp2 := '//ROW[@NUM="1"]/EXPR_NEW_DUEDATE';
         datTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp2,datTemp2,Gconst.TYPENODEPATH);
         varTemp2 := '//ROW[@NUM="1"]/EXPR_NEW_FXRATE';
         numRate := GConst.fncXMLExtract(xmlTemp,varTemp2,numRate,Gconst.TYPENODEPATH);

         varTemp3 := '//ROW[@NUM="1"]/EXPR_OLD_DUEDATE';
         datTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp3,datTemp3,Gconst.TYPENODEPATH);
         varTemp4 := '//ROW[@NUM="1"]/EXPR_OLD_FXRATE';
         numRate1 := GConst.fncXMLExtract(xmlTemp,varTemp4,numRate1,Gconst.TYPENODEPATH);

     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then

               varoperation :='Extracting Data from XML' || varTemp;

          update TRTRAN002 set TRAD_TRADE_RATE =numRate,TRAD_MATURITY_DATE=datTemp2
                    where TRAD_TRADE_REFERENCE=varReference;
--                     AND TRAD_SERIAL_NUMBER=numSerial;
         end if; 
          if numAction = GConst.DELETESAVE then
                      update TRTRAN002 set TRAD_TRADE_RATE =numRate1,TRAD_MATURITY_DATE=datTemp3
                    where TRAD_TRADE_REFERENCE=varReference;
           end if;
 end if; 

--if EditType=SYSFORWARDDEALINSERT then 
--          varOperation := 'Add records to sub tables';
--          
--          varreference:=GConst.fncXMLExtract(xmlTemp, 'DEAL_DEAL_NUMBER', varreference);     
--          numSerial:=GConst.fncXMLExtract(xmlTemp, 'DEAL_SERIAL_NUMBER', numSerial); 
--
--    if  numAction in(GConst.ADDSAVE, GConst.EDITSAVE) then
--       
--          update trtran001A
--          set QUOT_RECORD_STAUTS=10200006
--          where QUOT_DEAL_NUMBER=varreference;
--          
--           begin 
--            select nvl(count(*),0)+1
--              into numSerial1
--              from trtran001A
--             where QUOT_DEAL_NUMBER=varreference; 
--          exception
--            when no_data_found then 
--              numSerial1:=1;
--          end ;
--          
--          varTemp2 := '//MULTIPLEQUOTES//DROW';       
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
--          --numSerial:=1;
--          if(xmlDom.getLength(nlsTemp)>0) then
--          
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop
--              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/CounterParty';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);
--               Glog.log_write(varTemp);
--              
--              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/SpotRate';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numRate := GConst.fncXMLExtract(xmlTemp, varTemp, numRate, Gconst.TYPENODEPATH);
--              Glog.log_write(varTemp);
--              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/ForwardPremium';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numRate1 := GConst.fncXMLExtract(xmlTemp, varTemp, numRate1, Gconst.TYPENODEPATH);
--              Glog.log_write(varTemp);
--              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/MarginRate';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numRate2 := GConst.fncXMLExtract(xmlTemp, varTemp, numRate2, Gconst.TYPENODEPATH);
--              Glog.log_write(varTemp);
--              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/AllInRate';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numRate3 := GConst.fncXMLExtract(xmlTemp, varTemp, numRate3, Gconst.TYPENODEPATH);
--              Glog.log_write(varTemp);
--              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/UserRemarks';
--              varoperation :='Extracting Data from XML' || varTemp;
--              varTemp5 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp5, Gconst.TYPENODEPATH);
--                         
--              varoperation :='Inserting Data into trtran001a';
--              insert into trtran001a (QUOT_DEAL_NUMBER, QUOT_DEAL_SERIAL, QUOT_SERIAL_NUMBER, 
--              QUOT_COUNTER_PARTY, QUOT_SPOT_RATE, QUOT_FORWARD_PERIMUM, QUOT_MARGIN_RATE, 
--              QUOT_ALLIN_RATE, QUOT_USER_REMARKS, QUOT_RECORD_STAUTS, QUOT_ADD_DATE, QUOT_CREATE_DATE,
--              QUOT_ENTRY_DETAILS)
--              Values(varreference, numSerial, numSerial1, numCode1,numRate,numRate1,numRate2,numRate3,varTemp5,
--              10200001, sysdate, sysdate, null);
--              
--               numSerial1:=numSerial1+1;
--              
--
--          end loop;
--
--      end if;
-- 
--         
--          
--
--  elsif  numAction in(GConst.DELETESAVE) then
--     
--          update trtran001a
--          set QUOT_RECORD_STAUTS=10200006
--          where QUOT_DEAL_NUMBER=varreference;
--          commit;
--
--  elsif  numAction in(GConst.CONFIRMSAVE) then
--     
--          update trtran001a
--          set QUOT_RECORD_STAUTS=10200003
--          where QUOT_DEAL_NUMBER=varreference;
--         
--          commit;       
--               
--  end if;
--end if;   
   if EditType = SYSDUEDATEALERTCONFIGPROCESS then

        varOperation := 'Due Date Alert Configuration Details, Getting ReferenceNumber';
        varTemp := '//ROW[@NUM="1"]/DUEM_SYSTEM_REFERENCE';
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//EditedItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

        varOperation := 'Users Entering Into Main loop ' || varXPath;

         update TRSYSTEM961A set DUED_RECORD_STATUS=10200005
                    where DUEC_SYSTEM_REFERECE=varReference;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'LabelText',varTemp1, Gconst.TYPENODEPATH);
               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OrderBy',varTemp2, Gconst.TYPENODEPATH);
               varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnName',varTemp2, Gconst.TYPENODEPATH);
               begin
               varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Condition',varTemp4, Gconst.TYPENODEPATH);
                exception 
                when others  then 
                varTemp4 := null;
              end;
              select nvl(max(DUED_SERIAL_NUMBER),0)+1
               into numSerial
              from TRSYSTEM961A
              where DUEC_SYSTEM_REFERECE=varReference;

--             update TRSYSTEM961A set DUED_RECORD_STATUS=10200005
--                    where DUEC_SYSTEM_REFERECE=varReference;
--                    AND DUED_XML_FIELD=varTemp1;

            insert into TRSYSTEM961A (DUED_XML_FIELD,DUED_RECORD_STATUS,DUED_SERIAL_NUMBER,DUEC_SYSTEM_REFERECE,DUEC_ORDERBY_SERIAL,DUED_LABEL_NAME,DUED_WHERE_CONDITION)          
            values (varTemp3,10200001,numSerial,varReference,varTemp2,varTemp1,varTemp4);
             End Loop;
         end if;

         if (numAction = GConst.CONFIRMSAVE) then
          update TRSYSTEM961A set DUED_RECORD_STATUS=10200003
                    where DUEC_SYSTEM_REFERECE=varReference;
          end if;

           if numAction = GConst.DELETESAVE then
                      update TRSYSTEM961A set DUED_RECORD_STATUS=10200006
                    where DUEC_SYSTEM_REFERECE=varReference;
           end if;

 end if;

--     if EditType = SYSCOMPLIANCEALERTPROCESS then
-- 
--        varOperation := 'Compliance Alert Configuration Details, Getting ReferenceNumber';
--        varTemp := '//ROW[@NUM="1"]/CMPM_SYSTEM_REFERENCE';
--        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
--        
--     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
--        varXPath := '//EditedItems/DROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--           varOperation := 'Users Entering Into Main loop ' || varXPath;
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath;
--          varoperation :='Extracting Data from XML' || varTemp;
--              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnName',varTemp1, Gconst.TYPENODEPATH);
--              select nvl(max(CMPD_SERIAL_NUMBER),0)+1
--               into numSerial
--              from TRSYSTEM962A
--              where CMPD_SYSTEM_REFERECE=varReference;
--           varoperation :='Extracting Data from XML' || varTemp;
--         
--          update TRSYSTEM962A set CMPD_RECORD_STATUS=10200005
--                    where CMPD_SYSTEM_REFERECE=varReference
--                     AND CMPD_XML_FIELD=varTemp1;
--                    
--            insert into TRSYSTEM962A (CMPD_XML_FIELD,CMPD_RECORD_STATUS,CMPD_SERIAL_NUMBER,CMPD_SYSTEM_REFERECE)          
--            values (varTemp1,10200001,numSerial,varReference);
--             End Loop;
--         end if;
-- 
--         if (numAction = GConst.CONFIRMSAVE) then
--          update TRSYSTEM962A set CMPD_RECORD_STATUS=10200003
--                    where CMPD_SYSTEM_REFERECE=varReference;
--          end if;
--         
--           if numAction = GConst.DELETESAVE then
--                      update TRSYSTEM962A set CMPD_RECORD_STATUS=10200006
--                    where CMPD_SYSTEM_REFERECE=varReference;
--           end if;
-- 
-- end if;

   if EditType = SYSDAILYRATESPROCESS then
 GLOG.log_write('Effective date will come here');  
        varOperation := 'Daily Rates Details, Getting EffectiveDate';
  --      varTemp := '//ROW[@NUM="1"]/DRAT_EFFECTIVE_DATE';
--            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/DRAT_EFFECTIVE_DATE';  
            datTemp2 := GConst.fncXMLExtract(xmlTemp, 'DRAT_EFFECTIVE_DATE', datTemp2);
          --  datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2, Gconst.TYPENODEPATH);  
      --     varTemp3 := '//ROW[@NUM="1"]/DRAT_SERIAL_NUMBER';   
      --    numSerial := GConst.fncXMLExtract(xmlTemp, varTemp3, numSerial, Gconst.TYPENODEPATH);  
          numSerial := GConst.fncXMLExtract(xmlTemp, 'DRAT_SERIAL_NUMBER', numSerial);

     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//EditedItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
      GLOG.log_write('Effective date ');    
        varOperation := 'Users Entering Into Main loop ' || varXPath;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';

              varoperation :='Extracting Data from XML' || varTemp;
             varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ASKRate',varTemp1, Gconst.TYPENODEPATH);
             varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'BIDRate',varTemp2, Gconst.TYPENODEPATH);
             numCode := GConst.fncXMLExtract(xmlTemp,varTemp || 'BaseCurrency',numCode, Gconst.TYPENODEPATH);
             numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OtherCurrency',numCode1, Gconst.TYPENODEPATH);
             datTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ContractMonth',datTemp1, Gconst.TYPENODEPATH);
              numCode2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ForwardMonth',numCode2, Gconst.TYPENODEPATH);
--              select nvl(max(DRAD_SERIAL_NUMBER),0)+1
--               into numSerial
--              from TRTRAN013A
--              where DRAD_EFFECTIVE_DATE=datTemp2;
              GLOG.log_write('Serial Number'); 

           varoperation :='Extracting Data from XML' || varTemp;
            insert into TRTRAN013A (DRAD_ADD_DATE,DRAD_ASK_RATE,DRAD_BID_RATE,DRAD_CONTRACT_MONTH,DRAD_CREATE_DATE,
                                      DRAD_CURRENCY_CODE,DRAD_EFFECTIVE_DATE,DRAD_FOR_CURRENCY,
                                      DRAD_RECORD_STATUS,DRAD_SERIAL_NUMBER,DRAD_FORWARD_MONTHNO)    
            values (sysdate,varTemp1,varTemp2,datTemp1,sysdate,numCode,datTemp2,numCode1,10200001,numSerial,numCode2);

             End Loop;
         end if;

         if (numAction = GConst.CONFIRMSAVE) then
          update TRTRAN013A set DRAD_RECORD_STATUS=10200003
                    where DRAD_EFFECTIVE_DATE=datTemp2
                      AND DRAD_SERIAL_NUMBER =numSerial;
          end if;

           if numAction = GConst.DELETESAVE then
                      update TRTRAN013A set DRAD_RECORD_STATUS=10200006
                    where DRAD_EFFECTIVE_DATE=datTemp2
                    AND DRAD_SERIAL_NUMBER =numSerial;
           end if;

 end if;


  if EditType = SYSREPORTCONFIGURATION then
 GLOG.log_write('Aggregate Function will come here');  
        varOperation := 'Report Configuration Details, Getting Aggregate Function';
--         varTemp3 := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/REPO_PROGRAM_UNIT', varTemp3,Gconst.TYPENODEPATH);
--        varTemp4 := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/REPO_COLUMN_NAME', varTemp4,Gconst.TYPENODEPATH);

     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//EditedItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
      GLOG.log_write('Aggregate Function ');    
        varOperation := 'Users Entering Into Main loop ' || varXPath;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';

              varoperation :='Extracting Data from XML' || varTemp;
             varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'AggregateFunction',varTemp1, Gconst.TYPENODEPATH);
             varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Synonym',varTemp2, Gconst.TYPENODEPATH);
             varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnName',varTemp3, Gconst.TYPENODEPATH);

           varoperation :='Updating data into trsystem999g' || varTemp1;

            UPDATE TRSYSTEM999G  SET REPT_AGGREGATE_FUNCTION=varTemp1
            WHERE REPT_PROGRAM_UNIT=varTemp2
            AND REPT_COLUMN_NAME =varTemp3;

             End Loop;
         end if;

 end if;
--manjunath sir ends
--For FD Closure------

    If Edittype = Sysuserupdate Then
        VARREFERENCE := GCONST.FNCXMLEXTRACT(xmlTemp, 'PSWD_USER_ID', VARREFERENCE);
        Varxpath := '//USERUPDATE/ROW';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
          Vartemp := Varxpath || '[@NUM="' || numTemp || '"]/UserComapnyCode';
          Numcompany := Gconst.Fncxmlextract(Xmltemp, Vartemp, Numcompany, Gconst.Typenodepath);
          DELETE FROM TRSYSTEM022A WHERE USCO_USER_ID=VARREFERENCE AND USCO_COMPANY_CODE=numCompany AND USCO_REPORT_DISPLAYCOM=numCompany;
          INSERT INTO TRSYSTEM022A
            (USCO_COMPANY_CODE,
            USCO_USER_ID,
            USCO_REPORT_DISPLAYCOM)
            values(numCompany,VARREFERENCE,numCompany);
        End Loop;
    END IF;
    If Edittype=SYSCOMPANYUPDATE then
         varOperation := 'Duplicating the entry in Transaction table';
         varTemp := GConst.fncXMLExtract(xmlTemp, 'COMP_COMPANY_CODE', varTemp);

         if numAction =GConst.ADDSAVE then
            update trmaster001 set pick_company_code=30199999 where pick_key_value=varTemp;

            insert into trsystem022A (USCO_COMPANY_CODE,USCO_USER_ID,USCO_REPORT_DISPLAYCOM)
               select varTemp,USER_USER_ID,varTemp 
                from trsystem022 
                where USER_RECORD_STATUS not in (10200005,10200006); 
          end if;
    end if;
--    If Edittype=Gconst.UTILUSERUPDATE then
--         varOperation := 'Duplicating the entry in Transaction table';
--         varTemp1 := GConst.fncXMLExtract(xmlTemp, 'USER_USER_ID', varTemp);
--         varTemp2 := GConst.fncXMLExtract(xmlTemp, 'USER_COMPANY_CODES', varTemp);
--         varTemp3 := GConst.fncXMLExtract(xmlTemp, 'USER_COMPANY_CODE', varTemp);
--    if numAction in (GConst.DELETESAVE) then 
--         UPDATE trsystem022A SET USCO_RECORD_STATUS = 10200006 WHERE  USCO_USER_ID= varTemp1;
--         UPDATE trsystem023 SET PSWD_RECORD_STATUS = 10200006 where PSWD_USER_ID = varTemp1;
--         -- added by manjunath Reddy on 29/08/2020
--         UPDATE trsystem022C SET USPF_RECORD_STATUS = 10200006 where USPF_USER_ID = varTemp1;
--         
--        end if;
--  -- insert into temp values(varTemp2,'lak'); commit;
--         if ((numAction =GConst.ADDSAVE) or (numAction = GConst.EDITSAVE)) then
--         
--         
--            --DELETE FROM  trsystem022A WHERE  USCO_USER_ID= varTemp1;
--            UPDATE trsystem022A SET USCO_RECORD_STATUS = 10200006 WHERE  USCO_USER_ID= varTemp1;
--            
--             varOperation := 'Get the Maximium Serial Number';   
--            begin
--              select nvl(Max(USCO_SERIAL_NUMBER),1)
--                into numCode1
--                from trsystem022A
--               -- where USCO_RECORD_STATUS not in (10200005,10200006)
--                WHERE USCO_USER_ID = varTemp1;
--            exception
--              when others then
--                numCode1:=1;
--            end;
--            
--            varOperation := 'link user to company' || varTemp2; 
--            
--            FOR curcomp IN (SELECT DISTINCT REGEXP_SUBSTR (varTemp2,'[^,]+',1,LEVEL) as company
--                            FROM   DUAL
--                            CONNECT BY REGEXP_SUBSTR (varTemp2,'[^,]+',1,LEVEL) IS NOT NULL
--              order by 1)
--              LOOP
--              BEGIN  
--              numCode1 := numCode1+1;
--                insert into trsystem022A (USCO_COMPANY_CODE,USCO_USER_ID,USCO_REPORT_DISPLAYCOM,USCO_SERIAL_NUMBER,USCO_RECORD_STATUS) 
--                   (select DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE),varTemp1,
----                          DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE),
--                          varTemp3,numCode1, 10200001
--                    from TRMASTER301 
--                    where COMP_COMPANY_CODE = curcomp.company
--                    AND COMP_RECORD_STATUS not in (10200005,10200006));                    
--              END;
--            END LOOP;
--            
----            insert into trsystem022A (USCO_COMPANY_CODE,USCO_USER_ID,USCO_REPORT_DISPLAYCOM)
----               select DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE),varTemp1,
----                      DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE) 
----                from TRMASTER301 
----                where COMP_RECORD_STATUS not in (10200005,10200006); 
--          if (numAction =GConst.ADDSAVE) THEN     
--           varOperation := 'Get the Maximium Password Serial Number';   
--            begin
--              select nvl(Max(PSWD_SERIAL_NUMBER),1) + 1
--                into numCode
--                from trsystem023
--              --  where PSWD_RECORD_STATUS not in (10200005,10200006)
--                WHERE PSWD_USER_ID=varTemp1;
--            exception
--              when others then
--                numCode:=1;
--            end;    
--         varOperation := 'Insert PassCode';      
--         
--         Varxpath := '//Password/DROW';
--         Vartemp := Varxpath || '[@DNUM="1"]/NewPassword';
--           insert into trsystem023(PSWD_COMPANY_CODE,PSWD_USER_ID,PSWD_SERIAL_NUMBER,
--                  PSWD_PASSWORD_KEY,PSWD_PASSWORD_CODE,PSWD_PASSWORD_HINT,
--                  PSWD_PASSWORD_STATUS,PSWD_CREATE_DATE,PSWD_ADD_Date,
--                  PSWD_RECORD_STATUS)
--            values( 30199999, varTemp1, numCode,
--                   Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath),
--                   Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath),
--                   null,14500002,sysdate,sysdate,10200003);
--         
--             varOperation := 'Pushing the One row in Add load';      
--             -- becuase we are not providing add load to user preferences
--             -- added by Manjunath Reddy 
--             begin
--              select nvl(uspf_serial_number,1)
--                  into numCode
--                from 
--                trsystem022C 
--               where uspf_user_id=varTemp1;
--             exception 
--               when no_data_found then 
--                 numcode:=1;
--              end;
--      
--              insert into trsystem022C
--                 (USPF_USER_ID, USPF_DASHBOARD_PROGRAMUNIT, USPF_ADD_DATE,
--                   USPF_CREATE_DATE, USPF_ENTRY_DETAIL, 
--                   USPF_RECORD_STATUS,USPF_SERIAL_NUMBER)
--              select varTemp1, GRUP_DASHBOARD,sysdate,
--                 sysdate,null,10200001,numcode+1
--               from usermaster inner join TRMASTER142
--                on user_group_code=GRUP_PICK_CODE
--                where GRUP_record_status not in (10200005,10200006)
--                and user_user_id=varTemp1;
--                 
--                varOperation := 'Update License Key to User Table';      
--                 
--                 select PRMC_LICENSE_REFERENCE 
--                   into VarTemp6
--                 from trsystem051;
--                 
--                varOperation := 'Update License Key to User Table';   
--        
--                 Update Usermaster set USER_LICENSE_REFERENCE = VarTemp6
--                   where User_User_Id=varTemp1;
--           
--           END IF; 
----          varOperation := 'Generating E-Mail ID for the new user';
----          
----          varTemp2 := '<TABLE BORDER=1 BGCOLOR="#EEEEEE">';
----          varTemp2:=varTemp2||'<TR BGCOLOR="Gray">';
----          varTemp2:=varTemp2||'<TH><FONT COLOR="WHITE">Header</FONT></TH>';
----          varTemp2:=varTemp2||'<TH><FONT COLOR="WHITE">Values</FONT></TH>';
----          varTemp2:=varTemp2||'</TR>';
----          varTemp2:= varTemp2 || '<TR BGCOLOR="yellow"<td>User Name</td><td>' ||  GConst.fncXMLExtract(xmlTemp, 'USER_USER_NAME', varTemp) || '</td></tr>';
----          varTemp2:= varTemp2 || '<TR BGCOLOR="yellow"<td>Password</td><td>' ||  
----              Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath) || '</td></tr>';
----          varTemp2:= varTemp2 || '</table>';
----          
----          varOperation := 'Sending Email';  
----          
----          pkgsendingmail.send_mail_secure(GConst.fncXMLExtract(xmlTemp, 'USER_EMAIL_ID', varTemp),'',
----                           '',
----                           'Password for First Time Login into TMS',
----                           'Hi',
----                           varTemp2);
--
--          END IF;
--    end if;

    If Edittype=Gconst.UTILUSERUPDATE then
         varOperation := 'Duplicating the entry in Transaction table';
         varTemp1 := GConst.fncXMLExtract(xmlTemp, 'USER_USER_ID', varTemp);
         varTemp2 := GConst.fncXMLExtract(xmlTemp, 'USER_COMPANY_CODES', varTemp);
         varTemp3 := GConst.fncXMLExtract(xmlTemp, 'USER_COMPANY_CODE', varTemp);
         varTemp4 := GConst.fncXMLExtract(xmlTemp, 'USER_ENTITY_CODES', varTemp);
    if numAction in (GConst.DELETESAVE) then 
         UPDATE trsystem022A SET USCO_RECORD_STATUS = 10200006 WHERE  USCO_USER_ID= varTemp1;
         UPDATE trsystem022D SET USLO_RECORD_STATUS = 10200006 WHERE  USLO_USER_ID= varTemp1;
         UPDATE trsystem023 SET PSWD_RECORD_STATUS = 10200006 where PSWD_USER_ID = varTemp1;
         -- added by manjunath Reddy on 29/08/2020
         UPDATE trsystem022C SET USPF_RECORD_STATUS = 10200006 where USPF_USER_ID = varTemp1;

        end if;
  -- insert into temp values(varTemp2,'lak'); commit;
         if ((numAction =GConst.ADDSAVE) or (numAction = GConst.EDITSAVE)) then


            --DELETE FROM  trsystem022A WHERE  USCO_USER_ID= varTemp1;
            UPDATE trsystem022A SET USCO_RECORD_STATUS = 10200006 WHERE  USCO_USER_ID= varTemp1;
            UPDATE trsystem022D SET USLO_RECORD_STATUS = 10200006 WHERE  USLO_USER_ID= varTemp1;

             varOperation := 'Get the Maximium Serial Number';   
            begin
              select nvl(Max(USCO_SERIAL_NUMBER),1)
                into numCode1
                from trsystem022A
               -- where USCO_RECORD_STATUS not in (10200005,10200006)
                WHERE USCO_USER_ID = varTemp1;
            exception
              when others then
                numCode1:=1;
            end;

            begin
              select nvl(Max(USLO_SERIAL_NUMBER),1)
                into numCode2
                from trsystem022D
               -- where USCO_RECORD_STATUS not in (10200005,10200006)
                WHERE USLO_USER_ID = varTemp1;
            exception
              when others then
                numCode2:=1;
            end;
            varOperation := 'link user to company' || varTemp2; 

            FOR curcomp IN (SELECT DISTINCT REGEXP_SUBSTR (varTemp2,'[^,]+',1,LEVEL) as company
                            FROM   DUAL
                            CONNECT BY REGEXP_SUBSTR (varTemp2,'[^,]+',1,LEVEL) IS NOT NULL
              order by 1)
              LOOP
              BEGIN  
              numCode1 := numCode1+1;
                insert into trsystem022A (USCO_COMPANY_CODE,USCO_USER_ID,USCO_REPORT_DISPLAYCOM,USCO_SERIAL_NUMBER,USCO_RECORD_STATUS) 
                   (select DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE),varTemp1,
--                          DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE),
                          varTemp3,numCode1, 10200001
                    from TRMASTER301 
                    where COMP_COMPANY_CODE = curcomp.company
                    AND COMP_RECORD_STATUS not in (10200005,10200006));                    
              END;
            END LOOP;

             varOperation := 'link user to Entities' || varTemp4; 

            FOR curLoc IN (SELECT DISTINCT REGEXP_SUBSTR (varTemp4,'[^,]+',1,LEVEL) as Entity
                            FROM   DUAL
                            CONNECT BY REGEXP_SUBSTR (varTemp4,'[^,]+',1,LEVEL) IS NOT NULL
              order by 1)
              LOOP
              BEGIN  
              numCode2 := numCode2+1;
                insert into trsystem022D (USLO_ENTITY,USLO_USER_ID,USLO_DEFAULT_ENTITY,USLO_SERIAL_NUMBER,USLO_RECORD_STATUS) 
                   (select LOCN_PICK_CODE,varTemp1,
                          curLoc.Entity,numCode2, 10200001
                    from TRMASTER302 
                    where LOCN_PICK_CODE = curLoc.Entity
                    AND LOCN_RECORD_STATUS not in (10200005,10200006));                    
              END;
            END LOOP;

--            insert into trsystem022A (USCO_COMPANY_CODE,USCO_USER_ID,USCO_REPORT_DISPLAYCOM)
--               select DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE),varTemp1,
--                      DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE) 
--                from TRMASTER301 
--                where COMP_RECORD_STATUS not in (10200005,10200006); 
          if (numAction =GConst.ADDSAVE) THEN     
           varOperation := 'Get the Maximium Password Serial Number';   
            begin
              select nvl(Max(PSWD_SERIAL_NUMBER),1) + 1
                into numCode
                from trsystem023
              --  where PSWD_RECORD_STATUS not in (10200005,10200006)
                WHERE PSWD_USER_ID=varTemp1;
            exception
              when others then
                numCode:=1;
            end;    
         varOperation := 'Insert PassCode';      

         Varxpath := '//Password/DROW';
         Vartemp := Varxpath || '[@DNUM="1"]/NewPassword';
           insert into trsystem023(PSWD_COMPANY_CODE,PSWD_USER_ID,PSWD_SERIAL_NUMBER,
                  PSWD_PASSWORD_KEY,PSWD_PASSWORD_CODE,PSWD_PASSWORD_HINT,
                  PSWD_PASSWORD_STATUS,PSWD_CREATE_DATE,PSWD_ADD_Date,
                  PSWD_RECORD_STATUS)
            values( 30199999, varTemp1, numCode,
                   Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath),
                   Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath),
                   null,14500002,sysdate,sysdate,10200003);

             varOperation := 'Pushing the One row in Add load';      
             -- becuase we are not providing add load to user preferences
             -- added by Manjunath Reddy 

             begin
                 select nvl(max(uspf_serial_number),0) + 1
                 into numCode
                 from trsystem022C 
                 where upper(uspf_user_id)=upper(varTemp1);
             exception 
               when no_data_found then 
                 numcode:=1;
              end;
              GLOG.log_write('Extracting SerialNumber '|| numCode);  
             GLOG.log_write('Pushing the One row in Add load ' ||varTemp1);  
              UPDATE trsystem022C SET USPF_RECORD_STATUS = 10200006 where USPF_USER_ID = varTemp1;

              insert into trsystem022C
                 (USPF_USER_ID, USPF_DASHBOARD_PROGRAMUNIT, USPF_ADD_DATE,
                   USPF_CREATE_DATE, USPF_ENTRY_DETAIL, 
                   USPF_RECORD_STATUS,USPF_SERIAL_NUMBER)
              select varTemp1, GRUP_DASHBOARD,sysdate,
                 sysdate,null,
                 10200001,numCode
               from usermaster inner join TRMASTER142
                on user_group_code=GRUP_PICK_CODE
                where GRUP_record_status not in (10200005,10200006)
                and upper(user_user_id)=upper(varTemp1)
                and user_record_status not in (10200005,10200006);

                 GLOG.log_write('Inserted into trsystem022C');  

                varOperation := 'Update License Key to User Table';      

                 select PRMC_LICENSE_REFERENCE 
                   into VarTemp6
                 from trsystem051;

                varOperation := 'Update License Key to User Table';   

                 Update Usermaster set USER_LICENSE_REFERENCE = VarTemp6
                   where User_User_Id=varTemp1;

           END IF; 
--          varOperation := 'Generating E-Mail ID for the new user';
--          
--          varTemp2 := '<TABLE BORDER=1 BGCOLOR="#EEEEEE">';
--          varTemp2:=varTemp2||'<TR BGCOLOR="Gray">';
--          varTemp2:=varTemp2||'<TH><FONT COLOR="WHITE">Header</FONT></TH>';
--          varTemp2:=varTemp2||'<TH><FONT COLOR="WHITE">Values</FONT></TH>';
--          varTemp2:=varTemp2||'</TR>';
--          varTemp2:= varTemp2 || '<TR BGCOLOR="yellow"<td>User Name</td><td>' ||  GConst.fncXMLExtract(xmlTemp, 'USER_USER_NAME', varTemp) || '</td></tr>';
--          varTemp2:= varTemp2 || '<TR BGCOLOR="yellow"<td>Password</td><td>' ||  
--              Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath) || '</td></tr>';
--          varTemp2:= varTemp2 || '</table>';
--          
--          varOperation := 'Sending Email';  
--          
--          pkgsendingmail.send_mail_secure(GConst.fncXMLExtract(xmlTemp, 'USER_EMAIL_ID', varTemp),'',
--                           '',
--                           'Password for First Time Login into TMS',
--                           'Hi',
--                           varTemp2);

          END IF;
    end if;

----added by Supriya on 14/12/2020----------------
if EditType = SYSFORWARDOPTIONLINK then
    varOperation := 'Extracting Fields For Forward Option Linking';
    varReference := GConst.fncXMLExtract(xmlTemp, 'LINK_LINKING_REFERENCE', varReference);

    if numAction = GConst.DELETESAVE then
        varOperation := 'Delete Previous Entry For ForwardOptionGridData ' || varReference;
        UPDATE TRTRAN112A
        SET LINK_RECORD_STATUS = 10200006
        WHERE LINK_LINKING_REFERENCE = varReference;
    elsif numAction = GConst.CONFIRMSAVE then
        varOperation := 'Confirm Entry For ForwardOptionGridData ' || varReference;
        UPDATE TRTRAN112A
        SET LINK_RECORD_STATUS = 10200003
        WHERE LINK_LINKING_REFERENCE = varReference;
    else
        varXPath := '//ForwardOptionGridData/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        varOperation := 'ADD Entry For ForwardOptionGridData ' || varReference;
        for numTemp in 1..xmlDom.getLength(nlsTemp)
        Loop
            varoperation :='Extracting Data from XML';

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/LinkingReference';
            varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH); 

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/BookingDeal';
            varTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp1, Gconst.TYPENODEPATH);

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/CancelDeal';
            varTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp2, Gconst.TYPENODEPATH);

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/DealSerial';
            numcode := GConst.fncXMLExtract(xmlTemp, varTemp, numcode, Gconst.TYPENODEPATH);

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ReverseSerial';
            numcode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numcode1, Gconst.TYPENODEPATH);

            varTemp := varXPath || '[@DNUM="' || numTemp || '"]/LinkAmount';
            numFCY := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY, Gconst.TYPENODEPATH);

            varOperation := 'Inserting into TRTRAN122A';       
            insert into TRTRAN112A(LINK_LINKING_REFERENCE,LINK_SERIAL_NUMBER,LINK_BOOKING_DEAL,LINK_CANCEL_DEAL,
                                   LINK_DEAL_SERIAL,LINK_REVERSE_SERIAL,LINK_AMOUNT,LINK_RECORD_STATUS)
            values(varReference,1,varTemp1,varTemp2,numcode,numcode1,numFCY,10200001); 
        end loop;
    END IF;  
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);       
--    varOperation := 'Before Loop';
--    varXPath := '//ForwardOptionGridData/DROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    
--    if xmlDom.getLength(nlsTemp) > 0 then
--        varXPath := '//ForwardOptionGridData/DROW[@DNUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--            varOperation := 'Inside Loop';
--            GLOG.log_write(varOperation); 
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodtemp1 := xmldom.item(nmptemp, 0);
--            
--            numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--            varTemp := varXPath || numTemp || '"]/LinkingReference';
--            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--            
--            varTemp := varXPath || numTemp || '"]/BookingDeal';
--            varTemp1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--            GLOG.log_write('BookingDeal ' || varTemp1); 
--            
--            varTemp := varXPath || numTemp || '"]/CancelDeal';
--            varTemp2 := GConst.fncGetNodeValue(nodFinal, varTemp);  
--            
--            varTemp := varXPath || numTemp || '"]/DealSerial';
--            numcode := GConst.fncGetNodeValue(nodFinal, varTemp);  
--            
--            varTemp := varXPath || numTemp || '"]/ReverseSerial';
--            numcode1 := GConst.fncGetNodeValue(nodFinal, varTemp); 
--            
--            varTemp := varXPath || numTemp || '"]/LinkAmount';
--            numFCY := GConst.fncGetNodeValue(nodFinal, varTemp); 
--            
--            if numAction = GConst.ADDSAVE  then 
--            GLOG.log_write('ADDSAVE BookingDeal' || varTemp1); 
--            varOperation := 'Inserting into TRTRAN122A';       
--                insert into TRTRAN112A(LINK_LINKING_REFERENCE,LINK_SERIAL_NUMBER,LINK_BOOKING_DEAL,LINK_CANCEL_DEAL,
--                                       LINK_DEAL_SERIAL,LINK_REVERSE_SERIAL,LINK_AMOUNT,LINK_RECORD_STATUS)
--                values(varReference,1,varTemp1,varTemp2,numcode,numcode1,numFCY,10200001); 
--            elsif numAction = GConst.DELETESAVE  then 
--            varOperation := 'Deleting from TRTRAN122A'; 
--            GLOG.log_write('DELETESAVE BookingDeal' || varTemp1); 
--                UPDATE TRTRAN112A SET
--                LINK_RECORD_STATUS = 10200006
--                WHERE LINK_LINKING_REFERENCE = varReference AND LINK_SERIAL_NUMBER = numSerial;
--            end if;
--        End loop;
--    end if;          
End if;

    if EditType = SYSFUTUREMTMUPLOAD then

      varOperation := 'Extractng Parametersfor Futures MTM Rates';
      datTemp := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/CFMM_EFFECTIVE_DATE', datTemp,Gconst.TYPENODEPATH);
      numCode := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/CFMM_EXCHANGE_CODE', numCode,Gconst.TYPENODEPATH);

      varOperation := 'Inserting MTM Rates for Futures, Exchange ' || numCode;
      insert into trtran062
      (cfmr_company_code,cfmr_deal_number,cfmr_serial_number,cfmr_mtm_date,
      cfmr_mtm_rate,cfmr_profit_loss,cfmr_margin_amount,cfmr_create_date,
      cfmr_entry_detail,cfmr_record_status,cfmr_mtm_user,cfmr_pl_voucher,
      cfmr_mtm_amount,cfmr_margin_excess)
      select cfut_company_code, cfut_deal_number,
        (select NVL(max(cfmm_serial_number),0) + 1
          from trtran062
          where cfmr_deal_number = cfut_deal_number), datTemp,
        cfmm_closing_rate,pkgForexProcess.fnccalfuturepandl(cfut_buy_sell,
          cfut_lot_numbers,cfut_Exchange_rate,cfmm_closing_rate) * 1000, 0,
          sysdate, NULL, 10200001, cfut_user_id, NULL,
          Round(cfut_base_amount * cfmm_closing_rate), 0
        from trtran061, trtran064
        where cfut_exchange_code = cfmm_exchange_code
        and cfut_base_currency = cfmm_base_currency
        and cfut_maturity_date = cfmm_expiry_month
        and cfut_exchange_code = numCode
        and cfmm_effective_date = datTemp
        and cfut_process_complete = 12400002
        and cfmm_record_status in (10200001,10200002,10200004);

      update trtran064
        set cfmm_record_status = 10200003
        where cfmm_exchange_code = numCode
        and cfmm_effective_date = datTemp;
    End if;


--Ishwarachandra ---
    if EditType = SYSCANCELDEAL then
      varReference := GConst.fncXMLExtract(xmlTemp, 'CDEL_DEAL_NUMBER', varTemp);
      numSerial := GConst.fncXMLExtract(xmlTemp, 'CDEL_DEAL_SERIAL', numFCY2);
      varOperation := 'Updating Cancelled Deals';

      if numAction = GConst.ADDSAVE then
      nlsTemp    := xslProcessor.selectNodes(nodFinal,'//DealUnLink/ROWD[@NUM]');
      varXPath   := '//DealUnLink/ROWD[@NUM="';
        FOR numSub IN 0..xmlDom.getLength(nlsTemp) -1
        LOOP
          nodTemp       := xmlDom.item(nlsTemp, numSub);
          nmpTemp       := xmlDom.getAttributes(nodTemp);
          nodTemp1      := xmlDom.item(nmpTemp, 0);
          numTemp       := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp       := varXPath || numTemp || '"]/DealSerial';
          numCode1      := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp       := varXPath || numTemp || '"]/TradeReference';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp       := varXPath || numTemp || '"]/LinkDealNumber';
          varReference  := GConst.fncGetNodeValue(nodFinal, varTemp);

          varTemp       := varXPath || numTemp || '"]/HedgedAmount';
          numFCY        := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

          varTemp       := varXPath || numTemp || '"]/CompanyCode';
          numCompany    := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

--          varTemp       := varXPath || numTemp || '"]/LinkDate';
--          datTemp       := GConst.fncGetNodeValue(nodFinal, varTemp);
          SELECT deal_exchange_rate
          INTO numRate1
          FROM trtran001
          WHERE deal_deal_number = varReference;

          IF numFCY <= 0 THEN
            UPDATE trtran004
            SET hedg_record_status     = GConst.STATUSDELETED
            WHERE hedg_trade_reference = varReference1
            AND hedg_deal_number       = varReference
            AND hedg_deal_serial       = numCode1;
          ELSE
            UPDATE trtran004
            SET hedg_record_status     = GConst.STATUSDELETED
            WHERE hedg_trade_reference = varReference1
            AND hedg_deal_number       = varReference
            AND hedg_deal_serial       = numCode1;

            INSERT
            INTO trtran004
              ( hedg_company_code,    hedg_trade_reference,    hedg_deal_number,    hedg_deal_serial,    hedg_hedged_fcy,
                hedg_other_fcy,    hedg_hedged_inr,    hedg_create_date,    hedg_entry_detail,    hedg_record_status,
                hedg_hedging_with,    hedg_multiple_currency,    hedg_linked_date,  hedg_location_code  )
              VALUES
              (
                numCompany,    varReference1,    varReference, numCode1+1,    numFCY,
                0,numFCY * numRate1,    sysdate,    NULL,    10200001,
                32200001,    12400002,    datWorkDate, 30299999 );

          END IF;
        END LOOP;      

          numError := fncCompleteUtilization(varReference, GConst.UTILHEDGEDEAL,
                        datWorkDate);
--        update trtran001
--          set deal_record_status = GConst.STATUSPOSTCANCEL,
--          deal_process_complete = GConst.OPTIONYES,
--          deal_complete_date = datWorkDate
--          where deal_deal_number = varReference
--          and deal_serial_number = numSerial;
      elsif numAction = GConst.EDITSAVE then
        numError := fncCompleteUtilization(varReference, GConst.UTILHEDGEDEAL,
                           datWorkDate);
      elsif numAction = GConst.DELETESAVE then
--        update trtran001
--          set deal_record_status = GConst.STATUSENTRY,
--          deal_process_complete = GConst.OPTIONNO,
--          deal_complete_date = NULL
--          where deal_deal_number = varReference
--          and deal_serial_number = numSerial;
        numError := fncCompleteUtilization(varReference, GConst.UTILHEDGEDEAL,
                           datWorkDate);

      End if;

    End if;

    if EditType = SYSLOANCONNECT then
      numCompany := GConst.fncXMLExtract(xmlTemp, 'FCLN_COMPANY_CODE', numCompany);
      varReference := GConst.fncXMLExtract(xmlTemp, 'FCLN_LOAN_NUMBER', varTemp);
      numRate := GConst.fncXMLExtract(xmlTemp, 'FCLN_CONVERSION_RATE', varTemp);

      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
        nlsTemp := xslProcessor.selectNodes(nodFinal,'//EXIMPDETAIL/ReturnFields/ROWD[@NUM]');
        varXPath := '//EXIMPDETAIL/ReturnFields/ROWD[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/MerchantFcy';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/ReverseNow';
          numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantRate';
--          numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantInr';
--          numInr := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          numInr := Round(numFcy * numRate);
          -- updated by ramya on 19-apr-10to update record status in fcy loan edit mode
          if numStatus = GConst.LOTMODIFIED then
            varOperation := 'Deleting record of Loan Connect';
            update trtran010                                    -- Updated From Cygnet
              --set trln_record_status = GConst.STATUSDELETED
                set loln_record_status = GConst.STATUSUPDATED
              Where Loln_Company_Code = Numcompany
              and loln_loan_number = varReference;              -- End Updated Cygnet
              numStatus := GConst.LOTNEW;
          end if;
          if numStatus = GConst.LOTNEW then
            varOperation := 'Inserting record to Loan Connect';
            insert into trtran010(loln_company_code, loln_loan_number,                     -- Updated From cygnet
              loln_serial_number, loln_trade_reference, loln_adjusted_date,
              Loln_Adjusted_Fcy, Loln_Adjusted_Rate, Loln_Adjusted_Inr,
              loln_create_date, loln_entry_detail, loln_record_status)                     -- End Updated Cygnet
              values(numCompany, varReference, (select nvl(max(trln_serial_number),0)+1
                                                  from trtran007
                                                 where trln_trade_reference = varReference1
                                                   and trln_loan_number = varReference), varReference1,
              datWorkDate, numFCY1, numRate, numInr,
              sysdate, null, GConst.STATUSENTRY);
                 --RAMYA UPDATES on  23-ape-10 for fcy loan linking
                varOperation := 'Inserting Into Order Reveral Table TRTRAN003 Reverse the Orders';
--Updated From Cygnet
--                varOperation := 'Inserting Into Order Reveral Table TRTRAN003 Reverse the Orders';
--                  insert into trtran003(brel_company_code,brel_trade_reference,
--                              brel_reverse_serial,brel_entry_date,brel_reference_date,
--                              brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,
--                              brel_reversal_inr,brel_period_code,brel_trade_period,
--                              brel_create_date,brel_record_status)
--                              values(numCompany,varReference1,(select nvl(max(brel_reverse_serial),0)+1
--                 from trtran003
--                 where brel_trade_reference=varReference1),datworkdate,datworkdate,
--              Gconst.TRADEPAYMENTS,numFCY1, numRate, numInr,0,0,datworkdate,Gconst.STATUSENTRY);

--            numError := fncCompleteUtilization(varReference1, GConst.UTILEXPORTS,
--                          datWorkDate);
---End Updated Cygnet
-- Since amounts are adjusted in full, there is no need for edit cluase here
          elsif numStatus = GConst.LOTDELETED then
            varOperation := 'Deleting record of Loan Connect';
            update trtran010                                        -- Updated From Cygnet
              set loln_record_status = GConst.STATUSDELETED
              where loln_company_code = numCompany
              And Loln_Loan_Number = Varreference
              and loln_trade_reference = varReference1;            -- End Update
          End if;

        End Loop;

      elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        select decode(numAction,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
          into numCode
          from dual;
   -- Updated From  Cygnet
        update trtran010
          set loln_record_status = numCode
          where loln_company_code = numCompany
          And Loln_Loan_Number = Varreference;
   --End
      End if;

    End if;

        -- Order - Invoice linking -----------------------------------------------------
        -- Order - Invoice linking -----------------------------------------------------
   if EditType = SYSUPDATEORDINVLINK then
      begin
          delete from temp;

          varOperation := 'Updating Reverse Reference Numbers';
          varXPath := '//ORDINVLINKING/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;

          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_COMPANY_CODE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_TRADE_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference1 := GConst.fncXMLExtract(xmlTemp, varTemp, varReference1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_USER_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp1, Gconst.TYPENODEPATH);

              if numAction = GConst.ADDSAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = varReference1
                  where TRAD_COMPANY_CODE = varReference
                    and TRAD_TRADE_REFERENCE =varTemp1;
              elsif numAction = GConst.DELETESAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = null
                  where TRAD_COMPANY_CODE = varReference1
                    and TRAD_TRADE_REFERENCE = varTemp1;
              end if;
          end loop;
      end;
   end if;

 if EditType = SYSDELETEFUTUREDATA then
      begin
          delete from temp;

          VAROPERATION := 'Deleting Future Reference Numbers';
        --  varXPath := '//FUTURESDATA/ROW';
           varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
          begin
          varReference := GConst.fncXMLExtract(xmlTemp, 'KeyValues/RefStaNumber', varReference);
        --  nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        --  varOperation := 'Deleting Future Reference Numbers ' || varXPath;
       exception
       WHEN OTHERS THEN
        VARREFERENCE:='';
        end ;
          if numAction = GConst.DELETESAVE then

--             update trtran103
--                set intc_record_status =10200006
--                where intc_refsta_number = varReference;     
--              
           UPDATE TRTRAN102 SET INTC_RECORD_STATUS = 10200006
              WHERE INTC_REFSTA_NUMBER=varReference;             

            UPDATE  TRTRAN061 SET CFUT_RECORD_STATUS = 10200006  
                WHERE CFUT_DEAL_NUMBER IN (SELECT INTC_DEAL_NUMBER FROM TRTRAN102 WHERE 
                INTC_REFSTA_NUMBER=VARREFERENCE AND INTC_DEAL_NUMBER IS NOT NULL
                AND INTC_CLASSIFICATION_CODE=64000001);

             UPDATE  TRTRAN063 SET CFRV_RECORD_STATUS = 10200006  
                WHERE CFRV_DEAL_NUMBER IN (SELECT INTC_DEAL_NUMBER FROM TRTRAN102 WHERE 
                INTC_REFSTA_NUMBER=VARREFERENCE AND INTC_DEAL_NUMBER IS NOT NULL
                AND INTC_CLASSIFICATION_CODE=64000002);
          end if;


      END;
   end if;


  ---kumar.h 12/05/09  updates for buyers credit--------
    if EditType = SYSBCRCONNECT then
      numCompany := GConst.fncXMLExtract(xmlTemp, 'BCRD_COMPANY_CODE', numCompany);
      varReference := GConst.fncXMLExtract(xmlTemp, 'BCRD_BUYERS_CREDIT', varTemp);
      numRate := GConst.fncXMLExtract(xmlTemp, 'BCRD_CONVERSION_RATE', varTemp);


      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
        nlsTemp := xslProcessor.selectNodes(nodFinal,'//EXIMPDETAIL/ReturnFields/ROWD[@NUM]');
        varXPath := '//EXIMPDETAIL/ReturnFields/ROWD[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/ReverseNow';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantRate';
--          numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantInr';
--          numInr := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          numInr := Round(numFcy * numRate);

          if numStatus = GConst.LOTNEW then
            varOperation := 'Inserting record to Loan Connect';
--Updated From cygnet
            insert into trtran010(loln_company_code, loln_loan_number,
              loln_serial_number, loln_trade_reference, loln_adjusted_date,
              loln_adjusted_fcy, loln_adjusted_rate, loln_adjusted_inr,
              loln_create_date, loln_entry_detail, loln_record_status)
              values(numCompany, varReference, 1, varReference1,
              datWorkDate, numFcy, numRate, numInr,
              sysdate, null, GConst.STATUSENTRY);
--End Updated
            insert into trtran007(trln_company_code, trln_loan_number,
              trln_serial_number, trln_trade_reference, trln_adjusted_date,
              trln_adjusted_fcy, trln_adjusted_rate, trln_adjusted_inr,
              trln_create_date, trln_entry_detail, trln_record_status)
              values(numCompany, varReference, 1, varReference1,
              datWorkDate, numFcy, numRate, numInr,
              sysdate, null, GConst.STATUSENTRY);

             Varoperation := 'Inserting Into Order Reveral Table TRTRAN003 Reverse the Orders';
--Updated From cygnet
             select nvl(max(BREL_REVERSE_SERIAL),0) into numcode3 from trtran003 where BREL_TRADE_REFERENCE = varReference1;
             Numcode3 := Numcode3 + 1;
--End Updated
             insert into trtran003 (brel_company_code,brel_trade_reference,
              brel_reverse_serial,brel_entry_date,brel_reference_date,
              brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,
              brel_reversal_inr,brel_period_code,brel_trade_period,
              Brel_Create_Date,Brel_Record_Status)
              values( numCompany,varReference1,numcode3,datworkdate,datworkdate,                    -- Updated From Cygnet
              Gconst.Tradepayments,Numfcy, Numrate, Numinr,0,0,Datworkdate,Gconst.Statusentry);
                             varOperation := 'Inserting Into DEAL linking Table TRTRAN004';
              ---Cheking for Lc linked with deal-----------
  --Updated From cygnet
--              Select Count(Hedg_Trade_Reference) Into Numsub1 From Trtran004 Where Hedg_Trade_Reference = Varreference1
--                  and hedg_record_status not in (10200012,10200006,10200005) group by HEDG_TRADE_REFERENCE;
--              if numSub1 > 0 then
--                insert into trtran004 (HEDG_COMPANY_CODE,HEDG_TRADE_REFERENCE,
--                  HEDG_DEAL_NUMBER,HEDG_DEAL_SERIAL,
--                  HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,
--                  HEDG_CREATE_DATE,HEDG_ENTRY_DETAIL,HEDG_RECORD_STATUS,
--                  HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY)
--                  (select HEDG_COMPANY_CODE,varReference,
--                  HEDG_DEAL_NUMBER,HEDG_DEAL_SERIAL,
--                  HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,
--                  HEDG_CREATE_DATE,HEDG_ENTRY_DETAIL,HEDG_RECORD_STATUS,
--                  HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY
--                from trtran004 where HEDG_TRADE_REFERENCE = varReference1 and hedg_record_status not in (10200012,10200006,10200005));
--                ---Existing Link Closing---
--                update trtran004 set HEDG_RECORD_STATUS = 10200012 where HEDG_TRADE_REFERENCE = varReference1;
--              End If;
  --End Updated
            numfcy1 := pkgforexprocess.fncGetOutstanding(varReference1,0,GConst.UTILEXPORTS,
                   GConst.AMOUNTFCY, datworkdate);
--Updated From cygnet
            numfcy1 := pkgforexprocess.fncGetOutstanding(varReference1,0,GConst.UTILEXPORTS,
                   GConst.AMOUNTFCY, datworkdate);
             if numfcy1 = 0 then
              update trtran002 set trad_process_complete= Gconst.OptionYES,
                trad_complete_date= datworkdate
                where trad_trade_reference=varReference1;
                --and numfcy1 <=numFcy;
            End If;
--End Updated
-- Since amounts are adjusted in full, there is no need for edit clause here

-- Since amounts are adjusted in full, there is no need for edit cluase here
          elsif numStatus = GConst.LOTDELETED then
            varOperation := 'Deleting record of Loan Connect';
            update trtran007
              set trln_record_status = GConst.STATUSDELETED
              where trln_company_code = numCompany
              and trln_loan_number = varReference
              and trln_trade_reference = varReference1;
             varOperation := 'Deleting record of Reverseing Of Export Order';

             delete from trtran003 where  brel_trade_reference=varReference1;

             update trtran002 set trad_process_complete= Gconst.OptionNo,
               trad_complete_date= null
               where trad_trade_reference=varReference1;
          End if;

        End Loop;

      elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        select decode(numAction,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
          into numCode
          from dual;

        update trtran007
          set trln_record_status = numCode
          where trln_company_code = numCompany
          and trln_loan_number = varReference;
      End if;
      ---adding hedge details to hedgeregister
      if numAction in (GConst.ADDSAVE,GConst.EDITSAVE) then
        varOperation := 'Inserting Hedge Details';
         nlsTemp := xslProcessor.selectNodes(nodFinal,'//HEDGEDETAIL/ReturnFields/ROWD[@NUM]');
         varXPath := '//HEDGEDETAIL/ReturnFields/ROWD[@NUM="';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          numSub := xmlDom.getLength(nlsTemp);
         if numSub > 0 and  numAction  in (GConst.EDITSAVE) then
  --      if  numAction  in (GConst.EDITSAVE) then
            delete
            from trtran004
            where hedg_company_code=numCompany
             and  hedg_trade_reference=varReference;
         end if;
              for numSub in 0..xmlDom.getLength(nlsTemp) -1
              Loop
                nodTemp := xmlDom.item(nlsTemp, numSub);
                nmpTemp := xmlDom.getAttributes(nodTemp);
                nodTemp1 := xmlDom.item(nmpTemp, 0);
                numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
                varTemp := varXPath || numTemp || '"]/RecordStatus';
                numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/DealNumber';
                varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
                varTemp := varXPath || numTemp || '"]/HedgingAmount';
                numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/ExchangeRate';
                numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                numInr := Round(numFcy * numRate);
                 insert into trtran004(hedg_company_code, hedg_trade_reference,
                    hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
                    hedg_other_fcy, hedg_hedged_inr,
                    hedg_create_date, hedg_entry_detail, hedg_record_status)
                    values(numCompany, varReference,
                    varReference1,1, numFcy,
                    numInr, 0,
                    sysdate, null, GConst.STATUSENTRY);
             End loop;
       elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        if numAction in (GConst.DELETESAVE)then
           delete
           from trtran004
           where hedg_company_code=numCompany
           and  hedg_trade_reference=varReference;
        else
          update trtran004
            set hedg_record_status = gconst.STATUSAUTHORIZED
            where hedg_company_code = numCompany
            and hedg_trade_reference = varReference;
      End if;
    End if;
  End if;
  ---kumar.h 12/05/09  updates for buyers credit--------

   ---kumar.h 12/05/09  updates for purchase order--------
    if EditType = SYSPURCONNECT then
      numCompany := GConst.fncXMLExtract(xmlTemp, 'TRAD_COMPANY_CODE', numCompany);
      varReference := GConst.fncXMLExtract(xmlTemp, 'TRAD_REVERSE_REFERENCE', varTemp);
    --  numRate := GConst.fncXMLExtract(xmlTemp, 'BCRD_CONVERSION_RATE', varTemp);

      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
        varOperation := 'Adding record for Bill Realization';
        insert into  ImportRealize(brel_company_code, brel_trade_reference,
            brel_reverse_serial,brel_entry_date,
            brel_user_reference, brel_reference_date,
            brel_reversal_type,brel_reversal_fcy, brel_reversal_rate,
            brel_reversal_inr, brel_period_code, brel_trade_period,
            brel_maturity_from, brel_maturity_date,brel_local_bank,
            brel_create_date, brel_entry_detail, brel_record_status)
            values(numCompany,varReference, 1,
            GConst.fncXMLExtract(xmlTemp, 'TRAD_ENTRY_DATE', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_USER_REFERENCE', varTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_REFERENCE_DATE', datTemp),
            25800008,
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_FCY', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_RATE', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_INR', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_PERIOD_CODE', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_PERIOD', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_MATURITY_FROM', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_MATURITY_DATE', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_LOCAL_BANK', numFCY),
            sysdate, null, GConst.STATUSENTRY);

         update trtran002
          set trad_process_complete =  GConst.OPTIONYES, trad_complete_date=datWorkDate
          where trad_company_code = numCompany
          and trad_trade_reference = varReference;

      End if;

    End if;
  ---kumar.h 12/05/09  updates for purchase order--------




 -- commented by Manjunath Reddy on 01-Jul-2021
--    if EditType = SYSEXPORTADJUST then
--      numCode := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numCode);
--      varReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTemp);
--      numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--
--      numFcy := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFcy);
--      numRate := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);
--
--      if numCode in (Gconst.BILLREALIZE,Gconst.BILLIMPORTREL,
--        GConst.BILLEXPORTCANCEL, GConst.BILLIMPORTCANCEL, GConst.BILLLOANCLOSURE) then
--
--        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
----  The second parameter is just to indicate the utilization should be
----  checked between trtran002 and trtran003 and does not represent
----  the actual reversal type - 23/05/08 - TMM
--
----            if numRate <> 0 then -- Cash Deal entry
----                PrcCashDealEntry(datWorkDate  ,varReference ,numRate  ,numFcy ,datWorkDate);
----            end if ;
--
----            numError := fncLoanDeal(RecordDetail, varReference);
----            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
----                          datWorkDate);
--          numError := fncBillSettlement(RecordDetail);
--        elsif numAction = GConst.DELETESAVE then
--           --              update trtran002
----                set trad_record_status = GConst.STATUSAUTHORIZED
----                where trad_trade_reference = varReference;
----                
-----Ishwara chandra update as on 27/03/2015 for deletion of reversal transactios
--
--      if numCode in (GConst.BILLLOANCLOSURE) then
--      
--                  numError := fncCompleteUtilization(varReference, GConst.UTILBCRLOAN,
--                          datWorkDate);
--                -- himatsingkatf_prod.pkgTreasury.prcBillSettlement(RecordDetail,0);                          
--      
--      else
--      
--      
--
--            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
--                          datWorkDate);
--    end if;                          
----                UPDATE trtran002
----                SET Trad_Process_Complete  = GConst.OPTIONNO,
----                  Trad_Complete_Date       = NULL
----                WHERE trad_trade_reference = varReference;
--        BEGIN
--          FOR cur_in IN
--          (SELECT cdel_deal_number,
--            deal_deal_type
--          FROM trtran006,
--            trtran001
--          WHERE cdel_trade_reference = varReference
--          AND cdel_deal_number       = deal_deal_number
--          AND CDEL_TRADE_SERIAL      = numSerial
--          )
--          LOOP
--            UPDATE trtran006
--            SET cdel_record_status     = GConst.STATUSDELETED
--            WHERE cdel_trade_reference = varReference
--            AND Cdel_Deal_Number       = cur_in.cdel_deal_number--varReference1
--            AND CDEL_TRADE_SERIAL      = numSerial;
--            numError                  := fncCompleteUtilization(cur_in.cdel_deal_number, GConst.UTILHEDGEDEAL, datWorkDate);
--            IF cur_in.deal_deal_type   = 25400001 THEN ----For Cash deal
--              UPDATE trtran001
--              SET deal_record_status = GConst.STATUSDELETED
--              WHERE deal_deal_number = cur_in.cdel_deal_number;--varReference1;
--              UPDATE trtran004
--              SET hedg_record_status     = GConst.STATUSDELETED
--              WHERE hedg_trade_reference = varReference
--              AND hedg_deal_number       = cur_in.cdel_deal_number;--varReference1;
--            ELSE
----              UPDATE trtran001
----              SET deal_process_complete = 12400002,
----                  deal_complete_date = ''
----              WHERE deal_deal_number = cur_in.cdel_deal_number;
--              UPDATE trtran004
--              SET hedg_record_status     = GConst.STATUSDELETED
--              WHERE hedg_trade_reference = varReference
--              AND hedg_deal_number       = cur_in.cdel_deal_number
--              and HEDG_TRADE_SERIAL = numSerial;--varReference1;
--            END IF;
--          END LOOP;
--        end; 
--              
--       end if;           
--        
--      End if;
--
--
----      if numCode in (Gconst.LOANBCCLOSER) then
----        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
----            numError := fncLoanDeal(RecordDetail, varReference);
----            numError := fncCompleteUtilization(varReference, GConst.UTILBCRLOAN,
----                          datWorkDate);
----        elsif numAction = GConst.DELETESAVE then
----             update BuyersCredit
----               set bcrd_process_complete=Gconst.OptionNo,
----               bcrd_completion_date=null
----               where bcrd_buyers_credit= varReference;
----        end if;
----      end if;
--      -- changed by Reddy on 18-05-2009
--      if numCode in (Gconst.BILLCOLLECTION,GConst.BILLPURCHASE,GConst.BILLOVERDUE,
--            GConst.BILLIMPORTCOL,Gconst.BILLEXPORTORDER,Gconst.BILLIMPORTORDER, Gconst.BILLPURCHASEORDER,gconst.BILLAMENDMENT) then
--
--          select decode(numCode,
--              GConst.BILLCOLLECTION, GConst.TRADECOLLECTION,
--              GConst.BILLPURCHASE, GConst.TRADEPURCHASED,
--              GConst.BILLOVERDUE,  GConst.TRADEOVERDUE,
--              GConst.BILLIMPORTCOL, GConst.TRADEIMPORTBILL,
--              Gconst.BILLEXPORTORDER,Gconst.TRADERECEIVABLE,
--              Gconst.BILLIMPORTORDER ,Gconst.TRADEPAYMENTS,
--              Gconst.BILLPURCHASEORDER, Gconst.TRADEPORDER,
--              gconst.BILLAMENDMENT ,gconst.BILLAMENDMENT,
--              numCode)
--              into numCode3
--              from Dual;
--
--        if numAction = GConst.ADDSAVE then
--
----          varOperation := 'Selecting particulars of Trade Reference';
------          select trad_company_code, trad_buyer_seller, trad_trade_currency,
------            trad_product_code, trad_product_description, trad_trade_fcy,
------            trad_import_export
------            into numCompany, numCode, numCode1, numCode2,
------            varTemp, numFcy, numCode4
------            from TradeRegister
------            where trad_trade_reference = varReference;
----
----          varOperation := 'Getting Serial Number';
----          Varreference1 := Pkgreturncursor.Fncgetdescription(Numcode3, Gconst.Pickupshort);
----          varReference1 := varReference1 || '/' || fncGenerateSerial(GCOnst.SERIALTRADE,numCompany); -- Updated From  Cygnet
----
----          varOperation := 'Adding record for Bill Realization';
----          insert into TradeRegister(trad_company_code, trad_trade_reference,
----            trad_reverse_reference, trad_reverse_serial, trad_import_export,
----            trad_entry_date, trad_user_reference, trad_reference_date,
----            trad_buyer_seller, trad_trade_currency, trad_product_code,
----            trad_product_description, trad_trade_fcy, trad_trade_rate,
----            trad_forward_rate,trad_margin_rate,trad_final_rate,
----            trad_spot_rate,
----            trad_trade_inr, trad_period_code, trad_trade_period,
----            trad_maturity_from, trad_maturity_date, trad_local_bank,
----            trad_subproduct_code,trad_product_category,
----            trad_create_date, trad_entry_detail, trad_record_status, trad_process_complete)
----
----            select trad_company_code, varReference1, trad_trade_reference, numSerial, numCode3,
----                GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
----                GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
----                GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
----                trad_buyer_seller, trad_trade_currency, trad_product_code, trad_product_description,
----                GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
----                trad_trade_rate,trad_forward_rate,trad_margin_rate,trad_final_rate,
----                trad_spot_rate, numFCY* trad_trade_rate,
----                GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
----                GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
----                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
----                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
----                GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
----                trad_subproduct_code,trad_product_category,
----                sysdate, null, GConst.STATUSENTRY, GConst.OPTIONNO
----             from trtran002
----             where trad_trade_reference = varReference
----             and trad_record_status not in (10200005,10200006);
----
----
------            values(numCompany, varReference1, varReference, numSerial, numCode3,
------            GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
------            numCode, numCode1, numCode2, varTemp,
------            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numFCY),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
------            GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
------            sysdate, null, GConst.STATUSENTRY, GConst.OPTIONNO);
----
----            --;
------                   select trad_company_code, trad_buyer_seller, trad_trade_currency,
------            trad_product_code, trad_product_description, trad_trade_fcy,
------            trad_import_export
------            into numCompany, numCode, numCode1, numCode2,
------            varTemp, numFcy, numCode4
------            from TradeRegister
------            where trad_trade_reference = varReference;
----
----
----            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
----                          datWorkDate);
----            numError := fncLoanDeal(RecordDetail, varReference1);
----------Added from Almus Source
--          varOperation := 'Selecting particulars of Trade Reference';
--          select trad_company_code, trad_buyer_seller, trad_trade_currency, 
--            TRAD_PRODUCT_CODE, TRAD_PRODUCT_DESCRIPTION, TRAD_TRADE_FCY,
--            trad_import_export,TRAD_REVERSE_SERIAL,trad_trade_reference
--            Into Numcompany, Numcode, Numcode1, Numcode2, 
--            varTemp, numFcy, numCode4,numSub,varRelease
--            FROM TRADEREGISTER
--            where trad_trade_reference = varReference;
--          
--            Varoperation := 'Getting Serial Number';
--            Varreference1 := Pkgreturncursor.Fncgetdescription(Numcode3, Gconst.Pickupshort);
--            Varreference1 := Varreference1 || '/' ||fncGenerateSerial(Serialtrade,Numcompany);  
--            -- Updated From  Cygnet
--
--          If Numcode3 In(Gconst.Billamendment) Then 
--          -- 
--            --VARREFERENCE1 := varRelease;
--            Numcode3 := Numcode4;
--            
--            Numsub := Numsub + 1;
--            
--            Varrelease    := Pkgreturncursor.Fncgetdescription(Numcompany, Gconst.Pickupshort) ;
--            Varreference1 := Pkgreturncursor.Fncgetdescription(Numcode3, Gconst.Pickupshort) ;
--            Varreference1 := Varreference1 || '/' ||Varrelease|| '/' ||fncGenerateSerial(Serialtrade,Numcompany);
----            DELETE FROM TEMP;
----            Insert Into Temp Values(Varreference1,'chandra');
----            INSERT INTO TEMP VALUES(varRelease,'chandra2');
--            varOperation := 'Amendment details Inserting';
--            insert into TradeRegister(trad_company_code, trad_trade_reference,
--            trad_reverse_reference, trad_reverse_serial, trad_import_export, 
--            trad_entry_date, trad_user_reference, trad_reference_date, 
--            trad_buyer_seller, trad_trade_currency, trad_product_code, 
--            trad_product_description, trad_trade_fcy, trad_trade_rate, 
--            trad_trade_inr, trad_period_code, trad_trade_period,
--            trad_maturity_from, trad_maturity_date, trad_local_bank,
--            Trad_Create_Date, Trad_Entry_Detail, Trad_Record_Status, Trad_Process_Complete,
--            trad_spot_rate,
--            trad_forward_rate,trad_margin_rate)
--            Values(Numcompany, Varreference1, varReference, Numsub, Numcode3,
--            GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
--            GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
--            GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
--            numCode, numCode1, numCode2, varTemp,
--            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
--            GConst.fncXMLExtract(xmlTemp, 'TradeRate', numRate),
--            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
--            GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
--            GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
--            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
--            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
--            Gconst.Fncxmlextract(Xmltemp, 'BREL_LOCAL_BANK', Numfcy),
--            Sysdate, Null, Gconst.Statusentry, Gconst.Optionno,
--            GConst.fncXMLExtract(xmlTemp, 'SpotRate', numRate),
--            GConst.fncXMLExtract(xmlTemp, 'ForwardRate', numRate),
--            GConst.fncXMLExtract(xmlTemp, 'MarginRate', numRate)
--            );
--            
--            Update Trtran003 Set Brel_Reverse_Reference = (Select Fncchecktheoder(Brel_Trade_Reference) From Dual) 
--                    where BREL_TRADE_REFERENCE = varReference;
--            
--          ELSE
--            varOperation := 'Adding record for Bill Realization';
--            insert into TradeRegister(trad_company_code, trad_trade_reference,
--              trad_reverse_reference, trad_reverse_serial, trad_import_export, 
--              trad_entry_date, trad_user_reference, trad_reference_date, 
--              trad_buyer_seller, trad_trade_currency, trad_product_code, 
--              trad_product_description, trad_trade_fcy, trad_trade_rate, 
--              trad_trade_inr, trad_period_code, trad_trade_period,
--              trad_maturity_from, trad_maturity_date, trad_local_bank,
--              trad_create_date, trad_entry_detail, trad_record_status, trad_process_complete,
--              trad_spot_rate,
--              trad_forward_rate,trad_margin_rate)
--              values(numCompany, varReference1, varReference, numSerial, numCode3,
--              GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
--              numCode, numCode1, numCode2, varTemp,
--              GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
--              GConst.fncXMLExtract(xmlTemp, 'TradeRate', numRate),
--              --GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numFCY),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
--              GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
--              SYSDATE, NULL, GCONST.STATUSENTRY, GCONST.OPTIONNO,
--              GConst.fncXMLExtract(xmlTemp, 'SpotRate', numRate),
--              GConst.fncXMLExtract(xmlTemp, 'ForwardRate', numRate),
--              GConst.fncXMLExtract(xmlTemp, 'MarginRate', numRate));
--            END IF;
--
--          
--            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
--                          datWorkDate);
--            --numError := fncLoanDeal(RecordDetail, varReference1);
--             numError := fncBillSettlement(RecordDetail);
--
--        elsif numAction = GConst.EDITSAVE then
--          varOperation := 'Editing the Bill Entry';
--
--          update TradeRegister
--            set trad_import_export = numCode3,
--            trad_entry_date = GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
--            trad_user_reference = GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
--            trad_reference_date = GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
--            trad_trade_fcy = GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
--            trad_trade_rate = GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numFCY),
--            trad_trade_inr = GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
--            trad_maturity_from = GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
--            trad_maturity_date = GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
--            trad_record_status = GConst.STATUSUPDATED
--            where trad_reverse_reference = varReference
--            and trad_reverse_serial = numSerial;
--
--            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
--                          datWorkDate);
--            numError := fncLoanDeal(RecordDetail, varReference);
--
--        elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
--          varOperation := 'Marking the Bill Entry for ' || numAction;
--          select decode(numAction,
--            GConst.DELETESAVE, GConst.STATUSDELETED,
--            GConst.CONFIRMSAVE, GConst.STATUSAUTHORIZED)
--            into numCode
--            from dual;
--
--          update TradeRegister
--            set trad_record_status = numCode
--            where trad_reverse_reference = varReference
--            and trad_reverse_serial = numSerial;
--
--          numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
--                        datWorkDate);
--          numError := fncLoanDeal(RecordDetail, varReference1);
--
--        End if;
--
--      End if;
----
--      numCode := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numCode);
--
----      if numcode in(Gconst.BILLIMPORTORDER) then
------         INSERT INTO TEMP VALUES ('eNTER THE dETAILS','DFDF');
------         COMMIT;
----
----         clbTemp := ExposureLink(SYSBCRFDLIEN ,numError);
----      end if;
--
----         INSERT INTO TEMP VALUES (Gconst.BILLIMPORTORDER,numcode);
----         COMMIT;
--
--
--  End if;
        -- Order - Invoice linking -----------------------------------------------------
   if EditType = SYSUPDATEORDINVLINK then
      begin
          delete from temp;

          varOperation := 'Updating Reverse Reference Numbers';
          varXPath := '//ORDINVLINKING/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;

          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_COMPANY_CODE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_TRADE_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference1 := GConst.fncXMLExtract(xmlTemp, varTemp, varReference1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_USER_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp1, Gconst.TYPENODEPATH);

              --insert into temp values ('Comp code',varReference);
              --insert into temp values ('Trade ref',varReference1);
              --insert into temp values ('User ref',varTemp1);
              --insert into temp values ('Action ->',to_char(numAction));
             -- commit;

              if numAction = GConst.ADDSAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = varReference1
                  where TRAD_COMPANY_CODE = varReference
                    and TRAD_TRADE_REFERENCE =varTemp1;
              elsif numAction = GConst.DELETESAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = null
                  where TRAD_COMPANY_CODE = varReference1
                    and TRAD_TRADE_REFERENCE = varTemp1;
              end if;
          end loop;
      end;
   end if;

--  if EditType = SYSDEALADJUST then
--
--    varOperation := 'Extracting Deal Type and Trade Reference';
--
--    IF varEntity = 'HEDGEDEALREGISTER' THEN
--      varXPath := '//HEDGEDEALREGISTER/ROW[@NUM]';
--      varTemp := varXPath || '/DEAL_BUY_SELL';
--      numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_OTHER_CURRENCY';
--      numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_DEAL_NUMBER';
--      varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--      varTemp := varXPath || '/DEAL_SERIAL_NUMBER';
--      numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_BASE_AMOUNT';
--      numFCY := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_OTHER_AMOUNT';
--      numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_AMOUNT_LOCAL';
--      numFcy2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_EXCHANGE_RATE';
--      numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_LOCAL_RATE';
--      numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      varTemp := varXPath || '/DEAL_LOCATION_CODE';
--      numCode4 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--      
--      if numCode1 = GConst.INDIANRUPEE then
--        numRate1 := numRate;
--        numFcy2 := numFcy1;
--      end if;
--      
--       if (numAction = GConst.DELETESAVE)  then
--         varOperation := 'Update the record for Delete Save' || varReference;
--           Update trtran004 set hedg_record_status=10200006
--              where hedg_deal_number= varReference;
--      elsif (numAction = GConst.CONFIRMSAVE)  then
--         varOperation := 'Update the record for Delete Save' || varReference;
--           Update trtran004 set hedg_record_status=10200003
--              where hedg_deal_number= varReference;
--       end if;
--       
--  
----        if numCode = GConst.PURCHASEDEAL then
----          nlsTemp := xslProcessor.selectNodes(nodFinal,'//BUY[@NUM]');
----          varXPath := '//BUY[@NUM="';
----        elsif numCode = GConst.SALEDEAL then
----          nlsTemp := xslProcessor.selectNodes(nodFinal,'//SELL[@NUM]');
----          varXPath := '//SELL[@NUM="';
----        end if;
--        
--        nlsTemp := xslProcessor.selectNodes(nodFinal,'//ExposureLink/DROW');
--        varXPath := '//ExposureLink/DROW[@DNUM="';
--  
--            begin 
--            select nvl(count(*),0)+1
--              into numSerial1
--              from trtran004
--             where hedg_deal_number=varReference;
--          exception
--            when no_data_found then 
--              numSerial1:=1;
--          end ;
--        GLOG.log_write('Entered into Deal Adjust');  
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--     
--         GLOG.log_write('Entered inside the Loop' ||numAction );  
--             
--          if ((numAction = GConst.EDITSAVE)) and (numsub=0) then
--                 varOperation := 'Remove already linked Deals' || varReference;
--                   Update trtran004 set hedg_record_status=10200006
--                      where hedg_deal_number= varReference;
--               
--          end if;
--          
--          nodTemp := xmlDom.item(nlsTemp, numSub);
--          nmpTemp := xmlDom.getAttributes(nodTemp);
--          nodTemp1 := xmlDom.item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--  
--           varTemp := varXPath || numTemp || '"]/TradeReference';
--           varReference1 := GConst.fncXMLExtract(xmlTemp, varTemp, varReference1, Gconst.TYPENODEPATH);
--        
--          varTemp := varXPath || numTemp || '"]/SerialNumber';
--          numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);
--            
--          --varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--          varTemp := varXPath || numTemp || '"]/HedgingAmount';
--           numFCY3 := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY3, Gconst.TYPENODEPATH);
--          --numFCY3 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/COMPANYCODE';
--          numCompany := GConst.fncXMLExtract(xmlTemp, varTemp, numCompany, Gconst.TYPENODEPATH);
--          --numCompany := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
--          --varTemp := varXPath || numTemp || '"]/SERIALNUMBER';
--          --numCode1 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));          
--           numCode1 :=1;  --GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);      
--    -- If the hedged amount = deal amount move the entire INR to the hedged amount
--          numFcy := numFcy - numFcy3;
--  
--          if numFcy = 0 then
--            numCross := numFcy1;
--            numInr := numFCy2;
--          else
--            numCross := round(numFcy3 * numRate);
--            numInr := round(numFcy3 * numRate1);
--            numFcy1 := numFcy1 - numCross;
--            numFcy2 := numFcy2 - numInr;
--          end if;
--          if numAction in( GConst.ADDSAVE,GConst.EditSAVE) then
--            varOperation := 'Inserting Hedge Details';
--            numSerial1:=numSerial1+numSub;
--              
--            insert into trtran004(hedg_company_code, hedg_trade_reference,
--              hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
--              hedg_other_fcy, hedg_hedged_inr,
--              hedg_create_date, hedg_entry_detail, hedg_record_status,
--              hedg_hedging_with, hedg_multiple_currency,
--              HEDG_TRADE_SERIAL,HEDG_LINKED_DATE,HEDG_SERIAL_NUMBER,HEDG_LOCATION_CODE)
--              values(numCompany, varReference1, varReference,
--              numSerial, numFCY3, numCross, numInr,
--              SYSDATE, NULL, GConst.STATUSENTRY,
--              Gconst.Forward, decode(numCode1,GConst.INDIANRUPEE, GConst.OPTIONNO, GConst.OPTIONYES)
--              ,numCode2,datWorkDate,numSerial1,numCode4);
--              
----          elsif numAction = GConst.EDITSAVE then
----            varOperation := 'Updating Hedge Details';
----              Update trtran004 set
----                hedg_hedged_fcy= numFCY3,
----                hedg_other_fcy = numCross,
----                hedg_hedged_inr = numInr,
----                hedg_record_status=Gconst.STATUSUPDATED
----              where hedg_deal_number= varReference;
--          end if;
--       End Loop;
--      END IF;
--      IF varEntity = 'FORWARDRATEAGREEMENT' THEN
--        varXPath := '//FORWARDRATEAGREEMENT/ROW[@NUM]';
--        varTemp := varXPath || '/IFRA_BUY_SELL';
--        numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
----        varTemp := varXPath || '/DEAL_OTHER_CURRENCY';
----        numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/IFRA_FRA_NUMBER';
--        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
----        varTemp := varXPath || '/DEAL_SERIAL_NUMBER';
----        numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/IFRA_NOTIONAL_AMOUNT';
--        numFCY := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
----        varTemp := varXPath || '/DEAL_OTHER_AMOUNT';
----        numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
----        varTemp := varXPath || '/DEAL_AMOUNT_LOCAL';
----        numFcy2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/IFRA_FRA_RATE';
--        numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
----        varTemp := varXPath || '/DEAL_LOCAL_RATE';
----        numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--    
--        if numCode1 = GConst.INDIANRUPEE then
--          numRate1 := numRate;
--          numFcy2 := numFcy1;
--        end if;
--    
--          if numCode = GConst.PURCHASEDEAL then
--            nlsTemp := xslProcessor.selectNodes(nodFinal,'//BUY[@NUM]');
--            varXPath := '//BUY[@NUM="';
--          elsif numCode = GConst.SALEDEAL then
--            nlsTemp := xslProcessor.selectNodes(nodFinal,'//SELL[@NUM]');
--            varXPath := '//SELL[@NUM="';
--          end if;
--    
--          for numSub in 0..xmlDom.getLength(nlsTemp) -1
--          Loop
--    
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodTemp1 := xmlDom.item(nmpTemp, 0);
--            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--    
--            varTemp := varXPath || numTemp || '"]/TradeReference';
--            varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--            varTemp := varXPath || numTemp || '"]/HedgingAmount';
--            numFCY3 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
--            varTemp := varXPath || numTemp || '"]/COMPANYCODE';
--            numCompany := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
--      -- If the hedged amount = deal amount move the entire INR to the hedged amount
--            numFcy := numFcy - numFcy3;
--    
--            if numFcy = 0 then
--              numCross := numFcy1;
--              numInr := numFCy2;
--            else
--              numCross := round(numFcy3 * numRate);
--              numInr := round(numFcy3 * numRate1);
--              numFcy1 := numFcy1 - numCross;
--              numFcy2 := numFcy2 - numInr;
--            end if;
--            if numAction = GConst.ADDSAVE then
--              varOperation := 'Inserting Hedge Details';
--              insert into trtran004(hedg_company_code, hedg_trade_reference,
--                hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
--                hedg_other_fcy, hedg_hedged_inr,
--                hedg_create_date, hedg_entry_detail, hedg_record_status,
--                hedg_hedging_with, hedg_multiple_currency)
--                values(numCompany, varReference1, varReference,
--                numSerial, numFCY3, numCross, numInr,
--                sysdate, null, GConst.STATUSENTRY,
--                Gconst.Forward, decode(numCode1,GConst.INDIANRUPEE, GConst.OPTIONNO, GConst.OPTIONYES));
--            elsif numAction = GConst.EDITSAVE then
--              varOperation := 'Updating Hedge Details';
--                Update trtran004 set
--                  hedg_hedged_fcy= numFCY3,
--                  hedg_other_fcy = numCross,
--                  hedg_hedged_inr = numInr,
--                  hedg_record_status=Gconst.STATUSUPDATED
--                where hedg_deal_number= varReference;
--            end if;
--         End Loop;
--      END IF;
--  
--      if numAction =Gconst.DELETESAVE then
--          varOperation := 'Deleting Hedge Details';
--          Delete trtran004 where
--             hedg_deal_number= varReference;
--      end if;
--  end if;


  if EditType = SYSDEALADJUST then

    varOperation := 'Extracting Deal Type and Trade Reference';
  varreference:=GConst.fncXMLExtract(xmlTemp, 'DEAL_DEAL_NUMBER', varreference);  
  Glog.log_write(varOperation || varreference);

  numSerial:=GConst.fncXMLExtract(xmlTemp, 'DEAL_SERIAL_NUMBER', numSerial); 
    IF varEntity = 'HEDGEDEALREGISTER' THEN
      varXPath := '//HEDGEDEALREGISTER/ROW[@NUM]';
      varTemp := varXPath || '/DEAL_BUY_SELL';
      numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_OTHER_CURRENCY';
      numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_DEAL_NUMBER';
      varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
      varTemp := varXPath || '/DEAL_SERIAL_NUMBER';
      numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_BASE_AMOUNT';
      numFCY := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_OTHER_AMOUNT';
      numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_AMOUNT_LOCAL';
      numFcy2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_EXCHANGE_RATE';
      numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_LOCAL_RATE';
      numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_LOCATION_CODE';
      numCode4 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

      if numCode1 = GConst.INDIANRUPEE then
        numRate1 := numRate;
        numFcy2 := numFcy1;
      end if;

       if (numAction = GConst.DELETESAVE)  then
         varOperation := 'Update the record for Delete Save' || varReference;
           Update trtran004 set hedg_record_status=10200006
              where hedg_deal_number= varReference;
      elsif (numAction = GConst.CONFIRMSAVE)  then
         varOperation := 'Update the record for Delete Save' || varReference;
           Update trtran004 set hedg_record_status=10200003
              where hedg_deal_number= varReference;
       end if;


--        if numCode = GConst.PURCHASEDEAL then
--          nlsTemp := xslProcessor.selectNodes(nodFinal,'//BUY[@NUM]');
--          varXPath := '//BUY[@NUM="';
--        elsif numCode = GConst.SALEDEAL then
--          nlsTemp := xslProcessor.selectNodes(nodFinal,'//SELL[@NUM]');
--          varXPath := '//SELL[@NUM="';
--        end if;

        nlsTemp := xslProcessor.selectNodes(nodFinal,'//ExposureLink/DROW');
        varXPath := '//ExposureLink/DROW[@DNUM="';

            begin 
            select nvl(count(*),0)+1
              into numSerial1
              from trtran004
             where hedg_deal_number=varReference;
          exception
            when no_data_found then 
              numSerial1:=1;
          end ;
        GLOG.log_write('Entered into Deal Adjust');  
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop

         GLOG.log_write('Entered inside the Loop' ||numAction );  

          if ((numAction = GConst.EDITSAVE)) and (numsub=0) then
                 varOperation := 'Remove already linked Deals' || varReference;
                   Update trtran004 set hedg_record_status=10200006
                      where hedg_deal_number= varReference;

          end if;

          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));

           varTemp := varXPath || numTemp || '"]/TradeReference';
           varReference1 := GConst.fncXMLExtract(xmlTemp, varTemp, varReference1, Gconst.TYPENODEPATH);

          varTemp := varXPath || numTemp || '"]/SerialNumber';
          numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);

          --varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/HedgingAmount';
           numFCY3 := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY3, Gconst.TYPENODEPATH);
          --numFCY3 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/COMPANYCODE';
          numCompany := GConst.fncXMLExtract(xmlTemp, varTemp, numCompany, Gconst.TYPENODEPATH);
          --numCompany := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
          --varTemp := varXPath || numTemp || '"]/SERIALNUMBER';
          --numCode1 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));          
           numCode1 :=1;  --GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);      
    -- If the hedged amount = deal amount move the entire INR to the hedged amount
          numFcy := numFcy - numFcy3;

          if numFcy = 0 then
            numCross := numFcy1;
            numInr := numFCy2;
          else
            numCross := round(numFcy3 * numRate);
            numInr := round(numFcy3 * numRate1);
            numFcy1 := numFcy1 - numCross;
            numFcy2 := numFcy2 - numInr;
          end if;
          if numAction in( GConst.ADDSAVE,GConst.EditSAVE) then
            varOperation := 'Inserting Hedge Details';
            numSerial1:=numSerial1+numSub;

            insert into trtran004(hedg_company_code, hedg_trade_reference,
              hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
              hedg_other_fcy, hedg_hedged_inr,
              hedg_create_date, hedg_entry_detail, hedg_record_status,
              hedg_hedging_with, hedg_multiple_currency,
              HEDG_TRADE_SERIAL,HEDG_LINKED_DATE,HEDG_SERIAL_NUMBER,HEDG_LOCATION_CODE)
              values(numCompany, varReference1, varReference,
              numSerial, numFCY3, numCross, numInr,
              SYSDATE, NULL, GConst.STATUSENTRY,
              Gconst.Forward, decode(numCode1,GConst.INDIANRUPEE, GConst.OPTIONNO, GConst.OPTIONYES)
              ,numCode2,datWorkDate,numSerial1,numCode4);

--          elsif numAction = GConst.EDITSAVE then
--            varOperation := 'Updating Hedge Details';
--              Update trtran004 set
--                hedg_hedged_fcy= numFCY3,
--                hedg_other_fcy = numCross,
--                hedg_hedged_inr = numInr,
--                hedg_record_status=Gconst.STATUSUPDATED
--              where hedg_deal_number= varReference;
          end if;
       End Loop;
      END IF;
      IF varEntity = 'FORWARDRATEAGREEMENT' THEN
        varXPath := '//FORWARDRATEAGREEMENT/ROW[@NUM]';
        varTemp := varXPath || '/IFRA_BUY_SELL';
        numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_OTHER_CURRENCY';
--        numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || '/IFRA_FRA_NUMBER';
        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || '/DEAL_SERIAL_NUMBER';
--        numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || '/IFRA_NOTIONAL_AMOUNT';
        numFCY := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_OTHER_AMOUNT';
--        numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_AMOUNT_LOCAL';
--        numFcy2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || '/IFRA_FRA_RATE';
        numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_LOCAL_RATE';
--        numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

        if numCode1 = GConst.INDIANRUPEE then
          numRate1 := numRate;
          numFcy2 := numFcy1;
        end if;

          if numCode = GConst.PURCHASEDEAL then
            nlsTemp := xslProcessor.selectNodes(nodFinal,'//BUY[@NUM]');
            varXPath := '//BUY[@NUM="';
          elsif numCode = GConst.SALEDEAL then
            nlsTemp := xslProcessor.selectNodes(nodFinal,'//SELL[@NUM]');
            varXPath := '//SELL[@NUM="';
          end if;

          for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop

            nodTemp := xmlDom.item(nlsTemp, numSub);
            nmpTemp := xmlDom.getAttributes(nodTemp);
            nodTemp1 := xmlDom.item(nmpTemp, 0);
            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));

            varTemp := varXPath || numTemp || '"]/TradeReference';
            varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
            varTemp := varXPath || numTemp || '"]/HedgingAmount';
            numFCY3 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/COMPANYCODE';
            numCompany := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
      -- If the hedged amount = deal amount move the entire INR to the hedged amount
            numFcy := numFcy - numFcy3;

            if numFcy = 0 then
              numCross := numFcy1;
              numInr := numFCy2;
            else
              numCross := round(numFcy3 * numRate);
              numInr := round(numFcy3 * numRate1);
              numFcy1 := numFcy1 - numCross;
              numFcy2 := numFcy2 - numInr;
            end if;
            if numAction = GConst.ADDSAVE then
              varOperation := 'Inserting Hedge Details';
              insert into trtran004(hedg_company_code, hedg_trade_reference,
                hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
                hedg_other_fcy, hedg_hedged_inr,
                hedg_create_date, hedg_entry_detail, hedg_record_status,
                hedg_hedging_with, hedg_multiple_currency)
                values(numCompany, varReference1, varReference,
                numSerial, numFCY3, numCross, numInr,
                sysdate, null, GConst.STATUSENTRY,
                Gconst.Forward, decode(numCode1,GConst.INDIANRUPEE, GConst.OPTIONNO, GConst.OPTIONYES));
            elsif numAction = GConst.EDITSAVE then
              varOperation := 'Updating Hedge Details';
                Update trtran004 set
                  hedg_hedged_fcy= numFCY3,
                  hedg_other_fcy = numCross,
                  hedg_hedged_inr = numInr,
                  hedg_record_status=Gconst.STATUSUPDATED
                where hedg_deal_number= varReference;
            end if;
         End Loop;
      END IF;

  if  numAction in(GConst.ADDSAVE, GConst.EDITSAVE) then

          update trtran001A
          set QUOT_RECORD_STAUTS=10200006
          where QUOT_DEAL_NUMBER=varreference;

           begin 
            select nvl(count(*),0)+1
              into numSerial1
              from trtran001A
             where QUOT_DEAL_NUMBER=varreference; 
          exception
            when no_data_found then 
              numSerial1:=1;
          end ;

          varTemp2 := '//MULTIPLEQUOTES//DROW';       
          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          --numSerial:=1;
          if(xmlDom.getLength(nlsTemp)>0) then

          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop
             varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/CounterParty';
              varoperation :='Extracting Data from XML' || varTemp;
              begin
              numCode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);
              exception
               when others then
                 numCode1 :=30699999;
              end;
               Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/SpotRate';
              varoperation :='Extracting Data from XML' || varTemp;
              begin
              numRate := GConst.fncXMLExtract(xmlTemp, varTemp, numRate, Gconst.TYPENODEPATH);
               exception
               when others then
                 numRate :=0;
              end;
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/ForwardPremium';
              varoperation :='Extracting Data from XML' || varTemp;
              begin
              numRate1 := GConst.fncXMLExtract(xmlTemp, varTemp, numRate1, Gconst.TYPENODEPATH);
               exception
               when others then
                 numRate1 :=0;
              end;
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/MarginRate';
              varoperation :='Extracting Data from XML' || varTemp;
              begin
              numRate2 := GConst.fncXMLExtract(xmlTemp, varTemp, numRate2, Gconst.TYPENODEPATH);
               exception
               when others then
                 numRate2 :=0;
              end;
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/AllInRate';
              varoperation :='Extracting Data from XML' || varTemp;
              begin
              numRate3 := GConst.fncXMLExtract(xmlTemp, varTemp, numRate3, Gconst.TYPENODEPATH);
               exception
               when others then
                 numRate3 :=0;
              end;
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/UserRemarks';
              varoperation :='Extracting Data from XML' || varTemp;
              begin
              varTemp5 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp5, Gconst.TYPENODEPATH);
               exception
               when others then
                 varTemp5 :=null;
              end;

              varoperation :='Inserting Data into trtran001a';
              insert into trtran001a (QUOT_DEAL_NUMBER, QUOT_DEAL_SERIAL, QUOT_SERIAL_NUMBER, 
              QUOT_COUNTER_PARTY, QUOT_SPOT_RATE, QUOT_FORWARD_PERIMUM, QUOT_MARGIN_RATE, 
              QUOT_ALLIN_RATE, QUOT_USER_REMARKS, QUOT_RECORD_STAUTS, QUOT_ADD_DATE, QUOT_CREATE_DATE,
              QUOT_ENTRY_DETAILS)
              Values(varreference, numSerial, numSerial1, numCode1,numRate,numRate1,numRate2,numRate3,varTemp5,
              10200001, sysdate, sysdate, null);

               numSerial1:=numSerial1+1;


          end loop;

      end if;




  elsif  numAction in(GConst.DELETESAVE) then

          update trtran001a
          set QUOT_RECORD_STAUTS=10200006
          where QUOT_DEAL_NUMBER=varreference;
        --  commit;

  elsif  numAction in(GConst.CONFIRMSAVE) then

          update trtran001a
          set QUOT_RECORD_STAUTS=10200003
          where QUOT_DEAL_NUMBER=varreference;

      --    commit;       

  end if;
      if numAction =Gconst.DELETESAVE then
          varOperation := 'Deleting Hedge Details';
          Delete trtran004 where
             hedg_deal_number= varReference;
      end if;
  end if;

    IF EditType = SYSFUTUREREVERSAL THEN
         varOperation := 'Inserting into Currency Future  Deal Reversal';


       IF ((varEntity= 'CURRENCYFUTUREDEALCANCEL') or (varEntity= 'CURRENCYFUTURETRADDEALCANCEL')) THEN
         varXPath := '//' || varEntity || '/ROW[@NUM]';
         varTemp := varXPath || '/CFRV_DEAL_NUMBER';
         varOperation := 'Geting Deal Number';

         varReference := GConst.fncGetNodeValue(nodFinal, varTemp);

         numError := fncCompleteUtilization(varReference, GConst.UTILFUTUREDEAL,
                        datWorkDate);

          IF (varEntity= 'CURRENCYFUTUREDEALCANCEL') THEN
            IF numAction = GConst.ADDSAVE THEN                
              nlsTemp    := xslProcessor.selectNodes(nodFinal,'//DealUnLink/ROWD[@NUM]');
              varXPath   := '//DealUnLink/ROWD[@NUM="';
              FOR numSub IN 0..xmlDom.getLength(nlsTemp) -1
              LOOP
                nodTemp       := xmlDom.item(nlsTemp, numSub);
                nmpTemp       := xmlDom.getAttributes(nodTemp);
                nodTemp1      := xmlDom.item(nmpTemp, 0);
                numTemp       := to_number(xmlDom.getNodeValue(nodTemp1));
                varTemp       := varXPath || numTemp || '"]/DealSerial';
                numCode1      := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp       := varXPath || numTemp || '"]/TradeReference';
                varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
                varTemp       := varXPath || numTemp || '"]/LinkDealNumber';
                varReference  := GConst.fncGetNodeValue(nodFinal, varTemp);

                varTemp       := varXPath || numTemp || '"]/HedgedAmount';
                numFCY        := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

                varTemp       := varXPath || numTemp || '"]/CompanyCode';
                numCompany    := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

      --          varTemp       := varXPath || numTemp || '"]/LinkDate';
      --          datTemp       := GConst.fncGetNodeValue(nodFinal, varTemp);
--                SELECT deal_exchange_rate
--                INTO numRate1
--                FROM trtran001
--                WHERE deal_deal_number = varReference;

                IF numFCY <= 0 THEN
                  UPDATE trtran004
                  SET hedg_record_status     = GConst.STATUSDELETED
                  WHERE hedg_trade_reference = varReference1
                  AND hedg_deal_number       = varReference
                  AND hedg_deal_serial       = numCode1;
                ELSE
                  UPDATE trtran004
                  SET hedg_record_status     = GConst.STATUSDELETED
                  WHERE hedg_trade_reference = varReference1
                  AND hedg_deal_number       = varReference
                  AND hedg_deal_serial       = numCode1;

                  INSERT
                  INTO trtran004
                    ( hedg_company_code,    hedg_trade_reference,    hedg_deal_number,    hedg_deal_serial,    hedg_hedged_fcy,
                      hedg_other_fcy,    hedg_hedged_inr,    hedg_create_date,    hedg_entry_detail,    hedg_record_status,
                      hedg_hedging_with,    hedg_multiple_currency,    hedg_linked_date,  hedg_location_code  )
                    VALUES
                    (
                      numCompany,    varReference1,    varReference, numCode1+1,    numFCY,
                      0, numFCY ,    sysdate,    NULL,    10200001,
                      32200002,    12400002,    datWorkDate, 30299999 );

                END IF;
              END LOOP;      
            END IF;
           END IF;                        
       ELSE

         varXPath := '//' || varEntity || '/ROW[@NUM]';
         varTemp := varXPath || '/CFUT_DEAL_NUMBER';
         varOperation := 'Geting Deal Number';
         varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
         varTemp := varXPath || '/CFUT_COMPANY_CODE';
         numcode1 :=   to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
         nlsTemp := xslProcessor.selectNodes(nodFinal,'//' || varEntity || '/ReverseDetails/ReverseRow[@NUM]');
         varXPath := '//' || varEntity || '/ReverseDetails/ReverseRow[@NUM="';

        for numSub in 1..xmlDom.getLength(nlsTemp)
         loop
          varTemp := varXPath || numSub || '"]/ReverseDealNumber';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numSub || '"]/ReverseLot';
          numcode := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numSub || '"]/ReserveProcess';
           varOperation := 'Geting Process Complite  Number';
          numcode2:= GConst.fncGetNodeValue(nodFinal, varTemp);
          varOperation := 'Fetching ReserveProcessComplete';
          varTemp := varXPath || numSub || '"]/ReserveProfitLoss';
          numINR := GConst.fncGetNodeValue(nodFinal, varTemp);
          if numAction = GConst.ADDSAVE then
             insert into trtran063 ( cfrv_company_code,cfrv_deal_number,cfrv_reverse_deal,
               cfrv_reverse_lot,cfrv_profit_loss,cfrv_create_Date,cfrv_record_status, cfrv_execute_date)
               VALUES (numcode1,varReference, varReference1,
               numcode,numINR,sysdate,10200001,datWorkDate);

             varOperation := 'Updating Process Complete and Process Complite Date';
             if numcode2=Gconst.OptionYES then
                update trtran061 set cfut_process_complete= numcode2,
                  cfut_complete_date= datWorkDate
                  where cfut_deal_number=  varReference1;
              end if;
          elsif numAction = GConst.EDITSAVE then
             update trtran063 set cfrv_reverse_deal=varReference1,
               cfrv_reverse_lot=numcode
               where cfrv_deal_number= varReference;

          elsif  numAction = GConst.DELETESAVE then
             delete from trtran063 where  cfrv_deal_number= varReference;
          end if;
        end Loop;
      end if;
  end if;



------------------------------------------ Option Deals-----------------------------------------
--   if EditType = GConst.SYSOPTIONMATURITY then
--
--        varOperation := 'Option Maturities Gettinging DealNumber';
--        varTemp := '//ROW[@NUM="1"]/COPT_DEAL_NUMBER';
--        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
--      --Before adding deleteing the Existing data if anyh
--        delete from trtran072
--           where cosu_deal_number=varReference;
--
--     -- if numAction in (GConst.ADDSAVE) then
--        varXPath := '//LEG/LEGROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--        varOperation := 'Option Maturities Entering Into Main loop ' || varXPath;
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath || '[@NUM="' || numTemp || '"]/SUBROW';
--          varoperation :='Extracting Data from XML' || varTemp;
--          nlsTemp1 := xslProcessor.selectNodes(nodFinal, varTemp);
--          numSub1 := xmlDom.getLength(nlsTemp1);
--          for numsub1 in 0.. xmldom.getlength(nlsTemp1) -1
--          loop
--              varOperation := 'Option Maturities Entering Into Sub  loop ' || varXPath;
--              nodTemp := xmlDom.Item(nlsTemp1, numSub1);
--              nmpTemp:= xmlDom.getAttributes(nodTemp);
--              nodTemp := xmlDom.Item(nmpTemp, 0);
--              numTemp1 := to_number(xmlDom.GetNodeValue(nodTemp));
--
--              varTemp := varXPath || '[@NUM="' || numTemp || '"]/SUBROW[@SUBNUM="'|| numTemp1 || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numSerial := GConst.fncXMLExtract(xmlTemp,varTemp || 'SRNO',numSerial, Gconst.TYPENODEPATH);
--              numSerial1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SUBSRNO',numSerial1, Gconst.TYPENODEPATH);
--              numCode := GConst.fncXMLExtract(xmlTemp,varTemp || 'BuySell',numCode, Gconst.TYPENODEPATH);
--              numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OptionType',numCode1, Gconst.TYPENODEPATH);
--              numFCY := GConst.fncXMLExtract(xmlTemp,varTemp || 'BaseAmount',numFCY, Gconst.TYPENODEPATH);
--              numRate2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'StrikeRate',numFCY1, Gconst.TYPENODEPATH);
--              numFCY2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OtherAmount',numFCY2, Gconst.TYPENODEPATH);
--              numFCY3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalRate',numFCY3, Gconst.TYPENODEPATH);
--              numCross := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalAmount',numCross, Gconst.TYPENODEPATH);
--              numRate := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumRate',numRate, Gconst.TYPENODEPATH);
--              numFCY4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumAmount',numFCY4, Gconst.TYPENODEPATH);
--              numRate1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumLocalRate',numRate1, Gconst.TYPENODEPATH);
--              numINR := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumLocalAmount',numINR, Gconst.TYPENODEPATH);
--              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp || 'MATURITY',datTemp, Gconst.TYPENODEPATH);
--              datTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SETTLEMENTDATE',datTemp1, Gconst.TYPENODEPATH);
--
--              insert into trtran072 (COSU_DEAL_NUMBER,COSU_SERIAL_NUMBER,COSU_SUBSERIAL_NUMBER,COSU_OPTION_TYPE,
--                                     COSU_BUY_SELL,COSU_BASE_AMOUNT,COSU_STRIKE_RATE,COSU_OTHER_AMOUNT,COSU_LOCAL_RATE,
--                                     COSU_LOCAL_AMOUNT,COSU_PREMIUM_RATE,COSU_PREMIUM_AMOUNT,COSU_PREMIUM_LOCALRATE,
--                                     COSU_PREMIUM_LOCALAMOUNT,COSU_MATURITY_DATE,COSU_SETTLEMENT_DATE,
--                                     COSU_RECORD_STATUS,COSU_PROCESS_COMPLETE)
--                            values (varReference,numSerial,numSerial1,numCode1,
--                                    numCode,numFCY,numRate2,numFCY2,numFCY3,
--                                    numCross,numRate,numFCY4,numRate1,
--                                    numINR,datTemp,datTemp1,10200001,12400002);
--
--         end loop;
--       End Loop;
----       elsif numAction in (GConst.DELETESAVE) then
----          varOperation :='Deleting Deals';
----          update trtran072 set cosu_record_status= 10200006
----                 where cosu_deal_number=varReference;
--   --   end if;
--
--  End if;
  if EditType = SYSOPTIONMATURITY then

        varOperation := 'Option Maturities Gettinging DealNumber';
        varTemp := '//ROW[@NUM="1"]/COPT_DEAL_NUMBER';
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
      --Before adding deleteing the Existing data if anyh
     if numAction in (GConst.DELETESAVE) then 
        update  trtran072 set cosu_record_Status =10200006
           where cosu_deal_number=varReference;

        update trtran072A set cosm_record_Status =10200006
           where cosm_deal_number=varReference;
     else
        delete from trtran072
           where cosu_deal_number=varReference;

        delete from trtran072A
           where cosm_deal_number=varReference;

     -- if numAction in (GConst.ADDSAVE) then
        varXPath := '//MultipleDeals/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
        varOperation := 'Option Maturities Entering Into Main loop ' || varXPath;
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath; --|| '[@NUM="' || numTemp || '"]/SUBROW';
          varoperation :='Extracting Data from XML' || varTemp;
--          nlsTemp1 := xslProcessor.selectNodes(nodFinal, varTemp);
--          numSub1 := xmlDom.getLength(nlsTemp1);
----          for numsub1 in 0.. xmldom.getlength(nlsTemp1) -1
----          loop
--              varOperation := 'Option Legs entering Into Sub  loop ' || varXPath;
--              nodTemp := xmlDom.Item(nlsTemp1, numSub1);
--              nmpTemp:= xmlDom.getAttributes(nodTemp);
--              nodTemp := xmlDom.Item(nmpTemp, 0);
--              numTemp1 := to_number(xmlDom.GetNodeValue(nodTemp));

              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
              numSerial := GConst.fncXMLExtract(xmlTemp,varTemp || 'SerialNumber',numSerial, Gconst.TYPENODEPATH);
            --  numSerial1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SUBSRNO',numSerial1, Gconst.TYPENODEPATH);
              numCode := GConst.fncXMLExtract(xmlTemp,varTemp || 'BuySell',numCode, Gconst.TYPENODEPATH);
              numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OptionType',numCode1, Gconst.TYPENODEPATH);
              numFCY := GConst.fncXMLExtract(xmlTemp,varTemp || 'BaseAmount',numFCY, Gconst.TYPENODEPATH);
              numRate2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'StrikeRate',numRate2, Gconst.TYPENODEPATH);
              numFCY2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OtherAmount',numFCY2, Gconst.TYPENODEPATH);
--              numFCY3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalRate',numFCY3, Gconst.TYPENODEPATH);
--              numCross := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalAmount',numCross, Gconst.TYPENODEPATH);
              numRate := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumRate',numRate, Gconst.TYPENODEPATH);
              numFCY4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumAmount',numFCY4, Gconst.TYPENODEPATH);
              begin 
               numCode2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ProductCode',numCode2, Gconst.TYPENODEPATH);
              exception
               when others then
                 numCode2 :=null;
              end;
              numINR := GConst.fncXMLExtract(xmlTemp,varTemp || 'NoOfLots',numINR, Gconst.TYPENODEPATH);
              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp || 'MaturityDate',datTemp, Gconst.TYPENODEPATH);
              datTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SettlementDate',datTemp1, Gconst.TYPENODEPATH);

              insert into trtran072 (COSU_DEAL_NUMBER,COSU_SERIAL_NUMBER,COSU_OPTION_TYPE,
                                     COSU_BUY_SELL,COSU_BASE_AMOUNT,COSU_STRIKE_RATE,COSU_OTHER_AMOUNT,
                                     Cosu_Premium_rate,cosu_premium_amount,cosu_maturity_date,
                                     cosu_settlement_date,COSU_PRODUCT_CODE,COSU_LOT_NUMBERS,
                                     COSU_RECORD_STATUS,COSU_PROCESS_COMPLETE)
                            values (varReference,numSerial,numCode1,
                                    numCode,numFCY,numRate2,numFCY2,
                                    numrate,numfcy4,datTemp,
                                    datTemp1,numCode2,numINR,
                                    10200001,12400002);


         --end loop;
       End Loop;

        --varXPath := '//MLegs/MLeg';
        varXPath := '//Maturity/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
        varOperation := 'Option Maturities Entering Into Main loop ' || varXPath;
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop       

              varOperation := 'Option Legs entering Into Sub  loop ' || varXPath;
              nodTemp := xmlDom.Item(nlsTemp, numSub);
              nmpTemp:= xmlDom.getAttributes(nodTemp);
              nodTemp := xmlDom.Item(nmpTemp, 0);
              numTemp1 := to_number(xmlDom.GetNodeValue(nodTemp));

              varTemp := varXPath || '[@DNUM="' || numTemp1 || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
              numSerial := GConst.fncXMLExtract(xmlTemp,varTemp || 'SrNo',numSerial, Gconst.TYPENODEPATH);
              numSerial1 := Gconst.fncXMLExtract(xmltemp,vartemp || 'SubSrNo',numserial1,Gconst.TYPENODEPATH);
              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp || 'MaturityDate',datTemp, Gconst.TYPENODEPATH);
              datTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SettlementDate',datTemp1, Gconst.TYPENODEPATH);
              numFcy6 :=  GConst.fncXMLExtract(xmlTemp,varTemp || 'Amount',numFcy6, Gconst.TYPENODEPATH);
          insert into trtran072A (COSM_DEAL_NUMBER,cosm_serial_number,COSM_SUBSERIAL_NUMBER,COSM_MATURITY_DATE,
                                 COSM_SETTLEMENT_DATE,COSM_PROCESS_COMPLETE,COSM_CREATE_DATE,
                                 COSM_RECORD_STATUS,COSM_AMOUNT_FCY)
             values (varReference,numSerial,numserial1,datTemp,
                     datTemp1,12400001,sysdate,10200001,numFcy6); 

      end loop;
    end if;
    DELETE FROM trsystem966;
  End if;


   if EditType = SYSOPTIONCANCELDEAL then
      varReference := GConst.fncXMLExtract(xmlTemp, 'CORV_DEAL_NUMBER', varTemp);
      numSerial := GConst.fncXMLExtract(xmlTemp, 'CORV_SERIAL_NUMBER', numFCY2);
      numCode15 := GConst.fncXMLExtract(xmlTemp, 'CORV_SERIAL_NUMBER', numCode15);

      varOperation := 'Updating Cancelled Option Deals';

      if numAction = GConst.ADDSAVE then
          numError := fncCompleteUtilization(varReference, Gconst.UTILOPTIONHEDGEDEAL,
                        datWorkDate, numserial,numCode15);
--        update trtran071
--          set copt_record_status = GConst.STATUSPOSTCANCEL,
--          copt_process_complete = GConst.OPTIONYES,
--          copt_complete_date = datWorkDate
--          where copt_deal_number = varReference
--          and copt_serial_number = numSerial;
      elsif numAction = GConst.DELETESAVE then
        update trtran071
          set --copt_record_status = GConst.STATUSENTRY,
          copt_process_complete = GConst.OPTIONNO,
          copt_complete_date = NULL
          where copt_deal_number = varReference
          and copt_serial_number = numSerial;
      End if;

    End if;

    if EditType =SYSLINKUPDATETABLES then
      varReference := GConst.fncXMLExtract(xmlTemp, 'LINK_BATCH_NUMBER', varTemp);
      varOperation := 'Updating Updating Link Batch Numbers';
      varXPath := '//HEDGEREFERENCE';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      varOperation := 'Update Option Deals With Linking No ' || varXPath;

      varOperation := 'Updating null to Old Reference';
--      update trtran071 set copt_link_batchno=null, copt_link_date=datWorkDate
--             where copt_link_batchno=varReference;
--
--      varOperation := 'Updating null to Old Reference';
--      update trtran002 set trad_link_batchno=null, trad_link_date=datWorkDate
--             where trad_link_batchno=varReference;


     -- insert into temp values (varOperation,varXPath);
      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath || '[@NUM="' || numTemp || '"]';
          varoperation :='Extracting Data from XML' || varTemp;
          varReference1 := GConst.fncXMLExtract(xmlTemp,varTemp,varReference, Gconst.TYPENODEPATH);

--          Update trtran071 set copt_link_batchno= varReference,
--                               copt_link_date= datWorkDate
--                where copt_deal_number =varReference1;
          --insert into temp values (varOperation,varReference1);
      end loop;

      varOperation := 'Updating Link Batch Trade Reference';
      varXPath := '//TRADEREFERENCE';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      varOperation := 'Update Option Deals With Linking No ' || varXPath;
      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath || '[@NUM="' || numTemp || '"]';
          varoperation :='Extracting Data from XML' || varTemp;
          varReference1 := GConst.fncXMLExtract(xmlTemp,varTemp,varReference, Gconst.TYPENODEPATH);

          Update trtran002 set trad_link_batchno= varReference,
                               trad_link_date= datWorkDate
                where trad_trade_reference =varReference1;
          --insert into temp values (varOperation,varReference1);



      end loop;
   end if;

   if EditType =SYSUPDATEDEALNO then --Added By Sivadas on 18DEC2011

        --delete from temp;
        --insert into temp values(varReference, varReference);
        varTemp := Gconst.fncXMLExtract(xmlTemp,'UpdateType',varTemp);

        if varTemp=Gconst.UpdateIBSRefNo then
            varReference  := GConst.fncXMLExtract(xmlTemp, 'MTMR_USER_REFERENCE', varTemp);
            varReference1 := GConst.fncXMLExtract(xmlTemp, 'MTMR_BATCH_NUMBER', varTemp);
            datWorkDate   := GConst.fncXMLExtract(xmlTemp, 'MTMR_REPORT_DATE', datWorkDate);

            begin
              select dealnumber,
                     companycode,
                     counterparty,
                     dealtype,
                     slno
                into varTemp1,
                     numCode1,
                     numCode2,
                     numCode3,
                     numTemp
                from (
                      select dealnumber,
                             regexp_substr(userref,'[^,]+', 1, level) userref,
                             companycode,
                             counterparty,
                             dealtype,
                             slno
                        from (
                              select copt_user_reference userref,
                                     copt_deal_number dealnumber,
                                     copt_company_code companycode,
                                     copt_counter_party counterparty,
                                     copt_deal_type dealtype,
                                     copt_serial_number slno
                                from trtran071
                               where instr(copt_user_reference, varReference) > 0
                                 and ((copt_process_complete = 12400001
                                       and copt_complete_date > datWorkDate)
                                        or copt_process_complete = 12400002)
                                 and copt_record_status not in (10200005,10200006)
                             )
                      connect by regexp_substr(userref, '[^,]+', 1, level) is not null
                     )
               where userref = varReference
                 and rownum = 1;

              -- Update Deal number, company code and bank code
              update trtran075
                 set mtmr_ibs_ref_no = varTemp1,
                     mtmr_company_code = numCode1,
                     mtmr_bank_code = numCode2
               where mtmr_user_reference = varReference
                    and mtmr_report_date=datWorkDate;
              -- update mtm amounts if Barclays/Citi bank
              update trtran075
                 set mtmr_mtm_amount = -mtmr_mtm_amount,
                     mtmr_mtm_usd = -mtmr_mtm_usd,
                     mtmr_national1 = -mtmr_national1
               where mtmr_user_reference = varReference
                 and mtmr_bank_code in (30600024, 30600114, 30600113, 30600034, 30600088, 30600089)
                 and mtmr_report_date=datWorkDate;
              -- update notional1 as '0' if Strangle/Straddle option for ICICI Bank
              if numCode3 = 32300002 or numCode3 = 32300005 then
                  update trtran075
                     set mtmr_national1 = 0
                   where mtmr_user_reference in (select userref
                                                   from (select rownum rno,
                                                                copt_deal_number,
                                                                regexp_substr(copt_user_reference,'[^,]+', 1, level) userref
                                                           from (select copt_user_reference,
                                                                        copt_deal_number
                                                                   from trtran071
                                                                  where instr(copt_user_reference, varReference) > 0)
                                                        connect by regexp_substr(copt_user_reference, '[^,]+', 1, level) is not null)
                                                    where rno > 1)
                     and mtmr_bank_code in (30600096, 30600097, 30600110, 30600115, 30600020)
                     and mtmr_report_date=datWorkDate;
              end if;

              -- update notional as 0 for Barclays bank STRANGLE option
              if numCode3 = 32300002 then
                  update trtran075
                     set mtmr_national1 = 0
                   where mtmr_user_reference = varReference
                     and mtmr_bank_code in (30600024, 30600114, 30600113)
                     and mtmr_national1 < 0;
              end if;

              -- Update Notional value for Axis Bank --
              update trtran075
                 set mtmr_national1 = (select copt_base_amount
                                         from trtran071
                                        where copt_company_code = numCode1
                                          and copt_deal_number = varTemp1
                                          and copt_serial_number = numTemp)
               where mtmr_user_reference = varReference
                 and mtmr_bank_code in (30600094, 30600011, 30600031, 30600035);

            exception
              when no_data_found then
                -- Delete all rows updated till now
--                delete
--                  from trtran075
--                 where mtmr_batch_number = varReference1;
             --    commit;

                -- Raise application error
                numError := 0;
                varError := 'No deal number found for ' || varReference || ' or is in process complete status!';
                --varError := GConst.fncReturnError('MTM Upload', numError, varMessage,
                --                varOperation, varError);
                --raise_application_error(-20101, varError);
                --raise error_occured;
                   --numError := SQLCODE;
               -- varError := SQLERRM;
                --varError := GConst.fncReturnError('MTM Upload', numError, varMessage,
                                --varOperation, varError);
                raise_application_error(-20101, varError);

              when others then
                numError := SQLCODE;
                varError := SQLERRM;
                varError := GConst.fncReturnError('MTM Upload', numError, varMessage,
                                varOperation, varError);
                raise_application_error(-20101, varError);
            end;







        elsif varTemp=Gconst.UpdateBankRefNo then
          begin
            --varReference := GConst.fncXMLExtract(xmlTemp, 'LINK_BATCH_NUMBER', varTemp);
            varOperation := 'Updating Batch Numbers';
            varXPath := '//Rows/Row';
            nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
            varOperation := 'Update Batch No ' || varXPath;

            for numTemp in 1..xmlDom.getLength(nlsTemp)
            Loop
                varTemp := varXPath || '[@Num="' || numTemp || '"]/DealNo';
                varoperation :='Extracting Data from XML' || varTemp;
                varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference, Gconst.TYPENODEPATH);

                varTemp := varXPath || '[@Num="' || numTemp || '"]/UserRefNo';
                varoperation :='Extracting Data from XML' || varTemp;
                varReference1 := GConst.fncXMLExtract(xmlTemp,varTemp,varReference1, Gconst.TYPENODEPATH);

                update trtran071 set copt_user_reference= varReference1
                 where copt_deal_number =varReference
                   and copt_record_status not in(10200005,10200006);

            end loop;
        end;
        end if;
   end if;

if EditType = SYSRUNACCOUNTINGPROCESS then
    varReference := GConst.fncXMLExtract(xmlTemp, 'AHPM_REFERENCE_NUMBER', varReference);
    --datTemp := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/AHPM_EFFECTIVE_DATE',datTemp,Gconst.TYPENODEPATH);

    GLOG.log_Write('Confirm for Ref' || varReference); 
  --  GLOG.log_Write(to_char(datTemp)); 

    if numAction = GConst.CONFIRMSAVE then
    update TRTRAN111 set CASH_RECORD_STATUS=10200003
    where CASH_AMTM_REFERENCENUMBER IN (SELECT AHPM_AMTM_REFERENCENUMBER 
                                        FROM TRTRAN111_MAIN 
                                        WHERE AHPM_REFERENCE_NUMBER=varReference
                                        AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));

    update TRTRAN111_DETAIL set CASH_RECORD_STATUS=10200003
    where CASH_AMTM_REFERENCE IN (SELECT AHPM_AMTM_REFERENCENUMBER 
                                 FROM TRTRAN111_MAIN 
                                 WHERE AHPM_REFERENCE_NUMBER=varReference
                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));



--    update trtran008 set bcac_record_Status =10200006
--     where  bcac_voucher_number=varReference;

     pkghedgeaccounting.prcPopulateAccountingEntry(varReference);

--   numcode6:=0;
--   for cur in (  select *  from TRTRAN111
--            where cash_Record_Status not in (10200005,10200006)
--            and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER
--                                 FROM TRTRAN111_MAIN
--                                 WHERE AHPM_REFERENCE_NUMBER=varReference
--                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006)))
--    loop
--   
--    numcode6:=numcode6+1;
--    varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);
--    -- HEDGE Reserve
--    if cur.cash_INeffective_PL !=0 then
--     insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--           values( cur.cash_company_code,cur.Cash_location_code,cur.cash_bank_code,varTemp,
--                cur.CASH_EFFECTIVE_DATE,( case when cur.cash_INeffective_PL>0 then 14600001 else 14600002 end ),
--                24900002,24800003,varReference,
--                numcode6,30400003,abs(cur.cash_INeffective_PL),
--                1,abs(cur.cash_INeffective_PL),null,
--                sysdate,sysdate,30699999,
--                10200001,23800002,cur.CASH_PORTOFLIO_CODE,cur.CASH_SUBPORTFOLIO_CODE);
----            from TRTRAN111
----            where cash_INeffective_PL >0
----            --and cash_effective_date ='27-Dec-2021'
----            and cash_Record_Status not in (10200005,10200006)
----            and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER
----                                 FROM TRTRAN111_MAIN
----                                 WHERE AHPM_REFERENCE_NUMBER=varReference
----                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
--                                 
--     varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);        
--  -- IND AS Accoount Reversal
--    insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--           values( cur.cash_company_code,cur.Cash_location_code,cur.cash_bank_code,varTemp,
--                cur.CASH_EFFECTIVE_DATE,( case when cur.cash_INeffective_PL>0 then 14600002 else 14600001 end ),
--                24900004,24800003,varReference,
--                numcode6,30400003,abs(cur.cash_INeffective_PL),
--                1,abs(cur.cash_INeffective_PL),null,
--                sysdate,sysdate,30699999,
--                10200001,23800002,cur.CASH_PORTOFLIO_CODE,cur.CASH_SUBPORTFOLIO_CODE);
----            from TRTRAN111
----            where cash_INeffective_PL >0
----           -- and cash_effective_date ='27-Dec-2021'
----            and cash_Record_Status not in (10200005,10200006)
----            and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER
----                                 FROM TRTRAN111_MAIN
----                                 WHERE AHPM_REFERENCE_NUMBER=varReference
----                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
-- 
--    end if;
--    numcode6:=numcode6+1;
--    if cur.cash_effective_PL !=0 then
--        varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);  
--       -- HEDGE MTM
--        insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--               values( cur.cash_company_code,cur.Cash_location_code,cur.cash_bank_code,varTemp,
--                    cur.CASH_EFFECTIVE_DATE,( case when cur.cash_effective_PL>0 then 14600001 else 14600002 end ),
--                    24900003,24800003,varReference,
--                    numcode6,30400003,abs(cur.cash_effective_PL),
--                    1,abs(cur.cash_effective_PL),null,
--                    sysdate,sysdate,30699999,
--                    10200001,23800002,cur.CASH_PORTOFLIO_CODE,cur.CASH_SUBPORTFOLIO_CODE);
----                from TRTRAN111
----                where cash_effective_PL >0
----                --and cash_effective_date ='27-Dec-2021'
----                and cash_Record_Status not in (10200005,10200006)
----                and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER
----                                     FROM TRTRAN111_MAIN
----                                     WHERE AHPM_REFERENCE_NUMBER=varReference
----                                     AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
--        varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);            
--      -- IND AS Accoount Reversal
--        insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--               values( cur.cash_company_code,cur.Cash_location_code,cur.cash_bank_code,varTemp,
--                    cur.CASH_EFFECTIVE_DATE,( case when cur.cash_effective_PL>0 then 14600002 else 14600001 end ),
--                    24900004,24800003,varReference,
--                    numcode6,30400003,abs(cur.cash_effective_PL),
--                    1,abs(cur.cash_effective_PL),null,
--                    sysdate,sysdate,30699999,
--                    10200001,23800002,cur.CASH_PORTOFLIO_CODE,cur.CASH_SUBPORTFOLIO_CODE);
----                from TRTRAN111
----                where cash_effective_PL >0
----                --and cash_effective_date ='27-Dec-2021'
----                and cash_Record_Status not in (10200005,10200006)
----                and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER
----                                     FROM TRTRAN111_MAIN
----                                     WHERE AHPM_REFERENCE_NUMBER=varReference
----                                     AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
--    end if;    
--    end loop;
--    varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);
--  -- HEDGE Reserve
--    insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--           select cash_company_code,Cash_location_code,cash_bank_code,varTemp,
--                CASH_EFFECTIVE_DATE,( case when cash_effective_PL>0 then 14600001 else 14600002 end ),
--                24900002,24800003,varReference,
--                1,30400003,abs(cash_effective_PL),
--                1,abs(cash_effective_PL),null,
--                sysdate,sysdate,30699999,
--                10200001,23800002,CASH_PORTOFLIO_CODE,CASH_SUBPORTFOLIO_CODE
--            from TRTRAN111
--            where cash_INeffective_PL >0
--            --and cash_effective_date ='27-Dec-2021'
--            and cash_Record_Status not in (10200005,10200006)
--            and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER 
--                                 FROM TRTRAN111_MAIN 
--                                 WHERE AHPM_REFERENCE_NUMBER=varReference
--                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
--                                 
--     varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);        
--  -- IND AS Accoount Reversal
--    insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--           select cash_company_code,Cash_location_code,cash_bank_code,varTemp,
--                CASH_EFFECTIVE_DATE,( case when cash_effective_PL>0 then 14600002 else 14600001 end ),
--                24900004,24800003,varReference,
--                1,30400003,abs(cash_effective_PL),
--                1,abs(cash_effective_PL),null,
--                sysdate,sysdate,30699999,
--                10200001,23800002,CASH_PORTOFLIO_CODE,CASH_SUBPORTFOLIO_CODE
--            from TRTRAN111
--            where cash_INeffective_PL >0
--           -- and cash_effective_date ='27-Dec-2021'
--            and cash_Record_Status not in (10200005,10200006)
--            and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER 
--                                 FROM TRTRAN111_MAIN 
--                                 WHERE AHPM_REFERENCE_NUMBER=varReference
--                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
--
--    varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);   
--   -- HEDGE MTM
--    insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--           select cash_company_code,Cash_location_code,cash_bank_code,varTemp,
--                CASH_EFFECTIVE_DATE,( case when cash_effective_PL>0 then 14600001 else 14600002 end ),
--                24900003,24800003,varReference,
--                1,30400003,abs(cash_effective_PL),
--                1,abs(cash_effective_PL),null,
--                sysdate,sysdate,30699999,
--                10200001,23800002,CASH_PORTOFLIO_CODE,CASH_SUBPORTFOLIO_CODE
--            from TRTRAN111
--            where cash_effective_PL >0
--            --and cash_effective_date ='27-Dec-2021'
--            and cash_Record_Status not in (10200005,10200006)
--            and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER 
--                                 FROM TRTRAN111_MAIN 
--                                 WHERE AHPM_REFERENCE_NUMBER=varReference
--                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
--    varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);            
--  -- IND AS Accoount Reversal
--    insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type,BCAC_PORTFOLIO_CODE,BCAC_SUBPORTFOLIO_CODE)
--           select cash_company_code,Cash_location_code,cash_bank_code,varTemp,
--                CASH_EFFECTIVE_DATE,( case when cash_effective_PL>0 then 14600002 else 14600001 end ),
--                24900004,24800003,varReference,
--                1,30400003,abs(cash_effective_PL),
--                1,abs(cash_effective_PL),null,
--                sysdate,sysdate,30699999,
--                10200001,23800002,CASH_PORTOFLIO_CODE,CASH_SUBPORTFOLIO_CODE
--            from TRTRAN111
--            where cash_effective_PL >0
--            --and cash_effective_date ='27-Dec-2021'
--            and cash_Record_Status not in (10200005,10200006)
--            and CASH_AMTM_REFERENCENUMBER in (SELECT AHPM_AMTM_REFERENCENUMBER 
--                                 FROM TRTRAN111_MAIN 
--                                 WHERE AHPM_REFERENCE_NUMBER=varReference
--                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));






--    GLOG.log_Write('Insert record into trtran008'); 
--    
--    SELECT CASH_COMPANY_CODE,CASH_LOCATION_CODE,CASH_BANK_CODE
--    into numCode,numCode1,numCode2
--    FROM TRTRAN111 
--    where CASH_AMTM_REFERENCENUMBER IN (SELECT AHPM_AMTM_REFERENCENUMBER 
--                                        FROM TRTRAN111_MAIN 
--                                        WHERE AHPM_REFERENCE_NUMBER=varReference
--                                        AND AHPM_RECORD_STATUS NOT IN (10200005,10200006))
--    and CASH_RECORD_STATUS NOT IN (10200005,10200006)
--    AND Rownum =1;
--    
--    varTemp := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);
--    GLOG.log_Write('Generated voucher serial - '|| varTemp);
--    insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type, bcac_account_number, bcac_bank_reference,BCAC_ENTRY_DETAIL)
----            values(numCompany, numLocation, numBank, varVoucher, datTransDate,
----            numCrdr, numHead, numType, varReference, numSerial, numCurrency,
----            numFcy, numRate, numInr,varDetail , sysdate,sysdate, numMerchant, GConst.STATUSENTRY,
----            numRecord, varAccount, varBankRef,xmltype(clbentrydetails));
--            values (numCode,numCode1,numCode2,varTemp,SYSDATE,14699999,
--            24999999,24899999,'DEALNUMBER',1,30499999,0,70,0,NULL,sysdate,sysdate,30699999,10200001,
--            23800002,0,null,null);

    end if;

    if numAction = GConst.UNCONFIRMSAVE then
    update TRTRAN111 set CASH_RECORD_STATUS=10200004
    where CASH_AMTM_REFERENCENUMBER IN (SELECT AHPM_AMTM_REFERENCENUMBER 
                                        FROM TRTRAN111_MAIN 
                                        WHERE AHPM_REFERENCE_NUMBER=varReference
                                        AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));

    update TRTRAN111_DETAIL set CASH_RECORD_STATUS=10200004
    where CASH_AMTM_REFERENCE IN (SELECT AHPM_AMTM_REFERENCENUMBER 
                                 FROM TRTRAN111_MAIN 
                                 WHERE AHPM_REFERENCE_NUMBER=varReference
                                 AND AHPM_RECORD_STATUS NOT IN (10200005,10200006));
    end if;
end if;

-- abhijit added on 28/08/2012 for exchange mtm upload


      --abhijit added
    if EditType =SYSEXCHMTMUPDATE then --Added By Sivadas on 18DEC2011
           ---insert into temp values('siva', 'Misc updates');commit;

           begin
               datWorkDate   := GConst.fncXMLExtract(xmlTemp, 'NSER_UPLOAD_DATE', datWorkDate);
               numSerial := to_number(GConst.fncXMLExtract(xmlTemp, 'NSER_SERIAL_NUMBER', numSerial));
               varReference := GConst.fncXMLExtract(xmlTemp, 'NSER_BATCH_NUMBER', varReference);

               --insert into temp values('siva', 'Delete calling');commit;
               if numSerial = 1 then
                  delete from trtran077
                   where nser_upload_date=datWorkDate
                     and NSER_BATCH_NUMBER <> varReference;

                  --insert into temp values('siva', 'Delete called!');
                  --commit;
               end if;
         exception
           when others then
              null;
               --insert into temp values('EXCHNG', 'Exception1');
              --commit;
           end;
    end if;

if EditType =SYSSTRESSINSERTSUB then
      varReference := GConst.fncXMLExtract(xmlTemp, 'STRE_REFERENCE_NUMBER', varTemp);
      varOperation := 'Data into Child Table';
     -- varXPath := '//STRESSTESTSENSITIVESUB/ROWSUB';
      varXPath := '//PriceInfo/DROW';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      numTemp:=1;
      varOperation := 'Data into Child Table';

  if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then  

      Delete from trsystem061
       where stre_reference_number=varReference;

      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));

          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/CurrencyPair';
          varoperation :='Extracting Data from XML' || varTemp;
          numCode3 := GConst.fncXMLExtract(xmlTemp,varTemp,numCode3, Gconst.TYPENODEPATH);

    begin
         select CNDI_BASE_CURRENCY,CNDI_OTHER_CURRENCY
            into numCode,numCode1
          from TRMASTER256
        where CNDI_PICK_CODE=numCode3
        and CNDI_record_status not in (10200005,10200006);
    exception 
            when others then
            numCode := 30499999;
            numCode1 := 30499999;
            end;
--          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/BaseCurrency';
--          varoperation :='Extracting Data from XML' || varTemp;
--          numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode, Gconst.TYPENODEPATH);

--          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/OtherCurrency';
--          varoperation :='Extracting Data from XML' || varTemp;
--          numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp,numCode1, Gconst.TYPENODEPATH);

          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/ForwardMonth';
          varoperation :='Extracting Data from XML' || varTemp;
          numCode2 := GConst.fncXMLExtract(xmlTemp,varTemp,numCode2, Gconst.TYPENODEPATH);

          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PriceChange';
          varoperation :='Extracting Data from XML' || varTemp;
          numFCY := GConst.fncXMLExtract(xmlTemp,varTemp,numFCY, Gconst.TYPENODEPATH);
        varOperation := 'Insertting data into Child Table' ;
          insert into trsystem061
           values (varReference,numCode,numCode1,numCode2,numFCY);

         numTemp:=numTemp+1;
      end loop;

  elsif numAction in (GConst.DELETESAVE) then  
          Delete from trsystem061
             where stre_reference_number=varReference;
      end if;
   end if;

   --------Stress Analysis Ends---------------

-- Following Logic is for Mutual Fund Redemtion - Both for Switch-in
-- as well as regular redemption options - TMM 07/12/2014

    If Edittype = SYSHEDGELINKINGCANCEL Then
        VarOperation:= 'Extracting Linking CancellationDeals';
        --Numcode:= GCONST.FNCXMLEXTRACT(xmlTemp, 'LinkingCancelledDeals', Numcode);
        Numcode:=12400002;
        VarOperation:= ' Exhecing Numcode' || Numcode;



        if Numcode= Gconst.OptionYes then

                    varXPath := '//HEDGEREGISTER/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Extracting Rows ' || varXPath;
          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/HEDG_TRADE_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              VARREFERENCE := GCONST.FNCXMLEXTRACT(xmlTemp,varTemp, VARREFERENCE,Gconst.TYPENODEPATH);
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/HEDG_DEAL_NUMBER';
              varoperation :='Extracting Data from XML' || varTemp;
              VARREFERENCE1 := GCONST.FNCXMLEXTRACT(xmlTemp, varTemp, VARREFERENCE1,Gconst.TYPENODEPATH);

                update trtran004 set Hedg_record_status=10200010
                 where HEDG_TRADE_REFERENCE= VARREFERENCE
                 and HEDG_DEAL_NUMBER= VARREFERENCE1;
            end loop;
        end if;
     END IF;

    If Edittype = SYSRBIREFRATE Then
        VarOperation:= 'Extracting Linking CancellationDeals';
        if  numAction = GConst.ADDSAVE then       
          varXPath := '//RBIREFERENCERATE/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Extracting Rows ' || varXPath;
          for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop
              nodTemp := xmlDom.Item(nlsTemp, numSub);
              nmpTemp:= xmlDom.getAttributes(nodTemp);
              nodTemp := xmlDom.Item(nmpTemp, 0);
              numTemp := to_number(xmlDom.GetNodeValue(nodTemp));

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/CurrencyCode';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/EffectiveDate';
              varoperation :='Extracting Data from XML' || varTemp;
              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp,datTemp, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/Rate';
              varoperation :='Extracting Data from XML' || varTemp;
              numRate := GConst.fncXMLExtract(xmlTemp,varTemp,numRate, Gconst.TYPENODEPATH);
              insert into TRSYSTEM017
              (lrat_currency_code,lrat_for_currency,lrat_effective_date,
              lrat_serial_number,LRAT_RBI_USD,lrat_record_status,lrat_add_date)
              values (numCode,30400003,datTemp,1,numRate,10200003,sysdate);
          end loop;
       END IF; 
     END IF;

if EditType=Gconst.SYSBANKCHARGEINSERT then 
          varOperation := 'Add records to sub tables';

        --  varTemp2 := '//BANKCHARGESFORPERIOD//ROW';  
    --      nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          varreference:=GConst.fncXMLExtract(xmlTemp, 'CHAR_REFERENCE_NUMBER', varreference);     
          varTemp3:=GConst.fncXMLExtract(xmlTemp, 'CHAR_SCREEN_NAMES', varTemp3); 
          varTemp4:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CHARGE_EVENTS', varTemp4);
--          numcode:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_COMPANY_CODE', numcode);
--          numcode1:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOCATION_CODE', numcode1);
--        --  numcode2:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOB_CODE', numcode2);
--           numcode2:=  33399999;
--          numSerial:=GConst.fncXMLExtract(xmlTemp, 'CHAR_SERIAL_NUMBER', numSerial);
--          numcode3:=GConst.fncXMLExtract(xmlTemp,'CHAR_BANK_CODE',numcode3);          
--          datTemp:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_EFFECTIVE_DATE', datTemp); 
--          numcode4:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ACCOUNT_HEAD', numcode4);           
--          numcode5:=GConst.fncXMLExtract(xmlTemp, 'CHAR_LIMIT_TYPE', numcode5);
--          numcode6:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BILL_EVENT', numcode6);
--          numcode7:=GConst.fncXMLExtract(xmlTemp, 'CHAR_TIMING_EVENT', numcode7);
--          numcode8:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ROUNDING_UPTO', numcode8);        
--          numcode9:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CHARGING_EVENT', numcode9);          
--          numcode10:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BASED_ON', numcode10);
--          numcode11:=GConst.fncXMLExtract(xmlTemp, 'CHAR_PRODUCT_TYPE', numcode11);
--          numcode12:=GConst.fncXMLExtract(xmlTemp, 'CHAR_APPLICABLE_BILL', numcode12);          
--          numcode13:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MIN_AMOUNT', numcode13);
--          numcode14:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MAX_AMOUNT', numcode14); 
--          numCode15:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CONSOLIDATE_TYPE', numcode15); 
    if  numAction in(GConst.ADDSAVE, GConst.EDITSAVE) then
--          delete from trtran015d 
--          where CHAR_REFERENCE_NUMBER=varreference; 

          update trtran015E
          set chad_record_status=10200006
          where CHAD_REFERENCE_NUMBER=varreference;

           begin 
            select nvl(count(*),0)+1
              into numSerial1
              from trtran015E
             where CHAD_REFERENCE_NUMBER=varreference; 
          exception
            when no_data_found then 
              numSerial1:=1;
          end ;

          varTemp2 := '//PERIODTYPENODE//DROW';       
          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          --numSerial:=1;
          if(xmlDom.getLength(nlsTemp)>0) then

          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/PeriodType';
              varoperation :='Extracting Data from XML' || varTemp;
              numPeriodType := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodType, Gconst.TYPENODEPATH);
               Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/PeriodUpto';
              varoperation :='Extracting Data from XML' || varTemp;
              numPeriodUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodUpto, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/AmountFrom';
              varoperation :='Extracting Data from XML' || varTemp;
              numAmountFrom := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountFrom, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/AmountUpto';
              varoperation :='Extracting Data from XML' || varTemp;
              numAmountUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountUpto, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/PercentType';
              varoperation :='Extracting Data from XML' || varTemp;
              numPercentType := GConst.fncXMLExtract(xmlTemp, varTemp, numPercentType, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/ChargesAmount';
              varoperation :='Extracting Data from XML' || varTemp;
              numCharges := GConst.fncXMLExtract(xmlTemp, varTemp, numCharges, Gconst.TYPENODEPATH);

--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ServiceTax';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numRate := GConst.fncXMLExtract(xmlTemp, varTemp, numRate, Gconst.TYPENODEPATH);

              varoperation :='Inserting Data into BankChargeMaster table';
              insert into trtran015e (CHAD_REFERENCE_NUMBER,CHAD_SERIAL_NUMBER,CHAD_PERIOD_TYPE,CHAD_PERIOD_UPTO,CHAD_AMOUNT_FROM,
              CHAD_AMOUNT_UPTO,CHAD_PERCENT_TYPE,CHAD_CHARGES_AMOUNT,CHAD_RECORD_STATUS,CHAD_CREATE_DATE,CHAD_ADD_DATE,CHAD_ENTRY_DETAILS)
              Values(varreference, numSerial1, numPeriodType, numPeriodUpto, numAmountFrom, numAmountUpto, numPercentType, numCharges,
              10200001, sysdate, sysdate, null);

               numSerial1:=numSerial1+1;

--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                   Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,numPeriodType,nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),numPercentType,
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
--                                            );

          end loop;
--          else
--          varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                     Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,nvl(numPeriodType,23499999),nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),nvl(numPercentType,33799999),
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
--                                            );
      end if;
--        varTemp2 := '//ScreenNameNode//ROW';       
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);   

--          delete from trtran015e
--        where chga_ref_number=varreference;  
          update trtran015G
          set chas_record_status=10200006
          where CHAS_REFERENCE_NUMBER=varreference;

        begin 
            select nvl(count(*),0)+1
              into numSerial
              from trtran015G
             where CHAS_REFERENCE_NUMBER=varreference; 
          exception
            when no_data_found then 
              numSerial:=1;
          end ;

--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop  
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ScreenName';
--              varoperation :='Extracting Data from XML' || varTemp;
--              Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
--              
--             varoperation :='Inserting screen details into BankChargeLinking table';
--             
--             insert into trtran015G(CHAS_REFERENCE_NUMBER, CHAS_SERIAL_NUMBER, CHAS_SCREEN_NAME, CHAS_RECORD_STATUS, CHAS_CREATE_DATE,
--             CHAS_ADD_DATE, CHAS_ENTRY_DETAILS)
--              Values(varreference, numSerial, Varreference1, 10200001, sysdate, sysdate, null);
--              
--              numSerial:= numSerial + 1;
----             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
----                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
----                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
----                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
----                                    Values(numcode,numcode3,datTemp,numcode4,
----                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
----                                    null,10200001,numCurrency,numcode5,
----                                    numcode1,numcode2,varreference);
--                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
--          end loop;   

          FOR curEnt IN (SELECT DISTINCT REGEXP_SUBSTR (varTemp3,'[^,]+',1,LEVEL) as entity
                            FROM   DUAL
                            CONNECT BY REGEXP_SUBSTR (varTemp3,'[^,]+',1,LEVEL) IS NOT NULL
              order by 1)
              LOOP
              BEGIN  

            insert into trtran015G(CHAS_REFERENCE_NUMBER, CHAS_SERIAL_NUMBER, CHAS_SCREEN_NAME, CHAS_RECORD_STATUS, CHAS_CREATE_DATE,
             CHAS_ADD_DATE, CHAS_ENTRY_DETAILS)
              Values(varreference, numSerial, curEnt.entity, 10200001, sysdate, sysdate, null);

              numSerial:= numSerial + 1;              

              END;
            END LOOP;

--        varTemp2 := '//ChargeEventNode//ROW';       
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);   


          update trtran015F
          set chae_record_status=10200006
          where CHAE_REFERENCE_NUMBER=varreference;

        begin 
            select nvl(count(*),0)+1
              into numSerial2
              from trtran015F
             where CHAE_REFERENCE_NUMBER=varreference; 
          exception
            when no_data_found then 
              numSerial2:=1;
          end ;

--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop  
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargeEvent';
--              varoperation :='Extracting Data from XML' || varTemp;
--              varTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp1, Gconst.TYPENODEPATH);
--             varoperation :='Inserting event details into BankChargeLinking table';
--             
--             insert into trtran015F(CHAE_REFERENCE_NUMBER, CHAE_SERIAL_NUMBER, CHAE_CHARGE_EVENT, CHAE_RECORD_STATUS, CHAE_CREATE_DATE,
--              CHAE_ADD_DATE, CHAE_ENTRY_DETAILS)
--              Values(varreference, numSerial2, varTemp1, 10200001, sysdate, sysdate, null);
--                          
--              numSerial2:= numSerial2 + 1;
----             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
----                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
----                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
----                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
----                                    Values(numcode,numcode3,datTemp,numcode4,
----                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
----                                    null,10200001,numCurrency,numcode5,
----                                    numcode1,numcode2,varreference);
--                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
--          end loop;   
--    


      FOR curEnt IN (SELECT DISTINCT REGEXP_SUBSTR (varTemp4,'[^,]+',1,LEVEL) as event
                            FROM   DUAL
                            CONNECT BY REGEXP_SUBSTR (varTemp4,'[^,]+',1,LEVEL) IS NOT NULL
              order by 1)
              LOOP
              BEGIN  
            insert into trtran015F(CHAE_REFERENCE_NUMBER, CHAE_SERIAL_NUMBER, CHAE_CHARGE_EVENT, CHAE_RECORD_STATUS, CHAE_CREATE_DATE,
              CHAE_ADD_DATE, CHAE_ENTRY_DETAILS)
              Values(varreference, numSerial2, curEnt.event, 10200001, sysdate, sysdate, null);

              numSerial2:= numSerial2 + 1;                    

              END;
            END LOOP;
      elsif  numAction in(GConst.DELETESAVE) then

          update trtran015e
          set chad_record_status=10200006
          where CHAD_REFERENCE_NUMBER=varreference;

          update trtran015f
          set chae_record_status=10200006
          where CHAE_REFERENCE_NUMBER=varreference;

          update trtran015g
          set chas_record_status=10200006
          where CHAS_REFERENCE_NUMBER=varreference;
         -- commit;

  elsif  numAction in(GConst.CONFIRMSAVE) then

          update trtran015e
          set chad_record_status=10200003
          where CHAD_REFERENCE_NUMBER=varreference;

          update trtran015f
          set chae_record_status=10200003
          where CHAE_REFERENCE_NUMBER=varreference;

          update trtran015g
          set chas_record_status=10200003
          where CHAS_REFERENCE_NUMBER=varreference;
      --    commit;       

  end if;
end if;

if EditType = SYSBANKCHARGECONFIGPROCESS then 
          varOperation := 'Add records to sub tables';

          varreference:=GConst.fncXMLExtract(xmlTemp, 'ACCT_REFERENCE_NUMBER', varreference); 
          numSerial:=GConst.fncXMLExtract(xmlTemp, 'ACCT_SERIAL_NUMBER', numSerial);

           if  numAction in(GConst.ADDSAVE, GConst.EDITSAVE) then

        update TRCONFIG002A 
          set ACCD_RECORD_STATUS=10200006
          where ACCD_REFERENCE_NUMBER=varreference; 

           begin 
            select nvl(count(*),0)+1
              into numSerial1
              from TRCONFIG002A
             where ACCD_REFERENCE_NUMBER=varreference; 
          exception
            when no_data_found then 
              numSerial1:=1;
          end ;

           varTemp2 := '//CONFIGDETAILS//DROW';       
          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          --numSerial:=1;
          if(xmlDom.getLength(nlsTemp)>0) then

          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop
              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/AccountHead';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);
               Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/CreditDebit';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/BankReference';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp3 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp3, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/Amount';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp4 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp4, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/ExchangeRate';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp5 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp5, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/Currency';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp6 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp6, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/VoucherCurrency';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode3 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode3, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);

              varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/ChangeCreditDebit';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode4 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode4, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);

               varTemp := varTemp2 || '[@DNUM="' || numTemp || '"]/ChangeRecordType';
              varoperation :='Extracting Data from XML' || varTemp;
              numcode5 := GConst.fncXMLExtract(xmlTemp, varTemp, numcode5, Gconst.TYPENODEPATH);
              Glog.log_write(varTemp);             

              varoperation :='Inserting Data into BankChargeConfig table';
              insert into TRCONFIG002A(ACCD_REFERENCE_NUMBER, ACCD_SERIAL_NUMBER, ACCD_SUBSERIAL_NUMBER, ACCD_ACCOUNT_HEAD, ACCD_CRDR_COLUMN,
                ACCD_AMOUNT_COLUMN, ACCD_BANKREF_COLUMN, ACCD_CURRENCY_COLUMN, ACCD_EXCHANGERATE_COLUMN, ACCD_VOUCHER_CURRENCY, ACCD_CHNG_CRDR, 
                ACCD_CHNG_CHRG_COLLECTION, ACCD_RECORD_STATUS, ACCD_CREATE_DATE, ACCD_ADD_DATE, ACCD_ENTRY_DETAILS)              
              Values(varreference, numSerial, numSerial1, numCode1, numCode2, varTemp4, varTemp3, varTemp6, varTemp5, numCode3, numCode4, numcode5, 10200001, sysdate, sysdate, null);

               numSerial1:=numSerial1+1;

          end loop;
      end if;    
    end if;
End if;

if EditType = SYSBULKCONFIRMATIONPROCESS then 
          varOperation := 'uPDATE remarks in trtran008';          

          -- if  numAction in(GConst.CONFIRMSAVE) then

          BEGIN
          varTemp1 :=  GConst.fncXMLExtract(xmlTemp, '//VOUCHERREMARKS//DROW[@DNUM="1"]/Remarks', varTemp1, Gconst.TYPENODEPATH);
         exception
            when others then 
              varTemp1:= null;
          end ;

          BEGIN
          varTemp5 :=  GConst.fncXMLExtract(xmlTemp, '//VOUCHERREMARKS//DROW[@DNUM="1"]/AccNumber', varTemp5, Gconst.TYPENODEPATH);
         exception
            when others then 
              varTemp5:= '';
          end ;

          BEGIN
          datTemp1 :=  GConst.fncXMLExtract(xmlTemp, '//VOUCHERREMARKS//DROW[@DNUM="1"]/ConfirmUnConfirmDate', datTemp1, Gconst.TYPENODEPATH);
         exception
            when others then 
              datTemp1:= sysdate;
          end ;

          varTemp2 := '//BULKCONFIRMATION//ROW';       
          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          --numSerial:=1;
          if(xmlDom.getLength(nlsTemp)>0) then
          Glog.log_write('Inside if'); 
          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop
           Glog.log_write('Inside for loop');
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/BCAC_VOUCHER_NUMBER';
              varoperation :='Extracting Data from XML' || varTemp;
              varreference := GConst.fncXMLExtract(xmlTemp, varTemp, varreference, Gconst.TYPENODEPATH);
             --  Glog.log_write(varTemp);             
           --    Glog.log_write(varreference);

               varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/BCAC_VOUCHER_INR';
              varoperation :='Extracting Data from XML' || varTemp;
              numINR := GConst.fncXMLExtract(xmlTemp, varTemp, numINR, Gconst.TYPENODEPATH);

                select BCAC_RECON_REMARKS
                into varTemp3
                from trtran008 
                where BCAC_VOUCHER_NUMBER = varreference
                and BCAC_RECORD_STATUS not in (10200005, 10200006);
                Glog.log_write(varTemp1);

--                if varTemp1 IS null then
--              --  CONTINUE;  
--                varTemp1 := null;
                if varTemp3 IS null then
                varTemp4 := varTemp1;
                else
                varTemp4 := CONCAT(varTemp3, ',');
                varTemp4 := CONCAT(varTemp4, varTemp1);
                END IF;
                Glog.log_write(varTemp4);     
              varoperation :='Updating remarks into trtran008 table';
              update TRTRAN008 
              set BCAC_RECON_REMARKS=varTemp4,
         --     BCAC_RECON_DATE = datTemp1,
              BCAC_ADD_DATE = datTemp1,
              BCAC_ACCOUNT_NUMBER = varTemp5,
              BCAC_VOUCHER_INR = numINR
              where BCAC_VOUCHER_NUMBER= varreference; 
     Glog.log_write('Updated remarks into trtran008 table');
          end loop;
      end if;  
     --     end if;
End if;       

--if EditType=Gconst.SYSBANKCHARGEINSERT then 
--          varOperation := 'Add multiple record to trtran015d';
--     
--          varTemp2 := '//BANKCHARGEMASTER//ROW';  
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
--          varreference:=GConst.fncXMLExtract(xmlTemp, 'CHAR_REFERENCE_NUMBER', varreference);          
--          numcode:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_COMPANY_CODE', numcode);
--          numcode1:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOCATION_CODE', numcode1);
--        --  numcode2:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOB_CODE', numcode2);
--           numcode2:=  33399999;
--          numSerial:=GConst.fncXMLExtract(xmlTemp, 'CHAR_SERIAL_NUMBER', numSerial);
--          numcode3:=GConst.fncXMLExtract(xmlTemp,'CHAR_BANK_CODE',numcode3);          
--          datTemp:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_EFFECTIVE_DATE', datTemp); 
--          numcode4:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ACCOUNT_HEAD', numcode4);           
--          numcode5:=GConst.fncXMLExtract(xmlTemp, 'CHAR_LIMIT_TYPE', numcode5);
--          numcode6:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BILL_EVENT', numcode6);
--          numcode7:=GConst.fncXMLExtract(xmlTemp, 'CHAR_TIMING_EVENT', numcode7);
--          numcode8:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ROUNDING_UPTO', numcode8);        
--          numcode9:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CHARGING_EVENT', numcode9);          
--          numcode10:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BASED_ON', numcode10);
--          numcode11:=GConst.fncXMLExtract(xmlTemp, 'CHAR_PRODUCT_TYPE', numcode11);
--          numcode12:=GConst.fncXMLExtract(xmlTemp, 'CHAR_APPLICABLE_BILL', numcode12);          
--          numcode13:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MIN_AMOUNT', numcode13);
--          numcode14:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MAX_AMOUNT', numcode14); 
--          numCode15:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CONSOLIDATE_TYPE', numcode15); 
--    if  numAction in(GConst.ADDSAVE) then
--          delete from trtran015d 
--          where CHAR_REFERENCE_NUMBER=varreference; 
--          
--          varTemp2 := '//PERIODTYPENODE//ROW';       
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
--          numSerial:=1;
--          if(xmlDom.getLength(nlsTemp)>0) then
--          
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodType := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountFrom';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountFrom := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountFrom, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PercentType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPercentType := GConst.fncXMLExtract(xmlTemp, varTemp, numPercentType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargesAmount';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCharges := GConst.fncXMLExtract(xmlTemp, varTemp, numCharges, Gconst.TYPENODEPATH);
--              
--              varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                   Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,numPeriodType,nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),numPercentType,
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
--                                            );
--                                            numSerial:=numSerial+1;
--          end loop;
--          else
--          varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                     Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,nvl(numPeriodType,23499999),nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),nvl(numPercentType,33799999),
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
--                                            );
--      end if;
--        varTemp2 := '//ScreenNameNode//ROW';       
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);   
--        
--          delete from trtran015e
--        where chga_ref_number=varreference;  
--     
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop  
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ScreenName';
--              varoperation :='Extracting Data from XML' || varTemp;
--              Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargeEventnew';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numChargeEvent := GConst.fncXMLExtract(xmlTemp, varTemp, numChargeEvent, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/CurrencyCode';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCurrency := GConst.fncXMLExtract(xmlTemp, varTemp, numCurrency, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/SanctionApplied';
--              varoperation :='Extracting Data from XML' || varTemp;
--              varSanctionApplied := GConst.fncXMLExtract(xmlTemp, varTemp, varSanctionApplied, Gconst.TYPENODEPATH);
--              
--             varoperation :='Inserting Data into BankChargeLinking table';
--             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
--                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
--                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
--                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
--                                    Values(numcode,numcode3,datTemp,numcode4,
--                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
--                                    null,10200001,numCurrency,numcode5,
--                                    numcode1,numcode2,varreference);
--                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
--          end loop;
--        
--    elsif  numAction in(GConst.EDITSAVE) then
----          update trtran015d 
----          set char_record_status=10200006
----          where CHAR_REFERENCE_NUMBER=varreference; 
----          
----          update tftran015e
----           set chga_record_status=10200006,CHGA_ENTRY_DETAIL=null
----           where chga_ref_number=varreference; 
--          
----          varreference:= pkgGlobalMethods.fncGenerateSerial(GConst.SEARIALCHARGE, nodFinal);
----          varreference:='BCHA/'||varreference;
--       --insert into temp2 values(varreference||'inside edit save'); 
--              insert into trtran015d_audit select * from trtran015d where CHAR_REFERENCE_NUMBER=varreference
--              and char_record_status not in(10200005,10200006);commit;
--          --   insert into temp2 values(varreference||'123'); 
--              delete from trtran015d where CHAR_REFERENCE_NUMBER=varreference;commit;
--             -- insert into temp2 values(varreference||'345');
--               insert into trtran015e_audit select * from trtran015e where chga_ref_number=varreference
--              and chga_record_status not in(10200005,10200006);commit;
--              
--              delete from trtran015e where chga_ref_number=varreference;commit;
--          
--          varTemp2 := '//PERIODTYPENODE//ROW';       
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
--          numSerial:=1;
--        if(xmlDom.getLength(nlsTemp)>0) then
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodType := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountFrom';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountFrom := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountFrom, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PercentType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPercentType := GConst.fncXMLExtract(xmlTemp, varTemp, numPercentType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargesAmount';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCharges := GConst.fncXMLExtract(xmlTemp, varTemp, numCharges, Gconst.TYPENODEPATH);
--              
--              varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                     Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,numPeriodType,nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),numPercentType,
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numcode15
--                                            );
--                                            numSerial:=numSerial+1;
--                                         --    insert into temp2 values(numSerial||'999');
--          end loop;
--          else
--         -- insert into temp values(varreference||'Hari');
--           varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                     Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,nvl(numPeriodType,23499999),nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),nvl(numPercentType,33799999),
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numcode15
--                                            );
--          end if;
--          
--        varTemp2 := '//ScreenNameNode//ROW';       
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);  
--      
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop  
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ScreenName';
--              varoperation :='Extracting Data from XML' || varTemp;
--              Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargeEventnew';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numChargeEvent := GConst.fncXMLExtract(xmlTemp, varTemp, numChargeEvent, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/CurrencyCode';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCurrency := GConst.fncXMLExtract(xmlTemp, varTemp, numCurrency, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/SanctionApplied';
--              varoperation :='Extracting Data from XML' || varTemp;
--              varSanctionApplied := GConst.fncXMLExtract(xmlTemp, varTemp, varSanctionApplied, Gconst.TYPENODEPATH);
--              
--             varoperation :='Inserting Data into BankChargeLinking table';
--             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
--                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
--                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
--                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
--                                    Values(numcode,numcode3,datTemp,numcode4,
--                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
--                                    null,10200001,numCurrency,numcode5,
--                                    numcode1,numcode2,varreference);
--                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
--          end loop;
--      elsif  numAction in(GConst.DELETESAVE) then
--     
----          update trtran015d
----          set char_record_status=10200006,CHAR_ENTRY_DETAIL=null
----          where CHAR_REFERENCE_NUMBER=varreference;
----           
----           update tftran015e
----           set chga_record_status=10200006,CHGA_ENTRY_DETAIL=null
----           where chga_ref_number=varreference;  
--            insert into trtran015d_audit select * from trtran015d where CHAR_REFERENCE_NUMBER=varreference
--              and char_record_status not in(10200005,10200006);commit;
--            
--              delete from trtran015d where CHAR_REFERENCE_NUMBER=varreference;commit;
--              
--               insert into trtran015e_audit select * from trtran015e where chga_ref_number=varreference
--              and chga_record_status not in(10200005,10200006);commit;
--              
--              delete from trtran015e where chga_ref_number=varreference;commit;
--              
--  elsif  numAction in(GConst.CONFIRMSAVE) then
--     
--          update trtran015d
--          set char_record_status=10200003,CHAR_ENTRY_DETAIL=null
--          where CHAR_REFERENCE_NUMBER=varreference;
--           
--           update trtran015e
--           set chga_record_status=10200003,CHGA_ENTRY_DETAIL=null
--           where chga_ref_number=varreference;        
--               
--  end if;
--end if;

-- if EditType=SYSBANKCHARGEINSERT then 
--          varOperation := 'Add multiple record to trtran015d';
--     
--          varTemp2 := '//BANKCHARGEMASTERNEW//ROW';  
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
--          varreference:=GConst.fncXMLExtract(xmlTemp, 'CHAR_REFERENCE_NUMBER', varreference);          
--          numcode:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_COMPANY_CODE', numcode);
--          numcode1:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOCATION_CODE', numcode1);
--        --  numcode2:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOB_CODE', numcode2);
--           numcode2:=  33399999;
--          numSerial:=GConst.fncXMLExtract(xmlTemp, 'CHAR_SERIAL_NUMBER', numSerial);
--          numcode3:=GConst.fncXMLExtract(xmlTemp,'CHAR_BANK_CODE',numcode3);          
--          datTemp:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_EFFECTIVE_DATE', datTemp); 
--          numcode4:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ACCOUNT_HEAD', numcode4);           
--          numcode5:=GConst.fncXMLExtract(xmlTemp, 'CHAR_LIMIT_TYPE', numcode5);
--          numcode6:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BILL_EVENT', numcode6);
--          numcode7:=GConst.fncXMLExtract(xmlTemp, 'CHAR_TIMING_EVENT', numcode7);
--          numcode8:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ROUNDING_UPTO', numcode8);        
--          numcode9:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CHARGING_EVENT', numcode9);          
--          numcode10:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BASED_ON', numcode10);
--          numcode11:=GConst.fncXMLExtract(xmlTemp, 'CHAR_PRODUCT_TYPE', numcode11);
--          numcode12:=GConst.fncXMLExtract(xmlTemp, 'CHAR_APPLICABLE_BILL', numcode12);          
--          numcode13:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MIN_AMOUNT', numcode13);
--          numcode14:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MAX_AMOUNT', numcode14); 
--          numCode15:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CONSOLIDATE_TYPE', numcode15); 
--    if  numAction in(GConst.ADDSAVE) then
--          delete from trtran015d 
--          where CHAR_REFERENCE_NUMBER=varreference; 
--          
--          varTemp2 := '//PERIODTYPENODE//ROW';       
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
--          numSerial:=1;
--          if(xmlDom.getLength(nlsTemp)>0) then
--          
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodType := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountFrom';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountFrom := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountFrom, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PercentType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPercentType := GConst.fncXMLExtract(xmlTemp, varTemp, numPercentType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargesAmount';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCharges := GConst.fncXMLExtract(xmlTemp, varTemp, numCharges, Gconst.TYPENODEPATH);
--              
--              varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                   Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,numPeriodType,nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),numPercentType,
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
--                                            );
--                                            numSerial:=numSerial+1;
--          end loop;
--          else
--          varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                     Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,nvl(numPeriodType,23499999),nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),nvl(numPercentType,33799999),
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
--                                            );
--      end if;
--        varTemp2 := '//ScreenNameNode//ROW';       
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);   
--        
--          delete from trtran015e
--        where chga_ref_number=varreference;  
--     
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop  
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ScreenName';
--              varoperation :='Extracting Data from XML' || varTemp;
--              Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargeEventnew';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numChargeEvent := GConst.fncXMLExtract(xmlTemp, varTemp, numChargeEvent, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/CurrencyCode';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCurrency := GConst.fncXMLExtract(xmlTemp, varTemp, numCurrency, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/SanctionApplied';
--              varoperation :='Extracting Data from XML' || varTemp;
--              varSanctionApplied := GConst.fncXMLExtract(xmlTemp, varTemp, varSanctionApplied, Gconst.TYPENODEPATH);
--              
--             varoperation :='Inserting Data into BankChargeLinking table';
--             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
--                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
--                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
--                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
--                                    Values(numcode,numcode3,datTemp,numcode4,
--                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
--                                    null,10200001,numCurrency,numcode5,
--                                    numcode1,numcode2,varreference);
--                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
--          end loop;
--        
--    elsif  numAction in(GConst.EDITSAVE) then
----          update trtran015d 
----          set char_record_status=10200006
----          where CHAR_REFERENCE_NUMBER=varreference; 
----          
----          update tftran015e
----           set chga_record_status=10200006,CHGA_ENTRY_DETAIL=null
----           where chga_ref_number=varreference; 
--          
----          varreference:= Gconst.fncGenerateSerial(GConst.SEARIALCHARGE, nodFinal);
----          varreference:='BCHA/'||varreference;
--       --insert into temp2 values(varreference||'inside edit save'); 
--              insert into trtran015d_audit select * from trtran015d where CHAR_REFERENCE_NUMBER=varreference
--              and char_record_status not in(10200005,10200006);commit;
--          --   insert into temp2 values(varreference||'123'); 
--              delete from trtran015d where CHAR_REFERENCE_NUMBER=varreference;commit;
--             -- insert into temp2 values(varreference||'345');
--               insert into trtran015e_audit select * from trtran015e where chga_ref_number=varreference
--              and chga_record_status not in(10200005,10200006);commit;
--              
--              delete from trtran015e where chga_ref_number=varreference;commit;
--          
--          varTemp2 := '//PERIODTYPENODE//ROW';       
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
--          numSerial:=1;
--        if(xmlDom.getLength(nlsTemp)>0) then
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodType := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPeriodUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountFrom';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountFrom := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountFrom, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountUpto';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numAmountUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountUpto, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PercentType';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numPercentType := GConst.fncXMLExtract(xmlTemp, varTemp, numPercentType, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargesAmount';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCharges := GConst.fncXMLExtract(xmlTemp, varTemp, numCharges, Gconst.TYPENODEPATH);
--              
--              varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                     Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,numPeriodType,nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),numPercentType,
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numcode15
--                                            );
--                                            numSerial:=numSerial+1;
--                                         --    insert into temp2 values(numSerial||'999');
--          end loop;
--          else
--         -- insert into temp values(varreference||'Hari');
--           varoperation :='Inserting Data into BankChargeMaster table';
--                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
--                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
--                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
--                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
--                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
--                                     Values (numcode3,datTemp,numcode4,numcode5,
--                                            numcode12,nvl(numPeriodType,23499999),nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),nvl(numPercentType,33799999),
--                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
--                                            null,10200001,numcode9,numcode10,varreference,numcode11,
--                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numcode15
--                                            );
--          end if;
--          
--        varTemp2 := '//ScreenNameNode//ROW';       
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);  
--      
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--           Loop  
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ScreenName';
--              varoperation :='Extracting Data from XML' || varTemp;
--              Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargeEventnew';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numChargeEvent := GConst.fncXMLExtract(xmlTemp, varTemp, numChargeEvent, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/CurrencyCode';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numCurrency := GConst.fncXMLExtract(xmlTemp, varTemp, numCurrency, Gconst.TYPENODEPATH);
--              
--              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/SanctionApplied';
--              varoperation :='Extracting Data from XML' || varTemp;
--              varSanctionApplied := GConst.fncXMLExtract(xmlTemp, varTemp, varSanctionApplied, Gconst.TYPENODEPATH);
--              
--             varoperation :='Inserting Data into BankChargeLinking table';
--             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
--                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
--                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
--                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
--                                    Values(numcode,numcode3,datTemp,numcode4,
--                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
--                                    null,10200001,numCurrency,numcode5,
--                                    numcode1,numcode2,varreference);
--                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
--          end loop;
--      elsif  numAction in(GConst.DELETESAVE) then
--     
----          update trtran015d
----          set char_record_status=10200006,CHAR_ENTRY_DETAIL=null
----          where CHAR_REFERENCE_NUMBER=varreference;
----           
----           update tftran015e
----           set chga_record_status=10200006,CHGA_ENTRY_DETAIL=null
----           where chga_ref_number=varreference;  
--            insert into trtran015d_audit select * from trtran015d where CHAR_REFERENCE_NUMBER=varreference
--              and char_record_status not in(10200005,10200006);commit;
--            
--              delete from trtran015d where CHAR_REFERENCE_NUMBER=varreference;commit;
--              
--               insert into trtran015e_audit select * from trtran015e where chga_ref_number=varreference
--              and chga_record_status not in(10200005,10200006);commit;
--              
--              delete from trtran015e where chga_ref_number=varreference;commit;
--              
--  elsif  numAction in(GConst.CONFIRMSAVE) then
--     
--          update trtran015d
--          set char_record_status=10200003,CHAR_ENTRY_DETAIL=null
--          where CHAR_REFERENCE_NUMBER=varreference;
--           
--           update trtran015e
--           set chga_record_status=10200003,CHGA_ENTRY_DETAIL=null
--           where chga_ref_number=varreference;        
--               
--  end if;
--end if;
 if EditType=SYSFORWARDROLLOVERPROCESS then 

--64500001	Rollover
--64500002	Cancellation
  if  numAction in(GConst.ADDSAVE) then    
        -- if numCode1 in (64500002 then --Cancel
           varTemp2 := '//DealDetails//DROW';       
           nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);  

          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop  
                varxPath := '//DealDetails//DROW[@DNUM="' || numTemp || '"]';   
                varTemp := varxPath || '/DealNumber';
                varOperation:=' Extracting information from ' || varTemp;

                varoperation :='Extracting Data from XML' || varTemp;
                Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
              varOperation:=' Extracting information for Deal' || Varreference1;
              begin
               select nvl(max(cdel_deal_serial) +1,1) 
                 into numSerial
                 from trtran006
                 where cdel_deal_number=varReference1;
               exception
                 when no_data_found then
                 numSerial:=1;
              end ;

              varOperation:=' Extracting information for Deal from Base Table' || Varreference1; 
                 select max(DEAL_HEDGE_TRADE)
                 into numCode2
                 from trtran001
                 where deal_deal_number=varReference1;

              varOperation:=' Insert Data into Cancel Table for Deal' || Varreference1; 

              begin 
            varTemp4:=GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_REMARKS',vartemp);
         exception 
           when others then 
             varTemp4:='';
          end ;

          begin 
            varTemp5:=GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_REFERENCE',vartemp);
         exception 
           when others then 
             varTemp5:='';
          end ;

          begin 
            varTemp6:=GConst.fncXMLExtract(xmlTemp,'DEAR_DEALER_NAME',vartemp);
         exception 
           when others then 
             varTemp6:='';
          end ;
          numCode2 := GConst.fncXMLExtract(xmlTemp,'DEAR_CURRENCY_PAIR',numCode);

          SELECT CNDI_BASE_CURRENCY,CNDI_OTHER_CURRENCY ,CNDI_DIRECT_INDIRECT
          INTO numCode3, numCode4,numcode5
          FROM TRMASTER256 WHERE CNDI_PICK_CODE = numCode2
          and Cndi_Record_Status NOT IN (10200005, 10200006);

              insert into trtran006
                (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,
                 cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,
                 cdel_cancel_rate,cdel_other_amount,CDEL_FORWARD_RATE,CDEL_SPOT_RATE,CDEL_MARGIN_RATE,
                 cdel_cancel_inr,cdel_profit_loss,
                 CDEL_DEALER_NAME,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_record_status,
                 cdel_pandl_spot, cdel_pandl_usd,cdel_bank_reference,CDEL_ROLLOVER_REFERENCE,
                 CDEL_EDC_CHARGE,CDEL_CASHFLOW_DATE,CDEL_NPV_VALUE,CDEL_IRR_RATE,cdel_location_code)
             select GConst.fncXMLExtract(xmlTemp,'DEAR_COMPANY_CODE',numCode) cdel_company_code,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/DealNumber',varReference, Gconst.TYPENODEPATH) cdel_deal_number,
                     numSerial cdel_deal_serial, 1 cdel_reverse_serial,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp) cdel_cancel_date,
                     numCode2 cdel_deal_type ,27000001 cdel_cancel_type,
                     (case when numcode5=12400002 then 
                         GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_RATE',numFcy) /
                          GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH)
                         else GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH) end)
                         cdel_cancel_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_RATE',numFcy) cdel_cancel_rate,
                     --GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH) *
                    -- GConst.fncXMLExtract(xmlTemp,'DEAR_SPOT_RATE',numFcy) cdel_other_amount,
                     --GConst.fncXMLExtract(xmlTemp,'DEAR_OTHER_AMOUNT',numFcy) cdel_other_amount,
                     (case when numcode5=12400001 then 
                         GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_RATE',numFcy) *
                          GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH)
                         else GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH) end) cdel_other_amount,
--                     GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy) cdel_other_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_FORWARD',numFcy) CDEL_FORWARD_RATE,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_SPOT',numFcy) CDEL_SPOT_RATE,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_MARGIN',numFcy) CDEL_MARGIN_RATE,
                     0 cdel_cancel_inr,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/ProfitLoss',numFcy, Gconst.TYPENODEPATH) cdel_profit_loss,
                    -- GConst.fncXMLExtract(xmlTemp,'DEAR_DEALER_NAME',varReference) CDEL_DEALER_NAME,
                    varTemp6 CDEL_DEALER_NAME,
                    -- GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_REMARKS',varReference) cdel_dealer_remark,
                    varTemp4 cdel_dealer_remark,
                     to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3') cdel_time_stamp, sysdate cdel_create_date,
                     10200001 cdel_record_status,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CONVERSION_RATE',numFcy) cdel_pandl_spot,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CONVERSION_PANDL',numFcy) cdel_pandl_usd,
                    -- GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_REFERENCE',varReference) cdel_bank_reference,
                    varTemp5 cdel_bank_reference,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference) CDEL_ROLLOVER_REFERENCE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/EarlyDeliveryCharges',numFcy, Gconst.TYPENODEPATH) CDEL_EDC_CHARGE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/CashflowDate',datTemp, Gconst.TYPENODEPATH) CDEL_CASHFLOW_DATE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/NpvValue',numFcy, Gconst.TYPENODEPATH) CDEL_NPV_VALUE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/IrrRate',numFcy, Gconst.TYPENODEPATH) CDEL_NPV_VALUE,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_LOCATION_CODE',numCode) cdel_location_code
              from dual;

            varOperation:=' Update the Deal Linking table ' || Varreference1; 

            update trtran004 set HEDG_RECORD_STATUS= 10200010,
                                 HEDG_RollOVer_Reference= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference)
              where Hedg_deal_number= varReference1
              and hedg_record_Status not in (10200005,10200006);
           end loop;

        numCode1 := GConst.fncXMLExtract(xmlTemp,'DEAR_ROLLOVER_TYPE',numCode1);

         if numCode1=64500001 then --Rollover

         begin 
            varTemp1:=GConst.fncXMLExtract(xmlTemp,'DEAR_USER_REMARKS',vartemp);
         exception 
           when others then 
             varTemp1:='';
          end ;
           begin 
            varTemp3:= GConst.fncXMLExtract(xmlTemp,'DEAR_USER_REFERENCE',vartemp);
         exception 
           when others then 
             varTemp3:='';
          end ;  
        begin 
            varTemp7:=GConst.fncXMLExtract(xmlTemp,'DEAR_BANK_REFERENCE',vartemp);
         exception 
           when others then 
             varTemp7:='';
          end ;



          varOperation:=' Insert Deal into Base Table incase of Roll Over  ' || Varreference1; 
           varReference := 'FWD' || fncGenerateSerial(SERIALDEAL,numCompany);
            insert into trtran001
              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,
              deal_hedge_trade,deal_buy_sell,deal_swap_outright,
              deal_deal_type,deal_counter_party,deal_currency_pair,deal_base_currency,deal_other_currency,
              deal_forward_rate,deal_spot_rate,deal_margin_rate,deal_exchange_rate,deal_base_amount,
              deal_other_amount,DEAL_AMOUNT_LOCAL,deal_maturity_from,deal_maturity_date,
              DEAL_DEALER_NAME,deal_dealer_remarks,deal_time_stamp,deal_process_complete,
              deal_create_date,deal_record_status,
              deal_user_reference, deal_backup_deal,deal_init_code,deal_location_code,deal_maturity_code,DEAL_BANK_REFERENCE)
              select GConst.fncXMLExtract(xmlTemp,'DEAR_COMPANY_CODE',numCode) deal_company_code,
                      varReference deal_deal_number,1 deal_serial_number,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp) deal_execute_date,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_HEDGE_TRADE',numCode) deal_hedge_trade ,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_BUY_SELL',numCode) deal_buy_sell ,
                     25200002 deal_swap_outright,25400006  deal_deal_type,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_COUNTER_PARTYNEW',numCode) deal_counter_party,
                   GConst.fncXMLExtract(xmlTemp,'DEAR_CURRENCY_PAIR',numCode) deal_currency_pair,
                   numCode3 deal_base_currency,
                   numCode4 deal_other_currency,
                  -- GConst.fncXMLExtract(xmlTemp,'DEAR_BASE_CURRENCY',numCode) deal_base_currency,
                   -- GConst.fncXMLExtract(xmlTemp,'DEAR_OTHER_CURRENCY',numCode) deal_other_currency,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_FORWARD_RATE',numFcy) deal_forward_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_SPOT_RATE',numCode) deal_spot_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_MARGIN_RATE',numCode) deal_margin_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_EXCHNAGE_RATE',numCode) deal_exchange_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) deal_base_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_OTHER_AMOUNT',numCode) deal_other_amount,
--                     GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode)*
--                     GConst.fncXMLExtract(xmlTemp,'DEAR_EXCHNAGE_RATE',numCode) deal_other_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode)*
                     GConst.fncXMLExtract(xmlTemp,'DEAR_EXCHNAGE_RATE',numCode) DEAL_AMOUNT_LOCAL,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_EXPIRY_DATE',datTemp) deal_maturity_from,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_NEWMATURITY_DATE',datTemp) deal_maturity_date,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_DEALER_NAME',vartemp) DEAL_DEALER_NAME,
                     varTemp1 deal_dealer_remarks,
                     to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3') deal_time_stamp,
                     12400002 deal_process_complete,sysdate deal_create_date,10200001 deal_record_status,
                      varTemp3 deal_user_reference,
                        GConst.fncXMLExtract(xmlTemp,'DEAR_BACKUP_DEALNEW',numCode) deal_backup_deal,
                          GConst.fncXMLExtract(xmlTemp,'DEAR_INIT_CODENEW',numCode) deal_init_code,
                          GConst.fncXMLExtract(xmlTemp,'DEAR_LOCATION_CODENEW',numCode) deal_location_code,
                          25500005,
                          --GConst.fncXMLExtract(xmlTemp,'DEAR_BANK_REFERENCE',vartemp) DEAL_BANK_REFERENCE
                          varTemp7 DEAL_BANK_REFERENCE
                  from dual;

          varOperation:='Update Deal number to Roll Over Table';        
          update trtran001RA set  DEAR_NEWDEAL_NUMBER=varReference
            where DEAR_REFERENCE_NUMBER=GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference)
            and dear_record_Status not in (10200005,10200006);

          varOperation:=' start the loop to do Hedge Deal linking To Retain the Linkage ';
          numFCY:=0;
          for curHedges in (select HEDG_COMPANY_CODE,HEDG_TRADE_REFERENCE,HEDG_DEAL_NUMBER,
                HEDG_DEAL_SERIAL,HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,HEDG_CREATE_DATE,
                HEDG_RECORD_STATUS,HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY,HEDG_LOCATION_CODE,HEDG_LINKED_DATE,
                HEDG_TRADE_SERIAL,HEDG_BATCH_NUMBER,HEDG_ROLLOVER_REFERENCE
              from trtran004 inner join trtran001
               on HEDG_DEAL_NUMBER= deal_deal_number
                where HEDG_RECORD_STATUS not in (10200005,10200006)
                and HEDG_RollOVer_Reference= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference)
                and HEDG_LINKED_DATE >=GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp)
                and deal_record_status not in (102000005,102000006)
                order by Deal_maturity_date)       
            loop 
                numFCY:= numFCY+curHedges.HEDG_HEDGED_FCY;
                begin
                  select nvl(max(HEDG_SERIAL_NUMBER) +1,1)
                    into numSerial
                    from trtran004 
                    where HEDG_TRADE_REFERENCE= curHedges.HEDG_TRADE_REFERENCE
                    and HEDG_DEAL_NUMBER= varReference;
                exception
                 when no_data_found then
                 numSerial:=1;
              end ;
               -- if numFCY <=  GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) then
                    varOperation:=' Insert Deals into Hedge Deal linking To Retain the Linkage ' || Varreference1; 
                    insert into trtran004 (HEDG_COMPANY_CODE,HEDG_TRADE_REFERENCE,HEDG_DEAL_NUMBER,
                    HEDG_DEAL_SERIAL,HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,HEDG_CREATE_DATE,
                    HEDG_RECORD_STATUS,HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY,HEDG_LOCATION_CODE,HEDG_LINKED_DATE,
                    HEDG_TRADE_SERIAL,HEDG_BATCH_NUMBER,HEDG_ROLLOVER_REFERENCE,HEDG_SERIAL_NUMBER)
                    values (curHedges.HEDG_COMPANY_CODE,curHedges.HEDG_TRADE_REFERENCE,varReference,
                    1,(case when numFCY <=  GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) then
                          curHedges.HEDG_HEDGED_FCY else
                           GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) end)
                          ,curHedges.HEDG_OTHER_FCY,curHedges.HEDG_HEDGED_INR,sysdate,
                    10200003,curHedges.HEDG_HEDGING_WITH,curHedges.HEDG_MULTIPLE_CURRENCY,
                    GConst.fncXMLExtract(xmlTemp,'DEAR_LOCATION_CODENEW',numCode),
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp),
                    curHedges.HEDG_TRADE_SERIAL,curHedges.HEDG_BATCH_NUMBER, 
                    GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference),numSerial);
             end loop;
         end if;
  elsif numAction in(GConst.DELETESAVE) then 
     varReference:= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference);


       varOperation:='Update the Hedge Deal Linking' || Varreference;    
        update trtran004 set HEDG_RECORD_STATUS =10200006
          where HEDG_ROLLOVER_REFERENCE=varReference
          and HEDG_RECORD_STATUS not in (10200010,10200006);

        varOperation:='Update the Hedge Deal Linking Back to Orginal' || Varreference;    
        update trtran004 set HEDG_RECORD_STATUS =10200003
         where HEDG_Deal_number in 
            (select Cdel_DEAL_NUMBER from trtran006
              where cdel_RECORD_STATUS not in (10200005,10200006)
              and CDEL_ROLLOVER_REFERENCE=varReference)
          and HEDG_RECORD_STATUS =10200010;

        varOperation:='Update the Delete Status to Cancel Records ' || Varreference; 
        update trtran006 set cdel_record_status =10200006
          where CDEL_ROLLOVER_REFERENCE=varReference;

       varOperation:='Update the new deal to Delete status ' || Varreference;      
        update trtran001 set DEAL_RECORD_STATUS =10200006
         where DEAL_Deal_number in 
            (select DEAR_NEWDEAL_NUMBER from TRTRAN001RA
             -- where DEAR_RECORD_STATUS not in (10200005,10200006) -- record status in TRTRAN001RA would already been changed to 10200006
              where DEAR_REFERENCE_NUMBER=varReference); 


  elsif numAction in(GConst.CONFIRMSAVE) then     
       varReference:= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference);
      varOperation:='Update the Delete Status to Cancel Records ' || Varreference; 
        update trtran006 set cdel_record_status =10200003
          where CDEL_ROLLOVER_REFERENCE=varReference;

       varOperation:='Update the Hedge Deal Linking' || Varreference;    
        update trtran004 set HEDG_RECORD_STATUS =10200003
          where HEDG_ROLLOVER_REFERENCE=varReference;

       varOperation:='Update the new deal to Delete status ' || Varreference;      
        update trtran001 set DEAL_RECORD_STATUS =10200003
         where DEAL_Deal_number in 
            (select DEAR_NEWDEAL_NUMBER from TRTRAN001RA
              where DEAR_RECORD_STATUS not in (10200005,10200006)
              and DEAR_REFERENCE_NUMBER=varReference); 

  end if;
 end if;

if EditType = SYSFUTUREROLLOVERPROCESS then
 if  numAction in(GConst.ADDSAVE) then    
        -- if numCode1 in (64500002 then --Cancel
           varTemp2 := '//DealDetails//DROW';       
           nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);  

          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop  
                varxPath := '//DealDetails//DROW[@DNUM="' || numTemp || '"]';   
                varTemp := varxPath || '/DealNumber';
                varOperation:=' Extracting information from ' || varTemp;

                varoperation :='Extracting Data from XML' || varTemp;
                Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
              varOperation:=' Extracting information for Deal' || Varreference1;
              begin
               select nvl(max(CFRV_REVERSE_SERIAL) +1,1) 
                 into numSerial
                 from trtran063
                 where CFRV_DEAL_NUMBER=varReference1;
               exception
                 when no_data_found then
                 numSerial:=1;
              end ;

              varOperation:=' Extracting information for Deal from Base Table' || Varreference1; 
                 select max(CFUT_HEDGE_TRADE)
                 into numCode2
                 from trtran061
                 where CFUT_DEAL_NUMBER=varReference1;

              varOperation:=' Insert Data into Cancel Table for Deal' || Varreference1; 

              begin 
            varTemp4:=GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_REMARKS',vartemp);
         exception 
           when others then 
             varTemp4:='';
          end ;

          begin 
            varTemp5:=GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_REFERENCE',vartemp);
         exception 
           when others then 
             varTemp5:='';
          end ;

          begin 
            varTemp6:=GConst.fncXMLExtract(xmlTemp,'CFUR_DEALER_NAME',vartemp);


         exception 
           when others then 
             varTemp6:='';
          end ;         

           numRate1:= GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_RATE',numRate1);
           numRate1:=GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_RATE',numRate1);
           numFcy:= GConst.fncXMLExtract(xmlTemp,'CFUR_CONVERSION_PANDL',numFcy) ;
             numRate1:=GConst.fncXMLExtract(xmlTemp,'CFUR_CONVERSION_RATE',numRate1) ;
            datTemp:= GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_DATE',datTemp) ;
            varReference:= GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_NUMBER',varReference) ;

          Insert into TRTRAN063 (CFRV_COMPANY_CODE,CFRV_DEAL_NUMBER,CFRV_REVERSE_DEAL,CFRV_CREATE_DATE,
                      CFRV_RECORD_STATUS,CFRV_PROFIT_LOSS,CFRV_SERIAL_NUMBER,CFRV_REVERSE_SERIAL,
                      CFRV_LOT_PRICE,
                      CFRV_CANCEL_AMOUNT,CFRV_SPOT_RATE,CFRV_FORWARD_RATE,
                      CFRV_BANK_MARGIN,CFRV_DEALER_NAME,
                    --  CFRV_COUNTER_DEALER,
                      CFRV_EXCHANGE_RATE,CFRV_USER_ID,
                      CFRV_REFERENCE_NUMBER,CFRV_LOCAL_RATE,
                      CFRV_CANCEL_RATE,CFRV_PANDL_USD,CFRV_PANDL_SPOT,
                      CFRV_DEALER_REMARKS,  CFRV_EXECUTE_DATE,
                      CFRV_ROLLOVER_REFERENCE,CFRV_REVERSE_LOT) 
             select GConst.fncXMLExtract(xmlTemp,'CFUR_COMPANY_CODE',numcode3) CFRV_COMPANY_CODE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/DealNumber',varReference, Gconst.TYPENODEPATH) CFRV_DEAL_NUMBER,
                     1 CFRV_REVERSE_DEAL,
                     sysdate CFRV_CREATE_DATE,10200001 CFRV_RECORD_STATUS,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/ProfitLoss',numFcy, Gconst.TYPENODEPATH) CFRV_PROFIT_LOSS,
                     1 CFRV_SERIAL_NUMBER,   numSerial CFRV_REVERSE_SERIAL,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_RATE',numRate1) CFRV_EXCHANGE_RATE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH),
                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_SPOT',numRate1) ,0, 
                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_MARGIN',numRate1),
                     varTemp6, 
                     --GConst.fncXMLExtract(xmlTemp,'CFUR_COUNTER_DEALER',vartemp),
                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_RATE',numRate1) CFRV_EXCHANGE_RATE,varTemp6,
                     varTemp5,1,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_RATE',numRate1)CFRV_CANCEL_RATE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_CONVERSION_PANDL',numFcy) CFRV_PANDL_USD,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_CONVERSION_RATE',numRate1) CFRV_PANDL_SPOT,varTemp4,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_DATE',datTemp) CFRV_EXECUTE_DATE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_NUMBER',varReference) CFRV_ROLLOVER_REFERENCE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/AdjustingLots',numFcy, Gconst.TYPENODEPATH) 
                     FROM DUAL;   
--Insert into TRTRAN063 (CFRV_COMPANY_CODE,CFRV_DEAL_NUMBER,CFRV_REVERSE_DEAL,CFRV_CREATE_DATE,CFRV_RECORD_STATUS,
--CFRV_PROFIT_LOSS,CFRV_SERIAL_NUMBER,CFRV_REVERSE_SERIAL,
----CFRV_LOT_PRICE,
----CFRV_DEALER_REMARKS,CFRV_CANCEL_REASON,
--CFRV_CANCEL_AMOUNT,
----CFRV_CONFIRM_DATE,CFRV_CONFIRM_TIME,
----CFRV_BANK_REFERENCE,
----CFRV_BO_REMARK,
--CFRV_SPOT_RATE,CFRV_FORWARD_RATE,
--CFRV_BANK_MARGIN,CFRV_DEALER_NAME,
----CFRV_COUNTER_DEALER,
--CFRV_EXCHANGE_RATE,
----CFRV_USER_ID,
----CFRV_REFERENCE_NUMBER,CFRV_LOCAL_RATE,
--CFRV_CANCEL_RATE,CFRV_PANDL_USD,CFRV_PANDL_SPOT,
--CFRV_DEALER_REMARKS, CFRV_REFERENCE_NUMBER, CFRV_EXECUTE_DATE,
--CFRV_ROLLOVER_REFERENCE)
----,CFRV_REVERSE_LOT) 
--select GConst.fncXMLExtract(xmlTemp,'CFUR_COMPANY_CODE',numcode3) CFRV_COMPANY_CODE,
--                     GConst.fncXMLExtract(xmlTemp,varxPath || '/DealNumber',varReference, Gconst.TYPENODEPATH) CFRV_DEAL_NUMBER,
--                     1 CFRV_REVERSE_DEAL,
--                     sysdate CFRV_CREATE_DATE,
--                     10200001 CFRV_RECORD_STATUS,
--                     GConst.fncXMLExtract(xmlTemp,varxPath || '/ProfitLoss',numFcy, Gconst.TYPENODEPATH) CFRV_PROFIT_LOSS,
--                     1 CFRV_SERIAL_NUMBER,
--                     numSerial CFRV_REVERSE_SERIAL,
--                     -- CFRV_LOT_PRICE,
--                     GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH) CFRV_CANCEL_AMOUNT,
--                     --varTemp5 CFRV_BANK_REFERENCE,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_SPOT_RATE',numFcy) CFRV_SPOT_RATE,
--                     0 CFRV_FORWARD_RATE,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_MARGIN',numFcy) CFRV_BANK_MARGIN,
--                     varTemp6 CFRV_DEALER_NAME,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_RATE',numFcy) CFRV_EXCHANGE_RATE,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_CANCEL_RATE',numFcy) CFRV_CANCEL_RATE,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_CONVERSION_PANDL',numFcy) CFRV_PANDL_USD,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_CONVERSION_RATE',numFcy) CFRV_PANDL_SPOT,
--                     varTemp4 CFRV_DEALER_REMARKS,
--                     varTemp5 CFRV_REFERENCE_NUMBER,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_DATE',datTemp) CFRV_EXECUTE_DATE,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_NUMBER',varReference) CFRV_ROLLOVER_REFERENCE
--                     FROM DUAL;                          

      --      varOperation:=' Update the Deal Linking table ' || Varreference1; 

--            update trtran004 set HEDG_RECORD_STATUS= 10200010,
--                                 HEDG_RollOVer_Reference= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference)
--              where Hedg_deal_number= varReference1
--              and hedg_record_Status not in (10200005,10200006);
           end loop;

        numCode1 := GConst.fncXMLExtract(xmlTemp,'CFUR_ROLLOVER_TYPE',numCode1);

         if numCode1=64500001 then --Rollover

         begin 
            varTemp1:=GConst.fncXMLExtract(xmlTemp,'CFUR_USER_REMARKS',vartemp);
         exception 
           when others then 
             varTemp1:='';
          end ;
           begin 
            varTemp3:= GConst.fncXMLExtract(xmlTemp,'CFUR_USER_REFERENCE',vartemp);
         exception 
           when others then 
             varTemp3:='';
          end ; 

          SELECT CPRO_BASE_CURRENCY, CPRO_QUOTE_CURRENCY
          INTO numCode4, numCode5
          FROM trmaster503 where CPRO_PICK_CODE = GConst.fncXMLExtract(xmlTemp,'CFUR_PRODUCT_CODE',numCode) 
          and Cpro_Record_Status  NOT IN (10200005,10200006);  

          varOperation:=' Insert Deal into Base Table incase of Roll Over  ' || Varreference1; 
           varReference := 'FUR' || fncGenerateSerial(SERIALFUTURETRADE,numCompany);
            insert into TRTRAN061
            (CFUT_COMPANY_CODE,CFUT_DEAL_NUMBER,
            CFUT_USER_REFERENCE,
            CFUT_EXECUTE_DATE,CFUT_EXCHANGE_CODE,CFUT_COUNTER_PARTY,CFUT_BASE_CURRENCY,
            CFUT_OTHER_CURRENCY,CFUT_EXCHANGE_RATE,
            --CFUT_LOCAL_RATE,
            CFUT_BASE_AMOUNT,CFUT_OTHER_AMOUNT,
            --CFUT_CONTRACT_TYPE,
            CFUT_HEDGE_TRADE,CFUT_BUY_SELL,CFUT_PRODUCT_CODE,
            --CFUT_LOCAL_BANK,
            CFUT_LOT_NUMBERS,CFUT_LOT_QUANTITY,
            CFUT_MARGIN_RATE,
            --CFUT_MARGIN_AMOUNT,
            --CFUT_BROKERAGE_RATE,CFUT_BROKERAGE_AMOUNT,CFUT_SERVICE_TAX,CFUT_TRANSACTION_COST,CFUT_OTHER_CHARGES,
            CFUT_MATURITY_DATE,
            --CFUT_USER_ID,
            CFUT_DEALER_REMARK,
            --CFUT_BO_REMARK,CFUT_CONFIRM_DATE,
            CFUT_EXECUTE_TIME,
            CFUT_TIME_STAMP,CFUT_PROCESS_COMPLETE,
            --CFUT_COMPLETE_DATE,
            CFUT_CREATE_DATE,
            CFUT_ADD_DATE,
            --CFUT_ENTRY_DETAIL,
            CFUT_RECORD_STATUS,
            CFUT_BACKUP_DEAL,CFUT_INIT_CODE,
            --CFUT_BANK_REFERENCE,CFUT_CONFIRM_TIME,
            CFUT_LOCATION_CODE,
            CFUT_SPOT_RATE,CFUT_FORWARD_RATE,
            --CFUT_BANK_MARGIN,
            CFUT_MATURITY_FROM,CFUT_DEALER_NAME,
            --CFUT_COUNTER_DEALER,
            CFUT_PRODUCT_DESCRIPTION)            

              select GConst.fncXMLExtract(xmlTemp,'CFUR_COMPANY_CODE',numcode3) CFUT_COMPANY_CODE,
                      varReference CFUT_DEAL_NUMBER,
                     varTemp3 CFUT_USER_REFERENCE,
                      --1 deal_serial_number,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_EXECUTE_DATE',datTemp) CFUT_EXECUTE_DATE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_EXCHENGE_CODE',numCode) CFUT_EXCHANGE_CODE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_COUNTER_PARTY',numCode) CFUT_COUNTER_PARTY,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_BASE_CURRENCY',numCode) CFUT_BASE_CURRENCY,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_OTHER_CURRENCY',numCode) CFUT_OTHER_CURRENCY,
                      numCode4  CFUT_BASE_CURRENCY,
                      numCode5 CFUT_OTHER_CURRENCY,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_EXCHNAGE_RATE',numCode) CFUT_EXCHANGE_RATE, 
                     GConst.fncXMLExtract(xmlTemp,'CFUR_DEAL_AMOUNT',numCode) CFUT_BASE_AMOUNT,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_DEAL_AMOUNT',numCode)*
                     GConst.fncXMLExtract(xmlTemp,'CFUR_EXCHNAGE_RATE',numCode) CFUT_OTHER_AMOUNT,
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_DEAL_AMOUNT',numCode)*
--                     GConst.fncXMLExtract(xmlTemp,'CFUR_EXCHNAGE_RATE',numCode) DEAL_AMOUNT_LOCAL,
                      GConst.fncXMLExtract(xmlTemp,'CFUR_HEDGE_TRADE',numCode) CFUT_HEDGE_TRADE ,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_BUY_SELL',numCode) CFUT_BUY_SELL,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_PRODUCT_CODE',numCode) CFUT_PRODUCT_CODE,
                    --GConst.fncXMLExtract(xmlTemp,'CFUR_DEAL_AMOUNT',numCode)/1000 CFUT_LOT_NUMBERS,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_NOOF_LOTS',numCode) CFUT_LOT_NUMBERS,                     
                     GConst.fncXMLExtract(xmlTemp,'CFUR_DEAL_AMOUNT',numCode)/GConst.fncXMLExtract(xmlTemp,'CFUR_NOOF_LOTS',numCode) CFUT_LOT_QUANTITY,                     
                     GConst.fncXMLExtract(xmlTemp,'CFUR_MARGIN_RATE',numCode) CFUT_MARGIN_RATE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_NEWMATURITY_DATE',datTemp) CFUT_MATURITY_DATE, 
                     varTemp1 CFUT_DEALER_REMARK,
                     to_char(systimestamp, 'HH24:MI:SS') CFUT_EXECUTE_TIME,
                     to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3') CFUT_TIME_STAMP,
                     12400002 CFUT_PROCESS_COMPLETE,sysdate CFUT_CREATE_DATE, sysdate CFUT_ADD_DATE, 10200001 CFUT_RECORD_STATUS,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_BACKUP_DEAL',numCode) CFUT_BACKUP_DEAL,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_INIT_CODE',numCode) CFUT_INIT_CODE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_LOCATION_CODE',numCode) CFUT_LOCATION_CODE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_SPOT_RATE',numCode) CFUT_SPOT_RATE,  0 CFUT_FORWARD_RATE,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_NEWMATURITY_DATE',datTemp) CFUT_MATURITY_FROM,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_DEALER_NAME',vartemp) CFUT_DEALER_NAME,
                     GConst.fncXMLExtract(xmlTemp,'CFUR_PRODUCT_DESC',vartemp) CFUT_PRODUCT_DESCRIPTION
                     FROM DUAL;                                

          varOperation:='Update Deal number to Roll Over Table';        
          update TRTRAN063A set  CFUR_NEWDEAL_NUMBER=varReference
            where CFUR_REFERENCE_NUMBER=GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_NUMBER',varReference)
            and CFUR_RECORD_STATUS not in (10200005,10200006);           

         end if;
  elsif numAction in(GConst.DELETESAVE) then 
     varReference:= GConst.fncXMLExtract(xmlTemp,'CFUR_REFERENCE_NUMBER',varReference);


--       varOperation:='Update the Hedge Deal Linking' || Varreference;    
--        update trtran004 set HEDG_RECORD_STATUS =10200006
--          where HEDG_ROLLOVER_REFERENCE=varReference
--          and HEDG_RECORD_STATUS not in (10200010,10200006);
--      
--        varOperation:='Update the Hedge Deal Linking Back to Orginal' || Varreference;    
--        update trtran004 set HEDG_RECORD_STATUS =10200003
--         where HEDG_Deal_number in 
--            (select Cdel_DEAL_NUMBER from trtran006
--              where cdel_RECORD_STATUS not in (10200005,10200006)
--              and CDEL_ROLLOVER_REFERENCE=varReference)
--          and HEDG_RECORD_STATUS =10200010;

        varOperation:='Update the Delete Status to Cancel Records ' || Varreference; 
        update TRTRAN063 set CFRV_RECORD_STATUS =10200006
          where CFRV_ROLLOVER_REFERENCE=varReference;

       varOperation:='Update the new deal to Delete status ' || Varreference;      
        update TRTRAN061 set CFUT_RECORD_STATUS =10200006
         where CFUT_DEAL_NUMBER in 
            (select CFUR_NEWDEAL_NUMBER from TRTRAN063A
             -- where DEAR_RECORD_STATUS not in (10200005,10200006) -- record status in TRTRAN001RA would already been changed to 10200006
              where CFUR_REFERENCE_NUMBER=varReference); 


  elsif numAction in(GConst.CONFIRMSAVE) then     
       varReference:= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference);
      varOperation:='Update the Delete Status to Cancel Records ' || Varreference; 

         update TRTRAN063 set CFRV_RECORD_STATUS =10200003
          where CFRV_ROLLOVER_REFERENCE=varReference;

--       varOperation:='Update the Hedge Deal Linking' || Varreference;    
--        update trtran004 set HEDG_RECORD_STATUS =10200003
--          where HEDG_ROLLOVER_REFERENCE=varReference;

       varOperation:='Update the new deal to Delete status ' || Varreference;      
        update TRTRAN061 set CFUT_RECORD_STATUS =10200003
         where CFUT_DEAL_NUMBER in 
            (select CFUR_NEWDEAL_NUMBER from TRTRAN063A
              where CFUR_RECORD_STATUS not in (10200005,10200006)
              and CFUR_REFERENCE_NUMBER=varReference); 

  end if;
 end if;

  If Edittype = SYSLOGINIPUPDATE Then
        VarOperation:= 'UPDATE IP';
--        insert into temp values('LAKSH', 'ME');COMMIT;
        varTemp1:=GConst.fncXMLExtract(xmlTemp, 'UserId', varTemp1); 
         varTemp2:=GConst.fncXMLExtract(xmlTemp, 'Param/IP', varTemp2);
        Update Usermaster set USER_TERMINAL_ID = varTemp2
           where User_User_Id=varTemp1;
  END IF;


    if EditType = Gconst.SYSIRSPOPULATE then
          varOperation := 'Extractng IRS Number';
          varReference := GConst.fncXMLExtract(xmlTemp, 'IIRS_IRS_NUMBER', varReference);
          varOperation := 'Insert Buy Leg into table';


          if numAction in (GConst.ADDSAVE) then
             varOperation := 'Extracting Reciept Details Parameters';
             docFinal := xmlDom.newDomDocument(xmlTemp);
             nodFinal := xmlDom.makeNode(docFinal);       
             varOperation := 'Before Loop';

             varXPath := '//RecieptDetails/DROW';
             nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
             varOperation := 'Update Reverse Reference ' || varXPath;
             Glog.log_write(varXPath);
             GLog.Log_write(' in Addload ' || varXpath || ' Length ' || xmlDom.getLength(nlsTemp));

             for numTemp in 1..xmlDom.getLength(nlsTemp)
                 Loop
                 GLog.Log_write(' in Addload Inside Loop ' || varXpath || ' Length ' || xmlDom.getLength(nlsTemp) );
                 varoperation :='Extracting Data from XML';

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptFinalRate';
                 numrate1 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate1, Gconst.TYPENODEPATH);    

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptSpreadRate';  
                 numrate2 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate2, Gconst.TYPENODEPATH);    

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptBaseRate';  
                 numrate3 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate3, Gconst.TYPENODEPATH);           

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptIntType';  
                 numCode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH); 

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptCurrencyCode';  
                 numCode := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);  

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptNotionalAmount';  
                 numfcy := GConst.fncXMLExtract(xmlTemp, varTemp, numfcy, Gconst.TYPENODEPATH);

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptInterestDaystype';  
                 numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);

                 insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
                                         IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,IIRL_NOTIONAL_AMOUNT,
                                         IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,IIRL_RECORD_STATUS)
                 values(varReference,1,1,25300001,numCode,numCode1,numrate3,numrate2,numrate1,numCode2,numfcy,
                        sysdate(),sysdate(),sysdate(),10200001);

             end loop;

             varOperation := 'Extracting Payment Details Parameters';
             docFinal := xmlDom.newDomDocument(xmlTemp);
             nodFinal := xmlDom.makeNode(docFinal);     

             varOperation := 'Before Loop';

             varXPath := '//PaymentDetails/DROW';
             nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
             varOperation := 'Update Reverse Reference ' || varXPath;
             for numTemp in 1..xmlDom.getLength(nlsTemp)
                 Loop
                 varoperation :='Extracting Data from XML';

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentFinalRate';
                 numrate1 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate1, Gconst.TYPENODEPATH);    

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentSpreadRate';  
                 numrate2 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate2, Gconst.TYPENODEPATH);    

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentBaseRate';  
                 numrate3 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate3, Gconst.TYPENODEPATH);           

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentIntType';  
                 numCode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH); 

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentCurrencyCode';  
                 numCode := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);  

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentNotionalAmount';  
                 numfcy := GConst.fncXMLExtract(xmlTemp, varTemp, numfcy, Gconst.TYPENODEPATH);

                 varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentInterestDaystype';  
                 numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);

                 insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
                                         IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,IIRL_NOTIONAL_AMOUNT,
                                         IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,IIRL_RECORD_STATUS)
                 values(varReference,1,2,25300002,numCode,numCode1,numrate3,numrate2,numrate1,numCode2,numfcy,
                        sysdate(),sysdate(),sysdate(),10200001);

             end loop;

             varOperation := 'Populate the buy Maturities';
             datTemp:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_START_DATE', datTemp);
             datTemp1:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_EXPIRY_DATE', datTemp1);
             --numTemp :=GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH);
             BEGIN
                 SELECT  Iirl_Base_Rate,Iirl_Spread,Iirl_Final_Rate  
                 INTO numRate,numRate1,numRate2
                 FROM TRTRAN091A WHERE IIRL_IRS_NUMBER = varReference
                 AND IIRL_FINAL_RATE != 0;

                 UPDATE TRTRAN091A 
                 SET Iirl_Base_Rate = numRate,
                     Iirl_Spread = numRate1,
                     Iirl_Final_Rate = numRate2
                 WHERE IIRL_IRS_NUMBER = varReference
                 AND IIRL_FINAL_RATE = 0;   
             exception 
             when others then
                 numRate := 0;
                 numRate1 := 0;
                 numRate2 := 0;
             end;      
          end if;       

          if numAction in (GConst.EDITSAVE) then
                if GCONST.FNCNODE_EXISTS(docFinal,'//RecieptDetails')=true then
                    varOperation := 'Update the existing Buy side records to in active';

                    select max(IIRL_SERIAL_NUMBER)
                    into numserial
                    from trtran091A 
                    where IIRL_IRS_NUMBER = varReference and IIRL_LEG_serial=1;

                    update  trtran091A set  IIRL_RECORD_status=10200005
                    where IIRL_IRS_NUMBER= varReference
                    and IIRL_LEG_serial=1
                    and IIRL_RECORD_status not in (10200005,10200006);

                      varOperation := 'Extracting Reciept Details Parameters';
                      docFinal := xmlDom.newDomDocument(xmlTemp);
                      nodFinal := xmlDom.makeNode(docFinal);       
                      varOperation := 'Before Loop';

                      varXPath := '//RecieptDetails/DROW';
                      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
                      varOperation := 'Update Reverse Reference ' || varXPath;
                      for numTemp in 1..xmlDom.getLength(nlsTemp)
                      Loop
                          varoperation :='Extracting Data from XML';

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptFinalRate';
                          numrate1 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate1, Gconst.TYPENODEPATH);    

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptSpreadRate';  
                          numrate2 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate2, Gconst.TYPENODEPATH);    

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptBaseRate';  
                          numrate3 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate3, Gconst.TYPENODEPATH);           

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptIntType';  
                          numCode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH); 

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptCurrencyCode';  
                          numCode := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);  

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptNotionalAmount';  
                          numfcy := GConst.fncXMLExtract(xmlTemp, varTemp, numfcy, Gconst.TYPENODEPATH);

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/RecieptInterestDaystype';  
                          numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);

                          insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,
                                      IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
                                      IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,IIRL_NOTIONAL_AMOUNT,
                                      IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
                                      IIRL_RECORD_STATUS)
                          values(varReference,numserial+1,1,25300001,numCode,numCode1,numrate3,numrate2,numrate1,numCode2,numfcy,
                                sysdate(),sysdate(),sysdate(),10200001);

                     end loop;
               end if;           
               if GCONST.FNCNODE_EXISTS(docFinal,'//PaymentDetails')=true then    
                  varOperation := 'Update the existing sell side records to in active';

                    select max(IIRL_SERIAL_NUMBER)
                    into numserial
                    from trtran091A 
                    where IIRL_IRS_NUMBER = varReference and IIRL_LEG_serial=2;

                  update  trtran091A set IIRL_RECORD_status=10200005
                  where IIRL_IRS_NUMBER= varReference
                  and IIRL_LEG_serial=2
                  and IIRL_RECORD_status not in (10200005,10200006);

                  varOperation := 'Insert Sell Leg into table';
                  docFinal := xmlDom.newDomDocument(xmlTemp);
                  nodFinal := xmlDom.makeNode(docFinal);     

                  varOperation := 'Before Loop';

                  varXPath := '//PaymentDetails/DROW';
                  nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
                  varOperation := 'Update Reverse Reference ' || varXPath;
                  for numTemp in 1..xmlDom.getLength(nlsTemp)
                      Loop
                          varOperation := 'Extracting Payment Details Parameters';

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentFinalRate';
                          numrate1 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate1, Gconst.TYPENODEPATH);    

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentSpreadRate';  
                          numrate2 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate2, Gconst.TYPENODEPATH);    

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentBaseRate';  
                          numrate3 := GConst.fncXMLExtract(xmlTemp, varTemp, numrate3, Gconst.TYPENODEPATH);           

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentIntType';  
                          numCode1 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH); 

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentCurrencyCode';  
                          numCode := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);  

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentNotionalAmount';  
                          numfcy := GConst.fncXMLExtract(xmlTemp, varTemp, numfcy, Gconst.TYPENODEPATH);

                          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/PaymentInterestDaystype';  
                          numCode2 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);

                          insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,
                                      IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
                                      IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,IIRL_NOTIONAL_AMOUNT,
                                      IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
                                      IIRL_RECORD_STATUS)
                          values(varReference,numserial+1,2,25300002,numCode,numCode1,numrate3,numrate2,numrate1,numCode2,numfcy,
                                sysdate(),sysdate(),sysdate(),10200001);                                
                      end loop;
              end if;                          

              varOperation := 'Populate the buy Maturities';
              datTemp:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_START_DATE', datTemp);
              datTemp1:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_EXPIRY_DATE', datTemp1);
              --numTemp :=GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH);
                BEGIN
                  SELECT  Iirl_Base_Rate,Iirl_Spread,Iirl_Final_Rate  
                    INTO numRate,numRate1,numRate2
                  FROM TRTRAN091A WHERE IIRL_IRS_NUMBER = varReference
                  AND IIRL_FINAL_RATE != 0;

                  UPDATE TRTRAN091A SET Iirl_Base_Rate = numRate,
                                      Iirl_Spread = numRate1,
                                      Iirl_Final_Rate = numRate2
                                  WHERE IIRL_IRS_NUMBER = varReference
                                   AND IIRL_FINAL_RATE = 0;  
                exception 
                when others then
                   numRate := 0;
                   numRate1 := 0;
                   numRate2 := 0;
                end;  
      end if;

      if  numAction in (GConst.CONFIRMSAVE) then
         update trtran091a set iirl_record_status =10200003
          where IIRL_IRS_NUMBER= varReference
           and IIRL_RECORD_STATUS not in (10200005,10200006);

--         Update trtran091D set IIRP_RECORD_status =10200003
--          where IIRP_IRS_NUMBER= varReference
--          and IIRP_RECORD_STATUS not in (10200005,10200006);
--         
--         update trtran091b set iirm_record_status =10200003
--          where IIRm_IRS_NUMBER= varReference;
--        
--        update trtran091c set iirn_record_status =10200003
--          where IIRn_IRS_NUMBER= varReference;
      end if; 

      if  numAction in (GConst.DELETESAVE) then
         update trtran091a set iirl_record_status =10200006
          where IIRL_IRS_NUMBER= varReference
          and IIRL_RECORD_STATUS not in (10200005,10200006);

--         Update trtran091D set IIRP_RECORD_status =10200006
--          where IIRP_IRS_NUMBER= varReference
--          and IIRP_RECORD_STATUS not in (10200005,10200006);

--         update trtran091b set iirm_record_status =10200006
--          where IIRm_IRS_NUMBER= varReference;
--        
--        update trtran091c set iirn_record_status =10200006
--          where IIRn_IRS_NUMBER= varReference;
      end if; 
  end if;    

     if EditType = SYSDATAUPLOADSPROCESS then
     varOperation := 'Data Uploads Details, Getting datauploads';
     Glog.log_write(varoperation);
     varEntity := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/LOAD_DATA_NAME', varEntity,Gconst.TYPENODEPATH);
     Glog.log_write(varEntity);
     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//EditedItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
        varOperation := 'Users Entering Into Main loop ' || varXPath;
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;

          varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
          varoperation :='Extracting Data from XML' || varTemp;
          Glog.log_write(varoperation);

          begin
            varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ToolTip',varTemp1, Gconst.TYPENODEPATH);
          exception
          when others then
            varTemp1 := null;
          end;

          begin
            numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ShowYN',numCode1, Gconst.TYPENODEPATH);
          exception
          when others then
            numCode1 := 0;
          end;

          begin
            varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'DisplayName',varTemp2, Gconst.TYPENODEPATH);
          exception
          when others then
            varTemp2 := null;
          end;

          begin
            numCode2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'MandatoryYN',numCode2, Gconst.TYPENODEPATH);
          exception
          when others then
            numCode2 := 0;
          end;

          begin
            numCode3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ColumnID',numCode3, Gconst.TYPENODEPATH);
          exception
          when others then
            numCode3 := 0;
          end;

          begin
            varTemp3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'DestinationColumn',varTemp3, Gconst.TYPENODEPATH);
          exception
          when others then
            varTemp3 := null;
          end;

          begin
            varTemp4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SourceColumn',varTemp4, Gconst.TYPENODEPATH);
          exception
          when others then
            varTemp4 := null;
          end;

          begin
            varTemp5 := GConst.fncXMLExtract(xmlTemp,varTemp || 'DefaultValue',varTemp5, Gconst.TYPENODEPATH);
          exception
          when others then
            varTemp5 := null;
          end;

            begin
            varTemp6 := GConst.fncXMLExtract(xmlTemp,varTemp || 'DescriptionType',varTemp6, Gconst.TYPENODEPATH);
          exception
          when others then
            varTemp6 := null;
          end;

             varoperation :='After Extracting Data from XML' || varTemp;
             Glog.log_write(varTemp1 || varTemp3);
--          update TRSYSTEM968 set LOCL_RECORD_STATUS=10200005
--                    where LOCL_DATA_NAME=varEntity;
             UPDATE TRSYSTEM968 
             SET LOCL_MANDATORY_YN = numCode2,
                    LOCL_COLUMN_ID = numCode3,
                    LOCL_COLUMN_WIDTH = 150,
                    LOCL_RECORD_STATUS = 10200004,
                    LOCL_SHOW_YN = numCode1,
                    LOCL_TOOL_TIP = varTemp1,
                    LOCL_DEFAULT_VALUE = varTemp5,
                    LOCL_SOURCE_COLUMN = varTemp4,
                    LOCL_DISPLAY_NAME = varTemp2,
                    LOCL_DESCRIPTION_TYPE=varTemp6
             WHERE LOCL_DATA_NAME=varEntity
             and LOCL_DESTINATION_COLUMN=varTemp3;
             End Loop;
         end if;

         if (numAction = GConst.CONFIRMSAVE) then
          update TRSYSTEM968 set LOCL_RECORD_STATUS=10200003
                    where LOCL_DATA_NAME=varEntity;
          end if;

           if numAction = GConst.DELETESAVE then
                      update TRSYSTEM968 set LOCL_RECORD_STATUS=10200006
                    where LOCL_DATA_NAME=varEntity;
           end if;

 end if;

 if EditType = SYSOPTIONTYPECONFIGPROCESS then

        varOperation := 'Option Type Configuration Details, Getting PickCode';
        varTemp := '//ROW[@NUM="1"]/OPTI_PICK_CODE';
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
       Glog.log_write('Option Type Config Details ' || varTemp || ',' || varTemp);
     if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
        varXPath := '//EditedItems/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
           varOperation := 'Users Entering Into Main loop ' || varXPath;
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath;
          varoperation :='Extracting Data from XML' || varTemp;
              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
               varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'BuySell',varTemp1, Gconst.TYPENODEPATH);
               varTemp2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'CallPut',varTemp2, Gconst.TYPENODEPATH);
               Glog.log_write('Buy SEll Details ' || varTemp1 || ',' || varTemp2);
              select nvl(max(OPTI_SERIAL_NUMBER),0)+1
               into numSerial
              from TRMASTER323A
              where OPIC_PICK_CODE=varReference;
              Glog.log_write('Serial Number Details ' || numSerial || ',' || numSerial);
           varoperation :='Extracting Data from XML' || varTemp;

--          update TRMASTER323A set OPTI_RECORD_STATUS=10200005
--                    where OPIC_PICK_CODE=varReference;

            insert into TRMASTER323A (OPTI_BUY_SELL,OPTI_OPTION_TYPE,OPTI_RECORD_STATUS,OPTI_SERIAL_NUMBER,OPIC_PICK_CODE)          
            values (varTemp1,varTemp2,10200001,numSerial,varReference);
            Glog.log_write('Insert Details' || numSerial || ',' || numSerial);
             End Loop;
         end if;

         if (numAction = GConst.CONFIRMSAVE) then
          update TRMASTER323A set OPTI_RECORD_STATUS=10200003
                    where OPIC_PICK_CODE=varReference;
          end if;

           if numAction = GConst.DELETESAVE then
                      update TRMASTER323A set OPTI_RECORD_STATUS=10200006
                    where OPIC_PICK_CODE=varReference;
           end if;

 end if;

if EditType = SYSLOCATIONMASTERPROCESS then

    numCode := GConst.fncXMLExtract(xmlTemp, 'LOCN_COMPANY_CODE', numCode);
    numCode1 := GConst.fncXMLExtract(xmlTemp, 'LOCN_PICK_CODE', numCode1);
    numStatus:=  FNCGENERATERELATION(numCode, numCode1, numAction);
--    IF numAction in (GConst.ADDSAVE) then
--    Insert into TRSYSTEM008(EREL_COMPANY_CODE,EREL_MAIN_ENTITY,EREL_ENTITY_RELATION,EREL_ENTITY_TYPE,EREL_RELATION_TYPE,EREL_CREATE_DATE,EREL_ADD_DATE,EREL_ENTRY_DETAIL,EREL_RECORD_STATUS) 
--    values(30199999,numCode,numCode1,301,302,sysdate,sysdate,null,10200001);
--    
--    ELSIF numAction in (GConst.EDITSAVE) then
--    Update TRSYSTEM008
--    SET EREL_MAIN_ENTITY = numCode
--    WHERE EREL_ENTITY_RELATION = numCode1 AND EREL_RECORD_STATUS NOT IN (10200005,10200006);
--    
--    ELSIF numAction in (GConst.DELETESAVE) then
--    Update TRSYSTEM008
--    SET EREL_RECORD_STATUS = 10200006
--    WHERE EREL_ENTITY_RELATION = numCode1 AND EREL_MAIN_ENTITY= numCode
--    AND EREL_RECORD_STATUS NOT IN (10200005,10200006);
--    
--    END IF;
END IF;

if EditType = SYSCURRENCYPAIRCONFIGPROCESS then

    numCode := GConst.fncXMLExtract(xmlTemp, 'CNDI_LOCATION_CODE', numCode);
    numCode1 := GConst.fncXMLExtract(xmlTemp, 'CNDI_PICK_CODE', numCode1);
    numStatus:=  FNCGENERATERELATION(numCode, numCode1, numAction);
END IF;  

if EditType = SYSBANKMASTERPROCESS then

    numCode := GConst.fncXMLExtract(xmlTemp, 'LBNK_LOCATION_CODE', numCode);
    numCode1 := GConst.fncXMLExtract(xmlTemp, 'LBNK_PICK_CODE', numCode1);
    numStatus:=  FNCGENERATERELATION(numCode, numCode1, numAction);
END IF;

if EditType = SYSCODEMASTERPROCESS then

    numCode := GConst.fncXMLExtract(xmlTemp, 'PICK_LOCATION_CODE', numCode);
    numCode1 := GConst.fncXMLExtract(xmlTemp, 'PICK_KEY_VALUE', numCode1);
    numStatus:=  FNCGENERATERELATION(numCode, numCode1, numAction);
END IF;

if  EditType = SYSREMITTANCESMAINTANCE then
   varOperation:= ' Inside Misli  Reemittance';
   varTemp := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTemp);

   NumCode := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_CURRENCY', numCode);
   NumCode1:= GConst.fncXMLExtract(xmlTemp, 'BREL_LOCATION_CODE', numCode);
   datTemp:=GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp);
   numCode2:=GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numCode);
   datTemp1:= GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp1);
  -- numcode5:=  GConst.fncXMLExtract(xmlTemp, 'BREL_GROUP_BATCH', numcode5);

   varOperation:= 'Extracting Local Currency ';  
  select LOCN_LOCAL_CURRENCY
    into Numcode3
   from trmaster302 
  where LOCN_PICK_CODE=numcode1
  and locn_record_Status not in (10200005,10200006);

--  17300001	Outflow
--17300002	Inflow

--   varOperation:= 'Extracting Margin ';  
--  select decode(EXTY_INFLOW_OUTFLOW,17300001,25300001,17300002,25300002)
--    into numCode2
--   from trmaster259
--   where exty_record_Status not in (10200005,10200006)
--    and exty_pick_code =numCode2;

  varOperation:= ' Extracting the Rate Type default Value from configuration';  
   select fldp_default_value 
     into numcode4 
     from trsystem999
     where fldp_column_name= 'BREL_RATE_TYPE'
     and fldp_Record_Status not in (10200005,10200006)
     and FLDP_TABLE_SYNONYM='REMITTANCES';

   glog.log_write(' Update Rate by calling Rate Type' ||NumCode || Numcode3 || datTemp ||numCode2 ||datTemp1 ||numcode4 );
   varOperation:= ' Calling the fncGetRate_For RateType';  
   select pkgforexprocess.fncGetRate_ForRateType(NumCode,Numcode3,datTemp,numCode2,datTemp1,numcode4)
     into numRate from dual;


    glog.log_write(' Update Rate by calling Return Rate ' ||numRate );

   varOperation:= ' Update the other Details for the Remittance';  
   update trtran003 set  BREL_REVERSAL_RATE=numRate,BREL_LOCAL_CURRENCY=Numcode3,BREL_RATE_TYPE=numcode4
      where BREL_TRADE_REFERENCE= varTemp;

   varoperation :=' Update the Delivery batch incase of Batch Group No';
    update trtran003 set BREL_BATCH_NUMBER='BREMI' || fncGenerateSerial(SERIALBATCHNO)
     where BREL_TRADE_REFERENCE= varTemp
       and BREL_GROUP_BATCH=12400002;

end if;
    --if numAction in (GConst.ADDSAVE) then

--      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,
--                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
--                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
--                              IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
--                              IIRL_RECORD_STATUS)
--                  values(varReference,1,25300001,
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptIntType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptBaseRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptSpreadRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptFinalRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptInterestDaystype', numTemp,Gconst.TYPENODEPATH),
--                        sysdate(),sysdate(),sysdate(),10200001);
--                        
--                        
--      varOperation := 'Insert Sell Leg into table';
--      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,
--                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
--                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
--                              IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
--                              IIRL_RECORD_STATUS)
--                  values(varReference,2,25300002,
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentIntType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentBaseRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentSpreadRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentFinalRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentInterestDaystype', numTemp,Gconst.TYPENODEPATH),
--                        sysdate(),sysdate(),sysdate(),10200001);

        --VarOperation:= 'Process the maturity Buy Details';
--    
--        Varxpath := '//SellMaturities/SellMaturity';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--          
--          begin
--            datTemp:= GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
--          exception 
--          when others then
--           datTemp:= null;
--          end;
--          
--            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_LEG_SERIAL,IIRM_INTSTART_DATE,
--                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_SERIAL_NUMBER,IIRM_INTFIXING_DATE,
--                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE)
--                    values (varReference,1,
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),datTemp
--                    ,sysdate(),10200001,12400002);
--                    
--              
--        end loop;
--        
--        VarOperation:= 'Process the maturity Details';
--    
--        Varxpath := '//BuyMaturities/BuyMaturity';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--          
--          begin
--            datTemp:= GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
--          exception 
--          when others then
--           datTemp:= null;
--          end;
--          
--            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_LEG_SERIAL,IIRM_INTSTART_DATE,
--                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_SERIAL_NUMBER,IIRM_INTFIXING_DATE,
--                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE)
--                    values (varReference,2,
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),datTemp
--                     ,sysdate(),10200001,12400002);
--                    
--              
--        end loop;
--              
--        VarOperation:= 'Process Roller Coaster Details';
--    
--        Varxpath := '//RollerCoaster/RollerCoasterDetails';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--          intLoop:=intloop+1;
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--          
--            insert into TRTRAN091C(IIRN_IRS_NUMBER,IIRN_LEG_SERIAL,IIRN_SERIAL_number,
--                       IIRN_OUTSTANDING_AMOUNT,IIRN_EFFECTIVE_DATE,IIRN_EFFECTIVE_AMOUNT,IIRN_RECORD_STATUS,
--                       IIRn_CREATE_DATE)
--                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numTemp,Gconst.TYPENODEPATH),
--                     intLoop,
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'OutstandingNotional', numTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'EffectiveDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'Amount',numTemp,Gconst.TYPENODEPATH),10200001, sysdate());
--                    
--              
--        end loop;
--      
--     VarOperation:= 'Select the fixed leg details ';
--              
--       select IIRL_LEG_SERIAL,IIRL_Final_Rate,
--              IIRL_INTEREST_DAYSTYPE
--         into Numcode,numfcy,numcode1
--        from trtran091A
--        where IIRL_IRS_NUMBER= VarReference
--        and IIRL_INT_TYPE=80300001;
--        
--       VarOperation:= 'Update the fixed leg with interest details ';                             
--       
--        Update trtran091B set IIRM_INTEREST_Amount=  pkgIRS.fncIRSIntCalcforperiod(
--                   iirm_intStart_date,iirm_intEnd_date,varReference,Numcode, numfcy,numcode1),
--                   IIRM_FINAL_RATE=numfcy
--        where IIRM_IRS_NUMBER= varReference
--        and IIRM_LEG_SERIAL= Numcode
--        and IIRM_record_Status not in (10200005,10200006);
--                                --Fiexed)
----        VarOperation:= 'Process Payment CalanderDates';
----    
----        Varxpath := '//PaymentCalendarLocs/PaymentCalendarLoc';
----        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
----        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
----        Loop
----           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
----            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_PAYMENT_CALENDAR_LOCATION,IIRP_CREATE_DATE,
----                                   IIRP_RECORD_STATUS)
----                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'PLocationCode', numTemp,Gconst.TYPENODEPATH),
----                    sysdate(),numStatus);
----        end loop;
----        
----        VarOperation:= 'Process Payment FixingDates';
----    
----        Varxpath := '//FixingCalendarLocs/FixingCalendarLoc';
----        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
----        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
----        Loop
----           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
----            insert into TRTRAN091E(IIRF_IRS_NUMBER,IIRF_FIXING_CALENDAR_LOCATION,IIRF_CREATE_DATE,
----                                   IIRF_RECORD_STATUS)
----                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'FLocationCode', numTemp,Gconst.TYPENODEPATH),
----                    sysdate(),numStatus);
----        end loop;
--        intLoop:=0;
--        Varxpath := '//PaymentCalendarLocs/PaymentCalendarLoc';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--          intLoop:=intLoop+1;
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_CALENDAR_LOCATION,IIRP_CREATE_DATE,
--                                   IIRP_PAYMENT_FIXINGTYPE,IIRP_SERIAL_NUMBER,IIRP_RECORD_STATUS)
--                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'PLocationCode', numTemp,Gconst.TYPENODEPATH),
--                    sysdate(),82100001,intLoop,numStatus);
--        end loop;
--        
--        VarOperation:= 'Process Payment FixingDates';
--        intLoop:=0;
--        Varxpath := '//FixingCalendarLocs/FixingCalendarLoc';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--          intLoop:=intLoop+1;
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_CALENDAR_LOCATION,IIRP_CREATE_DATE,
--                                   IIRP_PAYMENT_FIXINGTYPE,IIRP_SERIAL_NUMBER,IIRP_RECORD_STATUS)
--                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'FLocationCode', numTemp,Gconst.TYPENODEPATH),
--                    sysdate(),82100002,intLoop,numStatus);
--        end loop;

--    end if;
--    if numAction in (GConst.EDITSAVE) then
--
----      IF numcode12 = 0 THEN
--      if GCONST.FNCNODE_EXISTS(docFinal,'//RecieptDetails')=true then
--        varOperation := 'Update the existing Buy side records to in active';
--        update  trtran091A set  IIRL_RECORD_status=10200005
--        where IIRL_IRS_NUMBER= varReference
--        and IIRL_LEG_serial=1
--        and IIRL_RECORD_status not in (10200005,10200006);
--
--      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,
--                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
--                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
--                              IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
--                              IIRL_RECORD_STATUS)
--                  values(varReference,1,25300001,
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptIntType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptBaseRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptSpreadRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptFinalRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//RecieptDetails/RecieptInterestDaystype', numTemp,Gconst.TYPENODEPATH),
--                        sysdate(),sysdate(),sysdate(),10200001);
--          end if;           
--     if GCONST.FNCNODE_EXISTS(docFinal,'//PaymentDetails')=true then    
--               varOperation := 'Update the existing sell side records to in active';
--                update  trtran091A set  IIRL_RECORD_status=10200005
--                where IIRL_IRS_NUMBER= varReference
--                and IIRL_LEG_serial=2
--                and IIRL_RECORD_status not in (10200005,10200006);
--                
--              varOperation := 'Insert Sell Leg into table';
--              insert into trtran091A (IIRL_IRS_NUMBER,IIRL_LEG_SERIAL,IIRL_BUY_SELL,
--                                      IIRL_CURRENCY_CODE,IIRL_INT_TYPE,
--                                      IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
--                                      IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
--                                      IIRL_RECORD_STATUS)
--                          values(varReference,2,25300002,
--                              GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentIntType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentBaseRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentSpreadRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentFinalRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//PaymentDetails/PaymentInterestDaystype', numTemp,Gconst.TYPENODEPATH),
--                                sysdate(),sysdate(),sysdate(),10200001);
--      end if;                          
--      varOperation := 'Populate the buy Maturities';
--      datTemp:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_START_DATE', datTemp);
--      datTemp1:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_EXPIRY_DATE', datTemp1);
--      --numTemp :=GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH);
--        BEGIN
--          SELECT  Iirl_Base_Rate,Iirl_Spread,Iirl_Final_Rate  
--            INTO numRate,numRate1,numRate2
--          FROM TRTRAN091A WHERE IIRL_IRS_NUMBER = varReference
--          AND IIRL_FINAL_RATE != 0;
--        
--          UPDATE TRTRAN091A SET Iirl_Base_Rate = numRate,
--                              Iirl_Spread = numRate1,
--                              Iirl_Final_Rate = numRate2
--                          WHERE IIRL_IRS_NUMBER = varReference
--                           AND IIRL_FINAL_RATE = 0;   
--                    
--        exception 
--        when others then
--           numRate := 0;
--           numRate1 := 0;
--           numRate2 := 0;
--        end;      

--        VarOperation:= 'Process Payment CalanderDates';
--        --DELETE FROM TRTRAN091D WHERE IIRP_IRS_NUMBER = varReference;
--        select max(IIRP_SERIAL_NUMBER)
--          into intLoop
--        from TRTRAN091D
--        where IIRP_IRS_NUMBER=varReference
--        and IIRP_PAYMENT_FIXINGTYPE= 82100001;
--        
--        Varxpath := '//PaymentCalendarLocs/PaymentCalendarLoc';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--            if numTemp=0 then
--              varOperation:=' Update the Existing Record to inactive';
--              
--             update TRTRAN091D set IIRP_record_Status =10200005
--              where IIRP_IRS_number=varReference
--               and IIRP_PAYMENT_FIXINGTYPE= 82100001
--               and IIRP_Record_Status not in (10200005,10200006);
--            end if;
--           intLoop:=intLoop+1;
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_CALENDAR_LOCATION,IIRP_CREATE_DATE,
--                                   IIRP_PAYMENT_FIXINGTYPE,IIRP_SERIAL_NUMBER,IIRP_RECORD_STATUS)
--                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'PLocationCode', numTemp,Gconst.TYPENODEPATH),
--                    sysdate(),82100001,intLoop,numStatus);
--        end loop;
--        
--        VarOperation:= 'Process Payment FixingDates';
--        --DELETE FROM TRTRAN091E WHERE IIRF_IRS_NUMBER = varReference;
--        select max(IIRP_SERIAL_NUMBER)
--          into intLoop
--        from TRTRAN091D
--        where IIRP_IRS_NUMBER=varReference
--        and IIRP_PAYMENT_FIXINGTYPE= 82100002;
--        
--        Varxpath := '//FixingCalendarLocs/FixingCalendarLoc';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--           if numTemp=0 then
--              varOperation:=' Update the Existing Records to in-active';
--                 update TRTRAN091D set IIRP_record_Status =10200005
--                  where IIRP_IRS_number=varReference
--                   and IIRP_PAYMENT_FIXINGTYPE= 82100001
--                   and IIRP_Record_Status not in (10200005,10200006);
--            end if;
--           intLoop:=intLoop+1;
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_CALENDAR_LOCATION,IIRP_CREATE_DATE,
--                                   IIRP_PAYMENT_FIXINGTYPE,IIRP_SERIAL_NUMBER,IIRP_RECORD_STATUS)
--                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'PLocationCode', numTemp,Gconst.TYPENODEPATH),
--                    sysdate(),82100002,intLoop,numStatus);
--        end loop;


    --end if;    

  --


return clbTemp;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('MiscUpdate', numError, varMessage,
                          varOperation, varError);
          Glog.Log_error(varError,'SCHEMA.pkgMastemaintenance.fncMiscellaneousUpdates');                       
          raise_application_error(-20101, varError);
          return clbTemp;
End fncMiscellaneousUpdates;


Procedure prcCoordinator
        (   ParamData   in  Gconst.gClobType%Type,
            ErrorData   out Gconst.gClobType%Type,
            ProcessData out Gconst.gClobType%Type,
            GenCursor   out Gconst.DataCursor,
            NextCursor  out Gconst.DataCursor,
            CursorNo3   out Gconst.DataCursor,
            CursorNo4   out Gconst.DataCursor,
            CursorNo5   out Gconst.DataCursor,
            CursorNo6   out Gconst.DataCursor,
            CursorNo7   out Gconst.DataCursor,
            CursorNo8   out Gconst.DataCursor,
            CursorNo9   out Gconst.DataCursor,
            CursorNo10   out Gconst.DataCursor,
            CursorNo11   out Gconst.DataCursor)

  is            

--|--------------------------------------------------------------|
--|Name of Function   PrcCoordinator                             |
--|Author             T M Manjunath                              |
--|Package            PkgMasterMaintenance                       |
--|Type               Procedure                                  |
--|Date of Creation   19-Mar-2007                                |
--|Last Modified On   19-Mar-2007                                |
--|Input Parameters   1.Voucher Details in Clob                  |
--|Output Parameters  1.Error Data in Clob                       |
--|                   2.Process Data in Clob                     |
--|                   3.Ref Cursor No.1 depending on operation   |
--|                   4.Ref Cursor No.2 depending on operation   |
--|Return, if any     No Returns                                 |
--|Brief Discription                                             |
--| The function                                                 |
--|                                                              |
--|--------------------------------------------------------------|

      numError                number;
      numRecordSets           number(2);
      numTemp                 number(5);
      numAction               number(4);
      numType                 number(4);
      numLocation             number(8);
      numConsignee            number(8);
      numCompany              number(8);
      varAction               varchar2(15);
      varEntity               varchar2(30);
      varType               varchar2(100);
      varUserID               varchar2(30);
      varsql                  varchar2(500);
      varOperation            GConst.gvarOperation%Type;
      varMessage              GConst.gvarMessage%Type;
      varError                GConst.gvarError%Type;
      xmlTemp                 GConst.gXMLType%Type;
      xmlTemp1                GConst.gXMLType%Type;
      nmpTemp                 xmldom.domNamedNodeMap;
      Error_Function          Exception;
      Error_Occurred          Exception;
      pData                   clob;
      clbTemp                 clob;
      docRecord               xmldom.DomDocument;
      varWebLogin             Char(1);

      ApprovalConfirmStatus  number(8);
      ApprovalConfirmRemarks Varchar(500);
      datToday               Date;
      varTypes                varchar2(100);

      VarKeyValues           varchar(5000);
      varXpath               varchar(500);
      numSub                 number(8);
      nodFinal            xmlDom.domNode;
      docFinal            xmlDom.domDocument;
      nlsTemp             xmlDom.domNodeList;
      NodTemp             xmlDom.domNode;   
      RootNode            xmlDom.domNode;
      numcode1              number(8);
      numCode2             number(8);
      numType1            number(5);
      varTemp              varchar(50);
      BEGIN
   -- insert into temp values ('Inside prcCoordinator 0','welcome'); commit;
        numError := 0;
        numRecordSets := 0;
        xmltemp := XMLTYPE(paramdata);
    --    insert into rtemp(TT,TT2) values ('Inside prcCoordinator 1','xmlTemp: '||xmlTemp);
        dbms_lob.createTemporary (clbTemp,  TRUE);
        dbms_lob.createTemporary (pData,  TRUE);

        numError := 1;
        varOperation := 'Extracting Parameters for User ID';
        varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
        varOperation := 'Extracting Parameters for Action';
        numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);
        varOperation := 'Extracting Parameters for Entity';
        varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
        varMessage := 'Entity: ' || varEntity || ' Mode: ' || numAction;
        varType := GConst.fncXMLExtract(xmlTemp, 'Type', varType);

        numRecordSets := NVL(GConst.fncXMLExtract(xmlTemp, 'RecordSets', numRecordSets),0);
        varTypes := NVL(GConst.fncXMLExtract(xmlTemp, 'Type', varTypes),0);
        varOperation := 'Extracting Parameters for varTypes';
        varOperation := 'Extracting Parameters for numRecordSets';

        varMessage := 'To Check whether User Loged in from Windows or Web : ' || varEntity || ' Mode: ' || numAction;
        begin 
            varWebLogin:= GConst.fncXMLExtract(xmlTemp, 'WEBLogin', varWebLogin);
        exception 
          when others then 
            varWebLogin:='N';
        end;
        varOperation:=' Update the table with current Date';

        update trsystem978 set asondate= sysdate;

--        insert into temp(TT,TT1) values (varWebLogin,numAction);
--        commit;
--
--        insert into rtemp(TT,TT2) values ('Inside prcCoordinator 2','varType: '||varType||' varUserID: '||varUserID||' ;numAction: '|| numAction|| ' ;numAction: '|| numAction || ' ;varEntity: '|| varEntity ||' ;varMessage: '||varMessage);
        if numAction = 0 then
          varError := 'Action type not furnished';
          raise Error_Occurred;
        end if;

--        if numAction = GConst.MENULOAD then
--          numError := 2;
--          varOperation := 'Extracting Menu Items for the user';
--          pData := ParamData;
--          numTemp := Gconst.fncSetParam(pData, 'Type', GConst.REFMENUITEMS);
--          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
--          numError := GConst.fncReturnParam(ErrorData, 'Error');
--          varError := GConst.fncReturnParam(ErrorData, 'Message');
--
--          if numError <> 0 then
--              raise Error_Function;
--          else
--              numRecordSets := numRecordSets + 1;
--          end if;
--
--        end if;

        if numAction = Gconst.BROWSERLOAD then
          numError := 3;
          varOperation := 'Setting parameters for the cursor';
          pData := ParamData;

          numTemp := GConst.fncSetParam(pData, 'Type', pkgreturncursor.REFPICKUPLIST);
          varOperation := 'Extracting Browser items for ' || varEntity;
          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);

          numError := GConst.fncReturnParam(ErrorData, 'Error');
          varError := GConst.fncReturnParam(ErrorData, 'Message');

    if numError <> 0 then
        raise Error_Function;
    end if;

    varOperation := 'Extracting XML Fields';
    pData := ParamData;
    numTemp := GConst.fncSetParam(pData, 'Type', pkgreturncursor.REFXMLFIELDS);
    pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
    numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
    varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);

    if numError <> 0 then
        raise Error_Function;
    else
        numRecordSets := 2;
    end if;

    varOperation := 'Getting key values for the entity: ' || varEntity;
    select xmlElement("KeyValues",
      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
      into xmlTemp1
      from trsystem999 a
      where fldp_table_synonym = varEntity
      and fldp_key_no != 0
      order by fldp_key_no;

    varOperation := 'Adding Key Values to the document';
    xmlTemp := Gconst.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');

    varOperation := 'Getting Show fields for the entity: ' || varEntity;
    select xmlElement("ShowFields",
      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
      into xmlTemp1
      from trsystem999 a
      where fldp_table_synonym = varEntity
      and fldp_show_yn  = 'Y';


   varOperation := 'Adding Show Values to the document';
    xmlTemp := Gconst.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');

    varOperation := 'Getting Display fields for the entity: ' || varEntity;
    select xmlElement("DisplayFields",
      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
      into xmlTemp1
      from trsystem999 a
      where fldp_table_synonym = varEntity
      and fldp_show_yn  != 'Y';

     xmlTemp := Gconst.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');

     varOperation := 'Getting Key fields Display Name for the entity: ' || varEntity;

    select xmlelement("KeyFieldsDisplayName",'')
     into xmltemp1
     from dual;

    varOperation := 'Adding Key Display Values to the document';
    xmlTemp := Gconst.fncAddNode(xmlTemp, xmltemp1, 'CommandSet');

    for cur in (select a.fldp_xml_field as FieldName
                 from trsystem999 a
                where fldp_table_synonym = varEntity
                  and fldp_key_no != 0)
    loop
      varSQL := 'select xmlElement(' || '"' || cur.FieldName || '"' || ', fldp_column_displayname )
      from trsystem999 a
      where fldp_table_synonym = ' || '''' ||  varEntity || '''' ||
       ' and fldp_xml_field = '|| '''' ||  cur.FieldName || ''''  ;

      EXECUTE IMMEDIATE  varsql into xmlTemp1;

      xmlTemp := Gconst.fncAddNode(xmlTemp, xmltemp1, 'KeyFieldsDisplayName');
    end loop;



    clbTemp := xmlTemp.GetClobVal();
    Goto Process_End;

  end if;



--        if numAction = GConst.ACTIONDATA then
--          varOperation := 'Extracting information';
--          pData := ParamData;
--          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
--          numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
--          varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);
--
--          if numError <> 0 then
--              raise Error_Function;
--          else
--              numRecordSets := 1;
--          end if;
--        numType:=GConst.fncXMLExtract(xmlType(pData), 'Type', numError);
--
--          if numType= Gconst.REFPOSITIONGAPVIEW then
--              pData := ParamData;
--              numType := GConst.fncSetParam(pData, 'Type', Gconst.REFPOSITIONGAPVIEWGRID);
--
--              pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
--              if numError <> 0 then
--                  raise Error_Function;
--              else
--                  numRecordSets := 2;
--              end if;
--          end if;
--        end if;
  if numAction in (GConst.ACTIONDATA, GConst.USERVALIDATE) then
-- Logic for extracting multiple cursors (up to 5)  
-- The signature of procedure prcCoordinator is altered accordingly
-- TMM 07/06/2017fncM

    varOperation := 'Extracting information';
    pData := ParamData;
    varOperation := 'Extracting Parameters for Cursor Types';
    numTemp := 0;

    Glog.log_write( ' Cursors Requested ' || varTypes);

    if varTypes='9999' then 
         pkgletterpackage.prcExtractLetter(ParamData,ErrorData,ProcessData,GenCursor,
            NextCursor,CursorNo3,CursorNo4,CursorNo5,CursorNo6,
            CursorNo7,CursorNo8,CursorNo9,CursorNo10,CursorNo11); 
    else
        Glog.log_write(' Cursor to Extract ' || varTypes);
        for numTemp in 1 .. numRecordSets
        Loop
            numType := substr(varTypes,instr(varTypes,',',1, numTemp)-4,4);
            Glog.log_write( numCode2 || ' Extracting Indudual Cursor ' ||numType );

            numType1:=numType;
            numType := Gconst.fncSetParam(pData, 'Type', numType); 

        begin
            select nvl(count(*),0)
              into numCode2
             from trsystem999CA
            where GRIM_RECORD_STATUS not in (10200005,10200006)
             and GRIM_CURSOR_NUMBER=numType1;
        exception 
         when no_Data_found then
          numCode2:= 0;
        end ;
           Glog.log_write( numCode2 || ' Rows found for the Cursor ' ||numType1 || ' Loop Count ' || numTemp);
            if numTemp = 1 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  GenCursor);
               end if;
            elsif numTemp = 2 then
              if numCode2=0 then 
                pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  NextCursor);
               end if;
            elsif numTemp = 3 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo3);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo3);
               end if;
                --pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo3);
            elsif numTemp = 4 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo4);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo4);
               end if;
                --pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo4);
            elsif numTemp = 5 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo5);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo5);
               end if;
            elsif numTemp = 6 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo6);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo6);
               end if;
            elsif numTemp = 7 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo7);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo7);
               end if;
            elsif numTemp = 8 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo8);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo8);
               end if;
            elsif numTemp = 9 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo9);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo9);
               end if;
            elsif numTemp = 10 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo10);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo10);
               end if;
                --pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo5);
            end if;
            -- this has been added by Manjunath Reddy on 07/08/2019 to get the Cursor schema information 
            -- this has been added by Manjunath Reddy on 07/08/2019 to get the Cursor schema information 
            Glog.log_write('Cursorno6 grid column 1 ' || varTypes || ',' || varUserID);
            open CursorNo11 for
                select GRID_CURSOR_NAME "CursorName",
                    Grid_Cursor_Number CursorNumber, 
                    --pkgreturncursor.fncgetdescription(GRID_LANGUAGE_CODE,2) LanguageCode,--- en English French fr 903
                    GRID_COLUMN_NAME ColumnName,
                    pkgreturncursor.fncgetdescription(GRID_COLUMN_TYPE,2) ColumnType , -- New Pick Code --STRING, NUMBER, DATE ColumnDataType 904
                    fncGetMultiLangText(GRID_DISPLAY_NAME) DisplayName,
                    nvl(GRID_TEXT_LENGTH,'99999') "TextLength",
                    --pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1) DisplayYN,
                     ---added by supriya
                    (case when (SELECT count(*) FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) = 0 
                         then pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1)
                         else (SELECT pkgreturncursor.fncgetdescription(Nvl(UGRD_DISPLAY_YN,12400002),1) FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) end) DisplayYN,
                    to_char(nvl(GRID_COLUMN_WIDTH,100)) Width,
--                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_YN,12400002),1) AggregateYN,
                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_FUNCTION,92699999),1) AggregateFunctionDesc,
                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_FUNCTION,92699999),2) AggregateFunction,
--                    GRID_AGGREGATE_FUNCTION AggregateFunction, -- New Pick Code -- SUM, AVG, Etc.. -905
                    pkgreturncursor.fncgetdescription(nvl(GRID_EDITABLE_YN,12400002),1) EditableYN,
                    to_char(nvl(GRID_DECIMAL_SCALE,(case when format_data_type in (90400002,90400007) 
                        then Format_Decimal_scale else 0 end))) DecimalScale, -- incase case of number Format and not
                         --specified at cursor level string take the decimal scale from Global based on User Config
                    Format_format_string "FormatString",
                    GRID_DISPLAY_ORDER "DisplayOrder",
                    to_char(nvl(GRID_PICK_GROUP,0)) "PickGroup",                    
                    GRLK_PARAMETER_LINKNAME "ParameterLinkName", GRPP_URL_LINK "URLLink",
                    GRPP_PROGRAM_UNIT "ProgramUnit", 
                    (select listagg(GRLP_PARAMETER_NAME, ',') within group (order by GRLP_PARAMETER_NAME)
                      from TRSYSTEM999CP
                      where GRLP_PARAMETER_LINKNAME = GRLK_PARAMETER_LINKNAME
                      and GRLP_RECORD_STATUS not in (10200005,10200006)) "ParameterName",
                     (select listagg(GRLP_PARAMETER_FIELD, ',') within group (order by GRLP_PARAMETER_FIELD)
                      from TRSYSTEM999CP
                      where GRLP_PARAMETER_LINKNAME = GRLK_PARAMETER_LINKNAME
                      and GRLP_RECORD_STATUS not in (10200005,10200006)) "ParameterField",
                      (select PUNT_WEBCONTROL_NAME from CLOUDDB_MASTER.TRSYSTEM005
                      where PUNT_PROGRAM_UNIT = GRPP_PROGRAM_UNIT and PUNT_RECORD_STATUS not in (10200005,10200006)) "ControllerName",
                      'ActionExecute' "ActionMethod",
                      (select nvl(GRPP_ACTION_METHOD,'View') from TRSYSTEM999CPP
                      where GRPP_PARAMETER_LINKNAME = GRLK_PARAMETER_LINKNAME
                      and GRPP_RECORD_STATUS not in (10200005,10200006)) "ActionType",
--                      pkgreturncursor.fncgetdescription(nvl(GRID_CUSTOM_EDITOR, 
--                      (case when nvl(GRID_PICK_GROUP,0) > 0 then 12400001 else 12400002 end)),1) "CustomEditorForDropDowns"
                       pkgreturncursor.fncgetdescription(nvl(GRID_CUSTOM_EDITOR,12400002),1) "CustomEditorForDropDowns" 
                    from TRSYSTEM999C left outer join trGlobalmas914
                    on Grid_Column_type = format_data_type
                    and format_pick_code =Glog.LanguageCode
                    and format_pick_code=91499999                    
                    left outer join TRSYSTEM999CL
                    on GRID_CURSOR_NUMBER = GRLK_CURSOR_REPORT AND 
                    GRID_COLUMN_NAME = GRLK_COLUMN_NAME
                    left outer join trsystem999CPP
                    on GRPP_PARAMETER_LINKNAME=GRLK_PARAMETER_LINKNAME
                    and GRPP_RECORD_STATUS not in (10200005,10200006)
                    where instr(varTypes,Grid_Cursor_Number)>0
                    order by (case when (SELECT count(*) FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) = 0 
                         then GRID_DISPLAY_ORDER
                         else (SELECT UGRD_DISPLAY_ORDER FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) end) asc;
            Glog.log_write('After Running the Cursor No 6 ' || numError || ' ' || varError);
            Glog.log_write('ErrorData222 ' || ErrorData  );
            numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
            varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);
            Glog.log_write('After Extracting the Error Details of ' || numError || numError);
           if numError <> 0 then
                raise Error_Function;
            end if;

        End Loop;
        Glog.log_write('Cursorno6 grid column End ');
   end if;

  end if; 

        if numAction in
                    ( GConst.VIEWLOAD,
                      Gconst.DELETELOAD,
                      Gconst.CONFIRMLOAD,
                      Gconst.UNCONFIRMLOAD,
                      GConst.EDITLOAD) then
            numError := 5;
            varOperation := 'Extracting entity data';

            Glog.log_write('Extracting entity data start');

            xmlTemp1 := GConst.fncGenericGet(fncBuildQuery(ParamData));
            xmlTemp := GConst.fncAddNode(xmlTemp, xmlTemp1, varEntity, 'ROW');
            clbTemp := xmlTemp.getClobVal();
            Glog.log_write('Extracting entity data end');

            open GenCursor for
            select '0' from dual;

            varOperation := 'Extracting XML Fields';
            pData := ParamData;
            numTemp := GConst.fncSetParam(pData, 'Type', pkgreturncursor.REFPICKUPFORM);
            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
            numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
            varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);

            if numError <> 0 then
                raise Error_Function;
            else
                numRecordSets := 2;
            end if;

      end if;
--insert into temp values ('Before Entering into Save Mode',numAction);commit;
--        
    if numAction in
                    ( GConst.ADDSAVE,
                      GConst.EDITSAVE,
                      GConst.DELETESAVE,
                      Gconst.UNCONFIRMSAVE,
                      Gconst.REJECTSAVE,
                      GcONST.CONFIRMSAVE,
                      Gconst.INACTIVESAVE) then

       -- insert into temp values ('Entered into Save Mode',numAction);commit;
        numError := 0;
        pData := ParamData;
        varOperation := 'Inserting Pre-edit audit Trails';
        numError := fncAuditTrail(pData, GConst.BEFOREIMAGE);

        GLog.log_write('Before Substitute- outward After MasterMaintanance');

        begin 
            select punt_postbackwith_cursors 
              into numCode2
              from Clouddb_master.trsystem005 
             where PUNT_PROGRAM_UNIT like varEntity
             and PUNT_RECORD_STATUS not in (10200005,10200006);
         exception 
         when others then
            -- Exception handlled incase of no data in 005 like Dummy File
            numCode2:=12400001;
         end;
        if numCode2=12400001 then 
            pData := fncSubstituteFields(pData, varEntity, 'Inward');
        end if;
--        insert into temp values ('After SubstituteBefore MasterMaintanance',pData);commit;
--        if numAction in( GConst.EDITSAVE) then
--       -- begin 
--            varOperation := 'Inserting Pre-edit audit Trails';
--            numError := fncAuditTrail(pData, GConst.BEFOREIMAGE);
--        end if;


--        insert into temp values('Before Insert',pData);
--        commit;
        varOperation := 'Performing Table Processing';
        clbTemp := fncMasterMaintenance(pData, numError);
--        insert into temp values('After Insert',pData);
--        commit;
        varOperation := 'Checking how many rows are processed';
        varXPath := '//' || varentity || '/ROW';
        docFinal := xmlDom.newDomDocument(xmlTemp);
        nodFinal := xmlDom.makeNode(docFinal);
    --    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        GLog.log_write('Extract Key Values' ||varXPath);
        numSub := xmlDom.getLength(nlsTemp);
        if numSub>=1 then 
            for curFields in
                (select fldp_xml_field, fldp_column_name
                    from trsystem999
                    where fldp_table_synonym = varEntity
                    and nvl(FLDP_PICK_GROUP,0)=0 
                    and nvl(FLDP_KEY_NO,0) !=0 )
            loop
              GLog.log_write('Extract Key Values entered Into Loop ' || curFields.fldp_xml_field);
               if ((VarKeyValues is null) or (VarKeyValues ='')) then
                     VarKeyValues := VarKeyValues ||  GConst.fncXMLExtract(xmltype(clbTemp), 'ROW[@NUM="1"]/' || curFields.fldp_column_name, VarKeyValues) ; 
               else 
                     VarKeyValues := VarKeyValues || '~' ||  GConst.fncXMLExtract(xmltype(clbTemp), 'ROW[@NUM="1"]/' ||curFields.fldp_column_name, VarKeyValues)  ; 
               end if;
            end loop;
        end if;

--        insert into temp values(VarKeyValues,VarKeyValues);
--        commit;



--        insert into temp values ('Before  Substitute After MasterMaintanance',clbTemp);commit;
--       

        varOperation:='Check Whether the Actual Columns or XML columns';
--      if varEntity = 'SCANNEDIMAGES' then 
--                docFinal := xmlDom.newDomDocument(xmlTemp);
--                nodFinal := xmlDom.makeNode(docFinal);
--                numError := 0;
--                varOperation := 'Processing Master Rows';
--                varXPath := '//' || varEntity || '/ROW[@NUM]';
--                nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--                Glog.Log_Write(varXPath || ' Before Loop ');
--                for numSub in 0..xmlDom.getLength(nlsTemp) -1
--                Loop
--                  nodTemp := xmlDom.Item(nlsTemp, numSub);
--                  nmpTemp:= xmlDom.getAttributes(nodTemp);
--                  nodTemp := xmlDom.Item(nmpTemp, numSub);
--                  numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--                  varTemp := '//' || varEntity || '/ROW' || '[@NUM="' || numTemp || '"]/';
--      
--                  --varXPath :='//' || varEntity ||'/ROW[@NUM="'||numSub || '"]';
--                  nodTemp := xslProcessor.selectSingleNode(nodFinal, varTemp || '/IMAG_DOCUMENT_IMAGE');
----                  if  docFinal.GETLENGTH(nodTemp)=0 then
----                         Glog.Log_Write(varXPath || ' Extracting image Document Type is coming Null ');
----                  end if;
--                  Glog.Log_Write(varXPath || ' Inside Loop ');
--                  --XMLDOM.SETNODEVALUE(nodTemp, 'Null');
--                  nodTemp := xmlDom.REMOVECHILD(nodTemp, nodTemp);
--                 end loop;
               -- clbTemp:=null;
                -- XMLDOM.WRITETOCLOB(docFinal, clbTemp);
        if numCode2=12400001 then 
             clbTemp := fncSubstituteFields(clbTemp, varEntity, 'Outward');
        end if;
--        insert into temp values ('After  Substitute After MasterMaintanance',clbTemp);commit;
--        
        GLog.log_write('After Substitute- outward After MasterMaintanance');
--        varOperation := 'Inserting Post-edit audit Trails';
--        numError := fncAuditTrail(clbTemp, Gconst.AFTERIMAGE);

--        if numError <> 0 then
--            raise Error_Function;
--        end if;
      begin
        select nvl(PUNT_POSTBACKWITH_CURSORS,12400001)
          into numcode1
          from Clouddb_master.trsystem005
          where PUNT_PROGRAM_UNIT=varEntity
          and punt_Record_status not in (10200005,10200006);
      exception
        when others then
        numcode1:=12400001;
     end;
       varoperation:='Checking whether the Cursors required for the Action For ' ||varEntity || numcode1 ;   
       GLog.log_write(varoperation);
-- Changed by Manjunath Reddy to take care of new changes 
--       if numcode1 = 12400001 then
--     
--            VarOperation:='Remove Additional Information from XML';
--            xmlTemp:=XMLTYPE(pData);
--            
--            select DELETEXML(xmlTemp,'/Treasury/EntityAdditionalInfo')
--              into xmlTemp from dual;
--            pData:=xmlTemp.getclobval();
--            
--            
--           -- insert into tempClob values ( varoperation,pData);commit;   
--            VarOperation:='Get Details for the Synonym Config';
--            Glog.log_write(VarOperation);
--            numTemp := GConst.fncSetParam(pData, 'Type', 1004);
--            Glog.log_write('after set param Type');
--            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
--            Glog.log_write('after get cursor Type 1004');
--            VarOperation:='Get Details for the Buttons';
--            Glog.log_write(VarOperation);
--            
--            
--            numTemp := GConst.fncSetParam(pData, 'Type',1005);
--            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, nextCursor);
--            
--            numTemp := GConst.fncSetParam(pData, 'Type',3028);
--            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo3);
--            
--            numTemp := GConst.fncSetParam(pData, 'Type',3029);
--            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo4);
--    
--            numTemp := GConst.fncSetParam(pData, 'Type',3078);
--            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo5);
--            
--            Glog.log_write('Extracted Information for Type 3078' );
--            Glog.log_write('Cursorno6 grid column 2');
--                    open CursorNo6 for
--                    --commented by supriya
--    --            select GRID_CURSOR_NAME "CursorName",
--    --                Grid_Cursor_Number CursorNumber, 
--    --                --pkgreturncursor.fncgetdescription(GRID_LANGUAGE_CODE,2) LanguageCode,--- en English French fr 903
--    --                GRID_COLUMN_NAME ColumnName,
--    --                pkgreturncursor.fncgetdescription(GRID_COLUMN_TYPE,2) ColumnType , -- New Pick Code --STRING, NUMBER, DATE ColumnDataType 904
--    --                GRID_DISPLAY_NAME DisplayName,
--    --                pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1) DisplayYN,
--    --                to_char(nvl(GRID_COLUMN_WIDTH,100)) Width,
--    --                pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_YN,12400002),1) AggregateYN,
--    --                GRID_AGGREGATE_FUNCTION AggregateFunction, -- New Pick Code -- SUM, AVG, Etc.. -905
--    --                pkgreturncursor.fncgetdescription(nvl(GRID_EDITABLE_YN,12400002),1) EditableYN,
--    --                to_char(nvl(GRID_DECIMAL_SCALE,(case when format_data_type in (90400002,90400007) 
--    --                    then Format_Decimal_scale else 0 end))) DecimalScale, -- incase case of number Format and not
--    --                     --specified at cursor level string take the decimal scale from Global based on User Config
--    --                Format_format_string "FormatString",
--    --                GRID_DISPLAY_ORDER "DisplayOrder",
--    --                to_char(nvl(GRID_PICK_GROUP,0)) "PickGroup"
--    --                from TRSYSTEM999C left outer join trGlobalmas914
--    --                on Grid_Column_type = format_data_type
--    --                and format_pick_code=91499999
--    --                where instr('1004,1005,3028,3078',Grid_Cursor_Number)>0
--    --                order by GRID_DISPLAY_ORDER asc;
--    
--    ----added by supriya on 08/12/2020
--            select GRID_CURSOR_NAME "CursorName",
--                    Grid_Cursor_Number CursorNumber, 
--                    --pkgreturncursor.fncgetdescription(GRID_LANGUAGE_CODE,2) LanguageCode,--- en English French fr 903
--                    GRID_COLUMN_NAME ColumnName,
--                    pkgreturncursor.fncgetdescription(GRID_COLUMN_TYPE,2) ColumnType , -- New Pick Code --STRING, NUMBER, DATE ColumnDataType 904
--                    GRID_DISPLAY_NAME DisplayName,
--                    nvl(GRID_TEXT_LENGTH,'99999') "TextLength",
--                    --pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1) DisplayYN,
--                    (case when (SELECT count(*) FROM TRSYSTEM999CU
--                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
--                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
--                                  and upper(UGRD_USER_ID) = upper(varUserID)
--                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) = 0 
--                         then pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1)
--                         else (SELECT pkgreturncursor.fncgetdescription(Nvl(UGRD_DISPLAY_YN,12400002),1) FROM TRSYSTEM999CU
--                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
--                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
--                                  and upper(UGRD_USER_ID) = upper(varUserID)
--                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) end) DisplayYN,
--                    to_char(nvl(GRID_COLUMN_WIDTH,100)) Width,
----                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_YN,12400002),1) AggregateYN,
--                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_FUNCTION,92699999),1) AggregateFunctionDesc,
--                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_FUNCTION,92699999),2) AggregateFunction,
----                    GRID_AGGREGATE_FUNCTION AggregateFunction, -- New Pick Code -- SUM, AVG, Etc.. -905
--                    pkgreturncursor.fncgetdescription(nvl(GRID_EDITABLE_YN,12400002),1) EditableYN,
--                    to_char(nvl(GRID_DECIMAL_SCALE,(case when format_data_type in (90400002,90400007) 
--                        then Format_Decimal_scale else 0 end))) DecimalScale, -- incase case of number Format and not
--                         --specified at cursor level string take the decimal scale from Global based on User Config
--                    Format_format_string "FormatString",
--                    GRID_DISPLAY_ORDER "DisplayOrder",
--                    to_char(nvl(GRID_PICK_GROUP,0)) "PickGroup"
--                from TRSYSTEM999C left outer join trGlobalmas914
--                on Grid_Column_type = format_data_type
--                and format_pick_code = 91499999
--                where instr('1004,1005,3028,3078', Grid_Cursor_Number)>0
--                order by (case when (SELECT count(*) FROM TRSYSTEM999CU
--                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
--                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
--                                  and upper(UGRD_USER_ID) = upper(varUserID)
--                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) = 0 
--                         then GRID_DISPLAY_ORDER
--                         else (SELECT UGRD_DISPLAY_ORDER FROM TRSYSTEM999CU
--                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
--                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
--                                  and upper(UGRD_USER_ID) = upper(varUserID)
--                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) end) asc;
--                
--       end if;     

    if Numcode1 =12400001 then

       for numTemp in 1 .. numRecordSets
        Loop
            numType := substr(varTypes,instr(varTypes,',',1, numTemp)-4,4);
            Glog.log_write( numCode2 || ' Extracting Indudual Cursor ' ||numType );

            numType1:=numType;
            numType := Gconst.fncSetParam(pData, 'Type', numType); 

        begin
            select nvl(count(*),0)
              into numCode2
             from trsystem999CA
            where GRIM_RECORD_STATUS not in (10200005,10200006)
             and GRIM_CURSOR_NUMBER=numType1;
        exception 
         when no_Data_found then
          numCode2:= 0;
        end ;
           Glog.log_write( numCode2 || ' Rows found for the Cursor ' ||numType1 || ' Loop Count ' || numTemp);
            if numTemp = 1 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  GenCursor);
               end if;
            elsif numTemp = 2 then
              if numCode2=0 then 
                pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  NextCursor);
               end if;
            elsif numTemp = 3 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo3);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo3);
               end if;
                --pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo3);
            elsif numTemp = 4 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo4);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo4);
               end if;
                --pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo4);
            elsif numTemp = 5 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo5);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo5);
               end if;
            elsif numTemp = 6 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo6);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo6);
               end if;
            elsif numTemp = 7 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo7);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo7);
               end if;
            elsif numTemp = 8 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo8);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo8);
               end if;
            elsif numTemp = 9 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo9);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo9);
               end if;
            elsif numTemp = 10 then
               if numCode2=0 then 
                 pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo10);
               else
                 pkgReturnCursor.Process_Cursor(numType1,pData, ErrorData,  CursorNo10);
               end if;
                --pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo5);
            end if;
            -- this has been added by Manjunath Reddy on 07/08/2019 to get the Cursor schema information 
            -- this has been added by Manjunath Reddy on 07/08/2019 to get the Cursor schema information 
            Glog.log_write('Cursorno6 grid column 1 ' || varTypes || ',' || varUserID);
            open CursorNo11 for
                select GRID_CURSOR_NAME "CursorName",
                    Grid_Cursor_Number CursorNumber, 
                    --pkgreturncursor.fncgetdescription(GRID_LANGUAGE_CODE,2) LanguageCode,--- en English French fr 903
                    GRID_COLUMN_NAME ColumnName,
                    pkgreturncursor.fncgetdescription(GRID_COLUMN_TYPE,2) ColumnType , -- New Pick Code --STRING, NUMBER, DATE ColumnDataType 904
                    fncGetMultiLangText(GRID_DISPLAY_NAME) DisplayName,
                    nvl(GRID_TEXT_LENGTH,'99999') "TextLength",
                    --pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1) DisplayYN,
                     ---added by supriya
                    (case when (SELECT count(*) FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) = 0 
                         then pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1)
                         else (SELECT pkgreturncursor.fncgetdescription(Nvl(UGRD_DISPLAY_YN,12400002),1) FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) end) DisplayYN,
                    to_char(nvl(GRID_COLUMN_WIDTH,100)) Width,
--                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_YN,12400002),1) AggregateYN,
                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_FUNCTION,92699999),1) AggregateFunctionDesc,
                    pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_FUNCTION,92699999),2) AggregateFunction,
--                    GRID_AGGREGATE_FUNCTION AggregateFunction, -- New Pick Code -- SUM, AVG, Etc.. -905
                    pkgreturncursor.fncgetdescription(nvl(GRID_EDITABLE_YN,12400002),1) EditableYN,
                    to_char(nvl(GRID_DECIMAL_SCALE,(case when format_data_type in (90400002,90400007) 
                        then Format_Decimal_scale else 0 end))) DecimalScale, -- incase case of number Format and not
                         --specified at cursor level string take the decimal scale from Global based on User Config
                    Format_format_string "FormatString",
                    GRID_DISPLAY_ORDER "DisplayOrder",
                    to_char(nvl(GRID_PICK_GROUP,0)) "PickGroup",                    
                    GRLK_PARAMETER_LINKNAME "ParameterLinkName", GRPP_URL_LINK "URLLink",
                    GRPP_PROGRAM_UNIT "ProgramUnit", 
                    (select listagg(GRLP_PARAMETER_NAME, ',') within group (order by GRLP_PARAMETER_NAME)
                      from TRSYSTEM999CP
                      where GRLP_PARAMETER_LINKNAME = GRLK_PARAMETER_LINKNAME
                      and GRLP_RECORD_STATUS not in (10200005,10200006)) "ParameterName",
                     (select listagg(GRLP_PARAMETER_FIELD, ',') within group (order by GRLP_PARAMETER_FIELD)
                      from TRSYSTEM999CP
                      where GRLP_PARAMETER_LINKNAME = GRLK_PARAMETER_LINKNAME
                      and GRLP_RECORD_STATUS not in (10200005,10200006)) "ParameterField",
                      (select PUNT_WEBCONTROL_NAME from CLOUDDB_MASTER.TRSYSTEM005
                      where PUNT_PROGRAM_UNIT = GRPP_PROGRAM_UNIT and PUNT_RECORD_STATUS not in (10200005,10200006)) "ControllerName",
                      'ActionExecute' "ActionMethod",
                      (select nvl(GRPP_ACTION_METHOD,'View') from TRSYSTEM999CPP
                      where GRPP_PARAMETER_LINKNAME = GRLK_PARAMETER_LINKNAME
                      and GRPP_RECORD_STATUS not in (10200005,10200006)) "ActionType",
--                      pkgreturncursor.fncgetdescription(nvl(GRID_CUSTOM_EDITOR, 
--                      (case when nvl(GRID_PICK_GROUP,0) > 0 then 12400001 else 12400002 end)),1) "CustomEditorForDropDowns"
                        pkgreturncursor.fncgetdescription(nvl(GRID_CUSTOM_EDITOR,12400002),1) "CustomEditorForDropDowns" 
                    from TRSYSTEM999C left outer join trGlobalmas914
                    on Grid_Column_type = format_data_type
                    and format_pick_code =Glog.LanguageCode
                    and format_pick_code=91499999                    
                    left outer join TRSYSTEM999CL
                    on GRID_CURSOR_NUMBER = GRLK_CURSOR_REPORT AND 
                    GRID_COLUMN_NAME = GRLK_COLUMN_NAME
                    left outer join trsystem999CPP
                    on GRPP_PARAMETER_LINKNAME=GRLK_PARAMETER_LINKNAME
                    and GRPP_RECORD_STATUS not in (10200005,10200006)
                    where instr(varTypes,Grid_Cursor_Number)>0
                    order by (case when (SELECT count(*) FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) = 0 
                         then GRID_DISPLAY_ORDER
                         else (SELECT UGRD_DISPLAY_ORDER FROM TRSYSTEM999CU
                                  where UGRD_CURSOR_NUMBER = Grid_Cursor_Number 
                                  and UGRD_COLUMN_NAME = GRID_COLUMN_NAME
                                  and upper(UGRD_USER_ID) = upper(varUserID)
                                  and UGRD_RECORD_STATUS not in (10200005,10200006)) end) asc;
            Glog.log_write('After Running the Cursor No 6 ' || numError || ' ' || varError);
            Glog.log_write('ErrorData11 '||ErrorData);
            numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
            varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);
            Glog.log_write('After Extracting the Error Details of ' || numError || numError);
           if numError <> 0 then
                raise Error_Function;
            end if;

        End Loop;

    end if;





--       --  insert into temp values (varOperation,varOperation);
--        varOperation := 'Before E-mail Notification Sent';
--       numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp,numError ) ;   
--        varOperation := 'After E-mail Notification Sent';
--     --    insert into temp values (varOperation,varOperation);
--     
--       if varEntity in ('HEDGEDEALREGISTER','IMPORTTRADEREGISTER','EXPORTTRADEREGISTER') then
--         datToday := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datToday);
--       --  pkgriskvalidation.prcRiskPopulateNew(datToday);
--        -- pkgriskvalidation.prcActiononRisk(datToday);
--         numError:=pkgriskvalidation.fncRiskPopulateGAP(datToday);
--      end if;

--                 varOperation := 'Check whether the Entity is exist into the Notification sendign list';
--        
--        begin
--            select count(*) 
--             into numtemp
--            from trsystem022B
--             where ualt_synonym_name =varEntity
--               and ualt_record_Status not in(10200005,10200006);
--        exception
--          when others then 
--            numtemp:=0;
--        end;

--        if  ( numtemp >0) then
--           varOperation := 'Before E-mail Notification Sent';
--           --numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp,numError ) ;   
--           varOperation := 'After E-mail Notification Sent';
--        end if ;
--         if varEntity in ('HEDGEDEALREGISTER','IMPORTTRADEREGISTER','EXPORTTRADEREGISTER') then
--           datToday := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datToday);
--         --  pkgriskvalidation.prcRiskPopulateNew(datToday);
--          -- pkgriskvalidation.prcActiononRisk(datToday);
--          -- numError:=pkgriskvalidation.fncRiskPopulateGAP(datToday);
--        end if;

        if numError <> 0 then
            raise Error_Function;
        else
            numRecordsets := 0;
            Goto Process_End;
        end if;
    end if;




          -- Confirm Save Store the remarks
      if  (numAction = Gconst.VIEWLOAD ) then
        begin
         ApprovalConfirmStatus := GConst.fncXMLExtract(xmlTemp, 'ApprovalConfirmStatus', ApprovalConfirmStatus);
        exception
         when others then
           ApprovalConfirmStatus :=37800000;
         end;
      end if;
      if ((numAction = Gconst.CONFIRMSAVE) or
          (numAction = Gconst.VIEWLOAD and ApprovalConfirmStatus = 37800001))  then
        varOperation := 'Checking Process Confirm and Capture the information';
        ApprovalConfirmStatus := GConst.fncXMLExtract(xmlTemp, 'ApprovalConfirmStatus', ApprovalConfirmStatus);
        ApprovalConfirmRemarks:= GConst.fncXMLExtract(xmlTemp, 'ApprovalConfirmRemarks', ApprovalConfirmRemarks);
          insert into TRTRAN100 
                (CONF_KEY_VALUES, CONF_APPROVAL_STATUS,CONF_APPROVAL_REMARKS,
                  CONF_ENTITY_NAME,CONF_USER_ID)
          Values (null,ApprovalConfirmStatus,ApprovalConfirmRemarks,
                  varEntity,varUserID);
      end if;
    --  varOperation := 'Call Sending E-mail Procedure in case of Confirmation rejected';
      if ((numAction = Gconst.VIEWLOAD) and (ApprovalConfirmStatus = 37800001))then
          varOperation := 'Check whether the Entity is exist into the Notification sendign list';

            begin
                select count(*) 
                 into numtemp
                from trsystem022B
                 where ualt_synonym_name =varEntity
                   and ualt_record_Status not in(10200005,10200006);
            exception
              when others then 
                numtemp:=0;
            end;

      end if;


      <<Process_End>>
       -- insert into temp values ('Inside prcCoordinator 0','End'); commit;
          numError := 0;
          -- 
          Glog.Log_write(varKeyValues);
          varError := 'Successful Operation ' || varKeyValues;
          ProcessData := clbTemp;
          ErrorData := Gconst.fncReturnError('Coordinator', varMessage, numRecordSets,
                numError, varOperation, varError);

    Exception

--        When Error_Function then -- Error thrown by the called method
--       --   Null;   -- Error object is already populated by the called method
----          insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
----                      ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
----              values  (-20101,varError,xmltype(ParamData),
----                      xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
--          raise_application_error(-20101, varError);
--        When Error_Occurred then
--       --  insert into rtemp(TT,TT2) values ('Inside prcCoordinator exp ',varOperation);
--          ErrorData := Gconst.fncReturnError('Coordinator',varMessage, 0, numError,varOperation,varError);
----           insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
----                       ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
----              values  (numError,varError,xmltype(ParamData),
----                       xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
        When others then
--          numError := SQLCODE;
          varError := SQLERRM || ' - ' || nvl(varError, ' ');

          ErrorData := Gconst.fncReturnError('Coordinator',varMessage, 0, numError,varOperation,varError);
         GLOG.LOG_Error(ErrorData,'SCHEMA.PKGMASTERMAINTENANCE.prcCoordinator');
           raise_application_error(-20101, ErrorData);
--        insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
--                       ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
--              values  (numError,varError,xmltype(ParamData),
--                       xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
End prcCoordinator;

function fncCurrenctExtractInfo 
   (xmlTemp in xmlType,
    ColumnField in varchar2,
    eventType in varchar2,
    Entity in varchar2) return varchar2
is 
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    numError            number;
    --clbTemp             Clob;
    varTemp             varchar(50);
    varTemp1            varchar(50);
    varTemp2            varchar(100);
begin 
    Glog.Log_Write(' Entered inside the fncCurrenctExtractInfo ' );
    varMessage := 'Current Account Entries';
--    dbms_lob.createTemporary (clbTemp,  TRUE);
--    clbTemp := RecordDetail;
--    numError := 1;
--    varOperation := 'Extracting Input Parameters';
--    xmlTemp := xmlType(RecordDetail);

    select (case when ColumnField='Systemreference' then acct_systemreference_field
                when ColumnField='ReferenceSerial' then acct_serialnumber_field
                when ColumnField='ReferenceSubSerial' then acct_subserialnumber_field
                end)
    into varTemp       
    from trconfig002 
    where acct_record_status not in (10200005,10200006)
    and acct_synonym_name= Entity
    and acct_event_type=eventType;
    -- we are checking the is number to check in case of serial number or any number has been hard coded 
    -- if yes then return the same number
    if (is_number(varTemp)) ='N'then
        select FLDP_COLUMN_NAME 
         into varTemp1
        from trsystem999
        where fldp_table_synonym =Entity
        and FLDP_XML_FIELD=varTemp
        and fldp_record_status not in (10200005,10200006);

        varTemp2 := '//' || Entity || '/ROW[@NUM]/' || varTemp1 ;
        varTemp := GConst.fncXMLExtract(xmlTemp,varTemp2,varTemp, Gconst.TYPENODEPATH);
    end if;
    return varTemp;
exception
  when others then 
    varError := SQLERRM || ' - ' || nvl(varError, ' ');
    varError := Gconst.fncReturnError('Coordinator',varMessage, 0, numError,varOperation,varError);
    GLOG.LOG_Error(varError,'SCHEMA.PKGMASTERMAINTENANCE.fncCurrenctExtractInfo');
           raise_application_error(-20101, varError);
end fncCurrenctExtractInfo;

Function fncCurrentAccount
    (   RecordDetail in GConst.gClobType%Type,
        ErrorNumber in out nocopy number)
    return clob
    is
--  Created on 23/09/2007
    numError            number;
    numTemp             number;

    numStatus           number;
    numSub              number(3);
    numAction           number(4);
    numSerial           number(5);
    numCompany          number(8);
    numLocation         number(8);
    numBank             number(8);
    numCrdr             number(8);
    numType             number(8);
    numHead             number(8);
    numCurrency         number(8);
    numMerchant         number(8);
    numRecord           number(8);
    numFCY              number(15,4);
    numRate             number(15,4);
    numINR              number(15,2);
    varAccount          varchar2(25);
    varVoucher          varchar2(25);
    varBankRef          varchar2(25);
    varReference        varchar2(30);
    varUserID           varchar2(30);
    varEntity           varchar2(30);
    varDetail           varchar2(100);
    varterminalid       varchar2(100);
    varTemp             varchar2(512);
    varTemp1            varchar2(512);
    varTemp2            varchar2(512);
    varXPath            varchar2(512);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         date;
    datTransDate        date;
    clbTemp             clob;
    clbentrydetails    clob;
    xmlTemp             xmlType;
    nodTemp             xmlDom.domNode;
    nodVoucher          xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodeMap;
    nlsTemp             xmlDom.DomNodeList;
    nlsTemp1            xmlDom.DomNodeList;
    xlParse             xmlparser.parser;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    numRecords          number;

--    numCompany          number(8);
--    numLocation         number(8);
    numPortfolio        number(8);
    numSubSerial        number(5);
    numSubPortfolio     number(8);
Begin
    Glog.Log_Write(' Entered inside the fncCurrentAccount ');
    varMessage := 'Current Account Entries';
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := RecordDetail;
    numError := 1;
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(RecordDetail);
--  insert into temp values ('Enter Into CA',xmlTemp); commit;
--  
--    varUserID := GConst.fncXMLExtract(xmlTemp, 'User', varUserID);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
    Glog.Log_Write(varOperation);
    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    varterminalid:=GConst.fncXMLExtract(xmlTemp, 'TerminalID', varterminalid);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyId', numCompany);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);



     select xmlElement("AuditTrails" , xmlElement("AuditTrail" ,
                    XmlForest( numAction as "Process" ,
                               varUserID as "UserName" ,
                               to_char(systimestamp ,'dd-mon-yyyy hh24:mi:ss:FF3') as "TimeStamp" ,
                               varterminalid as "TerminalName" ,
                               to_char(datworkdate,'dd-mon-yyyy') as "ProcessDate"
                               ))).getclobval()
        into clbentrydetails
        from Dual ;

    numError := 2;
    varOperation := 'Creating Document for Master';
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

    varXPath := '//CURRENTACCOUNTMASTER/DROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);

    Glog.Log_Write(' Extracting' || varXPath);
    if numSub = 0 then
      return clbTemp;
    End if;
    varOperation := 'Extracting Account Number';
--    Begin

--     IF varEntity ='MARKETDEALCONFIRMATION' THEN
--         varTemp := varXPath || '[@NUM="2"]/LocalBank';
--     ELSE
--        varTemp := varXPath || '[@NUM="1"]/LocalBank';
--     END IF;
--      numBank := GConst.fncXMLExtract(xmlTemp,varTemp,numBank,Gconst.TYPENODEPATH);
--
--      select lbnk_Account_number
--        into varAccount
--        from trmaster306
--        where lbnk_company_code = numCompany
--        and lbnk_pick_code = numBank;
--        --and bank_record_type = GConst.BANKCURRENT
----        and bank_effective_date =
----        (select max(bank_effective_date)
----          from tftran015
----          where bank_company_code = numCompany
----          and bank_local_bank = numBank
----          and bank_record_type = GConst.BANKCURRENT
----          and bank_effective_date <= datWorkDate);
--    Exception
--      when no_data_found then
--        varAccount := '';
--    End;

    varOperation := 'Assign the datworkdate as by default to transactiondate';

    datTransDate:= datWorkdate;
    varOperation := 'Process begin to load the data';

    for numSub in 0..xmlDom.getLength(nlsTemp) -1
    Loop

      varOperation := 'Extracting Data';
      nodTemp := xmlDom.Item(nlsTemp, numSub);
      nmpTemp:= xmlDom.getAttributes(nodTemp);
      nodTemp := xmlDom.Item(nmpTemp, 0);
      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
      varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
      varTemp1 := varTemp || 'LocalBank';
      numBank := GConst.fncXMLExtract(xmlTemp,varTemp1,numBank,Gconst.TYPENODEPATH);
      varOperation := 'Extracting VoucherNumber';
     -- nodVoucher := xmlDom.Item(xslProcessor.selectNodes(nodFinal, varTemp || 'VoucherNumber'),0);

      nodVoucher := xslProcessor.selectSingleNode(nodFinal, varTemp || 'VoucherNumber');
      begin
       varTemp1 := varTemp || 'AccountNumber';
      varAccount := GConst.fncXMLExtract(xmlTemp, varTemp1, varAccount,Gconst.TYPENODEPATH);
        exception
          when others then
          varAccount:='0';
      end;    
      Glog.Log_Write(' Extracting' || varTemp1);
      varTemp1 := varTemp || 'CreditDebit';
      numCrdr := GConst.fncXMLExtract(xmlTemp,varTemp1,numCrdr,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'AccountHead';
      numHead := GConst.fncXMLExtract(xmlTemp,varTemp1,numHead,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherType';

        varOperation := 'Extracting VoucherType';

      numType := GConst.fncXMLExtract(xmlTemp,varTemp1,numType,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'RecordType';
      numRecord := GConst.fncXMLExtract(xmlTemp,varTemp1,numRecord,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'CurrencyCode';
      numCurrency := GConst.fncXMLExtract(xmlTemp,varTemp1,numCurrency,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherReference';
--      varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);


      varTemp1 := varTemp || 'Systemreference';

      begin 
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);
      exception 
      when others then 
        varReference:=null;
      end ;
      if varReference is null then
            varReference:= fncCurrenctExtractInfo(xmlTemp,'Systemreference',numType,varEntity);
      end if;

      varOperation := 'Extracting ReferenceSerial';
      varTemp1 := varTemp || 'ReferenceSerial';

      begin 
         numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
      exception
      when others then
         numSerial:=0;
      end;
      if (numSerial =0) then
            numSerial:= fncCurrenctExtractInfo(xmlTemp,'ReferenceSerial',numType,varEntity);
      end if;
      varTemp1 := varTemp || 'ReferenceSubSerial';
      begin
         numSubSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
      exception
      when others then 
        numSubSerial:=0;
      end;

      if (numSubSerial=0) then
           numSubSerial:= fncCurrenctExtractInfo(xmlTemp,'ReferenceSubSerial',numType,varEntity);
      end if;

      varTemp1 := varTemp || 'VoucherFcy';
      numFcy := GConst.fncXMLExtract(xmlTemp,varTemp1,numFcy,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherRate';
      numRate := GConst.fncXMLExtract(xmlTemp,varTemp1,numRate,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherInr';
      numInr := GConst.fncXMLExtract(xmlTemp,varTemp1,numInr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherDetail';
--

--      varOperation := 'Extracting Voucher Details';
--      varDetail := GConst.fncXMLExtract(xmlTemp,varTemp1,varDetail,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'BankReference';
      begin
      varBankRef := GConst.fncXMLExtract(xmlTemp,varTemp1,varBankRef,Gconst.TYPENODEPATH);
      exception
      when others then 
        varBankRef:='NA';
      end;
        Glog.Log_Write(' Extracting' || varTemp1);
      varTemp1 := varTemp || 'Company';
      numCompany := GConst.fncXMLExtract(xmlTemp,varTemp1,numCompany,Gconst.TYPENODEPATH);

      varTemp1 := varTemp || 'Location';
      numLocation := GConst.fncXMLExtract(xmlTemp,varTemp1,numLocation,Gconst.TYPENODEPATH);

      varTemp1 := varTemp || 'Portfolio';
      numPortfolio := GConst.fncXMLExtract(xmlTemp,varTemp1,numPortfolio,Gconst.TYPENODEPATH);

      varTemp1 := varTemp || 'Subportfolio';
      numSubPortfolio := GConst.fncXMLExtract(xmlTemp,varTemp1,numSubPortfolio,Gconst.TYPENODEPATH);


--      varTemp1 := varTemp || 'LocalMerchant';
--      numMerchant := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
        numMerchant:=30600001;
       varOperation := 'Extracting RecordStatus';
      varTemp1 := varTemp || 'RecordStatus';
      numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
       Glog.Log_Write(' Extracting' || varTemp1);
      varOperation := 'After Extracting Data';
      if numAction = GConst.DELETESAVE then
        numStatus := GConst.LOTDELETED;
      elsif numAction = GConst.CONFIRMSAVE then
        numStatus := GConst.LOTCONFIRMED;
      elsif numAction = GConst.ADDSAVE then ---addedd by prasanta
         numStatus := GConst.LOTNEW ;
      end if;

--         if varEntity in ('BONDDEBENTUREPURCHASE') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BPUR_DEAL_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BPUR_VALUE_DATE';
--          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--         
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BPUR_COMPANY_CODE'; 
--          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--        
--        elsif varEntity in ('BONDDEBENTUREREDEMPTION') then
--         
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRED_DEAL_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRED_SETTLEMENT_DATE';
--          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--         
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRED_COMPANY_CODE'; 
--          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);   
--        elsif varEntity in ('FDCLOSURE','FDCLOSURECONFIRM') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_FD_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_SR_NUMBER';
--          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_TRANSACTION_DATE';
--          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_COMPANY_CODE'; 
--          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--          
--        elsif ((varEntity ='FIXEDDEPOSITFILE') or (varEntity ='FIXEDDEPOSITFILECONFIRM')) then
--
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_FD_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_SR_NUMBER';
--          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_TRANSACTION_DATE';
--          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_COMPANY_CODE'; 
--          numCompany := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--          
--         --- insert into temp values ('Extract',varReference);
--       elsif varEntity in ('MUTUALFUNDCLOSURE','MUTUALFUNDCLOSURECONFIRM') then
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_REFERENCE_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          -- varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_SERIAL_NUMBER';
--          -- numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--           numSerial := 0;
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_TRANSACTION_DATE';
--           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_COMPANY_CODE'; 
--           numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--
--      elsif varEntity in ('MUTUALFUNDTRANSACTION','MUTUALFUNDTRANSACTIONCONFIRM') then
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_REFERENCE_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--           --varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_SERIAL_NUMBER';
--           -- numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--           numSerial:=0;
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_TRANSACTION_DATE';
--           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_COMPANY_CODE'; 
--          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--           
--      elsif varEntity in ('MARKETDEAL' ,'MARKETDEALCONFIRMATION') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MDEL_DEAL_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial:=0;
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MDEL_VALUE_DATE';
--          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MDEL_COMPANY_CODE'; 
--          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--          
----        elsif varEntity in ('DEALREDEMPTION' ,'DEALREDEMPTIONCONFIRMATION') then
----          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_DEAL_NUMBER';
----          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
----          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_SERIAL_NUMBER';
----          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial,Gconst.TYPENODEPATH);
----          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_CLOSURE_DATE';
----          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
----          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_COMPANY_CODE'; 
----          numCompany := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
----          
----          if  numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
----            varOperation := 'Updating Process Complete for Market Deal';
----            update trtran031
----              set mdel_process_complete = 12400001,
----              mdel_complete_date = datTransDate
----              where mdel_deal_number = varReference;
----          elsif numAction = GConst.DELETESAVE then
----            update trtran031
----              set mdel_process_complete = 12400002,
----              mdel_complete_date = NULL
----              where mdel_deal_number = varReference;
----          End if;
--
--        elsif varEntity in ('PSLLOAN', 'PSCFCLOAN') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/INLN_PSLOAN_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--
--        elsif varEntity = 'BILLREALISATION' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BREL_REALIZATION_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'IMPORTREALIZE' then
--         varTemp2 := '//' || varEntity || '/ROW[@NUM]//BREL_REVERSE_SERIAL';
--         numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'ROLLOVERFILE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/LMOD_REFERENCE_SERIAL';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BUYERSCREDIT' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRD_BUYERS_CREDIT';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'EXPORTADVANCE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/EADV_ADVANCE_REFERENCE';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity in ('INTERESTCAL', 'LOANCLOSURE') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/INTC_PSLOAN_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--        elsif varEntity = 'TERMLOAN' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/TLON_LOAN_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'FOREIGNREMITTANCE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REMT_REMITTANCE_REFERENCE';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'IMPORTLCAMENDMENT' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/POLC_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BUYERSCREDITROLLOVER' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRL_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BCCLOSURE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRPY_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BANKGUARANTEE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BGAR_BG_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'BGROLLOVER' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BGRL_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif ((VarEntity ='DEALCONFIRMCANCELATION') or (VarEntity ='FORWARDDEALCANCELFOREDIT') or
--         (VarEntity ='HEDGEDEALCANCELLATION') or (VarEntity ='TRADEDEALCANCELLATION')) then 
--           varTemp1 := '//' || varEntity || '/ROW[@NUM]/CDEL_DEAL_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CDEL_REVERSE_SERIAL';
--           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CDEL_CASHFLOW_DATE';
--           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--        elsif ((VarEntity ='OPTIONHEDGEEXERCISE') or (VarEntity ='OPTIONTRADEEXERCISE')) then 
--           varTemp1 := '//' || varEntity || '/ROW[@NUM]/CORV_DEAL_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CORV_SERIAL_NUMBER';
--           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);    
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CORV_SETTLEMENT_DATE';
--           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
----           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_COMPANY_CODE'; 
----           numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--           
--        elsif ((VarEntity ='OPTIONHEDGEDEAL') or (VarEntity ='OPTIONTRADEDEAL')) then 
--           varTemp1 := '//' || varEntity || '/ROW[@NUM]/COPT_DEAL_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_SERIAL_NUMBER';
--           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);    
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_PREMIUM_VALUEDATE';
--           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_COMPANY_CODE'; 
--           numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
--          
--        elsif ((VarEntity ='CCIRSSETTLEMENT')) THEN 
--           varTemp1 := '//' || varEntity || '/ROW[@NUM]/ICST_IRS_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/ICST_LEG_SERIAL';
--           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif ((VarEntity ='IRSSETTLEMENT')) THEN 
--           varTemp1 := '//' || varEntity || '/ROW[@NUM]/IIRM_IRS_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/IIRM_LEG_SERIAL';
--           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--            varTemp2 := '//' || varEntity || '/ROW[@NUM]/IIRM_SETTLEMENT_DATE';
--           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--           
--        elsif ((VarEntity ='IMPORTREALIZE') or (VarEntity ='EXPORTREALIZE') or
--         (VarEntity ='BUYERSCREDITCLOSER')) THEN 
--           varTemp1 := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="1"]/DealNumber';--'//' || varEntity || '/ROW[@NUM]/DealNumber';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/BREL_REVERSE_SERIAL';
--           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);   
--        elsif ((VarEntity ='HEDGEDEALREGISTER')) then 
--         
--           varTemp1 := '//' || varEntity || '/ROW[@NUM]/DEAL_DEAL_NUMBER';
--           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
--           numSerial := 1 ;
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/DEAL_EXECUTE_DATE';
--           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);       
--        end if;


    if numStatus = GConst.LOTMODIFIED then
               varOperation := 'in Edit mode Update the Old transaction to Status in active';

                   update trtran008
                    set bcac_record_status = 10200005, bcac_add_date =sysdate,
                    bcac_account_number = varAccount
                    where bcac_voucher_reference = varReference
                    and bcac_reference_serial = numSerial
                    and bcac_account_head = numHead
                   -- and BCAC_ENTRY_DETAIL=xmltype(clbentrydetails)
                    and bcac_voucher_type=numType
                    and bcac_crdr_code=numCrdr
                    and bcac_record_Status not in (10200005,10200006)
                    and bcac_voucher_number = (  select max(bcac_voucher_number)  from trtran008
                                                where bcac_voucher_reference =varReference
                                                  and bcac_reference_serial = numSerial
                                                  and bcac_account_head =numHead
                                                  and bcac_record_Status not in(10200005,10200006)) ;

                    numRecords := SQL%ROWCOUNT;
                    numStatus := GConst.LOTNEW;
--                    if numRecords >= 0  then
--                        numStatus := GConst.LOTNEW;
--                    elsif varEntity ='MUTUALFUNDCLOSURE'   then
--                       select nvl(count(*),0) into numRecords from trtran008
--                                  where bcac_voucher_reference =varReference
--                                    and bcac_reference_serial = numSerial
--                                    and bcac_account_head =numHead
--                                    and bcac_voucher_type=numType
--                                    and bcac_crdr_code=numCrdr
--                                    and bcac_record_Status not in(10200005,10200006);
--                        if numRecords = 0  then
--                            numStatus := GConst.LOTNEW;
--                        end if;
--                    end if;
--                    if numRecords = 0  then
--                            numStatus := GConst.LOTNEW;
--                    end if;
--            end if;
      end if;
 --insert into temp values ('Enter Into CA ' || numStatus ,numStatus); commit;
      if numStatus = GConst.LOTNOCHANGE then
        NULL;

      elsif numStatus = GConst.LOTNEW then
      varOperation := 'in Edit mode Update the Old transaction to Status in active';
       Glog.Log_Write('Inside LotNew - Inserting into trtran008');
       -- insert into temp values ('Enter Into CA LOTNEW','3'); commit;
        varVoucher := 'VC/Tr/' || fncGenerateSerial(SERIALCURRENT, 0);
            insert into trtran008 (bcac_company_code, bcac_location_code,
            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
            bcac_record_type, bcac_account_number, bcac_bank_reference,BCAC_ENTRY_DETAIL)
            values(numCompany, numLocation, numBank, varVoucher, datTransDate,
            numCrdr, numHead, numType, varReference, numSerial, numCurrency,
            numFcy, numRate, numInr,varDetail , sysdate,sysdate, numMerchant, GConst.STATUSENTRY,
            numRecord, varAccount, varBankRef,xmltype(clbentrydetails));

            numError := GConst.fncSetNodeValue(nodFinal, nodVoucher, varVoucher);

        elsif ((numStatus= GConst.LOTDELETED)) then
--            select decode(numStatus,
--              GConst.LOTDELETED, GConst.STATUSDELETED,
--              GConst.LOTCONFIRMED, GConst.STATUSAUTHORIZED)
--              into numStatus
--              from dual;
 -- insert into temp values ('Enter Into CA LOTNEW' || numStatus,'4'); commit;
            varOperation := 'Processing Current Account Transaction';

            update trtran008
              set bcac_record_status = GConst.STATUSDELETED,
                  bcac_add_date =sysdate,
                  bcac_account_number = varAccount
              where bcac_voucher_reference = varReference
              and bcac_reference_serial = numSerial
              and bcac_voucher_type=numType
              and bcac_account_head = numHead
              and bcac_record_Status not in(10200005,10200006);

        elsif  (numStatus= GConst.LOTCONFIRMED) then
            varOperation := 'Processing Current Account Transaction';

            update trtran008
              set bcac_record_status = GConst.STATUSAUTHORIZED,
                  bcac_add_date =sysdate
              where bcac_voucher_reference = varReference
              and bcac_reference_serial = numSerial
              and bcac_voucher_type=numType
              and bcac_account_head = numHead
              and bcac_record_Status not in(10200003,10200005,10200006);
        end if;

    End Loop;

    dbms_lob.createTemporary (clbTemp,  TRUE);
    xmlDom.WriteToClob(nodFinal, clbTemp);

    return clbTemp;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM || varVoucher;
      varError := GConst.fncReturnError('CurAccount', numError, varMessage,
                      varOperation, varError);
      GLOG.LOG_Error(varError,'SCHEMA.PKGMASTERMAINTENANCE.fncCurrentAccount');                
      raise_application_error(-20101, varError);
      return clbTemp;
END fncCurrentAccount;


Function fncSubstituteFields
    (ParamData in Gconst.gClobType%Type,
     EntityName in varchar2,
     InwardOutward in varchar2)
return clob
is
    varEntity           varchar2(30);
    numError            Number;
    varOperation        varchar(4000);
    varMessage          varchar(4000);
    varError            varchar(4000);
    xmlTemp             xmltype;
    clbTemp             clob;
    clbTemp1             clob;
    nodTemp             xmlDom.domNode;
    nodTemp1             xmlDom.domNode;
    nodInnerTemp        xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodFinal            xmlDom.domNode;
    RootNode            xmlDom.domNode;
    TXTNODE             XMLDOM.DOMTEXT;
    varXPath            varchar2(512);
    varXPath1            varchar2(512);
    varColumnType       varchar(100);           
    nlsTemp             xmlDom.DomNodeList;
    nlsTempInner        xmlDom.DomNodeList;
    nmpTemp             xmldom.domNamedNodeMap;
    ELMXML              XMLDOM.DOMELEMENT;
    numSub              number(5);
    varNodeName         varchar(30);
    varTemp             varchar2(100);
    clbNodeValue        Clob;
    BloNodeValue        Blob;
    varNodeValue        varchar2(4000);
    numInnerSub         number(5);
    TXTDOM              XMLDOM.DOMTEXT;
    numAction           number(8);
    VarParseEntity      varchar(100);
    varParseNode        varchar(100);
    varQuery            varchar(4000);
    numformatDataType   number(8);
    numGeneralDataType  number(8);
    varFormatString     varchar(50);
    VARTEMP1            varchar(100); 
Begin
    varMessage := 'Substituting XML Fields to DB Fields  for ' ||  EntityName || ' Type ' ||  InwardOutward  ;
    Glog.log_write('fncSubstituteFields ' || varMessage);
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := ParamData;
    VarOperation:='Processing XML convertion for ' ||  EntityName || ' Type ' ||  InwardOutward ;
    xmlTemp:=XMLTYPE(ParamData);
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

    -- numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);


   -- dbms_lob.createtemporary (clbTempRows,true);
    --clbTempRows := nlsTemp;

    varXPath := '//' || EntityName  ;
    RootNode:= xslProcessor.SELECTSINGLENODE(nodFinal,varXPath);
--                nodTemp:=XMLDOM.REMOVECHILD(nodTemp, nodTemp);

    Glog.log_write('varXPath ' || varXPath);
    varXPath := '//' || EntityName || '/ROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);

    for numSub in 1..xmlDom.getLength(nlsTemp)
    Loop
        varOperation := 'Extracting Data' || numSub;
        nodTemp := xmlDom.Item(nlsTemp, numSub);
        nmpTemp:= xmlDom.getAttributes(nodTemp);
        nodTemp := xmlDom.Item(nmpTemp, 0);
      --  GLOG.log_write('You message goes here'|| numSub);
      -- GLOG.log_write('You message goes here'|| InwardOutward);
        --xmlDom.writeToClob(nodTemp, clbTemp);
        varXPath :='//' || EntityName ||'/ROW[@NUM="'||numSub || '"]';
       -- VARTEMP := '//' || TRIM(NODENAME) || '/text()';
       -- nlsTempInner := xslProcessor.selectNodes(nodFinal, varXPath);
       Glog.log_write('varXPath ' || varXPath);
        RootNode:= xslProcessor.SelectSingleNode(nodFinal, varXPath);
        nlsTempInner :=xmlDom.getChildNodes(RootNode);
        for numInnerSub in 0..dbms_xmldom.getLength(nlsTempInner) -1
        loop

           nodTemp := xmlDom.Item(nlsTempInner, numInnerSub);
           varNodeName := DBMS_XMLDOM.getNodeName(nodTemp);
           varoperation:='Processign Node ' ||varNodeName;
           varXPath1:=varXPath || '/' || varNodeName || '/text()';
            Glog.log_write(varoperation || ' varNodeName '|| varNodeName);
          if  InwardOutward = 'Inward' then     

              begin
                 select fldp_column_name,FLDP_DATA_TYPE,
                        FORMAT_DATA_TYPE,nvl(FORMAT_GENERAL_DATATYPE,94099999),
                        FORMAT_FORMAT_STRING
                       into varTemp,varColumnType, numformatDataType,numGeneralDataType,
                            varFormatString
                      from trsystem999 left outer join trglobalmas914
                         on FORMAT_DATA_TYPE=FLDP_TEXT_FORMAT_CODE
                         and format_pick_code =Glog.LanguageCode
                         and format_record_Status not in (10200005,10200006)
                      where fldp_table_synonym = EntityName
                        and fldp_xml_field=varNodeName;
                 exception 
                 when no_data_found then 
                    varTemp:=null;
                 end;
           end if;
           if  InwardOutward = 'Outward' then
              begin
                select fldp_xml_field,FLDP_DATA_TYPE
                 into varTemp,varColumnType
                from trsystem999
                where fldp_table_synonym = EntityName
                  and fldp_column_name=varNodeName;
              exception 
                when no_data_found then 
                    varTemp:=null;
              end;
           End if;

            varoperation:='Extracting Value ' ||varNodeName;
--             if ((varColumnType in ('CLOB','BLOB')) and (InwardOutward = 'Inward'))  then 
--                varoperation:='Extracting Clob ' ||varNodeName;
--                VarParseEntity:= '//' || EntityName;
--                varParseNode:='//' || varNodeName; 
--                
----               varQuery:= 'SELECT x.LoadData
----                    FROM dual , XMLTable(' || '''' || VarParseEntity  || '''' ||
----                      ' passing xmltype(' || ''''|| xmlTemp.getClobVal() || '''' || ')  columns
----                               LoadData  BLOB path ' || '''' || varParseNode || '''' ||
----                                ') x';
------               varQuery:= 'SELECT x.LoadData
------                    FROM dual , XMLTable(:1 passing :2  columns
------                               LoadData  :3 path :4
------                                ) x';
----                GLOG.log_write(varQuery);
----                
----                execute immediate varQuery into BloNodeValue ;
----                
--                --using VarParseEntity,xmlTemp.getClobVal(),varColumnType,varParseNode ;
--              if EntityName='DATAUPLOADMASTER' then
--                 SELECT x.LoadData
--                    into clbNodeValue
--                  FROM dual , XMLTable(
--                        --'//DATAUPLOADMASTER'
--                        varXPath
--                         passing xmlTemp
--                         columns
--                           LoadData  clob path '//LoadData' 
--                       ) x
--                       where x.LoadData is not null ;
--              elsif EntityName='SCANNEDIMAGES' then
--                 GLOG.log_write('You message goes varXPath '|| varXPath );
--                    SELECT x.LoadData
--                      into clbNodeValue
--                    FROM dual , XMLTable(
--                          --'//SCANNEDIMAGES/'
--                          varXPath
--                           passing xmlTemp
--                           columns
--                             LoadData  CLOB path '//DocumentImage' 
--                         ) x
--                        where x.LoadData is not null ;
--                 GLOG.log_write('You message goes varXPath after '|| varXPath );
--               end if;
--             els


--             if (varColumnType not in ('CLOB','BLOB')) then
--                 -- incase of Date columns Change Convert the String format into the Date format 
--              Glog.log_write(' Type for the Column ' || varTemp || ' Data Type ' || numGeneralDataType || ' Val ' || varNodeValue || ' Format ' || varFormatString || ' XML Path ' || varXPath1);
--               select extractValue(xmlTemp,varXPath1)
--                     into varNodeValue
--                from dual;
--                Glog.log_write(' Type for the Column ' || varTemp || ' Data Type ' || numGeneralDataType || ' Val ' || varNodeValue || ' Format ' || varFormatString);
--                if numGeneralDataType = 94000003 then -- for the Date format 
--                   VARTEMP1:= to_char(to_date(varNodeValue, 'yyyymmdd'),'dd/mm/yyyy');
--                   varNodeValue:=VARTEMP1;
--                   Glog.log_write(' Converted Date  ' || varNodeValue);
--                end if;
--             end if;

             if (varColumnType not in ('CLOB','BLOB')) then
                 -- incase of Date columns Change Convert the String format into the Date format 
              Glog.log_write(' Type for the Column ' || varTemp || ' Data Type ' || numGeneralDataType || ' Val ' || varNodeValue || ' Format ' || varFormatString || ' XML Path ' || varXPath1);
               select extractValue(xmlTemp,varXPath1)
                     into varNodeValue
                from dual;
                Glog.log_write(' Type for the Column ' || varTemp || ' Data Type ' || numGeneralDataType || ' Val ' || varNodeValue || ' Format ' || varFormatString);
                if ((numGeneralDataType = 94000003) and (length(varNodeValue)=8) and (varNodeValue is not null)) then -- for the Date format 
                   VARTEMP1:= to_char(to_date(varNodeValue, 'yyyymmdd'),'dd/mm/yyyy');
                   varNodeValue:=VARTEMP1;
                   Glog.log_write(' Converted Date  ' || varNodeValue);
                end if;
             end if;             


--           exception
--             when others then 
--              varNodeValue := null;
--              clbNodeValue:=null;
--           end;



             varOperation := 'Extracting Data Node Name ' || varTemp || ' Col Type ' ||varColumnType ;
--            TXTNODE := DBMS_XMLDOM.CREATETEXTNODE(docFinal, varNodeValue);
--            nodInnerTemp := XMLDOM.MAKENODE(TXTNODE);

           if varTemp is not null then
              ELMXML := xmlDom.CreateElement(docFinal,varTemp); 
              nodInnerTemp := XMLDOM.MAKENODE(ELMXML);
              nodInnerTemp:=DBMS_XMLDOM.AppendCHILD(RootNode, nodInnerTemp);
              if varColumnType='CLOB' then 
                  TXTDOM := XMLDOM.CREATETEXTNODE(docFinal,clbNodeValue);
                 --nodTemp1 := XMLDOM.MAKENODE(clbNodeValue);

                  --nodInnerTemp.Value:=clbNodeValue;
              ELSE
                  TXTDOM := XMLDOM.CREATETEXTNODE(docFinal,varNodeValue);
              END IF;
--              GLOG.log_write('After vartemp ');
              nodTemp1 := XMLDOM.MAKENODE(TXTDOM);
              nodInnerTemp := XMLDOM.APPENDCHILD(nodInnerTemp, nodTemp1);
           end if; 

--           if varTemp is not null then
--              ELMXML := xmlDom.CreateElement(docFinal,varTemp); 
--              nodInnerTemp := XMLDOM.MAKENODE(ELMXML);
--              nodInnerTemp:=DBMS_XMLDOM.AppendCHILD(RootNode, nodInnerTemp);
--              if varColumnType='CLOB' then 
--                  nodTemp1 := xmldom.makenode(xmldom.getdocumentelement(docFinal));
--                  prcAdd_CLOBToXMLNode(nodTemp1,clbNodeValue);
--                  
----                  select addValueToXMLNode(nodTemp1,clbNodeValue)
----                    into nodTemp1
----                    from dual;
--                    
--                  nodInnerTemp := XMLDOM.APPENDCHILD(nodInnerTemp, nodTemp1);
--                --  TXTDOM := XMLDOM.CREATETEXTNODE(docFinal,clbNodeValue);
--                 --nodTemp1 := XMLDOM.MAKENODE(clbNodeValue);
--                 
--                  --nodInnerTemp.Value:=clbNodeValue;
--                  xmlDom.writeToClob(docFinal, clbTemp1);
--                   GLOG.log_write(clbTemp1);
--              ELSE
--                  TXTDOM := XMLDOM.CREATETEXTNODE(docFinal,varNodeValue);
--                  nodTemp1 := XMLDOM.MAKENODE(TXTDOM);
--                  nodInnerTemp := XMLDOM.APPENDCHILD(nodInnerTemp, nodTemp1);
--              END IF;
----              GLOG.log_write('After vartemp ');
--
--           end if; 


           -- XMLDOM.SETNODEVALUE(nodInnerTemp, varNodeValue);

            varNodeValue:='';
            nodTemp:=XMLDOM.REMOVECHILD(nodTemp, nodTemp);

        end loop;
    end loop;

    DBMS_LOB.CREATETEMPORARY (clbTemp,  TRUE);
    XMLDOM.WRITETOCLOB(docFinal, clbTemp);
--    Glog.log_write('Inward in ' || 'fncSubstituteFields');
--    Glog.log_write('Inward ' || clbTemp);
    --dbms_output.put_line(clbTemp);
    return clbTemp;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('fncSubstituteFields', numError, varMessage,
                      varOperation, varError);
      GLOG.LOG_Error(varError,'SCHEMA.PKGMASTERMAINTENANCE.fncSubstituteFields');                   
      raise_application_error(-20101, varError);
      return clbTemp;
End fncSubstituteFields;



procedure prcAdd_CLOBToXMLNode
      (in_parent_node in out xmldom.domNode,
       in_value_cl in CLOB)
is
  v_offset_nr         number;
  v_left_nr           number;
  v_partNo_nr         number;
  v_buffer_tx         varchar2(32767);
  v_maxdatalength_nr  number := 8000;

  v_parent_doc          xmldom.domDocument;
  v_part_node           xmldom.domNode;
  v_bufferedValue_cdata xmldom.DOMCDATASection;
  v_temp_node           xmldom.domNode;
  v_value_node          xmldom.domNode;
  numError            number;
  VAROPERATION        GCONST.GVAROPERATION%TYPE;
  VARMESSAGE          GCONST.GVARMESSAGE%TYPE;
  VARERROR            GCONST.GVARERROR%TYPE;
begin
  -- get the owner document of the parent node
  v_parent_doc := xmldom.getownerdocument(in_parent_node);

  -- create a new node named "value" and add it to the parent node
  v_value_node := xmldom.makeNode(xmldom.createelement(v_parent_doc, 'value'));
  v_temp_node:= xmldom.appendchild(in_parent_node, v_value_node);

  -- get the length of CLOB value
  v_left_nr := dbms_lob.getlength(in_value_cl);

  -- if CLOB is bigger then the defined maximum value,
  -- divide it, otherwise add it directly to the parent node
  if v_left_nr > v_maxdatalength_nr then
    -- set multi part attribute to Yes
    xmldom.setattribute(xmldom.makeelement(v_value_node), 'multiPart', 'Y');

    v_offset_nr := 1;
    v_partNo_nr := 1;
    loop
      exit when v_left_nr <= 0;

      if v_left_nr > v_maxdatalength_nr then
        v_buffer_tx := dbms_lob.substr(in_value_cl, v_maxdatalength_nr, v_offset_nr);
        v_left_nr := v_left_nr - v_maxdatalength_nr;
        v_offset_nr := v_offset_nr + v_maxdatalength_nr;
      else
        v_buffer_tx := dbms_lob.substr(in_value_cl, v_left_nr, v_offset_nr);
        v_left_nr := 0;
      end if;
      -- create a node for each chunk and give it a number
      v_part_node := xmldom.makenode(xmldom.createelement(v_parent_doc,'part'));
      xmldom.setattribute(xmldom.makeelement(v_part_node), 'no', v_partNo_nr);
      v_partNo_nr := v_partNo_nr + 1;

      -- create a CDATA node with buffered value and add it to the v_part_node
      v_bufferedValue_cdata:=xmldom.createcdatasection(v_parent_doc,v_buffer_tx);
      v_temp_node := xmldom.appendchild(v_part_node, xmldom.makeNode(v_bufferedValue_cdata));
      -- add v_part_node to the value node
      v_temp_node := xmldom.appendchild(v_value_node, v_part_node);
    end loop;

  else
    -- set multi part attribute to No
    xmldom.setattribute(xmldom.makeelement(v_value_node), 'multiPart', 'N');
    -- create a CDATA node with buffered value and add it to the value node directly
    v_bufferedValue_cdata:=xmldom.createcdatasection(v_parent_doc, to_char(in_value_cl));
    v_temp_node := xmldom.appendchild(v_value_node, xmldom.makeNode(v_bufferedValue_cdata));

  end if;

Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('prcAdd_CLOBToXMLNode', numError, varMessage,
                      varOperation, varError);
      GLOG.LOG_Error(varError,'SCHEMA.PKGMASTERMAINTENANCE.prcAdd_CLOBToXMLNode');                   

      raise_application_error(-20101, varError);
end prcAdd_CLOBToXMLNode;

FUNCTION FNCPROCESSNODE
        (   DOCNODE IN OUT NOCOPY XMLDOM.DOMNODE,
            TARGETNODE IN OUT NOCOPY XMLDOM.DOMNODE,
            PROCESSTYPE IN NUMBER,
            ROWNUMBER IN NUMBER,
            WhereCondition in varchar2 default null)
            RETURN NUMBER
IS

    NUMERROR            NUMBER;
    NUMTEMP             NUMBER;
    NUMCODE             NUMBER(8);
    NUMCODE1            NUMBER(8);
    NUMTEMP1            NUMBER(15);
    NUMRATE             NUMBER(15,6);
    NUMACTION           NUMBER(8);
    VARUSERID           VARCHAR2(30);
    VARREFERENCE        VARCHAR2(25);
    VARTERMINALID       VARCHAR2(30);
    VARENTITY           VARCHAR2(30);
    VARNODE             VARCHAR2(30);
    VARPROCESS          VARCHAR2(30);
    VARTEMP             VARCHAR2(2048);
    VAROPERATION        GCONST.GVAROPERATION%TYPE;
    VARMESSAGE          GCONST.GVARMESSAGE%TYPE;
    VARERROR            GCONST.GVARERROR%TYPE;
    DATTEMP             DATE;
    NODTEMP             XMLDOM.DOMNODE;
    NODTEMP1            XMLDOM.DOMNODE;
    NODROOT             XMLDOM.DOMNODE;
    NODAUDIT            XMLDOM.DOMNODE;
    nmpTemp             xmldom.domNamedNodeMap;
    NLSTEMP             XMLDOM.DOMNODELIST;
    DOCTEMP             XMLDOM.DOMDOCUMENT;
    CLBTEMP             CLOB;
    XMLTEMP             XMLTYPE;
    XMLTEMP1            XMLTYPE;
    BLANK_NODE          EXCEPTION;
    varXMLEntryDetails  XMLTYPE;
    varXMLTEMP          varchar2(8000);
    varXmlField         varchar(50);
    varColumName        varchar(50);
    varTemp3            varchar(2000);

    nodTemp2            xmlDom.domNode;
    NODAUDITTEMP        xmlDom.domNode;
    nodFinal1           xmlDom.domNode;
    docFinal1           xmlDom.domDocument;
    nlsTemp2            xmlDom.domNodeList;
    numSub2             number;    
    varX2Path           varchar(2000);
    numAttr             number;

BEGIN
    NUMERROR := 0;
    VARMESSAGE := 'Processing for operation: ' || PROCESSTYPE ;
    Glog.log_write(VARMESSAGE);
    IF XMLDOM.ISNULL(TARGETNODE) THEN
      RAISE BLANK_NODE;
      -- Glog.log_write('TARGETNODE' || TARGETNODE);
    END IF;
  
    NUMERROR := 1;
    VAROPERATION := 'Extracting Node Details';
    VARNODE := XMLDOM.GETNODENAME(TARGETNODE);
    NODTEMP := XMLDOM.GETFIRSTCHILD(TARGETNODE);
    
     --Glog.log_write('NODTEMP' || NODTEMP);
    Glog.log_write('VARNODE' ||VARNODE);
    
    VARENTITY := Gconst.FNCGETNODEVALUE(DOCNODE, '//Entity');

    Glog.log_write('Entity' ||VARENTITY);
    
    VARMESSAGE := 'Processing for Action: ' || PROCESSTYPE || ' Node: ' || VARNODE;
    Glog.log_write(VARMESSAGE);

    BEGIN
      NUMERROR := 2;
      VAROPERATION := 'Extracting Action Type';
      SELECT NVL(DECODE(PROCESSTYPE,
          GCONST.ADDSAVE, FLDP_ADD_ACTION,
          GCONST.EDITSAVE, FLDP_EDIT_ACTION,
          GCONST.DELETESAVE, FLDP_DELETE_ACTION,
          GCONST.UNCONFIRMSAVE, FLDP_UNCONFIRM_ACTION,
          GCONST.REJECTSAVE, FLDP_REJECT_ACTION,
          GCONST.CONFIRMSAVE, FLDP_CONFIRM_ACTION,
          GCONST.INACTIVESAVE,FLDP_INACTIVE_ACTION),0) AS ACTION_TYPE
        INTO NUMACTION
        FROM TRSYSTEM999 
        WHERE FLDP_COLUMN_NAME = VARNODE
        AND FLDP_TABLE_SYNONYM = VARENTITY;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NUMERROR;
    END;

    IF NUMACTION = 0 THEN
      RETURN NUMERROR;
    END IF;

    NUMERROR := 3;
    VAROPERATION := 'Processing the Node';

    IF NUMACTION = SYSMOVESERIAL THEN
      VARTEMP := '1';
    ELSIF NUMACTION = SYSMOVETODAY THEN
      VARTEMP := TO_CHAR(SYSDATE, 'dd/mm/yyyy');
    ELSIF NUMACTION = SYSMOVESYSDATE THEN
      VARTEMP := TO_CHAR(SYSDATE, 'dd/mm/yyyy HH24:MI:SS');
    ELSIF NUMACTION = SYSMOVECOCODE THEN
      VARTEMP := '30199999';
    ELSIF NUMACTION = SYSENTRYCODE THEN
      VARTEMP := GCONST.STATUSENTRY;
    ELSIF NUMACTION = SYSUPDATECODE THEN
      VARTEMP := GCONST.STATUSUPDATED;
    ELSIF NUMACTION = SYSDELETECODE THEN
      VARTEMP := GCONST.STATUSDELETED;
    ELSIF NUMACTION = SYSCONFIRMCODE THEN
      VARTEMP := GCONST.STATUSAUTHORIZED;
    ELSIF NUMACTION = SYSUNCONFIRMCODE THEN
      VARTEMP := GCONST.STATUSUPDATED;   
    ELSIF NUMACTION =SYSINACTIVECODE then
      varTemp :=GCONST.STATUSINACTIVE;
    ELSIF NUMACTION = SYSREJECTCODE THEN
      VARTEMP := GCONST.STATUSREJECTED;
    ELSIF NUMACTION = SYSPRECONFIRM THEN
      VARTEMP := GCONST.STATUSAPREUTHORIZATION;
    ELSIF NUMACTION = SYSUPDATESTATUS THEN
      VARTEMP := GCONST.FNCRETURNSTATUS(SYSUPDATESTATUS,0);
    ELSIF NUMACTION = SYSADDSERIAL THEN
      NUMTEMP := XMLDOM.GETNODEVALUE(NODTEMP);
      NUMTEMP := NUMTEMP + 1;
      VARTEMP := NUMTEMP;
    ELSIF NUMACTION = SYSINCREMENTKEY THEN
      NUMTEMP1 := FNCKEYSERIAL(DOCNODE,ROWNUMBER);
      VARTEMP := NUMTEMP1;
    ELSIF NUMACTION = SYSPUTTIMESTAMP THEN
      SELECT TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH24:MI:SS:FF3')
        INTO VARTEMP
        FROM DUAL;
    ELSIF NUMACTION = SYSPICKPROCESS THEN
      DBMS_LOB.CREATETEMPORARY (CLBTEMP,  TRUE);
      XMLDOM.WRITETOCLOB(DOCNODE, CLBTEMP);
      PKGMASTERMAINTENANCE.PRCPROCESSPICKUP(CLBTEMP, VARNODE, VARTEMP);
    ELSIF NUMACTION IN (SYSEXPORTADJUST, SYSDEALADJUST, SYSDEALDELIVERY,
      SYSLOANCONNECT, SYSRISKGENERATE, SYSRATECALCULATE, SYSHEDGERISK,
      SYSVOUCHERCA,SYSCOMMDEALREVERSAL,SYSBCRCONNECT,SYSBCRFDLIEN) THEN
      NODTEMP1 := XMLDOM.GETFIRSTCHILD(TARGETNODE);
      VARTEMP := XMLDOM.GETNODEVALUE(NODTEMP1);
   ELSIF NUMACTION = SYSDEALNUMBER THEN
       NUMCODE1 := TO_NUMBER(GCONST.FNCGETNODEVALUE(DOCNODE, '//DEAL_COMPANY_CODE'));
--       VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE1,PICKUPSHORT) || '/FWD/';
--       VARTEMP := VARTEMP || FNCGENERATESERIAL(SERIALDEAL, NUMCODE1);
       VARTEMP := 'FWD' || FNCGENERATESERIAL(SERIALDEAL, NUMCODE1);
    ELSIF NUMACTION = SYSTRADENUMBER THEN
      NUMCODE := TO_NUMBER(GCONST.FNCGETNODEVALUE(DOCNODE, '//TRAD_COMPANY_CODE'));
--      VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE, PICKUPSHORT) || '/';
--      NUMCODE1 := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//TRAD_IMPORT_EXPORT'));
--      VARTEMP := VARTEMP || PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE1, PICKUPSHORT) || '/';
      VARTEMP := 'EXP' || FNCGENERATESERIAL(SERIALTRADE, NUMCODE); 
    ELSIF NUMACTION = SYSLOANNUMBER THEN

      NUMCODE := TO_NUMBER(GCONST.FNCGETNODEVALUE(DOCNODE, '//FCLN_COMPANY_CODE'));
--      VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE, PICKUPSHORT) || '/';
--      NUMCODE := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//FCLN_LOAN_TYPE'));
--      VARTEMP := VARTEMP || PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE, PICKUPSHORT) || '/';

      VARTEMP := 'LOAN' || FNCGENERATESERIAL(SERIALLOAN);


    ELSIF NUMACTION =SYSRISKNUMBER THEN
      NUMCODE := TO_NUMBER(GCONST.FNCGETNODEVALUE(DOCNODE, '//RISK_RISK_TYPE'));
     -- VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE,PICKUPSHORT);
      VARTEMP := 'RISK' || FNCGENERATESERIAL(SERIALRISK);
      --ADDED BY SUPRIYA
      ELSIF NUMACTION = SYSRISKPARAMETER THEN
      --NUMCODE := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//RISK_RISK_TYPE'));
      VARTEMP := 'RISK' || FNCGENERATESERIAL(SERIALRISKPARAMETER);

      ELSIF NUMACTION = SYSFUTURESETTLEMENT THEN
      --NUMCODE := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//RISK_RISK_TYPE'));
      VARTEMP := 'FUTU' || FNCGENERATESERIAL(SERIALFUTURESETTLEMENT);
      -------------------
    ELSIF NUMACTION = SYSVOUCHERNUMBER THEN
      VARTEMP := 'CA' || FNCGENERATESERIAL(SERIALCURRENT);
          ELSIF NUMACTION=SYSSTRESSANALYSIS THEN
      VARTEMP:='SRE' || FNCGENERATESERIAL(SERIALSTRESS);
    ELSIF NUMACTION =SYSDYNAMICREPORTID THEN
      VARTEMP := 'REP' || FNCGENERATESERIAL(SERIALDYNAMICREPORT);
    ELSIF NUMACTION =SYSCONTRACTUPLOAD THEN
      VARTEMP := 'EXL' || FNCGENERATESERIAL(SERIALCONTRACTSCHEDULE);  
    ELSIF NUMACTION = SYSMMDEALNUMBER THEN
--      NUMCODE := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//MDEL_TRANSACTION_TYPE'));
--      VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE,PICKUPSHORT);
      VARTEMP := 'MM' || FNCGENERATESERIAL(SERIALMMDEAL);
      --FORWARD ROLLOVER
   ELSIF NUMACTION = SYSFORWARDROLLOVER THEN
         VARTEMP:= 'FWDROLL' || FNCGENERATESERIAL(SERIALFORWARDROLLOVER);
  ELSIF NUMACTION = SYSFUTUREROLLOVER THEN
         VARTEMP:= 'FUTROLL' || FNCGENERATESERIAL(SERIALFUTUREROLLOVER);
  ELSIF NUMACTION = SYSBANKCHARGESMASTER THEN
         VARTEMP:= 'BNKCHAR' || FNCGENERATESERIAL(SERIALBANKCHARGESMASTER);
  ELSIF NUMACTION = SYSONSCREENALERTS THEN
         VARTEMP:= 'ALERT' || FNCGENERATESERIAL(SERIALONSCREENALERTS);
ELSIF NUMACTION = SYSDUEDATEALERTCONFIGURATION THEN
         VARTEMP:= 'DUEDATE' || FNCGENERATESERIAL(SERIALDUEDATEALERTCONFIG);
ELSIF NUMACTION = SYSACCOUNTCODEMAPPING THEN
         VARTEMP:= 'AMAP' || FNCGENERATESERIAL(SERIALACCOUNTCODEMAPPING);   
ELSIF NUMACTION = SYSSOURCEEMAILREADINGCONFIG THEN
         VARTEMP:= 'EMAIL' || FNCGENERATESERIAL(SERIALSOURCEEMAILREADINGCONFIG);         
ELSIF NUMACTION = SYSSOURCESFTPREADINGCONFIG THEN
         VARTEMP:= 'SFTP' || FNCGENERATESERIAL(SERIALSOURCESFTPREADINGCONFIG);           
ELSIF NUMACTION = SYSJOBSCHEDULER THEN
         VARTEMP:= 'JOBS' || FNCGENERATESERIAL(SERIALJOBSCHEDULER);                  
ELSIF NUMACTION = SYSEMAILCONFIGURATION THEN
         VARTEMP:= 'MAIL' || FNCGENERATESERIAL(SERIALEMAILCONFIGURATION);
   ELSIF NUMACTION = SYSTRANBULKCONFIG THEN
         VARTEMP:= 'BULK' || FNCGENERATESERIAL(SERIALETRANBULKCONFIG);      
    ELSIF NUMACTION = SYSEMAILTEMPLATES THEN
         VARTEMP:= 'MAILT' || FNCGENERATESERIAL(SERIALEMAILTEMPLATES);      
    ELSIF NUMACTION = SYSMTMACCOUNTING THEN
         VARTEMP:= 'MTMACC' || FNCGENERATESERIAL(SERIALMTMACCOUNTING);
    ELSIF NUMACTION = SYSRUNACCOUNTING THEN
         VARTEMP:= 'MTMACCPRC' || FNCGENERATESERIAL(SERIALRUNACCOUNTINGPROCESS);

         ELSIF NUMACTION = SYSREMITTANCES THEN
         VARTEMP:= 'REMIT' || FNCGENERATESERIAL(SERIALREMITTANCES);
         
         ELSIF NUMACTION = SYSLANGUAGESELECTOR THEN
         VARTEMP:= 'SLAG' || FNCGENERATESERIAL(SERIALLANGUAGESELECTOR);
           
            ELSIF NUMACTION = SYSMULTILANGUAGECONFIG THEN
         VARTEMP:= 'LANG' || FNCGENERATESERIAL(SERIALMULTILANGUAGECONFIG);
         
         ELSIF NUMACTION = SYSCOPYOVERMASTER THEN
         VARTEMP:= 'COPY' || FNCGENERATESERIAL(SERIALCOPYOVERMASTER);
         
          ELSIF NUMACTION = SYSTRANBULKCONFIRMATION THEN
         VARTEMP:= 'BULK' || FNCGENERATESERIAL(SERIALTRANBULKCONFIRMATION);
         
 ELSIF NUMACTION = SYSBANKCHARGECONFIG THEN
         VARTEMP:= 'BNKCHARCON' || FNCGENERATESERIAL(SERIALBANKCHARGECONFIG);
   ELSIF NUMACTION = SYSVARCONFIGURATION THEN
         VARTEMP:= 'VARC' || FNCGENERATESERIAL(SERIALVARCONFIGURATION);
--ELSIF NUMACTION = SYSCOMPLIANCEALERTCONFIG THEN
--         VARTEMP:= 'COMPAL' || FNCGENERATESERIAL(SERIALCOMPLIANCEALERTCONFIG);             
   ELSIF NUMACTION  = SYSFDNUMBER THEN
      VARTEMP := 'FD' || FNCGENERATESERIAL(SERIALFD,NUMCODE1);
   elsif numAction =SYSFXGO then
      varTemp := 'FX' || fncGenerateSerial(SERIALFXGO);
   elsif numAction = SYSDEALINTREFERENCE then
      varTemp := 'INT' || fncGenerateSerial(SERIALDEALINTEGRATION);
    ELSIF NUMACTION = SYSBCRNUMBER THEN

--      SELECT FLDP_COLUMN_NAME
--        INTO VARTEMP
--        FROM TRSYSTEM999
--        WHERE FLDP_XML_FIELD = 'CompanyCode' 
--        AND FLDP_TABLE_SYNONYM = VARENTITY;
--      VARTEMP := FNCGETNODEVALUE(DOCNODE, '//' || VARTEMP);
--      VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(TO_NUMBER(VARTEMP),PICKUPSHORT);
      VARTEMP := 'BCR' || FNCGENERATESERIAL(SERIALBCR);    
    ELSIF NUMACTION = SYSCOMMDITYDEAL THEN

--       NUMCODE := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//CMDL_EXCHANGE_CODE'));
--       NUMCODE1 := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//CMDL_COMPANY_CODE'));
--       VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE1,PICKUPSHORT);
--       NUMCODE := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//CMDL_HEDGE_TRADE'));
--       NUMTEMP := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//CMDL_BUY_SELL'));
--
--          IF NUMCODE = HEDGEDEAL THEN
--            VARTEMP := VARTEMP ||  '/HDG';
--          ELSE
--            VARTEMP := VARTEMP || '/TRD';
--          END IF;
--       
--          IF NUMTEMP =PURCHASEDEAL THEN
--            VARTEMP := VARTEMP ||  'B/';
--          ELSE
--            VARTEMP := VARTEMP ||  'S/';
--          END IF;
     VARTEMP := 'COM' || FNCGENERATESERIAL(SERIALCOMMODITYDEAL);
   ELSIF NUMACTION = SYSCOMMRISKNUMBER THEN
--      NUMCODE := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//CRSK_CRSK_TYPE'));
--      VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE,PICKUPSHORT);
      VARTEMP := 'RISK/' || VARTEMP || FNCGENERATESERIAL(SERIALCOMMRISK);
   ELSIF NUMACTION = SYSFUTURETRADEDEAL THEN
       NUMCODE1 := TO_NUMBER(GCONST.FNCGETNODEVALUE(DOCNODE, '//CFUT_COMPANY_CODE'));
--       VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE1,PICKUPSHORT) || '/FUT/';
      VARTEMP := 'FUR' || FNCGENERATESERIAL(SERIALFUTURETRADE, NUMCODE1);

    ELSIF NUMACTION = SYSOPTIONTRADEDEAL THEN
       NUMCODE1 := TO_NUMBER(GCONST.FNCGETNODEVALUE(DOCNODE, '//COPT_COMPANY_CODE'));
       --VARTEMP := PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE1,PICKUPSHORT) || '/OPT/';
      VARTEMP := 'OPT' || FNCGENERATESERIAL(SERIALOPTIONTRADE, NUMCODE1);
   ELSIF NUMACTION =SYSLINKBATCHNO THEN
      VAROPERATION :=' Generating Batch Link no';
      VARTEMP:= 'Link' || FNCGENERATESERIAL(SERIALLINKBATCHNO);
   ELSIF NUMACTION = SYSREMITTANCENUMBER THEN
        NUMCODE1 := TO_NUMBER(GCONST.FNCGETNODEVALUE(DOCNODE, '//REMT_REMITTANCE_TYPE'));
--        IF NUMCODE1 = 33900001 THEN
--        VARTEMP := 'BCCL/IRMT/';
--        ELSE
--        VARTEMP := 'BCCL/ORMT/';
--        END IF;
--        NUMCODE1 := TO_NUMBER(FNCGETNODEVALUE(DOCNODE, '//REMT_LOCAL_BANK'));
--        VARTEMP := VARTEMP || PKGRETURNCURSOR.FNCGETDESCRIPTION(NUMCODE1,PICKUPSHORT) || '/';
        VARTEMP := 'REMI' || FNCGENERATESERIAL(SERIALREMITTANCE);
   ELSIF NUMACTION =SYSREMINDERID THEN
      VARTEMP := 'REP' || FNCGENERATESERIAL(SERIALREMINDER);
    ELSIF NUMACTION = SYSMUTUALFUNDREFERENCE THEN
      VARTEMP := 'MFIN' || FNCGENERATESERIAL(SERIALMUTUALFUND);
   ELSIF NUMACTION = SYSMUTUALFUNDREDEMPTOIN THEN
      VARTEMP := 'MFRD' || FNCGENERATESERIAL(SERIALMUTUALFUNDREDEMPTION);
   ELSIF NUMACTION = SYSFRANUMBER THEN
      VARTEMP := 'IFRA' || FNCGENERATESERIAL(SERIALFRANUMBER);
   ELSIF NUMACTION = SYSIRSNUMBER AND VARENTITY ='IRS' THEN
      VARTEMP := 'IRS' || FNCGENERATESERIAL(SERIALIRSNUMBER); 
   ELSIF NUMACTION = SYSIRSNUMBER AND VARENTITY ='CCIRSWAP' THEN
      VARTEMP := 'CCS' || FNCGENERATESERIAL(SERIALIRSNUMBER);  
--   ELSIF NUMACTION = GCONST.SYSIRSNUMBER THEN
--      VARTEMP := 'IRS' || FNCGENERATESERIAL(SERIALIRSNUMBER); 
   ELSIF NUMACTION = SYSIRFNUMBER THEN
      VARTEMP := 'IRF' || FNCGENERATESERIAL(SERIALIRFNUMBER);  
   ELSIF NUMACTION = SYSIRONUMBER THEN
      VARTEMP := 'IRO' || FNCGENERATESERIAL(SERIALIRONUMBER);
   ELSIF NUMACTION = SYSCCIRSNUMBER THEN
      VARTEMP := 'CCIR' || FNCGENERATESERIAL(SERIALCCIRNUMBER);  
   elsif numAction = SYSBONDDEBENTUREPURCHASE then
      varTemp := 'BDPU' || fncGenerateSerial(SERIALBONDDEBENTUREPUR);
    elsif numAction =SYSCPBDEALNUMBER THEN
      varTemp := 'CPB' || fncGenerateSerial(SERIALCPB);
   ELSIF NUMACTION =SYSFUTURENUMBER THEN
      varTemp := 'BATCH' || fncGenerateSerial(SERIALFUTURENUMBER);
   elsif numAction=SYSEMAIL then
      varTemp := 'MAIL'||fncGenerateSerial(SERIALEMAIL);
   Elsif Numaction = SYSSCANFILES Then 
      VARTEMP := 'TRSCAN/' || fncGenerateSerial(SERIALSCANIMAGES);     
   elsif numAction = SYSBANKCHARGE then
      varTemp := fncGenerateSerial(SEARIALCHARGE);
      varTemp :='BCHA/'||varTemp;
   ELSIF NUMACTION = SYSCOPYOVERMASTER THEN
      VARTEMP:= 'COPY' || FNCGENERATESERIAL(SERIALCOPYOVERMASTER);
 ELSIF NUMACTION = SYSTRANBULKCONFIRMATION THEN
      VARTEMP:= 'BULK' || FNCGENERATESERIAL(SERIALTRANBULKCONFIRMATION);

--   ELSIF NUMACTION = SYSPICKPROCESS THEN
--      DBMS_LOB.CREATETEMPORARY (CLBTEMP,  TRUE);
--      XMLDOM.WRITETOCLOB(DOCNODE, CLBTEMP);
--      PKGMASTERMAINTENANCE.PRCPROCESSPICKUP(CLBTEMP, VARNODE, VARTEMP);
    END IF;

   --- 03/05/2022 -- in future for the serial number directly specify the serial number
    if substr(NUMACTION,1,3)=109 then 
      VARTEMP:= FNCGENERATESERIAL(NUMACTION);
    end if;


    IF NUMACTION NOT IN (SYSMOVEDETAIL,SYSADDDETAIL,SYSCANCELDEAL,
                  SYSCURRENTAC, SYSPACKINGCREDIT, SYSBUYERSCREDIT) THEN
      NUMERROR := GCONST.FNCSETNODEVALUE(DOCNODE, TARGETNODE, VARTEMP);
    END IF;

    IF NUMACTION IN (SYSMOVEDETAIL, SYSADDDETAIL) THEN
      VARUSERID := Gconst.FNCGETNODEVALUE(DOCNODE, '//UserCode');
      VARTERMINALID := Gconst.FNCGETNODEVALUE(DOCNODE, '//TerminalID');
      VARENTITY := Gconst.FNCGETNODEVALUE(DOCNODE, '//Entity');

      SELECT DECODE(PROCESSTYPE,
          GCONST.ADDSAVE, 'ADDSAVE',
          GCONST.EDITSAVE, 'EDITSAVE',
          GCONST.DELETESAVE, 'DELETESAVE',
          GCONST.UNCONFIRMSAVE, 'UNCONFIRMSAVE',
          GCONST.REJECTSAVE, 'REJECTSAVE',
          GCONST.CONFIRMSAVE, 'CONFIRMSAVE')
          INTO VARPROCESS
          FROM DUAL;

      NUMERROR := 5;
      VAROPERATION := 'Moving Details for ' || VARENTITY;
      DOCTEMP := XMLDOM.MAKEDOCUMENT(DOCNODE);

   --   IF NUMACTION = SYSMOVEDETAIL THEN
        NODAUDIT := Gconst.FNCADDNODE(DOCTEMP, TARGETNODE, 'AuditTrails', NULL);


      if PROCESSTYPE not in (GConst.ADDSAVE) then
        varOperation := ' Extracting Entry Details' ;

        begin
            select FLDP_COLUMN_NAME 
              into varColumName
            from trsystem999
            where fldp_table_synonym = varEntity
                and fldp_xml_field = 'EntryDetail';
        exception
          when others then
             varColumName:=null;
        end;
        if (varColumName is not null) then
            GLOG.log_write(varEntity || varColumName);

            varTemp3:= 'select ' ||  varColumName || ' from ' || varEntity || ' where ' || WhereCondition;
            GLOG.log_write('Execute Query'||VarTemp3);

            GLOG.log_write('before post executing Query'||varTemp3);
            --insert into temp values ( 'Execute Query',VarTemp3); commit;
            execute immediate varTemp3 into varXMLEntryDetails;
            --GLOG.log_write('post executing Query '||varXMLEntryDetails);
        end if;
    end if;      

    numSub2:=0;
    numTemp:=0;

     varOperation:=' Update Audit Trails for Base Tables';
    if (varXMLEntryDetails is not null) then
        if PROCESSTYPE in (GConst.EDITSAVE, GConst.DELETESAVE, GConst.CONFIRMSAVE, GConst.REJECTSAVE, GConst.UNCONFIRMSAVE) then
              varOperation:=' Update Audit Trails';
--              varTemp3:=replace(varTemp3,'<AuditTrails>',null);
--              varTemp3:=replace(varTemp3,'</AuditTrails>',null);
--              
--   
        GLOG.log_write(varOperation || '  ' || PROCESSTYPE);
        docFinal1 := xmlDom.newDomDocument((varXMLEntryDetails));
        nodFinal1 := xmlDom.makeNode(docFinal1);

        numError := 4;
        varOperation := 'Processing Master Rows';
        varX2Path := '//AuditTrail';
        nlsTemp2 := xslProcessor.selectNodes(nodFinal1, varX2Path);
        --GLOG.log_write(varOperation || '  ' || varXMLEntryDetails);

        for numSub2 in 0..xmlDom.getLength(nlsTemp2) -1
        Loop
        GLOG.log_write('Appending Log to Audit' || '  ' || numSub2);

              NODAUDITTEMP := XMLDOM.ITEM(nlsTemp2,numSub2);
             -- NODROOT := Gconst.FNCADDNODE(DOCTEMP, NODAUDIT, 'AuditTrail', NULL);
             --NUMTEMP:=
              nmpTemp:= xmlDom.getAttributes(NODAUDITTEMP);
              nodTemp := xmlDom.Item(nmpTemp, 0);
              numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
              varOperation:=' Extracting Attribute from Node  ' || numTemp;
               GLOG.log_write('Appending Log to Audit' || '  ' || numTemp);
              if ((numTemp is null) or (nvl(numTemp,0)=0)) then
                  NODROOT :=Gconst.FNCADDNODE_WithAttribute(DOCTEMP, NODAUDIT, 'AuditTrail', NULL,'AROW',numSub2+1);
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'Process', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail/Process'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'UserName', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail/UserName'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'TimeStamp', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail/TimeStamp'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'TerminalName', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail/TerminalName'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'ProcessDate',GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail/ProcessDate'));
                  numTemp:=numSub2+1;
             else
                  NODROOT :=Gconst.FNCADDNODE_WithAttribute(DOCTEMP, NODAUDIT, 'AuditTrail', NULL,'AROW',numTemp);
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'Process', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail[@AROW="'||numTemp ||'"]/Process'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'UserName', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail[@AROW="'||numTemp ||'"]/UserName'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'TimeStamp', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail[@AROW="'||numTemp ||'"]/TimeStamp'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'TerminalName', GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail[@AROW="'||numTemp ||'"]/TerminalName'));
                  NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'ProcessDate',GCONST.FNCGETNODEVALUE(NODAUDITTEMP,'//AuditTrail[@AROW="'||numTemp ||'"]/ProcessDate'));

             end if;
        end loop;
        end if;    
     end if;





--        NLSTEMP := XMLDOM.GETELEMENTSBYTAGNAME(DOCTEMP, 'AuditTrails');
--
--        IF (XMLDOM.GETLENGTH(NLSTEMP) = 0) THEN
--          NODAUDIT := Gconst.FNCADDNODE(DOCTEMP, TARGETNODE, 'AuditTrails', NULL);
--        ELSE
--          NODAUDIT := XMLDOM.ITEM(NLSTEMP, 0);
--        END IF;
--
--      END IF;
--      


      numTemp:=numTemp+1;

      NODROOT := Gconst.FNCADDNODE_WithAttribute(DOCTEMP, NODAUDIT, 'AuditTrail', NULL,'AROW',numTemp);
      --XMLDOM.setAttribute(NODROOT,'AROW',to_char(numSub2));
      NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'Process', VARPROCESS);
      NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'UserName', VARUSERID);
      NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'TimeStamp', TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH24:MI:SS:FF3'));
      NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'TerminalName', VARTERMINALID);
      NODTEMP := Gconst.FNCADDNODE(DOCTEMP, NODROOT, 'ProcessDate',TO_CHAR(SYSDATE, 'dd/mm/yyyy'));
    END IF;

    NUMERROR := 0;
    RETURN NUMERROR;
EXCEPTION
    WHEN BLANK_NODE THEN
      NUMERROR := -20101;
      VARERROR := 'Node: ' || VARNODE || ' does not exist or has no value';
      VARERROR := GCONST.FNCRETURNERROR('ProcessNode', NUMERROR, VARMESSAGE,
                        VAROPERATION, VARERROR);
      GLOG.LOG_Error(VARERROR,'SCHEMA.FNCPROCESSNODE');                  
      RAISE_APPLICATION_ERROR(NUMERROR, VARERROR);
      RETURN NUMERROR;
    WHEN OTHERS THEN
        NUMERROR := SQLCODE;
        VARERROR := SQLERRM;
        VARERROR := GCONST.FNCRETURNERROR('ProcessNode', NUMERROR, VARMESSAGE,
                        VAROPERATION, VARERROR);
        GLOG.LOG_Error(VARERROR,'SCHEMA.FNCPROCESSNODE');                      
        RAISE_APPLICATION_ERROR(-20101, VARERROR);
        RETURN NUMERROR;
END FNCPROCESSNODE;

FUNCTION FNCGENERATESERIAL
    ( SERIALTYPE IN NUMBER,
      COMPANYCODE IN NUMBER := 0)
    RETURN VARCHAR2
    IS
    NUMERROR            NUMBER;
    NUMSERIAL           NUMBER(10);
    NUMCONCAT           NUMBER(8);
    NUMRESET            NUMBER(8);
    NUMDATE             NUMBER(8);
    NUMWIDTH            NUMBER(1);
    NUMRESETMM          NUMBER(2);
    NUMRESETYY          NUMBER(2);
    NUMVALUEMM          NUMBER(2);
    NUMVALUEYY          NUMBER(2);
    NUMRETURNVALUE      NUMBER(15);
    DATRESET            DATE;
    DATVALUE            DATE;
    VARFLAG             VARCHAR2(1);
    VARFORMAT           VARCHAR2(25);
    VAROPERATION        GCONST.GVAROPERATION%TYPE;
    VARMESSAGE          GCONST.GVARMESSAGE%TYPE;
    VARERROR            GCONST.GVARERROR%TYPE;
    DATE_INCORRECT      EXCEPTION;
    varConcatinateText  varchar(4);
    pragma autonomous_transaction;
BEGIN
    VARMESSAGE := 'Generating serial number for ' || COMPANYCODE ||
                  PKGRETURNCURSOR.FNCGETDESCRIPTION(SERIALTYPE, GCONST.PICKUPLONG);
    NUMRETURNVALUE := 0;
    VARFORMAT := '';
    VAROPERATION := 'Extracting serial parameters';
    IF NVL(COMPANYCODE,0) = 0 THEN
      SELECT SERL_CONCAT_CODE, SERL_RESET_CODE, SERL_DATE_CODE,
        SERL_SERIAL_WIDTH, SERL_RESET_ON, SERL_SERIAL_NUMBER,
        SERL_CONCAT_BEGINTEXT
        INTO NUMCONCAT, NUMRESET, NUMDATE,
        NUMWIDTH, DATRESET, NUMSERIAL,varConcatinateText
        FROM SERIALTABLE
        WHERE SERL_SERIAL_CODE = SERIALTYPE
        and serl_Record_status not in (10200005,10200006);
    ELSE
      SELECT SERL_CONCAT_CODE, SERL_RESET_CODE, SERL_DATE_CODE,
        SERL_SERIAL_WIDTH, SERL_RESET_ON, SERL_SERIAL_NUMBER,
        SERL_CONCAT_BEGINTEXT
        INTO NUMCONCAT, NUMRESET, NUMDATE,
        NUMWIDTH, DATRESET, NUMSERIAL,varConcatinateText
        FROM SERIALTABLE
        WHERE decode(SERL_COMPANY_CODE,30199999,COMPANYCODE,SERL_COMPANY_CODE) = COMPANYCODE
        AND SERL_SERIAL_CODE = SERIALTYPE
        and serl_Record_status not in (10200005,10200006);
    END IF;
    IF NUMDATE = GCONST.OPTIONYES THEN
      IF NUMRESET = SRESETNEVER THEN
        DATVALUE := DATRESET;
      ELSE
        DATVALUE := SYSDATE;
      END IF;
    END IF;
    VAROPERATION := 'Extracting Date Reset';
    NUMRESETMM := TO_NUMBER(TO_CHAR(DATRESET, 'mm'));
    NUMRESETYY := TO_NUMBER(TO_CHAR(DATRESET, 'yy'));
    NUMVALUEMM := TO_NUMBER(TO_CHAR(DATVALUE, 'mm'));
    NUMVALUEYY := TO_NUMBER(TO_CHAR(DATVALUE, 'yy'));
    VARFLAG := 'N';

    IF TRUNC(DATVALUE,'dd') = TRUNC(DATRESET,'dd') THEN
      NUMSERIAL := NUMSERIAL + 1;
    ELSIF DATVALUE > DATRESET THEN 

      IF NUMRESET = SRESETDAILY THEN
          NUMSERIAL := 1;
          VARFLAG := 'Y';
      ELSIF NUMRESET = SRESETMONTHLY AND
          NUMRESETMM != NUMVALUEMM THEN
          NUMSERIAL := 1;
          VARFLAG := 'Y';
      ELSIF NUMRESET = SRESETCALENDAR AND
          NUMRESETYY != NUMVALUEYY THEN
          NUMSERIAL := 1;
          VARFLAG := 'Y';
      ELSIF NUMRESET = SRESETFINANCE THEN

          IF NUMRESETYY = NUMVALUEYY AND
                NUMRESETMM < 4 AND
                NUMVALUEMM > 3 THEN
            NUMSERIAL := 1;
            VARFLAG := 'Y';
          ELSIF NUMRESETYY != NUMVALUEYY AND
              NUMVALUEMM > 3 THEN
            NUMSERIAL := 1;
            VARFLAG := 'Y';
          END IF;
      END IF;
        IF VARFLAG = 'N' THEN
          NUMSERIAL := NUMSERIAL + 1;
        END IF;

        DATRESET := DATVALUE;
   ELSE                     
      RAISE DATE_INCORRECT;
    END IF;

    VAROPERATION := 'Generating serial number';
    IF NUMCONCAT = SGENCONCATDAY THEN
      SELECT (TO_NUMBER(TO_CHAR(DATVALUE, 'yyyymmdd')) * POWER(10,NUMWIDTH))
        + NUMSERIAL
        INTO NUMRETURNVALUE
        FROM DUAL;
    ELSIF NUMCONCAT = SGENCONCTMONTH THEN
      SELECT (TO_NUMBER(TO_CHAR(DATVALUE, 'yyyymm')) * POWER(10,NUMWIDTH))
        + NUMSERIAL
        INTO NUMRETURNVALUE
        FROM DUAL;
    ELSIF NUMCONCAT = SGENCONCATYEAR THEN
      SELECT (TO_NUMBER(TO_CHAR(DATVALUE, 'yyyy')) * POWER(10,NUMWIDTH))
        + NUMSERIAL
        INTO NUMRETURNVALUE
        FROM DUAL;
    ELSIF NUMCONCAT = SGENCONCATFIN THEN
      NUMVALUEMM := TO_NUMBER(TO_CHAR(DATVALUE, 'mm'));
      NUMVALUEYY := TO_NUMBER(TO_CHAR(DATVALUE, 'yy'));

      IF  TO_NUMBER(TO_CHAR(DATVALUE, 'mm')) > 3 THEN
        SELECT (TO_NUMBER(TO_CHAR(DATVALUE, 'yyyy') || TO_CHAR(DATVALUE, 'yy') + 1))
          * POWER(10,NUMWIDTH) + NUMSERIAL
          INTO NUMRETURNVALUE
          FROM DUAL;
      ELSE
       SELECT (TO_NUMBER(TO_CHAR(DATVALUE, 'yyyy') -1 || TO_CHAR(DATVALUE, 'yy')))
          * POWER(10,NUMWIDTH) + NUMSERIAL
          INTO NUMRETURNVALUE
          FROM DUAL;
      END IF;
   END IF;

    VAROPERATION := 'Updating serial number in database';
    IF NVL(COMPANYCODE,0) = 0 THEN
      UPDATE SERIALTABLE
        SET SERL_RESET_ON = DATRESET,
        SERL_SERIAL_NUMBER = NUMSERIAL
        WHERE SERL_SERIAL_CODE = SERIALTYPE
        and serl_Record_status not in (10200005,10200006);
    ELSE
      UPDATE SERIALTABLE
        SET SERL_RESET_ON = DATRESET,
        SERL_SERIAL_NUMBER = NUMSERIAL
        WHERE decode(SERL_COMPANY_CODE,30199999,COMPANYCODE,SERL_COMPANY_CODE) = COMPANYCODE
        AND SERL_SERIAL_CODE = SERIALTYPE
        and serl_Record_status not in (10200005,10200006);
    END IF;

    IF  NUMCONCAT = SGENCONCATFIN THEN
      VARFORMAT := SUBSTR(TO_CHAR(NUMRETURNVALUE),7,NUMWIDTH) ||
          '/' || SUBSTR(TO_CHAR(NUMRETURNVALUE), 3,2) || '-' ||
          SUBSTR(TO_CHAR(NUMRETURNVALUE), 5,2);

    ELSIF NUMCONCAT = SGENCONCATDAY THEN
      VARFORMAT := SUBSTR(TO_CHAR(NUMRETURNVALUE),1,8) ||
          '/' || SUBSTR(TO_CHAR(NUMRETURNVALUE),9,NUMWIDTH) ;
    ELSIF NUMRESET = SRESETNEVER   THEN
      VARFORMAT := LPAD(TO_CHAR(NUMSERIAL), NUMWIDTH,0);
    ELSE
      VARFORMAT := NUMRETURNVALUE;
    END IF;

    --- Added on 03/05/2022 to avoid the Concatenation at indivdual level

    if nvl(varConcatinateText,'NA')!='NA' then
       VARFORMAT:= varConcatinateText || VARFORMAT;
    end if;

    commit;
    RETURN VARFORMAT;
EXCEPTION
    WHEN DATE_INCORRECT THEN
        NUMERROR := -20101;
        VARERROR := 'Date: ' || DATRESET || ' is greater than System Date: ' || DATVALUE;
        GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.FNCGENERATESERIAL');    
        RAISE_APPLICATION_ERROR(-20101, VARERROR);
        rollback;
        RETURN NUMRETURNVALUE;

    WHEN OTHERS THEN
        NUMERROR := SQLCODE;
        VARERROR := SQLERRM;
        VARERROR := GCONST.FNCRETURNERROR('GenSerial', NUMERROR, VARMESSAGE,
                        VAROPERATION, VARERROR);
        GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.FNCGENERATESERIAL');                    
        RAISE_APPLICATION_ERROR(-20101, VARERROR);
        rollback;
        RETURN NUMRETURNVALUE;
END FNCGENERATESERIAL;

FUNCTION FNCKEYSERIAL
    (   DOCNODE IN XMLDOM.DOMNODE,
        ROWNUMBER IN NUMBER)
        RETURN NUMBER
IS

    NUMERROR            NUMBER;
    NUMFLAG             NUMBER(1);
    NUMSERIAL           NUMBER(5);
    VARFIELD            VARCHAR2(30);
    VARENTITY           VARCHAR2(30);
    VARVALUE            VARCHAR2(200);
    VARTEMP             VARCHAR2(200);
    VARXPATH            VARCHAR2(500);
    VARQUERY            VARCHAR2(4000);
    VAROPERATION        GCONST.GVAROPERATION%TYPE;
    VARMESSAGE          GCONST.GVARMESSAGE%TYPE;
    VARERROR            GCONST.GVARERROR%TYPE;
BEGIN
    NUMSERIAL := -1;

    NUMERROR := 1;
    VAROPERATION := 'Extracting Entity Name';
    VARENTITY := GCONST.FNCGETNODEVALUE(DOCNODE, '//Entity');

    VARMESSAGE := 'Generating Serial Number for: ' || VARENTITY;

    NUMERROR := 2;
    VAROPERATION := 'Selecting Field for incrementing number';
    SELECT FLDP_COLUMN_NAME
      INTO VARFIELD
      FROM TRSYSTEM999
      WHERE FLDP_TABLE_SYNONYM = VARENTITY
      AND FLDP_ADD_ACTION = SYSINCREMENTKEY;

    VARQUERY := 'Select NVL(max(' || VARFIELD || '),0) from ' || VARENTITY || ' where ';
    NUMERROR := 3;
    VAROPERATION := 'Extracting Key Fields and building query';
    IF  ROWNUMBER IS NOT NULL AND ROWNUMBER > 0 THEN
      VARTEMP := '//' || VARENTITY || '/ROW[@NUM="' || ROWNUMBER || '"]/';
    ELSE
      VARTEMP := '//' || VARENTITY || '/ROW/';
    END IF;
    NUMFLAG := 0;

    FOR CURFIELDS IN
    (SELECT FLDP_COLUMN_NAME, FLDP_DATA_TYPE
      FROM TRSYSTEM999
      WHERE FLDP_TABLE_SYNONYM = VARENTITY
      AND NVL(FLDP_KEY_NO,0) > 0
      ORDER BY FLDP_KEY_NO)
    LOOP

      IF CURFIELDS.FLDP_COLUMN_NAME != VARFIELD THEN

        IF NUMFLAG = 0 THEN
          NUMFLAG := 1;
        ELSE
          VARQUERY := VARQUERY || ' and ';
        END IF;

        VARXPATH := VARTEMP || CURFIELDS.FLDP_COLUMN_NAME;
        VARVALUE := GCONST.FNCGETNODEVALUE(DOCNODE, VARXPATH);
        VARQUERY := VARQUERY || CURFIELDS.FLDP_COLUMN_NAME || ' = ';

        IF CURFIELDS.FLDP_DATA_TYPE = 'VARCHAR2' THEN
          VARQUERY := VARQUERY || '''' || VARVALUE || '''';
        ELSIF CURFIELDS.FLDP_DATA_TYPE = 'DATE' THEN
          VARQUERY := VARQUERY || 'to_date(' ||  '''' || VARVALUE || '''';
          VARQUERY := VARQUERY || ',' || '''' || 'dd/mm/yyyy' || '''' || ')';
        ELSIF CURFIELDS.FLDP_DATA_TYPE = 'NUMBER' THEN
          VARQUERY := VARQUERY || VARVALUE;
        END IF;

      END IF;

    END LOOP;

    VAROPERATION := 'Executing Dynamic query';
 --   DELETE FROM TEMP;
--    INSERT INTO TEMP VALUES(VARQUERY,NUMSERIAL);COMMIT;
GLOG.log_write('Executing Dynamic query : ' ||VARQUERY );
    EXECUTE IMMEDIATE VARQUERY INTO NUMSERIAL;
    NUMSERIAL := NUMSERIAL + 1;
    RETURN NUMSERIAL;
EXCEPTION
    WHEN OTHERS THEN
        NUMERROR := SQLCODE;
        VARERROR := SQLERRM;
        VARERROR := GCONST.FNCRETURNERROR('KeySerial', NUMERROR, VARMESSAGE,
                        VAROPERATION, VARERROR);
        GLOG.LOG_Error(VARERROR,'SCHEMA.PKGMASTERMAINTENANCE.FNCKEYSERIAL');                    
        RAISE_APPLICATION_ERROR(-20101, VARERROR);
        RETURN NUMSERIAL;
END FNCKEYSERIAL;

End pkgMasterMaintenance;