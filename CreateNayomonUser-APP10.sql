-----------------------------------------------------------------------------
--
--  File:          CreateNayomonUser-APP10.sql
--
--  Purpose:       To create the oracle nayomon account for Nayo Managed Services monitoring.
--
--  Instructions:  This file should be executed as user SYS.
--
--                 Make sure you change the "password_ variable to the correct password value".
--                 
--  WARNING:       If you want to run this script again, drop the nayomon user and then run again.
--
--
--
--  Date      Sign                History
--  --------  ----------------    -----------------------------------------------------------
--  20240513  Michael Glorioso    Created.
--  20240726  Malindu Fernando    Added grant on V_$RMAN_BACKUP_JOB_DETAILS for RMAN monitoring
-------------------------------------------------------------------------------

SET serverout ON SIZE 1000000

col logfile new_value filename
select substr(ORA_DATABASE_NAME,1,instr(ORA_DATABASE_NAME, '.', 1, 1)-1) || '_Nayo-MS-CreateNayomonUser-APP10_' || to_char(sysdate, 'yyyymmddhh24miss')||'.log' as logfile from dual;
spool &filename


DECLARE
username_ VARCHAR2(30) := 'NAYOMON';
password_ VARCHAR2(30) := 'NayoService1!';

new_line_ VARCHAR2(10) := chr(13) || chr(10);


PROCEDURE Show_Message___ (
   message_ IN VARCHAR2 )
IS
   temp_msg_         VARCHAR2(4000);
   space_position_   NUMBER;
BEGIN
   temp_msg_ := message_;
   WHILE (LENGTH(temp_msg_) > 255) LOOP
      space_position_ := INSTR(SUBSTR(temp_msg_,1,255), ' ', -1);
      IF space_position_ < 240 THEN
         space_position_ := 240;
      END IF;
      Dbms_Output.Put_Line(SUBSTR(temp_msg_,1,space_position_));
      temp_msg_ := SUBSTR(temp_msg_, space_position_+1);
   END LOOP;
   IF temp_msg_ IS NOT NULL THEN
      Dbms_Output.Put_Line(temp_msg_);
   END IF;
END Show_Message___;


PROCEDURE Run_Ddl_Command___ (
   stmt_      IN VARCHAR2,
   procedure_ IN VARCHAR2,
   show_info_ IN BOOLEAN DEFAULT FALSE,
   raise_     IN BOOLEAN DEFAULT TRUE )
IS
BEGIN
   -- Safe due to deployed as sys
   -- ifs_assert_safe haarse 2010-09-23
   IF show_info_ THEN
      Dbms_Output.Put_Line('Executing ' || stmt_);
   END IF;
   EXECUTE IMMEDIATE stmt_;
EXCEPTION
   WHEN OTHERS THEN
      Show_Message___ (procedure_ || ' generates error when executing: ');
      Show_Message___ (stmt_);
      IF raise_ THEN
         RAISE;
      END IF;
END Run_Ddl_Command___;

PROCEDURE Create_User___ (
   username_ IN VARCHAR2,
   password_ IN VARCHAR2,
   default_ts_ IN VARCHAR2 DEFAULT 'IFSAPP_DATA',
   temp_ts_    IN VARCHAR2 DEFAULT 'TEMP',
   profile_    IN VARCHAR2 DEFAULT 'DEFAULT' )
IS
BEGIN
   Run_Ddl_Command___('CREATE USER ' || username_ || ' IDENTIFIED BY "'|| password_ || '" DEFAULT TABLESPACE ' || default_ts_ || ' TEMPORARY TABLESPACE ' || temp_ts_ || ' PROFILE ' || profile_, 'Create_User___', FALSE);
END Create_User___;

PROCEDURE Run_Ddl (stmt_  IN VARCHAR2,
                      type_  IN VARCHAR2 DEFAULT 'NORMAL')
   IS
      no_role              EXCEPTION;
      PRAGMA               EXCEPTION_INIT(no_role, -1951);
   BEGIN
      EXECUTE IMMEDIATE stmt_;
      Dbms_Output.Put_Line('SUCCESS: ' || stmt_);
   EXCEPTION
      WHEN no_role THEN
         NULL;
      WHEN OTHERS THEN
         Dbms_Output.Put_Line('ERROR  : ' || stmt_);
         CASE type_
            WHEN 'NORMAL' THEN
               NULL;
            WHEN 'ORACLETEXT' THEN
               Dbms_Output.Put_Line('CAUSE  : IFS Applications requires Oracle Text.');
               Dbms_Output.Put_Line('CAUSE  : Install Oracle Text if you are going to install IFS Applications.');
            WHEN 'CTXSYS' THEN
               Dbms_Output.Put_Line('CAUSE  : Index CTXSYS.DRX$ERR_KEY already exists. This error is OK.');
            ELSE
               NULL;
         END CASE;
   END Run_Ddl;


------------------------- Start Main ---------------------------------------------  

BEGIN

-- Drop old nayomon user.
Run_Ddl('DROP USER ' || username_);

-- PROMPT "Creating nayomon user..."
Create_User___(username_, password_, 'IFSAPP_DATA', 'TEMP' , 'DEFAULT' );

