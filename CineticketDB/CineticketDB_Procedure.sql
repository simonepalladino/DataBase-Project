--Procedura che può essere eseguita sia dal’utente che dalll’admin per eliminare biglietti associati a --spettacoli ormai terminati, questa procedura viene eseguita inoltre in modo automatico quando --l’utente esegue la procedura update_data_pagamento
--PROCEDURA 1
CREATE OR REPLACE PROCEDURE elimina_biglietti_scaduti (CAR char)
IS
 
temp number;
 
BEGIN 
select count(*) into temp 
from biglietto 
where codice_carrello = CAR AND ora_inizio_spettacolo < (select sysdate from dual);
 
if temp <= 0  then 
DBMS_OUTPUT.PUT_LINE('NEL CARRELLO ' || CAR || ' NON CI SONO BIGLIETTI SCADUTI, SE IL CARRELLO NON E’’VUOTO PUOI PROCEDERE ALL’’ACQUISTO’');
ELSE
DELETE 
FROM biglietto 
where codice_carrello = CAR AND ora_inizio_spettacolo < (select sysdate from dual);
end if;
 
end;
/
--PROCEDURA 2 aggiorna la data del pagamento del carrello preso in input se i biglietti associati allo spettacolo sono ancora validi e quindi lo spettacolo ancora non è iniziato
CREATE OR REPLACE PROCEDURE update_data_pagamento (CAR char,data_p date, data_sistema date default NULL)  
IS 
temp number;
temp1 date;
pagamento number;
conteggio number ;
CURSOR c1 IS
  select *
    from biglietto   
    where codice_carrello = CAR and ora_inizio_spettacolo <data_p;  
    biglietto_scaduto biglietto%ROWTYPE;
  
BEGIN
    conteggio := 0 ;
    if data_sistema IS NULL THEN
        SELECT SYSDATE into temp1 
        from dual; 
    ELSE
        temp1 := data_sistema;
    END IF;
     
    SELECT count(*) into pagamento
    from carrello cr join biglietto bg ON bg.codice_carrello = cr.codice_carrello 
    where cr.codice_carrello = CAR and cr.data_pagamento is null;
     
    if data_p < temp1 OR pagamento = 0 then  
  	IF data_p < temp1 then
            raise_application_error('-20001','La data di pagamento non è valida, non puoi tornare indietro nel tempo per pagare'); 
    elsif pagamento = 0 then
        raise_application_error('-20001','Non c''è alcun biglietto da pagare');
    END IF;
     
    END IF; 
     
    select COUNT ( DISTINCT bg.codice_carrello) INTO temp     
    from carrello cr JOIN biglietto bg ON bg.codice_carrello = cr.codice_carrello  
    where cr.codice_carrello = CAR AND data_p < ALL (  
    select bg.ora_inizio_spettacolo  
    from biglietto bg 
    where bg.codice_carrello = CAR ) ;  
      
    if temp = 1 then   
  	UPDATE carrello   
  	SET data_pagamento = data_p  
  	where codice_carrello = CAR;  
    else  
     DBMS_OUTPUT.PUT_LINE('Attenzione! Nel carrello ci sono dei biglietto associati a spettacoli terminati :');  
            OPEN c1;  
            LOOP  
            FETCH c1 INTO biglietto_scaduto ;
                
                if c1%FOUND then  
                    DBMS_OUTPUT.PUT_LINE(biglietto_scaduto.codice_biglietto);
                    conteggio := conteggio +1;
                end if; 
                           
               EXIT WHEN c1%NOTFOUND;  
            END LOOP;  
      DBMS_OUTPUT.PUT_LINE('I BIGLIETTI SCADUTI VERRANNO IN AUTOMATICO ELIMINATI DAL CARRELLO PER ESEGUIRE POI LA MODIFICA DELLA DATA DI PAGAMENTO.');
      SELECT count(*) into pagamento
    from carrello cr join biglietto bg ON bg.codice_carrello = cr.codice_carrello 
    where cr.codice_carrello = CAR;
elimina_biglietti_scaduti(CAR);
     if pagamento - conteggio > 0 then 
      UPDATE carrello   
  	SET data_pagamento = data_p  
  	where codice_carrello = CAR; 
  	end if;
      
    end if; 
end;
/

 

 --PROCEDURA 3 Inserisce un cinema e lo popola in base ai dati della capienza: sarà necessario specificare il numero massimo dei posti e quanti posti sono popolabili per fila
CREATE OR REPLACE PROCEDURE inserisci_posti (Nome VARCHAR, Citta VARCHAR, CAP CHAR, VIA VARCHAR, totale_sale NUMBER, totale_posti NUMBER DEFAULT NULL, massimo_fila NUMBER DEFAULT 1, tipo_sale VARCHAR DEFAULT NULL)
IS
    indice NUMBER;
    indice2 NUMBER;
    indice3 NUMBER;
    posti_da_inserire NUMBER;
    posti_inseriti NUMBER;
    fila_corrente CHAR;
    numero NUMBER;
    tipologia VARCHAR(10);
    posti_c NUMBER;
