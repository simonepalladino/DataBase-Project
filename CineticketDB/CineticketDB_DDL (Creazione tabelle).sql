create table Utente (
    Username char(10) constraint utente_pk primary key,
    Nome varchar(20) not null,
    Cognome varchar(20) not null,
    Sesso char(1) check (Sesso IN ('M','F')),  
    Data_di_nascita date,
    Luogo_di_nascita varchar(20),
    abilitato char(1) default 'V' check (abilitato IN ('V','F'))
);
 

create table Carta_fedelta ( 
    Codice_carta_fedelta char(10) constraint carta_fedelta_pk primary key, 
    Data_scadenza date, 
    Data_rinnovo date, 
    Username char(10) not null, 
    CONSTRAINT fk_Carta_fedelta_username FOREIGN KEY (USERNAME) REFERENCES UTENTE(USERNAME) ON DELETE CASCADE,
    CONSTRAINT uq_carta_fedelta_username UNIQUE (Username)
);


create table Promozione (
    Codice_promozione char(10) constraint promozione_pk primary key,
    Nome_promozione varchar(20),
    Data_inizio_promozione date not null,
    Data_fine_promozione date not null
);
 

create table Promozione_fedelta (
    Codice_carta_fedelta char(10),
    Codice_promozione char(10),
    constraint promozione_fedelta_pk primary key (Codice_carta_fedelta, Codice_promozione),
    constraint fk_promozionefedelta_codicecartafedelta foreign key (codice_carta_fedelta) references Carta_fedelta(codice_carta_fedelta) on delete cascade,
constraint fk_promozionefedelta_codicepromozione foreign key (codice_promozione) references Promozione(codice_promozione) on delete cascade
);
 
 
create table Carta_di_credito (
    Numero_carta varchar(16) constraint cartadicredito_pk primary key,
    Data_scadenza date not null, 
    CVV char(3) not null
);
 

create table Carrello ( 
    Codice_carrello char(10) constraint carrello_pk primary key, 
    Data_inserimento date not null, 
    Data_pagamento date, 
    Username char(10) not null, 
    Numero_carta varchar(16) not null,
    Codice_promozione char(10),
    constraint fk_carrello_username foreign key (Username) references utente(username),
    constraint fk_carrello_numerocarta foreign key (numero_carta) references carta_di_credito(numero_carta),
    constraint fk_carrello_codicepromozione foreign key (codice_promozione) references promozione(codice_promozione)
);
 

create table Biglietto (
    Codice_biglietto char(10) constraint biglietto_pk primary key,
    Prezzo number,
    Codice_carrello char(10) not null,
    Ora_inizio_spettacolo date not null,
    Ora_fine_spettacolo date not null,
    Fila_posto char(1) not null,
    Numero_posto number not null,
    Nome_sala char(2) not null,
    Citta_cinema varchar(20) not null,
    Via_cinema varchar(50) not null,
    CAP_cinema char(5) not null
);
 

create table Spettacolo (
    Ora_inizio date,
    Ora_fine date,
    Lingua varchar(20),
    Codice_film char(10),
    Nome_sala char(2),
    Citta_cinema varchar(20),
    Via_cinema varchar(50),
    CAP_cinema char(5),
    constraint spettacolo_pk primary key (Ora_inizio, Ora_fine, Nome_sala, Citta_cinema, Via_cinema, CAP_cinema)
);


alter table Biglietto add constraint fk_biglietto_spettacolo foreign key (Ora_inizio_spettacolo, Ora_fine_spettacolo,Nome_sala,Citta_cinema,via_cinema,CAP_cinema) references Spettacolo(Ora_inizio,Ora_fine,Nome_sala,Citta_cinema,via_cinema,CAP_cinema);


create table Cinema (
    Citta varchar(20),
    Via varchar(50),
    CAP char(5),
    Nome_cinema varchar(50) not null,
    constraint cinema_pk primary key (Citta, Via, CAP)
);
 

create table Sala (
    Nome_sala char(2),
    Citta_cinema varchar(20),
    Via_cinema varchar(50),
    CAP_cinema char(5),
    Tipo_sala varchar(10) not null,
    Massima_capienza number not null,
    constraint sala_pk primary key (Nome_sala, Citta_cinema, Via_cinema, CAP_cinema),
    constraint fk_sala_indirizzocinema foreign key (Citta_cinema, Via_cinema, CAP_cinema) references Cinema(Citta, Via, CAP)
);
 