-- PROMPT "Applying grants..."

   -- Oracle session privileges

   Run_Ddl('GRANT CREATE SESSION TO ' || username_ || ' WITH ADMIN OPTION');
   Run_Ddl('GRANT ALTER SESSION TO ' || username_ || ' WITH ADMIN OPTION');
   Run_Ddl('GRANT RESTRICTED SESSION TO ' || username_);
   Run_Ddl('ALTER USER ' || username_ || ' GRANT CONNECT THROUGH IFSSYS');
   
   -- Oracle Dictionary views
   --
   -- News grants due to changes in how Oracle grants to public
   --
   
   Run_Ddl('GRANT SELECT ON ALL_ARGUMENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON ALL_DB_LINKS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON ALL_ERRORS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON ALL_SOURCE TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON ALL_OBJECTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON ALL_TAB_COLUMNS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON ALL_USERS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON ALL_VIEWS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_ARGUMENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_COL_COMMENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_CONSTRAINTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_CONS_COLUMNS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_DB_LINKS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_INDEXES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_IND_COLUMNS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_SOURCE TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_TAB_COLUMNS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_TRIGGERS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER_VIEWS TO ' || username_ || ' WITH GRANT OPTION');
   --   
   Run_Ddl('GRANT SELECT ON DBA_AUDIT_TRAIL TO ' || username_);
   Run_Ddl('GRANT SELECT ON DBA_CONSTRAINTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_COL_COMMENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_CONTEXT TO ' || username_);
   Run_Ddl('GRANT SELECT ON DBA_DB_LINKS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_EXTENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_INDEXES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_IND_COLUMNS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_JOBS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_JOBS_RUNNING TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_LOCKS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBMS_LOCK_ALLOCATED TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_MVIEWS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_MVIEW_LOGS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_OBJECTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_2PC_PENDING TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_PLSQL_OBJECT_SETTINGS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_PROFILES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_ROLES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_ROLE_PRIVS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_SEGMENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_SCHEDULER_JOBS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_SCHEDULER_JOB_ARGS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_SCHEDULER_JOB_LOG TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_SCHEDULER_JOB_RUN_DETAILS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_SCHEDULER_RUNNING_JOBS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_SYS_PRIVS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TABLES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TAB_COLUMNS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TAB_COMMENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TAB_PRIVS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TABLESPACES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TEMP_FILES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TRIGGERS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_USERS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_VIEWS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_DIRECTORIES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON PROXY_USERS TO ' || username_ || ' WITH GRANT OPTION');
   
   -- PL/SQL Developer
   Run_Ddl('GRANT SELECT ON V_$SESSION TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$SESSTAT TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$SESSTAT TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$STATNAME TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$OPEN_CURSOR TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$SQLTEXT_WITH_NEWLINES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$LOCK TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$MYSTAT TO ' || username_ || ' WITH GRANT OPTION');
      --
   Run_Ddl('GRANT SELECT ON GV_$SESSION TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$ACCESS TO ' || username_);
   Run_Ddl('GRANT SELECT ON V_$DATABASE TO ' || username_);
   Run_Ddl('GRANT SELECT ON V_$NLS_VALID_VALUES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$OPTION TO ' || username_);
   Run_Ddl('GRANT SELECT ON V_$INSTANCE TO ' || username_);
   Run_Ddl('GRANT SELECT ON GV_$INSTANCE TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$PROCESS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$PARAMETER TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$RESERVED_WORDS TO ' || username_);
   Run_Ddl('GRANT SELECT ON V_$BGPROCESS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$SYSSTAT TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$PROCESS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$SGA TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$SGA_DYNAMIC_COMPONENTS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$SQL TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$SQL TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$SQL_PLAN TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$SQL_PLAN_STATISTICS_ALL TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$SQL_BIND_CAPTURE TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$LOCKED_OBJECT TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$PARAMETER2 TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_FREE_SPACE TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_DATA_FILES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON AUDIT_ACTIONS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$IM_SEGMENTS TO ' || username_ || ' WITH GRANT OPTION');
   
   -- Special grants
   Run_Ddl('GRANT SELECT ON V_$SQLTEXT_WITH_NEWLINES TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$ROWCACHE TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$OSSTAT TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$LIBRARYCACHE TO ' || username_ || ' WITH GRANT OPTION');
   
   -- Add items found in ZABBIX script that may be useful for monitoring.
   Run_Ddl('GRANT SELECT ON v_$sysmetric TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$system_parameter TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$recovery_file_dest TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$active_session_history TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$restore_point TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$datafile TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$pgastat TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$sgastat TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$log TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$archive_dest TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$asm_diskgroup TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON sys.dba_data_files TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON DBA_TABLESPACE_USAGE_METRICS TO ' || username_ || ' WITH GRANT OPTION');
   
   -- Add items for Site24x7 monitoring.
   Run_Ddl('GRANT SELECT ON V_$RMAN_STATUS TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$resource_limit TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON v_$sysstat TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON V_$RMAN_BACKUP_JOB_DETAILS TO ' || username_ || ' WITH GRANT OPTION');
  

   -- Run_Ddl('GRANT SELECT ON V$SQLTEXT TO ' || username_ || ' WITH GRANT OPTION');
   
   -- Grant Oracle packages
   Run_Ddl('GRANT EXECUTE ON DBMS_SYSTEM TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT EXECUTE ON DBMS_OUTPUT TO ' || username_ || ' WITH GRANT OPTION');

   --
   -- IFS Monitoring BEGIN
   Run_Ddl('GRANT SELECT ON GV_$LOCK TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$TRANSACTION TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON GV_$SQLAREA TO ' || username_ || ' WITH GRANT OPTION');
   -- END IFS Monitoring
   Run_Ddl('GRANT SELECT ON ARGUMENT$ TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT DELETE ON AUD$ TO ' || username_);
   Run_Ddl('GRANT SELECT ON COM$ TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON COL$ TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON JOBSEQ TO ' || username_);
   Run_Ddl('GRANT SELECT ON OBJ$ TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON USER$ TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON PENDING_TRANS$ TO ' || username_ || ' WITH GRANT OPTION');
   Run_Ddl('GRANT SELECT ON SOURCE$ TO ' || username_ || ' WITH GRANT OPTION');
   --
-- PROMPT "Creation of nayomon user and grants complete!"
END;
/
spool off


