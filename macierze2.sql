DECLARE
    index_sub int := 0;
    index_ve int := 0;    
    index_answear int := 0; -- index do pojemnika, ktory bedzie przechowywal nam indexy pojemnikow, w kotrych znajduja sie nasze graflety(poprostu 3 wierzcholki)
    rc sys_refcursor;
    
    wynik_w1 int := 0;
    wynik_w2 int := 0;
    wynik_w3 int := 0;
    typ int := 0;
    
BEGIN

    DELETE FROM HELP;
    DELETE FROM WYNIK;

    index_answear := nr_indexuf();
    INSERT INTO help VALUES(index_answear, null);
    
   FOR i IN (SELECT row_m from macierz group by row_m) LOOP
    index_ve := N(i.row_m,i.row_m, -1);
    
    index_sub := nr_indexuf();
    INSERT INTO help VALUES(index_sub, i.row_m);
    
    
    find_graflet(index_sub, index_ve, index_answear, i.row_m);
   END LOOP;
   
   
   FOR i IN (SELECT * FROM help where index_help = index_answear and nr_wierzcholka is not null) LOOP
        
        SELECT max(nr_wierzcholka) INTO wynik_w1 FROM help where index_help = i.nr_wierzcholka;
        SELECT min(nr_wierzcholka) INTO wynik_w3 FROM help where index_help = i.nr_wierzcholka;
        SELECT max(nr_wierzcholka) INTO wynik_w2 FROM help where index_help = i.nr_wierzcholka and nr_wierzcholka != wynik_w1 and nr_wierzcholka != wynik_w3;
        
        typ:= 0;
        typ:= JAKI_TYP(wynik_w1,wynik_w2, wynik_w3);
        
        INSERT INTO WYNIK VALUES(wynik_w1,wynik_w2, wynik_w3, typ);
    
   END LOOP;
   
    open rc for select DISTINCT * from wynik order by w1;
    dbms_sql.return_result(rc);
   
END;



--FUNCKJE
CREATE OR REPLACE PROCEDURE FIND_GRAFLET(index_sub int, index_e int, index_answear int, nr_wierzcholka int)
AS
    ilosc_sub int;
    ilosc_e int;
    wyrzucony_wierzcholek int;
    index_new_e int;
    index_new_sub int;
BEGIN
     SELECT COUNT(*) INTO ilosc_sub FROM help where index_help = index_sub;
 
    dbms_output.put_line(nr_wierzcholka || '-> s:' || index_sub || ', e: ' || index_e);
 
    IF ilosc_sub = 3 THEN
        dbms_output.put_line('akuku');
        INSERT INTO HELP VALUES(index_answear, index_sub);
        
    ELSE
        SELECT COUNT(*) INTO ilosc_e FROM help where index_help = index_e and nr_wierzcholka is not null;
         
        WHILE (ilosc_e > 0)
        LOOP
        
            SELECT min(nr_wierzcholka) INTO wyrzucony_wierzcholek from help where index_help = index_e;
            DELETE FROM HELP where (index_help = index_e and nr_wierzcholka = wyrzucony_wierzcholek);
    
            index_new_e := N_EXTENDED(wyrzucony_wierzcholek, index_sub,index_e, nr_wierzcholka);
            
            
            index_new_sub := NR_INDEXUF();
            INSERT INTO HELP(index_help, nr_wierzcholka) (SELECT index_new_sub, nr_wierzcholka from help where index_help = index_sub);
            INSERT INTO HELP VALUES(index_new_sub, wyrzucony_wierzcholek);
        
            FIND_GRAFLET(index_new_sub, index_new_e, index_answear, nr_wierzcholka);
           
            SELECT COUNT(*) INTO ilosc_e FROM help where index_help = index_e and nr_wierzcholka is not null;
        END LOOP;
    END IF;
    
END;


CREATE OR REPLACE FUNCTION N_EXTENDED(vi int, index_sub int, index_e int, aktualny_wierzcholek int)
RETURN int AS
    index_N_vi int;
    index_N_sub int;
    index_return int;
