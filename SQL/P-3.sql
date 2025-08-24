-- ficha 4 BD


--1
    select count(*)
    from
        ((select escola
         from escolas )
        minus
        ( select escola
        from candidatos))
    ;
    
    -- ou 
    
    select count(*)
    from escolas
    where escola not in (select escola from candidatos)
    ;
    
    -- ou 
    
    select count (*)
    from escolas left join candidatos using (escola)
    where idcandidato is null
    ;
    
    -- ou 
    
    with todas as 
        (select count(*) t
        from escolas),
    temcandidatos as
        (select count (distinct escola) n
        from candidatos)
    select t - n 
    from todas, temcandidatos;

--2
    select nomeescola, n_cand
    from (select escola, count(idcandidato) n_cand
         from candidatos
         group by escola) 
         inner join escolas using (escola)
    order by n_cand desc;

--3
    select nomeEscola, n_cand
    from escolas 
        left join   (select escola, count(Idcandidato) n_cand 
                    from candidatos 
                    group by escola) 
        using (escola)
    order by n_cand desc nulls last;
         
         
         
    





    
    
    