BEGIN
    IF totale_sale > 99 THEN
        raise_application_error('-20040', 'Impossibile aggiungere un cinema con piu'' di 99 sale!');
    END IF;
    IF totale_posti < 1 THEN
        raise_application_error('-20041', 'Inserire un numero di posti corretto!');
    END IF;
    IF massimo_fila < 1 THEN
        raise_application_error('-20042', 'Inserire un numero di file corretto!');
    END IF;
    INSERT INTO Cinema VALUES (Citta, Via, CAP, Nome);
    
    FOR indice IN 1..totale_sale
    LOOP
        --Genera un tipo di sala randomico se non è specificato in input
        IF tipo_sale IS NULL THEN
            numero := round(DBMS_RANDOM.VALUE (0, 10));
            IF numero < 6 THEN
                tipologia := 'Standard';
            ELSIF numero > 5 AND numero < 8 THEN
                tipologia := '3D';
            ELSIF numero > 8 AND numero < 11 THEN
                tipologia := 'IMAX';
            END IF;
        ELSE
            tipologia := tipo_sale;
        END IF;
        dbms_output.put_line('La sala '||TO_CHAR(indice, 'fm00')||' e'' di tipologia '||tipologia||'.');
        
        IF totale_posti IS NULL THEN
            posti_c := round(DBMS_RANDOM.VALUE (1, 20));
        ELSE
            posti_c := totale_posti;
        END IF;
        dbms_output.put_line('La sala '||TO_CHAR(indice, 'fm00')||' ha massima capienza: '||posti_c||'.');
        
        INSERT INTO Sala VALUES (TO_CHAR(indice, 'fm00'), Citta, VIA, CAP, tipologia, posti_c);
        
        posti_inseriti := 0;
        fila_corrente := 'A';
        FOR indice2 IN 1..massimo_fila+1
        LOOP
            posti_da_inserire := posti_c/massimo_fila;
            
            IF posti_da_inserire+posti_inseriti > posti_c THEN
                posti_da_inserire := posti_c - posti_inseriti;
            END IF;
            
            FOR indice3 IN 1..posti_da_inserire
            LOOP
                insert into posto values (fila_corrente, indice3, TO_CHAR(indice, 'fm00'), citta, via, cap);
                posti_inseriti := posti_inseriti + 1;
            END LOOP;
            
            fila_corrente := CHR(ASCII(fila_corrente) + 1);
            EXIT WHEN posti_inseriti = posti_c;
        END LOOP;
    END LOOP;
END inserisci_posti;
/

--delete from posto where citta_cinema='Pomigliano d''Arco' AND Via_cinema='Via Mauro Leone';
--delete from sala where citta_cinema='Pomigliano d''Arco' AND Via_cinema='Via Mauro Leone';
--delete from cinema where nome_cinema='Strunzonet';
--CALL inserisci_posti('Strunzonet', 'Pomigliano d''Arco', '80038', 'Via Mauro Leone', 3, NULL, 2, NULL);
--select * from posto where via_cinema='Via Mauro Leone' order by nome_sala;



--PROCEDURA 4 Annulla o rimborsa l’ordine effettuato se si è entro i limiti consentiti: il richiedente dell’annullamento/rimborso deve richiedere entro il giorno precedente allo spettacolo.
CREATE OR REPLACE PROCEDURE annulla_ordine(codice_carrell CHAR, data_eliminazione DATE DEFAULT SYSDATE)
IS
    conta_biglietti number;
    conta_biglietti_annullabili number;
    prezzo_r number := 0;
    conta_carrello number;
    indice number;
    biglietto_corrente char;
    data_pagamento_r date;