BEGIN
    
    index_N_vi := N(vi, aktualny_wierzcholek, -1);
    index_N_sub := N_FOR_GROUP(index_sub, aktualny_wierzcholek);
    
    index_return := NR_INDEXUF(); 
    INSERT INTO HELP VALUES(index_return, null);
    INSERT INTO HELP(index_help, nr_wierzcholka) (SELECT index_return, nr_wierzcholka from help where index_help = index_e UNION((SELECT DISTINCT index_return, nr_wierzcholka from help where index_help = index_N_vi) EXCEPT (SELECT index_return, nr_wierzcholka from help where index_help = index_sub or index_help = index_N_sub)));
  
    return index_return;  
END;

CREATE OR REPLACE FUNCTION N_FOR_GROUP(index_group int, aktualny_wierzcholek int)
RETURN int AS
    nr int;
BEGIN
    nr := -1;
    
    FOR i IN (SELECT * from help where index_help = index_group) LOOP
        nr := N(i.nr_wierzcholka, aktualny_wierzcholek, nr);
    END LOOP;

    return nr;
END;

CREATE OR REPLACE FUNCTION N(vi int, akutalny_wierzcholek int, index_wpisu int)
RETURN int AS
    nr_wierzcholka_do_wstawienia int:= 0;
    nr int:=0;
    ilosc int:=0;
BEGIN

    IF index_wpisu = -1 THEN
        nr := NR_INDEXUF();
        INSERT INTO HELP VALUES(nr, null);
    ELSE
        nr := index_wpisu;
    END IF;
    
    FOR i IN ((SELECT col_m from macierz where row_m=vi and value_m > 0 and row_m != col_m) UNION (SELECT row_m from macierz where value_m >0 and row_m != col_m and col_m=vi))
    LOOP
       
        ilosc := 0;
        SELECT COUNT(*) INTO ilosc from help where index_help = nr and nr_wierzcholka = i.col_m;
       
        IF ilosc = 0 THEN
          
            nr_wierzcholka_do_wstawienia := i.col_m;
            
            INSERT INTO HELP VALUES(nr, nr_wierzcholka_do_wstawienia);
          
        END IF;
    
    END LOOP;
   
    return nr;
END;







CREATE OR REPLACE FUNCTION NR_INDEXUF
RETURN int AS
   ilosc int := 0;
  nr int := 0;
BEGIN
    
    SELECT COUNT(*) INTO ilosc FROM help;
    
     IF ilosc = 0 THEN
        nr := 1;
    ELSE
        SELECT MAX(index_help) INTO nr FROM help;
        nr := nr+1;
    END IF;
    
    return nr;
    
END;


CREATE OR REPLACE FUNCTION JAKI_TYP(w1 int, w2 int, w3 int)
RETURN int AS
    wynik1 int :=0;
    wynik2 int :=0;
    wynik3 int :=0;
    wynik4 int :=0;
    wynik5 int :=0;
    wynik6 int :=0;
    typ_g int:=0;
BEGIN
    
    wynik1 := JAKI_TYP_WYNIK(w1, w2, w3);
    wynik2 := JAKI_TYP_WYNIK(w1, w3, w2);
    
    wynik3 := JAKI_TYP_WYNIK(w2, w1, w3);
    wynik4 := JAKI_TYP_WYNIK(w2, w3, w1);
    
    wynik5 := JAKI_TYP_WYNIK(w3, w1, w2);
    wynik6 := JAKI_TYP_WYNIK(w3, w2, w1);
    
    SELECT nr_typu into typ_g from typy where wynik1 = suma or wynik2 = suma or wynik3 = suma or wynik4 = suma or wynik5 = suma or wynik6 = suma;
    
    return typ_g;
END;

CREATE OR REPLACE FUNCTION JAKI_TYP_WYNIK(w1 int, w2 int, w3 int)
RETURN int AS
    ab int :=0;
    ac int :=0;
    ba int :=0;
    bc int :=0;
    ca int :=0;
    cb int :=0;
    wynik int :=0;
BEGIN
    
    SELECT value_m INTO ab from macierz where row_m = w1 and col_m = w2;
    SELECT value_m INTO ac from macierz where row_m = w1 and col_m = w3;
    
    SELECT value_m INTO ba from macierz where row_m = w2 and col_m = w1;
    SELECT value_m INTO bc from macierz where row_m = w2 and col_m = w3;
    
    SELECT value_m INTO ca from macierz where row_m = w3 and col_m = w1;
    SELECT value_m INTO cb from macierz where row_m = w3 and col_m = w2;
    
    wynik := 32 * ab + 16 * ac + 8 * ba + 4 * bc + 2 * ca + cb;
    
    return wynik;
    
END;