alter table Spettacolo add constraint fk_spettacolo_sala foreign key (Citta_cinema, Via_cinema, CAP_cinema, Nome_sala) references Sala(Citta_cinema, Via_cinema, CAP_cinema, Nome_sala);
 
 
create table Posto (
    Fila char(1),
    Numero_posto number,
    Nome_sala char(2),
    Citta_cinema varchar(20),
    Via_cinema varchar(50),
    CAP_cinema char(5),
    constraint posto_pk primary key (Fila, Numero_posto, Nome_sala, Citta_cinema, Via_cinema, CAP_cinema),
    constraint fk_posto foreign key (Nome_sala, Citta_cinema, Via_cinema, CAP_cinema) references Sala(Nome_sala, Citta_cinema, Via_cinema, CAP_cinema)
);
 

alter table Biglietto add constraint fk_biglietto_posto foreign key (Fila_posto, Numero_posto, Nome_sala, Citta_cinema, Via_cinema, CAP_cinema) references Posto(Fila, Numero_posto, Nome_sala, Citta_cinema, Via_cinema, CAP_cinema);
 
 
create table Compagnia_di_produzione (
    Nome_compagnia varchar(20) constraint compagnia_di_produzione_pk primary key,
    Citta varchar(20) not null
);
 
 
create table Genere (
    ID_genere char(3) constraint genere_pk primary key,
    Genere varchar(40) not null
);
 

create table Film (
    Codice_film char(10) constraint film_pk primary key,
    Titolo varchar(50) not null,
    Durata number not null,
    Anno_di_produzione number not null,
    Nome_compagnia varchar(20) not null,
    Classificazione number,
    constraint fk_film_nomecompagnia foreign key (nome_compagnia) references Compagnia_di_produzione(nome_compagnia)
);
 

alter table Spettacolo add constraint fk_spettacolo_codicefilm foreign key (Codice_film) references Film(Codice_film);
 
 
create table Genere_film (
    ID_genere char(3),
    ID_film char(10),
    constraint generefilm_pk primary key (id_genere, id_film),
    constraint fk_generefilm_idfilm foreign key (id_film) references Film(codice_film) on delete cascade,
    constraint fk_generefilm_idgenere foreign key (id_genere) references Genere(id_genere) on delete cascade
);
 
 
create table Recensione (
    ID_recensione char(5) constraint recensione_pk primary key,
    VotoProtagonista number not null, CHECK (VotoProtagonista<=10),
    VotoAntagonista number not null, CHECK (VotoAntagonista<=10),
    VotoTrama number not null, CHECK (VotoTrama<=10),
    VotoColonnaSonora number not null, CHECK (VotoColonnaSonora<=10),
    VotoScenografia number not null, CHECK (VotoScenografia<=10),
    Data_pubblicazione date not null,
    Codice_biglietto char(10) not null,
    Codice_film char(10),
    constraint fk_recensione_codicebiglietto foreign key (codice_biglietto) references Biglietto(codice_biglietto) on delete cascade,
    constraint fk_recensione_codicefilm foreign key (codice_film) references Film(codice_film) on delete cascade,
    constraint uq_recensione UNIQUE (codice_biglietto, codice_film)
);
 
 
create table Professionista (
    Codice_professionista char(5) constraint professionista_pk primary key,
    Nome varchar(40) not null,
    Data_di_nascita date
);


create table Diretto_da (
    Codice_film char(10),
    Codice_professionista char(5),
    constraint diretto_da_pk primary key (Codice_film, Codice_professionista),
    constraint fk_direttoda_codicefilm foreign key (codice_film) references Film(codice_film) on delete cascade,
    constraint fk_direttoda_codiceprofessionista foreign key (codice_professionista) references Professionista(codice_professionista) on delete cascade
);
 
 
create table Recitato_da (
    Codice_film char(10),
    Codice_professionista char(5),
    Nome_ruolo varchar(40) not null,
    constraint recitato_da_pk primary key (Codice_film, Codice_professionista),
    constraint fk_recitatoda_codicefilm foreign key (codice_film) references Film(codice_film) on delete cascade,
    constraint fk_recitatoda_codiceprofessionista foreign key (codice_professionista) references Professionista(codice_professionista) on delete cascade
);
