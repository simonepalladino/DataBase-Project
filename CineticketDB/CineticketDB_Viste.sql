--Viste 1 visualizza tutte le sale IMAX e 3D dei cinema
CREATE OR REPLACE VIEW SalaIMAX3D AS
select * from cinema ci join sala sa on (ci.Citta = sa.Citta_cinema and ci.Via = sa.Via_cinema and ci.CAP = sa.CAP_cinema) WHERE Tipo_sala = 'IMAX' or Tipo_sala = '3D';
 
 
--Viste 2 visualizza la media dei voti delle recensioni
CREATE OR REPLACE VIEW MediaRecensione AS
select fi.codice_film, fi.titolo, avg(re.votoprotagonista) as protagonista, avg(re.votoantagonista) as antagonista,
avg(re.vototrama) as trama, avg(re.votocolonnasonora) as colonna, avg(re.votoscenografia) as scenografia
from recensione re join film fi on re.codice_film=fi.codice_film
group by fi.codice_film, fi.titolo
order by fi.titolo;
 
 
--Viste 3 visualizza tutti i film in cui il professionista è sia il regista che l’attore
CREATE OR REPLACE VIEW RegistaAttore AS
select pro.nome AS Nome_professionista, re.nome_ruolo AS Personaggio, pro.codice_professionista  from professionista pro
join diretto_da di on pro.codice_professionista = di.codice_professionista
join recitato_da re on pro.codice_professionista = re.codice_professionista
order by re.nome_ruolo;
 
--Viste 4 visualizza i film (con i suoi multipli generi)
CREATE OR REPLACE VIEW VistaFilm AS
SELECT Codice_film, Titolo, LISTAGG(ge.genere, ',') WITHIN GROUP (ORDER BY genere) AS Genere
FROM Film fi JOIN genere_film gf ON fi.codice_film=gf.id_film
JOIN genere ge ON ge.id_genere=gf.id_genere
GROUP BY Codice_film, Titolo;
 
 
--Viste 5 visualizza tutti gli spettacoli 
CREATE OR REPLACE VIEW Orari_spettacoli AS
SELECT fi.titolo, fi.genere,to_char(spe.ora_inizio, 'hh24:mi') as Ora_inizio, to_char(spe.ora_fine, 'hh24:mi') as Ora_fine
FROM VistaFilm fi JOIN Spettacolo spe ON fi.codice_film=spe.codice_film
ORDER BY fi.titolo;
 
 
 
 
 
