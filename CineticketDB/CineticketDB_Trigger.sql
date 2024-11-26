--TRIGGER 1 Controlla se la carta fedeltà è scaduta e che la promo inserita è attiva! 
CREATE OR REPLACE TRIGGER Promozione_scaduta
BEFORE INSERT OR UPDATE OF Codice_promozione ON Carrello
FOR EACH ROW
DECLARE
    conteggio1 NUMBER;
    conteggio2 NUMBER;
    conteggio3 NUMBER;
BEGIN
    SELECT COUNT(*) INTO conteggio1 FROM promozione PRO WHERE PRO.Data_fine_promozione < :NEW.Data_inserimento AND PRO.Codice_promozione = :NEW.Codice_promozione;
    SELECT COUNT(*) INTO conteggio2 FROM Carta_fedelta CAR WHERE CAR.Data_scadenza < :NEW.Data_inserimento AND CAR.Username = :NEW.Username;
    SELECT COUNT(*) INTO conteggio3 FROM Carta_fedelta car WHERE car.Username=:NEW.Username;
    IF conteggio1+conteggio2 > 0 OR conteggio3 = 0 THEN
        IF conteggio3 = 0 THEN
	dbms_output.put_line('L''utente ' || TRIM(:NEW.Username) || ' non possiede una carta fedelta''!');
        ELSIF conteggio2 > 0 THEN
	dbms_output.put_line('La carta fedelta'' dell''utente ' || TRIM(:NEW.Username) || ' e'' scaduta!');
        ELSIF conteggio1 > 0 THEN
	dbms_output.put_line('La promozione ''' || TRIM(:NEW.Codice_promozione) || ''' e'' scaduta!');
        END IF;
        :NEW.Codice_promozione := NULL;
    END IF;
END;
/
 
 
 
 
--Esempio utilizzo
--select * from promozione;
--select * from carrello;
--insert into promozione values ('promo02', 'Clienti best vecchio', TO_DATE('01/06/2022', 'dd/mm/yyyy'), TO_DATE('15/06/2022', 'dd/mm/yyyy'));
--insert into carrello values ('cart003', TO_DATE('16/06/2022 20:14', 'dd/mm/yyyy hh24:mi'), 'Luke3012', '1000735724964861', 'promo02');
--select * from carrello order by codice_carrello;
--Osserviamo che la promo02 non c’è poiché non valida!
--UPDATE Carta_fedelta
--SET Data_scadenza = TO_DATE('10/06/2022','dd/mm/yyyy'), Data_rinnovo = TO_DATE('10/06/2021','dd/mm/yyyy')
--WHERE Username = 'Luke3012';
--insert into carrello values ('cart004', TO_DATE('16/06/2022 20:14', 'dd/mm/yyyy hh24:mi'), 'Luke3012', '1000735724964861', 'promo01');
--Osserviamo che la carta fedeltà aggiornata non è più valida poiché più vecchia
 
 
 
--TRIGGER 2 Controlla se la sala è piena dopo l’inserimento di un posto 
CREATE OR REPLACE TRIGGER Sala_piena
BEFORE INSERT ON Posto
FOR EACH ROW
DECLARE
    contsala NUMBER;
    capienza NUMBER;
BEGIN
    SELECT Massima_capienza INTO capienza from sala sl where :new.nome_sala = sl.nome_sala and :new.Citta_cinema = sl.Citta_cinema AND :new.Via_cinema = sl.Via_cinema AND :new.CAP_cinema = sl.CAP_cinema;
    select count(*) INTO contsala from posto po where :new.nome_sala = po.nome_sala AND :new.Citta_cinema = po.Citta_cinema AND :new.Via_cinema = po.Via_cinema AND :new.CAP_cinema = po.CAP_cinema;
    IF contsala = capienza THEN
        raise_application_error(-20000, 'massima capienza raggiunta');
    END IF;
END;
/
 
--TRIGGER 3 Controllo se i biglietti per una sala sono finiti, non si possono acquistare. 
CREATE OR REPLACE FUNCTION verifica_posti (numero_richiesto NUMBER, Ora_inizio DATE, Ora_fine DATE, Sala CHAR, Citta VARCHAR, Via VARCHAR, CAP CHAR)
RETURN BOOLEAN
IS
    numero_posti NUMBER;
    biglietti_venduti NUMBER;
BEGIN
    select count(*) into biglietti_venduti 
    from biglietto bg  
    where (bg.ora_inizio_spettacolo = ora_inizio) AND (bg.ora_fine_spettacolo = ora_fine)
    AND (bg.nome_sala = sala) AND (bg.citta_cinema = citta) AND (bg.cap_cinema = cap) AND (bg.via_cinema = via);
   
    --E’ possibile misurare la capienza in base al valore di “Massima_capienza” presente nell’entità Sala 
    --select distinct sl.Massima_capienza into numero_posti 
    --from spettacolo sp JOIN sala sl ON (sp.nome_sala = sl.nome_sala AND sp.Citta_cinema = sl.citta_cinema AND sp.via_cinema = sl.via_cinema AND sp.CAP_cinema = sl.CAP_cinema)
    --where ora_inizio = sp.ora_inizio AND ora_fine = sp.ora_fine AND sala = sp.nome_sala
    --AND Citta=sp.citta_cinema AND CAP=sp.cap_cinema AND Via=sp.via_cinema;
    
    --Ma è preferibile misurare la capienza in base al numero dei posti effettivamente inseriti per evitare errori
    select count(*) into numero_posti from posto po
    where po.citta_cinema=citta and po.via_cinema=via and po.cap_cinema=cap and po.nome_sala=sala;
    
    if (biglietti_venduti+numero_richiesto) > numero_posti then 
        RETURN FALSE;
    end if;
    RETURN TRUE;
END verifica_posti;
/
 
 
CREATE OR REPLACE TRIGGER biglietti_terminati
BEFORE INSERT ON biglietto 
FOR EACH ROW
DECLARE
    errore exception ;
BEGIN
    if verifica_posti(1, :New.Ora_inizio_spettacolo, :New.Ora_fine_spettacolo, :new.nome_sala, :new.citta_cinema, :new.via_cinema, :new.cap_cinema) = FALSE THEN
        RAISE errore;
    end if;
 
EXCEPTION  
WHEN errore then 
    raise_application_error('-20010','Posti terminati! Biglietto non acquistabile.');
END;
/
 
 
 
 

--TRIGGER 4 Controllo se l’utente ha l’età giusta per poter acquistare il biglietto 
CREATE OR REPLACE TRIGGER Limite_eta
BEFORE INSERT ON Biglietto
FOR EACH ROW
DECLARE
    rating NUMBER;
    eta NUMBER;
BEGIN
    SELECT TRUNC((SYSDATE - Data_di_nascita)/ 365.25) INTO eta FROM (utente us JOIN carrello cr ON us.username=cr.username) WHERE cr.codice_carrello=:NEW.codice_carrello;
    SELECT Classificazione INTO rating FROM (Spettacolo sp JOIN Film fi ON sp.Codice_film=fi.Codice_film)
    WHERE sp.ora_inizio=:NEW.ora_inizio_spettacolo AND sp.ora_fine=:NEW.ora_fine_spettacolo
    AND sp.nome_sala=:NEW.nome_sala AND sp.citta_cinema=:NEW.citta_cinema AND sp.cap_cinema=:NEW.cap_cinema AND :NEW.via_cinema=sp.via_cinema;
    IF eta < rating THEN
        raise_application_error(-20000, 'L''utente non ha l''eta'' adatta per poter acquistare biglietti per questo film!');
    END IF;
END;
/



--Esempio utilizzo
--insert into carrello values ('cart018', TO_DATE('28/06/2022 16:04', 'dd/mm/yyyy hh24:mi'), 'Napoli10', '1010294861827301', NULL);
--insert into biglietto values ('ticket003', 10, 'cart018', TO_DATE('19:30', 'hh24:mi'), TO_DATE('04/09/2022', 'dd/mm/yyyy'), TO_DATE('21:30', 'hh24:mi'), 'A', 3, '01', 'Salerno', 'Viale antonio', '84131');


--TRIGGER 5 Controlla se lo Spettacolo associato al Biglietto che si va ad aggiungere esiste e se il Posto è già occupato
CREATE OR REPLACE FUNCTION verifica_posto (Ora_inizio DATE, Ora_fine DATE, Sala CHAR, Citta VARCHAR, Via VARCHAR, CAP CHAR, Fila CHAR, Numero NUMBER)
RETURN BOOLEAN
IS
    conta_posto NUMBER;
BEGIN
    SELECT COUNT (*) INTO conta_posto FROM Biglietto bi WHERE bi.ora_inizio_spettacolo=ora_inizio AND bi.ora_fine_spettacolo=ora_fine
    AND bi.nome_sala=sala AND bi.citta_cinema=citta AND bi.via_cinema=via AND bi.Cap_cinema=cap AND bi.fila_posto=fila AND bi.numero_posto=numero;
    IF conta_posto = 1 THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END verifica_posto;
/


CREATE OR REPLACE TRIGGER VerificaPosto_Spettacolo
BEFORE INSERT ON Biglietto
FOR EACH ROW
DECLARE
    conta_spettacolo NUMBER;
    conta_posto NUMBER;
BEGIN
    SELECT COUNT(*) INTO conta_spettacolo FROM Spettacolo sp
    WHERE sp.ora_inizio=:NEW.ora_inizio_spettacolo AND sp.ora_fine=:NEW.ora_fine_spettacolo
    AND sp.nome_sala=:NEW.nome_sala AND sp.citta_cinema=:NEW.citta_cinema AND sp.via_cinema=:NEW.via_cinema AND sp.cap_cinema=:NEW.cap_cinema;
    IF conta_spettacolo <> 1 THEN
        raise_application_error(-20099, 'Non esiste uno spettacolo con queste caratteristiche!');
    END IF;
    
    IF verifica_posto(:New.Ora_inizio_spettacolo, :New.Ora_fine_spettacolo, :new.nome_sala, :new.citta_cinema, :new.via_cinema, :new.cap_cinema, :new.fila_posto, :new.numero_posto) = FALSE THEN
        raise_application_error(-20100, 'Questo posto ('||:NEW.fila_posto||:NEW.numero_posto||') risulta gia'' occupato!');
    END IF;
END;
/



--TRIGGER 6 CONTROLLO CARTA DI CREDITO SCADUTA, SE E’ SCADUTA NON TI FA ACQUISTARE IL BIGLIETTO
CREATE OR REPLACE TRIGGER carta_credito_scaduta
BEFORE INSERT OR UPDATE ON carrello
FOR EACH ROW
DECLARE
carta_scaduta number;
scaduta exception;
BEGIN
SELECT count (*) into carta_scaduta
from carta_di_credito car 
WHERE :new.Numero_carta = car.Numero_carta AND car.Data_scadenza < SYSDATE(); 
IF inserting THEN
IF carta_scaduta >= 1
THEN
RAISE scaduta;
END IF;
END IF;

IF updating THEN 
if carta_scaduta >= 1
THEN
RAISE scaduta;
end if;
END IF;

exception
WHEN scaduta THEN 
raise_application_error('-20001','La carta associata al carrello e'' scaduta e non puo'' fare acquisti');
END;
/


--TRIGGER 7 Verifica se l’utente ha visto il film, se ha pagato il biglietto e se ha già recensito il film. Se l’utente non ha ancora visto il film o non ha pagato oppure ha già recensito il film, allora non può recensire!
CREATE OR REPLACE TRIGGER controllo_recensione
BEFORE INSERT OR UPDATE ON recensione
FOR EACH ROW
DECLARE
    cont number;
    codice char(10);
    biglietto_corrente Biglietto%ROWTYPE;
    film_nonvisto exception;
    non_pagato exception;
    recensione_gia_fatta exception;
    no_codice_film exception;
BEGIN
    select count(*) INTO cont
    from biglietto bg WHERE bg.codice_biglietto=:NEW.codice_biglietto AND :NEW.data_pubblicazione>bg.ora_fine_spettacolo;
    if cont < 1 THEN
        RAISE film_nonvisto;
    end if;

    select count(*) INTO cont
    from biglietto bg JOIN carrello ca ON bg.codice_carrello=ca.codice_carrello
    WHERE bg.codice_biglietto=:NEW.codice_biglietto AND ca.data_pagamento IS NOT NULL;
    if cont < 1 THEN
        RAISE non_pagato;
    END IF;

    --Si assicura che il film venga recensito solo una volta per spettacolo da parte dell'utente
    SELECT * INTO biglietto_corrente FROM Biglietto WHERE codice_biglietto=:NEW.codice_biglietto;
    IF INSERTING THEN
        select count(*) INTO cont
        from recensione re join biglietto bi on re.codice_biglietto=bi.codice_biglietto
        where bi.codice_carrello = biglietto_corrente.codice_carrello
        and bi.ora_inizio_spettacolo = biglietto_corrente.ora_inizio_spettacolo
        and bi.ora_fine_spettacolo = biglietto_corrente.ora_fine_spettacolo
        and bi.nome_sala = biglietto_corrente.nome_sala
        and bi.citta_cinema = biglietto_corrente.citta_cinema
        and bi.cap_cinema = biglietto_corrente.cap_cinema
        and bi.via_cinema = biglietto_corrente.via_cinema;

        IF cont > 0 THEN
            RAISE recensione_gia_fatta;
        END IF;
    END IF;

    SELECT spe.codice_film INTO codice FROM Spettacolo spe JOIN Biglietto bi ON spe.citta_cinema=bi.citta_cinema
    AND spe.cap_cinema=bi.cap_cinema AND spe.via_cinema=bi.via_cinema AND spe.nome_sala=bi.nome_sala
    AND spe.Ora_inizio=bi.Ora_inizio_spettacolo AND spe.Ora_fine=bi.Ora_fine_spettacolo
    WHERE bi.codice_biglietto=:NEW.codice_biglietto;

    IF :NEW.codice_film IS NULL THEN
        :NEW.codice_film := codice;
    ELSIF codice <> :NEW.codice_film THEN
        RAISE no_codice_film;
    END IF;

EXCEPTION
WHEN film_nonvisto THEN
    raise_application_error('-20001','Non puoi recensire un film non visto!');
WHEN non_pagato THEN
    raise_application_error('-20002','Non puoi recensire un film se non hai pagato il biglietto!');
WHEN recensione_gia_fatta THEN
    raise_application_error('-20003','Non puoi recensire un film due volte nello stesso carrello!');
WHEN no_codice_film THEN
    raise_application_error('-20004','Il codice del film della recensione non combacia con quello del biglietto!');
END;
/

  
 
--TRIGGER 8 Applica una delle promozioni disponibili all’utente prima dell’inserimento di un carrello
CREATE OR REPLACE TRIGGER AutoPromo
BEFORE INSERT ON Carrello
FOR EACH ROW
DECLARE
    promo CHAR(10);
    fedelta CHAR(10);
BEGIN
    IF :NEW.Codice_promozione IS NOT NULL THEN
        RETURN;
    END IF;

    SELECT ca.codice_carta_fedelta INTO fedelta FROM Carta_fedelta ca WHERE ca.Username=:NEW.username;
    
    SELECT pro.Codice_promozione INTO promo FROM Promozione_fedelta pf JOIN Promozione pro ON pf.codice_promozione=pro.codice_promozione 
    JOIN Carta_fedelta ca ON ca.codice_carta_fedelta=pf.codice_carta_fedelta 
    WHERE ca.Codice_carta_fedelta=fedelta AND ca.Data_scadenza >= :NEW.Data_Inserimento AND pro.Data_fine_promozione >= :NEW.Data_Inserimento
    ORDER BY DBMS_RANDOM.VALUE 
    FETCH FIRST 1 ROWS ONLY;

    :NEW.Codice_promozione := promo;
    dbms_output.put_line('All''utente ' || TRIM(:NEW.Username) || ' e'' stata attribuita la promo ' || TRIM(promo));
EXCEPTION WHEN NO_DATA_FOUND THEN
    RETURN;
END;
/


--TRIGGER 9 Associa automaticamente una Promozione a una Carta Fedeltà, se e solo se quest’ultima non è scaduta e il sistema decide di assegnarla (genera un numero randomico da 1 a 100, se > 50 allora la assegna)
CREATE OR REPLACE TRIGGER AssociaPromoCarta
AFTER INSERT OR UPDATE ON Promozione
FOR EACH ROW
DECLARE
    CURSOR fedelta IS
        SELECT *
        FROM Carta_fedelta
        WHERE Data_scadenza>=:NEW.Data_inizio_promozione;
    fedelta_corrente carta_fedelta%ROWTYPE;
BEGIN
    OPEN fedelta;
    LOOP
        FETCH fedelta INTO fedelta_corrente;
        EXIT WHEN fedelta%NOTFOUND;
        
        IF round(DBMS_RANDOM.VALUE (0, 100)) > 49 THEN
            INSERT INTO promozione_fedelta values (fedelta_corrente.codice_carta_fedelta, :NEW.codice_promozione);
            dbms_output.put_line('Promozione ''' || TRIM(:NEW.codice_promozione) || ''' assegnata alla carta fedelta'' ' || fedelta_corrente.codice_carta_fedelta);
        END IF;
    END LOOP;
    CLOSE fedelta;
END;
/


--TRIGGER 10 CONTROLLO CHE LA DATA PAGAMENTO SIA NULL ALL’INSERIMENTO
CREATE OR REPLACE TRIGGER controllo_data_pagamento 
BEFORE INSERT ON carrello 
FOR EACH ROW
DECLARE 
temp number ;
controllo exception;

BEGIN 
SELECT count(*) INTO temp
FROM biglietto bg JOIN carrello cr ON bg.codice_carrello = :new.codice_carrello;

if temp = 0 AND :new.data_pagamento IS NOT NULL then
    RAISE controllo;
end if;

EXCEPTION 
WHEN controllo THEN
    :NEW.data_pagamento := NULL;
    DBMS_OUTPUT.PUT_LINE('Il carrello con codice : ' || TRIM(:NEW.codice_carrello) || ' è vuoto, per cui la data del pagamento viene setta a NULL');
END;
/

--TRIGGER 11 CONTROLLO COERENZA DATE SPETTACOLO
CREATE OR REPLACE TRIGGER controllo_giorno_spettacolo 
BEFORE INSERT OR UPDATE ON spettacolo 
FOR EACH ROW 
DECLARE 
temp number ;
controllo exception;


BEGIN 
temp := 0 ;
if EXTRACT( YEAR from :new.ora_inizio  ) = EXTRACT( YEAR from :new.ora_fine ) AND
       EXTRACT( MONTH FROM :new.ora_inizio ) = EXTRACT( MONTH from :new.ora_fine ) AND 
       EXTRACT( DAY FROM :new.ora_inizio ) = EXTRACT(DAY from :new.ora_fine ) AND 
        EXTRACT( HOUR FROM CAST( :new.ora_inizio AS TIMESTAMP )) < EXTRACT( HOUR FROM CAST( :new.ora_fine AS TIMESTAMP))
then
    temp := 1;
  end if ;

IF temp = 0  THEN
    RAISE controllo ;
   end if;

exception
when controllo then 
    raise_application_error ('-20001','ERRORE: sono state settate date non valide per l''inizio e la fine dello spettacolo!');
 END;
/


--TRIGGER 12 Verifica se l’utente ha una carta fedeltà. Se l’utente ha una carta fedeltà e se non ci sono altri biglietti dello stesso carrello già scontati, allora il prezzo finale sarà dimezzato. Altrimenti il prezzo sarà determinato in base al giorno della settimana!
CREATE OR REPLACE FUNCTION DeterminaPrezzo(codice_biglietto char, codice_carrell char, ora_inizio DATE)
RETURN NUMBER
IS
    costo NUMBER;
    conteggio NUMBER;
BEGIN
    IF to_char(ora_inizio, 'D') = '1' OR to_char(ora_inizio, 'D') = '7' THEN
        --Il costo il sabato e la domenica 
        costo := 10;
    ELSE
        costo := 8;
    END IF;
    
    SELECT COUNT(*) INTO conteggio FROM Biglietto bi JOIN Carrello car ON bi.codice_carrello=car.codice_carrello
    WHERE bi.codice_carrello=codice_carrell
    AND EXISTS (SELECT NULL FROM Carta_fedelta ca WHERE ca.Username=car.username AND ca.Data_scadenza>=ora_inizio);
    
    IF conteggio = 0 THEN
        --Se l'utente ha una carta fedeltà e non ha già acquistato un biglietto scontato, applica lo sconto
        dbms_output.put_line('Al biglietto ''' || TRIM(codice_biglietto) || ''' e'' stato applicato un buono sconto.');
        costo := costo/2;
    END IF;
    
    RETURN costo;
END DeterminaPrezzo;
/

CREATE OR REPLACE TRIGGER Prezzo_biglietto
BEFORE INSERT ON Biglietto
FOR EACH ROW
BEGIN
    IF :NEW.Prezzo IS NOT NULL THEN
        RETURN;
    END IF;
    
    :NEW.Prezzo := DeterminaPrezzo(:NEW.codice_biglietto, :NEW.codice_carrello, :NEW.ora_inizio_spettacolo);
END;
/

--TRIGGER 13 Verifica che non esistono ancora biglietti appartenenti al carrello prima di cancellarlo
CREATE OR REPLACE TRIGGER Verifica_cancellazione_carrello
BEFORE DELETE ON Carrello
FOR EACH ROW
DECLARE
    conta NUMBER;
BEGIN
    SELECT count(*) INTO conta FROM Biglietto bi
    WHERE bi.codice_carrello=:OLD.codice_carrello;
    
    IF conta > 0 THEN
        raise_application_error('-20030','Impossibile eliminare il carrello '''||TRIM(:OLD.codice_carrello)||''', ci sono ancora '||conta||' biglietti associati ad esso.');
    END IF;
END;
/


--TRIGGER 14 Se l’utente è bannato, allora non può acquistare nulla.
CREATE OR REPLACE TRIGGER Utente_bannato_carrello
BEFORE INSERT OR UPDATE ON Carrello
FOR EACH ROW
DECLARE
    banned CHAR(1);
BEGIN
    SELECT ut.abilitato INTO banned FROM Utente ut WHERE ut.Username=:NEW.Username;
    IF banned = 'F' THEN
        raise_application_error('-20050','Impossibile procedere, l''utente ' || TRIM(:NEW.Username) || ' è stato bannato.');
    END IF;
END;
/

--TRIGGER 15 Se l’utente è bannato, allora non può rinnovare la propria carta fedeltà
CREATE OR REPLACE TRIGGER Utente_bannato_fedelta
BEFORE INSERT OR UPDATE ON Carta_fedelta
FOR EACH ROW
DECLARE
    banned CHAR(1);
BEGIN
    SELECT ut.abilitato INTO banned FROM Utente ut WHERE ut.Username=:NEW.Username;
    IF banned = 'F' THEN
        raise_application_error('-20051','Impossibile procedere, l''utente ' || TRIM(:NEW.Username) || ' è stato bannato.');
    END IF;
END;
/
