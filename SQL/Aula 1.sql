-- comentario em linha
/* comentario em bloco */   
alter session set current_schema = candidaturas;

select * from candidatos;

--1
select Nome,Mediasec from candidatos;

--2
select count(*) n_candidatos from candidatos;

 --3
select avg(mediasec)/10 media from candidatos;
 
 --4
select count(distinct(Escola)) from candidatos;

--5
select Sexo,count(*) from candidatos group by sexo;

--6 
select count(distinct(idcandidato)) from alunosexames where fase = '2';

--7
select count(curso), sum(vagas) from Ofertas where estab = '0903';

--8
(select idCandidato from candidaturas where estab = '0902')
intersect
(select idCandidato from candidaturas where estab = '0903');

--9
select max(notacand) cand_max_FCT from candidaturas where estab = '0903';

--10
(select IDcandidato from candidatos)
minus
(select IDCANDIDATO from colocacoes);

--11
select nome, nomeEscola from candidatos inner join escolas using(escola);
/* ou */
select nome, nomeEscola from candidatos inner join escolas on(candidatos.escola = escolas.escola);
/* ou */
select nome, nomeEscola from candidatos,escolas where candidatos.escola = escolas.escola;

--12
select nome, nomeEscola, descrConcelho
from candidatos inner join escolas using(escola, distrito, concelho) 
                inner join concelhos using (distrito, concelho);








