--Lo SCHEDULER non funziona in Oracle Live SQL, quindi è inutile tentare.
--Tutto ciò serve per eseguire la procedura ‘assegna_carte_fedelta’ ogni giorno all’1 di notte.
--Crea un JOB che viene eseguito ogni giorno all'1 di notte
BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'assegna_carte_fedelta_run',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'daily_run',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'freq=hourly; byhour=01',
    end_date        => NULL,
    enabled         => TRUE);
END;
/
dbms_scheduler.create_schedule('daily_run', repeat_interval =>
  'FREQ=DAILY;BYHOUR=01');

--Successivamente il JOB esegue la procedura 'assegna_carte_fedelta'
DBMS_SCHEDULER.CREATE_PROGRAM (
   program_name => 'assegna_carte_fedelta_job',
   program_type   => 'STORED_PROCEDURE',
   program_action    => 'assegna_carte_fedelta',
   enabled   => TRUE);