BEGIN
    select count(*) INTO conta_biglietti from biglietto bigl 
    where bigl.codice_carrello = codice_carrell;
    select count(*) INTO conta_carrello from carrello car 
    where car.codice_carrello = codice_carrell;
    
    --Verifica se tutti i biglietti dell'ordine sono annullabili!
    --[Verifica se sono presenti delle recensioni]
    select count(*) INTO conta_biglietti_annullabili

    from biglietto bg join recensione rec on bg.codice_biglietto=rec.codice_biglietto
    where codice_carrell = bg.codice_carrello;
    if conta_biglietti_annullabili > 0 then
        raise_application_error('-20022','Ordine non annullabile! Ci sono '||conta_biglietti_annullabili||' recensioni fatte!');
    end if;
    
    --[Verifica se si è ancora in tempo per annullare l'ordine (il giorno prima dello spettacolo)]
    select count(*), sum(bg.prezzo) INTO conta_biglietti_annullabili, prezzo_r from biglietto bg join carrello car ON bg.codice_carrello=car.codice_carrello
    where codice_carrell = bg.codice_carrello and data_eliminazione<TO_DATE(bg.ora_inizio_spettacolo-1);
    if conta_biglietti_annullabili < conta_biglietti then
        raise_application_error('-20023','Ordine non annullabile! Ci sono '||conta_biglietti-conta_biglietti_annullabili||' biglietti non annullabili!');
    end if;
    
    IF conta_biglietti > 0 THEN
        FOR indice IN 1..conta_biglietti
        LOOP
            --Seleziona un biglietto desiderato alla volta
            select bg.codice_biglietto INTO biglietto_corrente from biglietto bg
            where codice_carrell = bg.codice_carrello
            FETCH FIRST 1 ROWS ONLY;
            
            delete from biglietto where codice_biglietto=biglietto_corrente;
        END LOOP;
        
        SELECT ca.data_pagamento INTO data_pagamento_r FROM carrello ca WHERE ca.codice_carrello=codice_carrell;
        DELETE FROM carrello ca WHERE ca.codice_carrello=codice_carrell;
        
        IF data_pagamento_r IS NOT NULL AND prezzo_r > 0 THEN
            DBMS_OUTPUT.PUT_LINE('L''importo di '||prezzo_r||' € sara'' rimborsato sulla propria carta.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Ordine annullato, sono stati eliminati '||conta_biglietti||' biglietti.');
        END IF;
    ELSIF conta_biglietti = 0 AND conta_carrello = 1 THEN
    	DBMS_OUTPUT.PUT_LINE('Il carrello non contiene biglietti, annullo l''ordine.');
    	DELETE FROM carrello ca WHERE ca.codice_carrello=codice_carrell;
    END IF;
END;
/




 
 
 
 
--PROCEDURA 5 Auto_Acquista, acquista un determinato numero di biglietti per il cliente e i suoi amici, determinando i posti disponibili. Le FUNCTION ultimo_biglietto e ultimo_carrello restituiscono il numero dell’ultimo biglietto e carrello presente nel database, allo scopo di non duplicare i dati.

--Restituisce come tipo number l’ultimo biglietto acquistato
CREATE OR REPLACE FUNCTION ultimo_biglietto
RETURN NUMBER
IS
    codice CHAR(10);
BEGIN
    SELECT Codice_biglietto INTO codice FROM Biglietto ORDER BY Codice_biglietto DESC FETCH FIRST 1 ROWS ONLY;
    RETURN TO_NUMBER(REPLACE(codice, 'ticket'));
EXCEPTION WHEN OTHERS THEN
    --Se da errore perché non ci sono biglietti (o per altre questioni), allora ritorna 0
    RETURN 0;
END ultimo_biglietto;
/

--Restituisce come tipo number l’ultimo carrello aggiunto
CREATE OR REPLACE FUNCTION ultimo_carrello
RETURN NUMBER
IS
    codice CHAR(10);
BEGIN
    SELECT Codice_carrello INTO codice FROM Carrello ORDER BY Codice_carrello DESC FETCH FIRST 1 ROWS ONLY;
    RETURN TO_NUMBER(REPLACE(codice, 'cart'));
EXCEPTION WHEN OTHERS THEN
    --Se da errore perché non ci sono carrelli (o per altre questioni), allora ritorna 0
    RETURN 0;
END ultimo_carrello;
/

--PROCEDURA che consente l’acquisto di biglietti multipli da parte dell’utente 
CREATE OR REPLACE PROCEDURE auto_acquista(username CHAR, numero_biglietti NUMBER, data_acquisto DATE, numero_carta CHAR,
ora_inizio DATE, Ora_fine DATE, Citta VARCHAR, Via VARCHAR, CAP CHAR, Sala CHAR, Fila CHAR DEFAULT NULL, Numero NUMBER DEFAULT NULL)
IS
    indice NUMBER;
    posto_corrente Posto%ROWTYPE;
    numero_corrente NUMBER;
BEGIN
    IF numero_biglietti < 1 THEN
        raise_application_error('-20021','Inserisci un numero di biglietti valido!');
    END IF;
    numero_corrente := numero_biglietti;
    
    if verifica_posti(numero_corrente, ora_inizio, ora_fine, sala, citta, via, cap) = FALSE THEN
        raise_application_error('-20020','Posti terminati! Biglietto/i non acquistabile/i.');
    end if;
    
    insert into carrello values ('cart' || TO_CHAR(ultimo_carrello+1, 'fm000'), data_acquisto, NULL, username, numero_carta, NULL);
    
    IF Fila IS NOT NULL AND Numero IS NOT NULL THEN
        IF verifica_posto(ora_inizio, ora_fine, sala, citta, via, cap, Fila, Numero) = TRUE THEN
            insert into biglietto values ('ticket'||TO_CHAR(ultimo_biglietto+1, 'fm000'), 10, 'cart'||TO_CHAR(ultimo_carrello, 'fm000'), ora_inizio, ora_fine, Fila, Numero, Sala, Citta, Via, CAP);
            numero_corrente := numero_corrente-1;
        END IF;
    END IF;
    
    
    FOR indice IN ultimo_biglietto+1..ultimo_biglietto+numero_corrente
    LOOP
        SELECT * INTO posto_corrente FROM Posto po
        WHERE po.nome_sala=sala AND po.citta_cinema=citta AND po.cap_cinema=cap AND po.via_cinema=via
        AND NOT EXISTS (
            SELECT NULL FROM Biglietto bi
            WHERE bi.ora_inizio_spettacolo=ora_inizio AND bi.ora_fine_spettacolo=ora_fine AND
            bi.citta_cinema=citta AND bi.via_cinema=via AND bi.cap_cinema=cap AND bi.nome_sala=sala
            AND bi.fila_posto=po.fila AND bi.numero_posto=po.numero_posto
        )
        ORDER BY po.Fila
        FETCH FIRST 1 ROWS ONLY;
        
        insert into biglietto values ('ticket'||TO_CHAR(indice, 'fm000'), NULL, 'cart'||TO_CHAR(ultimo_carrello, 'fm000'), ora_inizio, ora_fine, posto_corrente.Fila, posto_corrente.Numero_posto, Sala, Citta, Via, CAP);
    END LOOP;

    update_data_pagamento('cart'||TO_CHAR(ultimo_carrello, 'fm000'), data_acquisto, data_acquisto);
END auto_acquista;
/

--Esempio di utilizzo
--DELETE from Carrello;
--DELETE FROM BIGLIETTO;
--EXECUTE auto_acquista('Luke3012', 2, SYSDATE, '1000735724964861', TO_DATE('2022-04-30 20:00', 'YYYY-MM-DD hh24:mi'), TO_DATE('2022-04-30 21:30', 'YYYY-MM-DD hh24:mi'), 'Mondragone', 'Corso Umberto I', '81034', '01', 'A', 1);
--select * from carrello ca join biglietto bi on ca.codice_carrello=bi.codice_carrello order by ca.codice_carrello desc, bi.codice_biglietto desc;





--PROCEDURA 6 Procedura che determina se l’utente specificato fa parte della categoria di “recensori fake”. Un recensore è “fake” se pubblica spesso recensioni troppo positive rispetto alla media, se acquista molte volte biglietti per lo stesso film e se recensisce solo i film di una compagnia determinata. Sarà cura dell’amministratore decidere se bloccare l’utente dal sistema e se cancellare tutte le sue recensioni.
CREATE OR REPLACE FUNCTION AggiustaVoto (Voto NUMBER)
RETURN NUMBER
IS
BEGIN
    IF Voto > 10 THEN
        RETURN 10;
    END IF;
    
    RETURN Voto;
END AggiustaVoto;
/

CREATE OR REPLACE PROCEDURE FakeUser (utente CHAR, se_elimina_recensioni BOOLEAN DEFAULT FALSE, se_blocca_utente BOOLEAN DEFAULT FALSE)
IS
    CURSOR Recensioni IS
        SELECT fi.codice_film, fi.titolo, avg(re.votoprotagonista) as protagonista,
        avg(re.votoantagonista) as antagonista, avg(re.vototrama) as trama,
        avg(re.votocolonnasonora) as colonna, avg(re.votoscenografia) as scenografia
        FROM Recensione re JOIN Film fi ON re.codice_film=fi.codice_film
        JOIN Biglietto bi ON re.codice_biglietto=bi.codice_biglietto
        JOIN Carrello ca ON bi.codice_carrello=ca.codice_carrello
        WHERE ca.username=utente
        GROUP BY fi.codice_film, fi.titolo;
    recensioni_corrente Recensioni%ROWTYPE;
    
    protagonista NUMBER;
    antagonista NUMBER;
    trama NUMBER;
    colonna NUMBER;
    scenografia NUMBER;
    
    conteggio NUMBER := 0;
    conteggio1 NUMBER;
    conteggio2 NUMBER;
    temp VARCHAR(20);
BEGIN
    OPEN Recensioni;
    
    LOOP
        FETCH recensioni INTO recensioni_corrente;
        EXIT WHEN recensioni%NOTFOUND;
        
        --Salva la media delle recensioni del film legata agli altri utenti (tutti eccetto l'utente corrente)
        SELECT avg(mr.votoprotagonista), avg(mr.votoantagonista), avg(mr.vototrama),
        avg(mr.votocolonnasonora), avg(mr.votoscenografia) into protagonista, antagonista, trama, colonna, scenografia
        from Recensione mr JOIN Film fi ON mr.codice_film=fi.codice_film
        JOIN Biglietto bi ON mr.codice_biglietto=bi.codice_biglietto JOIN Carrello ca ON bi.codice_carrello=ca.codice_carrello
        WHERE ca.username<>utente AND mr.codice_film=recensioni_corrente.codice_film;
        
        --Se le recensioni sono più alte della media di almeno 2 punti, allora fai ulteriori verifiche
        IF recensioni_corrente.protagonista >= AggiustaVoto(protagonista+2) AND recensioni_corrente.antagonista >= AggiustaVoto(antagonista+2)
        AND recensioni_corrente.trama >= AggiustaVoto(trama+2) AND recensioni_corrente.colonna >= AggiustaVoto(colonna+2)
        AND recensioni_corrente.scenografia >= AggiustaVoto(scenografia+2) THEN
            conteggio := conteggio + 1;
            
            --Verifica se l'utente ha recensito il film più volte della media
            SELECT COUNT(*) INTO conteggio1 FROM Recensione re WHERE re.codice_film = recensioni_corrente.codice_film;
            SELECT COUNT(*) INTO conteggio2 FROM Recensione re JOIN Biglietto bi ON re.codice_biglietto=bi.codice_biglietto
            JOIN Carrello ca ON bi.codice_carrello=ca.codice_carrello
            WHERE re.codice_film = recensioni_corrente.codice_film AND ca.username=utente;
            conteggio1 := conteggio1 - conteggio2;
            IF conteggio1 < conteggio2 THEN
                conteggio := conteggio + 1;
            END IF;
            
            --Verifica se l'utente ha dato solo i massimi voti per questo film
            IF recensioni_corrente.protagonista = 10 AND recensioni_corrente.antagonista = 10
            AND recensioni_corrente.trama = 10 AND recensioni_corrente.colonna = 10
            AND recensioni_corrente.scenografia = 10 THEN
                conteggio := conteggio + 2;
            END IF;
            
            --Verifica se l'utente ha recensito il film ogni volta che è andato a vederlo
            --(le recensioni fatte dall'utente sono state già calcolate prima in conteggio2)
            SELECT COUNT(*) INTO conteggio1 FROM Biglietto bi JOIN Spettacolo spe ON bi.cap_cinema=spe.cap_cinema AND
            bi.via_cinema=spe.via_cinema AND bi.citta_cinema=spe.citta_cinema AND bi.nome_sala=spe.nome_sala AND
            bi.ora_inizio_spettacolo=spe.ora_inizio AND bi.ora_fine_spettacolo=spe.ora_fine
            JOIN Carrello car ON bi.codice_carrello=car.codice_carrello
            WHERE spe.codice_film = recensioni_corrente.codice_film AND car.username=utente;
            IF conteggio1 = conteggio2 THEN
                conteggio := conteggio + 1;
            END IF;
        ELSE
            --Il film non è sospetto, decrementa il contatore di 1
            conteggio := conteggio - 1;
        END IF;
    END LOOP;
    
    dbms_output.put_line('L''utente '''||TRIM(utente)||''' ha recensito '||recensioni%ROWCOUNT||' film.');
    
    --Verifica se l'utente ha recensito più volte soltanto i film di un'unica compagnia
    SELECT COUNT(*) INTO conteggio1 FROM
    (SELECT fi.nome_compagnia, count(*) FROM compagnia_di_produzione com JOIN Film fi ON com.nome_compagnia=fi.nome_compagnia
    JOIN (SELECT fi.codice_film, avg(re.votoprotagonista) as protagonista,
        avg(re.votoantagonista) as antagonista, avg(re.vototrama) as trama, avg(re.votocolonnasonora) as colonna, avg(re.votoscenografia) as scenografia
        FROM Recensione re JOIN Film fi ON re.codice_film=fi.codice_film
        JOIN Biglietto bi ON re.codice_biglietto=bi.codice_biglietto
        JOIN Carrello ca ON bi.codice_carrello=ca.codice_carrello
        WHERE ca.username=utente
        GROUP BY fi.codice_film)
        mr ON mr.codice_film=fi.codice_film
    GROUP BY fi.nome_compagnia);
    IF conteggio1 = 1 AND recensioni%ROWCOUNT > 1 THEN
        SELECT fi.Nome_compagnia INTO temp FROM Film fi WHERE fi.codice_film=recensioni_corrente.codice_film;
        dbms_output.put_line('L''utente '''||TRIM(utente)||''' ha recensito solo i film della compagnia '||temp||'.');
        conteggio := conteggio + (3*recensioni%ROWCOUNT);
    END IF;
    
    --Verifica se il "punteggio" supera o raggiunge 5 punti moltiplicati per il numero di film visti
    dbms_output.put_line('Punteggio totalizzato/Massimo possibile: '||conteggio||'/'||5*recensioni%ROWCOUNT);
    IF conteggio >= 5*recensioni%ROWCOUNT THEN
        dbms_output.put_line('L''utente '''||TRIM(utente)||''' e'' un possibile fake user.');
        
        IF se_elimina_recensioni = TRUE THEN
            DELETE FROM Recensione rec WHERE rec.id_recensione IN (
            SELECT rec2.id_recensione FROM Recensione rec2 JOIN Biglietto bi ON rec2.codice_biglietto=bi.codice_biglietto
            JOIN Carrello car ON car.codice_carrello=bi.codice_carrello
            WHERE car.username=utente);
            
            dbms_output.put_line('Le recensioni dell''utente '''||TRIM(utente)||''' sono state eliminate.');
        END IF;
        IF se_blocca_utente = TRUE THEN
            UPDATE Utente SET abilitato='F' WHERE Username=Utente;
            dbms_output.put_line('L''utente '''||TRIM(utente)||''' e'' stato bloccato.');
        END IF;
    ELSE
        dbms_output.put_line('L''utente '''||TRIM(utente)||''' e'' un bravo utente.');
    END IF;
    
    CLOSE Recensioni;
END FakeUser;
/



--EXECUTE auto_acquista('Simo', 2, SYSDATE, '1000735724964861', TO_DATE('2022-05-31 20:00', 'yyyy-mm-dd hh24:mi'), TO_DATE('2022-05-31 21:30', 'yyyy-mm-dd hh24:mi'), 'Milano', 'Via santa', '20121', '01');
--EXECUTE auto_acquista('Simo', 1, SYSDATE, '1000735724964861', TO_DATE('2019-08-01 20:00', 'yyyy-mm-dd hh24:mi'), TO_DATE('2019-08-01 22:30', 'yyyy-mm-dd hh24:mi'), 'Genova', 'Via magazzini', '16128', '01');
--EXECUTE auto_acquista('Simo', 1, SYSDATE, '1000735724964861', TO_DATE('2022-07-06 16:50', 'yyyy-mm-dd hh24:mi'), TO_DATE('2022-07-06 18:30', 'yyyy-mm-dd hh24:mi'), 'Bologna', 'Viale europa', '40127', '03');

--EXECUTE FakeUser('Simo');
--SELECT fi.codice_film, avg(re.votoprotagonista),
--        avg(re.votoantagonista), avg(re.vototrama), avg(re.votocolonnasonora), avg(re.votoscenografia)
--        FROM Recensione re JOIN Film fi ON re.codice_film=fi.codice_film
--        JOIN Biglietto bi ON re.codice_biglietto=bi.codice_biglietto
--        JOIN Carrello ca ON bi.codice_carrello=ca.codice_carrello
--        WHERE ca.username='Simo'
--        GROUP BY fi.codice_film;

--SELECT * FROM MediaRecensione;
--select * from biglietto order by codice_carrello, codice_biglietto;
--insert into recensione values ('rec09', 10, 10, 10, 10, 10, TO_DATE('2022-05-31 20:00', 'yyyy-mm-dd hh24:mi'), 'ticket032', 'marvel002');




--PROCEDURA 7 Procedura che consente all'amministratore e allo scheduler di assegnare carte fedeltà agli utenti che rispettano determinate condizioni:
-- -l'utente deve essere maggiorenne
-- -l'utente deve essere sprovvisto di carta fedeltà, oppure possederne una scaduta
-- -l'utente deve aver acquistato almeno 20 biglietti nel corso dell'ultimo mese
-- -l'utente deve aver visto almeno 5 Film diversi l'uno dall'altro nel corso delle ultime tre settimane
-- -l'utente deve aver pubblicato almeno la metà delle recensioni possibili
CREATE OR REPLACE PROCEDURE Assegna_carta_fedelta
IS
    CURSOR Utenti IS
        SELECT * FROM Utente
        WHERE TO_NUMBER((SYSDATE - Data_di_nascita)/365.25)>17
        AND abilitato='V';
    
    utente_corrente Utenti%ROWTYPE;
    codice_fedelta_c CHAR(10);
    codice_fedelta_n NUMBER;
    conteggio NUMBER;
    conteggio_massimo NUMBER;
    utenti_assegnatari NUMBER := 0;
BEGIN
    OPEN Utenti;
    
    LOOP
        FETCH utenti INTO utente_corrente;
        EXIT WHEN utenti%NOTFOUND;
        
        --Se l'utente ha già una carta fedeltà abilitata, salta avanti
        SELECT COUNT(*) INTO conteggio FROM Carta_fedelta cf WHERE cf.Username=utente_corrente.Username AND cf.Data_scadenza>SYSDATE;
        IF conteggio = 1 THEN
            CONTINUE;
        END IF;
        
        --Verifica se l'utente ha acquistato almeno 20 biglietti nell'ultimo mese
        SELECT COUNT(*) INTO conteggio FROM Biglietto bi JOIN Carrello car ON bi.codice_carrello=car.codice_carrello
        WHERE car.username=utente_corrente.username AND car.data_pagamento >= add_months(SYSDATE, -1);
        IF conteggio < 20 THEN
            CONTINUE;
        END IF;
        
        --Verifica se l'utente ha visto almeno 5 film nel corso delle ultime tre settimane
        SELECT COUNT(DISTINCT spe.codice_film) INTO conteggio FROM Spettacolo spe JOIN Biglietto bi ON bi.ora_inizio_spettacolo=spe.ora_inizio AND bi.ora_fine_spettacolo=spe.ora_fine
        AND bi.nome_sala=spe.nome_sala AND bi.citta_cinema=spe.citta_cinema AND bi.cap_cinema=spe.cap_cinema AND bi.via_cinema=spe.via_cinema
        JOIN Carrello car ON car.codice_carrello=bi.codice_carrello
        WHERE car.username=utente_corrente.username AND bi.ora_inizio_spettacolo>TO_DATE(SYSDATE - 21);
        IF conteggio < 5 THEN
            CONTINUE;
        END IF;
        
        --Verifica se l'utente ha pubblicato almeno la metà delle recensioni pubblicabili (una recensione per film diverso in un carrello)
        SELECT COUNT(*) INTO conteggio_massimo FROM (SELECT DISTINCT bi.ora_inizio_spettacolo, bi.ora_fine_spettacolo, bi.nome_sala,
        bi.citta_cinema, bi.cap_cinema, bi.via_cinema, bi.codice_carrello FROM Biglietto bi JOIN Carrello car ON bi.codice_carrello=car.codice_carrello
        WHERE car.Username=utente_corrente.Username);
        SELECT COUNT(*) INTO conteggio FROM Recensione rec JOIN Biglietto bi ON rec.codice_biglietto=bi.codice_biglietto
        JOIN Carrello car ON car.codice_carrello=bi.codice_carrello WHERE car.username=utente_corrente.username;
        IF conteggio < conteggio_massimo/2 THEN
            CONTINUE;
        END IF;
        
        SELECT COUNT(*) INTO conteggio FROM Carta_fedelta cf WHERE cf.Username=utente_corrente.username;
        codice_fedelta_n := 0;
        IF conteggio > 0 THEN
            SELECT TO_NUMBER(cf.codice_carta_fedelta) INTO codice_fedelta_n FROM Carta_fedelta cf WHERE cf.Username=utente_corrente.Username;
        END IF;
        IF codice_fedelta_n = 0 THEN
            SELECT COUNT(*) INTO conteggio FROM Carta_fedelta;
            IF conteggio > 0 THEN
                SELECT codice_carta_fedelta INTO codice_fedelta_c FROM Carta_fedelta ORDER BY Codice_carta_fedelta DESC FETCH FIRST 1 ROWS ONLY;
                codice_fedelta_n := TO_NUMBER(codice_fedelta_c) + 1;
            ELSE
                codice_fedelta_n := 0;
            END IF;
            dbms_output.put_line('All''utente '''||TRIM(utente_corrente.username)||''' e'' stata creata una nuova carta fedelta'' con codice '''||TO_CHAR(codice_fedelta_n, 'fm0000000000')||'''.');
        ELSE
            dbms_output.put_line('All''utente '''||TRIM(utente_corrente.username)||''' e'' stata rinnovata la sua carta fedelta'' con codice '''||TO_CHAR(codice_fedelta_n, 'fm0000000000')||'''.');
        END IF;
        
        INSERT INTO carta_fedelta VALUES (TO_CHAR(codice_fedelta_n, 'fm0000000000'), add_months(SYSDATE, 12), SYSDATE, utente_corrente.username);
        
        utenti_assegnatari := utenti_assegnatari + 1;
    END LOOP;
    
    dbms_output.put_line('Da un totale di '||utenti%ROWCOUNT||' possibili utenti, '||utenti_assegnatari||' sono assegnatari di una carta fedeltà.');
    
    CLOSE Utenti;
END Assegna_carta_fedelta;
/


--PROCEDURA 8 RICHIAMATA SOLO DALL’ADMIN PER ASSEGNARE DUE BIGLIETTI OMAGGIO ALL’UTENTE CHE HA FATTO PIU’ ACQUISTI NELL’ULTIMO MESE.
CREATE OR REPLACE PROCEDURE cliente_del_mese 
IS 
 
carrello_premio char(10); 
citta_spettacolo varchar(20);
spettacolo_premio spettacolo%ROWTYPE;
posto_corrente posto%ROWTYPE;
utente_vincente char(10);
BEGIN  

select cr.codice_carrello into carrello_premio 
from (select count(bg.codice_biglietto) AS numero_biglietti, cr.codice_carrello   
        from  biglietto bg JOIN carrello cr ON bg.codice_carrello = cr.codice_carrello   
        where cr.data_pagamento IS NOT NULL AND cr.data_pagamento <= sysdate and cr.data_pagamento >= ADD_MONTHS(SYSDATE, -1)  
        group by cr.codice_carrello
        order by dbms_random.value ) cr 
where cr.numero_biglietti = (select max(numero_biglietti)  
                            from  (select count(bg.codice_biglietto) AS numero_biglietti, cr.codice_carrello   
                                     from  biglietto bg JOIN carrello cr ON bg.codice_carrello = cr.codice_carrello   
                                    where cr.data_pagamento IS NOT NULL AND cr.data_pagamento <= sysdate and cr.data_pagamento >= ADD_MONTHS(SYSDATE, -1)  
                                     group by cr.codice_carrello) cr )
and rownum = 1 ;
          
                    --DBMS_OUTPUT.PUT_LINE(carrello_premio); 
                    
                    select al.citta_cinema into citta_spettacolo
                    from (select bg.citta_cinema, bg.codice_carrello
                             from carrello cr JOIN biglietto bg ON cr.codice_carrello = bg.codice_carrello 
                            order By dbms_random.value ) al
                    WHERE rownum = 1 and al.codice_carrello = carrello_premio;
                    
                    -- DBMS_OUTPUT.PUT_LINE(citta_spettacolo); 
                    
                    select * into spettacolo_premio 
                    from (select * 
                          from spettacolo 
                          where citta_cinema = citta_spettacolo and ora_inizio > sysdate
                          order by dbms_random.value) al
                    where rownum = 1 ; 
                    
                     DBMS_OUTPUT.PUT_LINE(spettacolo_premio.ora_inizio); 
                    SELECT * INTO posto_corrente FROM Posto po
                WHERE po.nome_sala=spettacolo_premio.nome_sala AND po.citta_cinema=spettacolo_premio.citta_cinema AND po.cap_cinema=spettacolo_premio.CAP_cinema AND po.via_cinema=spettacolo_premio.via_cinema
                             AND NOT EXISTS (
                                    SELECT NULL FROM Biglietto bi
                                    WHERE bi.ora_inizio_spettacolo=spettacolo_premio.ora_inizio AND bi.ora_fine_spettacolo=spettacolo_premio.ora_fine AND
                                     bi.citta_cinema=spettacolo_premio.citta_cinema AND bi.via_cinema=spettacolo_premio.via_cinema AND bi.cap_cinema=spettacolo_premio.CAP_cinema AND bi.nome_sala=spettacolo_premio.nome_sala
                                    AND bi.fila_posto=po.fila AND bi.numero_posto=po.numero_posto
                                    )
                    ORDER BY po.Fila
                    FETCH FIRST 1 ROWS ONLY;
                    
                     --DBMS_OUTPUT.PUT_LINE(posto_corrente.numero_posto);
                     --DBMS_OUTPUT.PUT_LINE(posto_corrente.fila);
                     
                     select distinct (username ) into utente_vincente 
                     from carrello 
                     where codice_carrello = carrello_premio;
                     
                      DBMS_OUTPUT.PUT_LINE ('COMPLIMENTI UTENTE : '||utente_vincente||' SEI IL CLIENTE DEL MESE.');
                      DBMS_OUTPUT.PUT_LINE ('IN REGALO DUE BIGLIETTI PER LO SPETTACOLO DEL : '||spettacolo_premio.ora_inizio||' a '||spettacolo_premio.citta_cinema);
insert into biglietto values ('ticket'||(TO_CHAR (TRUNC(DBMS_RANDOM.value(100,900)))), 0, carrello_premio, spettacolo_premio.ora_inizio, spettacolo_premio.ora_fine , posto_corrente.fila, posto_corrente.numero_posto, spettacolo_premio.nome_sala, spettacolo_premio.citta_cinema, spettacolo_premio.via_cinema, spettacolo_premio.CAP_cinema);
 SELECT * INTO posto_corrente FROM Posto po
                WHERE po.nome_sala=spettacolo_premio.nome_sala AND po.citta_cinema=spettacolo_premio.citta_cinema AND po.cap_cinema=spettacolo_premio.CAP_cinema AND po.via_cinema=spettacolo_premio.via_cinema
                             AND NOT EXISTS (
                                    SELECT NULL FROM Biglietto bi
                                    WHERE bi.ora_inizio_spettacolo=spettacolo_premio.ora_inizio AND bi.ora_fine_spettacolo=spettacolo_premio.ora_fine AND
                                     bi.citta_cinema=spettacolo_premio.citta_cinema AND bi.via_cinema=spettacolo_premio.via_cinema AND bi.cap_cinema=spettacolo_premio.CAP_cinema AND bi.nome_sala=spettacolo_premio.nome_sala
                                    AND bi.fila_posto=po.fila AND bi.numero_posto=po.numero_posto
                                    )
                    ORDER BY po.Fila
                    FETCH FIRST 1 ROWS ONLY;
insert into biglietto values ('ticket'||(TO_CHAR (TRUNC(DBMS_RANDOM.value(100,900)))), 0, carrello_premio, spettacolo_premio.ora_inizio, spettacolo_premio.ora_fine , posto_corrente.fila, posto_corrente.numero_posto, spettacolo_premio.nome_sala, spettacolo_premio.citta_cinema, spettacolo_premio.via_cinema, spettacolo_premio.CAP_cinema);
                      
             
end;
/


