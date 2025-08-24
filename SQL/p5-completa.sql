drop table colocados cascade constraints;
drop table matriculas cascade constraints;
drop table cursos cascade constraints;
drop table cadeiras cascade constraints;
drop table planos cascade constraints;
drop table inscricoes cascade constraints;

create table colocados(
  idCandidato number(11,0),
  nome varchar2(30),
  curso varchar2(4),
  ano number(4,0)
);

create table matriculas(
  numero number(6,0),
  idCandidato number(11,0),
  curso varchar2(4),
  dataMatr date
);

create table cursos(
  curso varchar2(4),
  nomeCurso varchar2(255)
);

create table cadeiras(
  cadeira number(5,0),
  nomeCad varchar2(200),
  ects number(2,0)
);

create table planos(
  cadeira number(5,0),
  curso varchar2(4),
  semestre number(2,0)
);

create table inscricoes(
  numero number(6,0),
  curso varchar2(4),
  cadeira number(5,0),
  anoLetivo number(4,0),
  dataInscr date
);

-- 1.2

-- Chaves primárias
alter table colocados add constraint pk_col primary key(idCandidato);
alter table matriculas add constraint pk_mat primary key(numero);
alter table cursos add constraint pk_cur primary key(curso);
alter table cadeiras add constraint pk_cad primary key(cadeira);
alter table planos add constraint pk_pla primary key(cadeira,curso);
alter table inscricoes add constraint pk_ins primary key(numero,cadeira,anoLetivo);

-- Chaves candidatas e estrangeiras
alter table colocados add constraint fk_colcurso foreign key (curso) references cursos(curso);

alter table matriculas add constraint un_mat unique(idCandidato);

-- ***** Trabalho *****
-- Tente adicionar a fk que (idCandidato,curso) em matriculas existe assim em colocados 
-- (para evitar alunos matriculados em cursos em que não foram colocados)
alter table matriculas add constraint fk_matrcolcurso foreign key (idCandidato,curso) references colocados(idCandidato,curso);

-- Não funcionou, certo? Antes de referir a fk em matriculas é preciso indicar o unique em colocados

-- ***** Adicione primeiro uma restrição chamada un_col que assegura que (idCandidato,curso) é único na tabela colocados

alter table colocados add constraint un_col unique(idCandidato,curso);

-- Tente então colocar a fk em matriculas agora
alter table matriculas add constraint fk_matrcolcurso foreign key (idCandidato,curso) references colocados(idCandidato,curso);

alter table planos add constraint fk_pcur foreign key (curso) references cursos(curso);
alter table planos add constraint fk_pcad foreign key (cadeira) references cadeiras(cadeira);

alter table matriculas add constraint un_matnumcur unique(numero,curso);
alter table inscricoes add constraint fk_inscurso foreign key (numero,curso) references matriculas(numero,curso);
alter table inscricoes add constraint fk_insplano foreign key (curso,cadeira) references planos(curso,cadeira);


-- Outras restricoes
-- ***** Trabalho ***** 
-- adicione uma restrição chamada numCred que verifica (em cadeiras) que o número de ects é entre 3 e 60
alter table cadeiras add constraint numCred check(ects >= 3 and ects <=60);


-- 1.3


-- Criação prévia de sinónimos

create or replace synonym candidatos for candidaturas.candidatos;
create or replace synonym colocacoes for candidaturas.colocacoes;


-- Inserir os dados a partir de candidaturas
insert into cursos
  select curso, nomeCurso
  from candidaturas.cursos natural join candidaturas.ofertas
  where estab = '0903';
  commit;

insert into colocados
  select idCandidato, nome, curso, 2021
  from candidatos inner join colocacoes using (idCandidato)
  where estab = '0903';
  commit;
  
 
-- 1.4
-- É só correr o ficheiro insereCadeiras.sql

-- 1.5
create sequence seq_num_aluno
start with 60000
increment by 1;

-- 1.6
insert into matriculas values (seq_num_aluno.nextval,112214,'9119',to_date('2021.09.10','YYYY.MM.DD'));
insert into matriculas values (seq_num_aluno.nextval,112361,'9209',to_date('2021.09.10','YYYY.MM.DD'));
insert into matriculas values (seq_num_aluno.nextval,112361,'9119',to_date('2021.09.10','YYYY.MM.DD'));
commit;

-- ***** Trabalho ***** 
-- Insere outro aluno a sua escolha em matriculas (o exemplo em baixo é um aluno colocado em Matemática)  
insert into matriculas values (seq_num_aluno.nextval,143146,'9209',to_date('2021.09.10','YYYY.MM.DD'));
commit;

-- Já agora, ver quem ficou matriculado.
select numero, nome, nomeCurso, dataMatr
from matriculas natural join colocados natural join cursos;


-- 2.1
create or replace trigger inscreve_novo_aluno
	after insert on matriculas
	for each row
	begin
		insert into inscricoes 
      select :new.numero, curso, cadeira, to_number(extract(year from :new.dataMatr)), :new.dataMatr
      from planos
      where curso = :new.curso and semestre = 1;
  end;
/

-- 2.2
-- ***** Trabalho *****
-- Vamos testar matriculando o aluno 72111 (ou outro/a a sua escolha) na Informática 
insert into matriculas values (seq_num_aluno.nextval,72111,'9119',to_date('2021.09.10','YYYY.MM.DD'));
commit;

-- Vejamos então o que está nas matrículas e nas inscrições
select * from matriculas;
select * from inscricoes natural join cadeiras;
-- Se correu bem o novo aluno deve aparecer com as quatro cadeiras do primeiro ano da Informática.


-- 3.1
-- Ajuda começar por ter uma view que a cada momento diz o nº de creditos a que cada aluno
-- está inscrito em cada ano 
create or replace view totalCred as
    select numero, anoLetivo, sum(ects) as total
    from inscricoes I natural join cadeiras
    group by numero, anoLetivo;

select * from totalCred;

-- Agora vamos adicionar um trigger que depois de cada inserção em inscricoes
-- verifica se não há nenhum aluno que ficou com mais de 72 créditos
create or replace trigger verifica_limite
  after insert on inscricoes
  declare NumECTS number;
  begin
    select max(total) into NumECTS from totalCred;
    if (NumECTS >  72)
      then Raise_Application_Error (-20100, 'Atingiu o limite de créditos. Inscrição não aceite!');
    end if;
  end;
/





---------------------------------------------------------------------------------------------------------


-- 3.2
-- ***** Trabalho *****
-- Vamos inscrever o aluno nº60004 (atenção este número pode variar e deve adapta-lo se necessário 
-- no seu caso ) a umas quantas cadeiras mais
-- No seu caso escolha um aluno com o nº que foi matriculado no exercício 2.2

-- Comecemos por tentar inscrevê-lo a uma cadeira que não é do seu curso
-- Por exemplo, tentemos dizer que ele é de Matemática e se quer inscrever a Álgebra 1
insert into inscricoes values (60004, '9209', 10970, 2021, to_date('2021.09.10','YYYY.MM.DD'));
commit;

-- Falhou, certo? Diz que o curso está mal...

-- Agora vamos inscrevê-lo como aluno de Informática, mas nessa cadeira
insert into inscricoes values (60004, '9119', 10970, 2021, to_date('2021.09.10','YYYY.MM.DD'));
commit;

-- Voltou a falhar, certo? Agora diz que o plano está mal...

-- Vamos então inscrevê-lo a cadeiras do curso dele
insert into inscricoes values (60004, '9119', 10640, 2021, to_date('2021.09.10','YYYY.MM.DD'));
insert into inscricoes values (60004, '9119', 11152, 2021, to_date('2021.09.10','YYYY.MM.DD'));
insert into inscricoes values (60004, '9119', 11153, 2021, to_date('2021.09.10','YYYY.MM.DD'));
insert into inscricoes values (60004, '9119', 11154, 2021, to_date('2021.09.10','YYYY.MM.DD'));
insert into inscricoes values (60004, '9119', 7996, 2021, to_date('2021.09.10','YYYY.MM.DD'));
commit;

-- So far so good...
-- Vejamos a quantos créditos já está inscrito em 2021
select sum(ects)
from inscricoes natural join cadeiras
where anoLetivo = 2021 and numero = 60004;

-- Esse aluno já deve ter 69 créditos (se no seu caso ainda não tiver, inscreva-o a mais umas quantas cadeiras).
-- Se agora o tentarmos inscrever a mais uma cadeira de 6 créditos a coisa não deve funcionar
insert into inscricoes values (60004, '9119', 7336, 2021, to_date('2021.09.10','YYYY.MM.DD'));
commit;

-- E cá está! Deu erro e não o inscreveu!
select sum(ects)
from inscricoes natural join cadeiras
where anoLetivo = 2021 and numero = 60004;

-- Se agora o desinscrevermos à cadeira 7996, depois já o conseguimos inscrever à 7336
delete from inscricoes where cadeira = 7996;
insert into inscricoes values (60004, '9119', 7336, 2021, to_date('2021.09.10','YYYY.MM.DD'));
commit;
select * from inscricoes natural join cadeiras;

-- Para a coisa ficar mesmo "à prova de bala", também há que fazer a verificação  quando se mudam os
-- créditos de uma cadeira,  e quando se muda uma inscricao.
-- Mas é tudo muito igual
create or replace trigger verifica_limite_credCadeira
  after update of ects on cadeiras
  declare NumECTS number;
  begin
    select max(total) into NumECTS from totalCred;
    if (NumECTS >  72)
      then Raise_Application_Error (-20100, 'Atingiu o limite de créditos. Inscrição não aceite!');
    end if;
  end;
/

-- ***** Trabalho *****
-- crie uma trigger semelhante para verificar quando  se muda uma inscrição

create or replace trigger verifica_limite_muda_ins
  after update on inscricoes
  declare NumECTS number;
  begin
    select max(total) into NumECTS from totalCred;
    if (NumECTS >  72)
      then Raise_Application_Error (-20100, 'Atingiu o limite de créditos. Inscrição não aceite!');
    end if;
  end;
/

---------------------------------------------------------------------------------------------------------------


-- 4.1
-- ***** Trabalho *****
-- corra os seguintes comandos individualmente, vai haver um erro - tente perceber porque e como ajustar.
alter table colocados drop constraint pk_col;
alter table colocados drop constraint un_col;
alter table colocados add constraint pk_col primary key (idCandidato, ano);
alter table matriculas drop constraint fk_matrcolcurso;

-- Nota: com isto o esquema deixa de estar normalizado!
-- Repare que idCandidato -> Nome 
-- Antes isso não tinha problema pois idCandidato era chave. Mas agora deixa de ser!
-- Haveria que decompor a tabela de colocações em duas:
-- nomesColocados(idCandidato, Nome)
-- colocados(idCandidato, curso, ano).


-- Vamos então adicionar algumas colocações, agora para Matemática, para o aluno que já tinha inscrições

-- ***** Trabalho *****
-- insere em colocados o aluno que inscreveu na 2.2 primeiro no ano 2021
insert into colocados values (72111,'AFONSO M. L.','9209',2021);
commit;
-- Dá erro, pois no mesmo ano não pode ser!
-- Mas em 2022 já deve dar...
insert into colocados values (72111,'AFONSO M. L.','9209',2022);
commit;

-----------------------------------------------------------------------------------------------------------------------------
-- 4.2

alter table matriculas add ano number(4,0);
update matriculas set ano = 2021;

alter table matriculas drop constraint un_mat;
alter table matriculas add constraint un_mat unique(idCandidato, ano);

alter table colocados add constraint un_col unique(idCandidato,curso,ano);
alter table matriculas add constraint fk_matrcolcurso foreign key (idCandidato,curso,ano) references colocados(idCandidato,curso,ano);

--4.3

create table inativas (
  numero number(6,0),
  curso varchar2(4)
  );
  
-- ***** Trabalho *****
-- corra os seguintes comandos individualmente, vai haver um erro - tente perceber porque e como ajustar. 
alter table inativas add constraint pk_ina primary key (numero, curso);
alter table matriculas add constraint uni_num_cur unique (numero, curso);
alter table inativas add constraint fk_ina foreign key (numero, curso) references matriculas(numero, curso);

-- 4.4
create or replace trigger muda_curso
  before insert on matriculas
  for each row
  declare Existe number;
  begin
    select count(*) into Existe 
    from matriculas where idCandidato = :new.idcandidato;
    if Existe > 0
      then
        insert into inativas 
          select numero, curso
          from matriculas
          where idCandidato = :new.idcandidato;
    end if;
  end;
/


-- 4.5
-- ***** Trabalho *****
-- insere em colocados o aluno que inscreveu na 2.2 primeiro no ano 2021
-- Tentemos então matricular o aluno que matriculou na 2.2. (em 2021 na Informática) em 2022 no curso de Matemática
insert into matriculas values (seq_num_aluno.nextval,72111,'9209',to_date('2022.09.10','YYYY.MM.DD'),2022);
commit;

-- Podemos verificar que ficou matriculado
select * from matriculas;

-- que a sua anterior matrícula ficou inativa  
select * from inativas;

-- e que em 2022 está inscrito a todas as cadeiras do primeiro ano de Matemática 
-- mantendo-se as suas inscrições em 2021 em Informática
select * from inscricoes natural join cadeiras;

-- 4.6
-- ***** Trabalho *****
-- crie uma trigger impede_matr_ant para impedir inserções e alterações em inscrições 
-- para cursos em que o aluno já não está inscrito
create or replace trigger impede_matr_ant
  before insert or update on inscricoes
  for each row
  declare Existe number;
  begin
    select count(*) into Existe 
    from inativas
    where numero = :new.numero and curso = :new.curso;
    if Existe > 0
      then Raise_Application_Error (-20100, 'O aluno já não está nesse curso. Inscrição não aceite!');
    end if;
  end;
/





-- Tentemos inscrever o aluno que mudou de curso (no meu caso é o 60005, mas no seu pode ser diferente)
-- numa cadeira do curso de matemática
insert into inscricoes values (60005, '9209', 3107, 2022, to_date('2022.09.11','YYYY.MM.DD'));
commit;
-- Inscreveu sem problema, certo?

-- Tentemos agora inscrevê-lo numa cadeira de informática
insert into inscricoes values (60005, '9119', 2468, 2022, to_date('2022.09.11','YYYY.MM.DD'));
commit;
-- Agora não dá porque o aluno 60005 não é de Informática - o aluno 60004 é que era!

-- tentemos então inscrever o aluno 60004 (pode ser nº diferente no seu caso) nessa cadeira de Informática
insert into inscricoes values (60004, '9119', 2468, 2022, to_date('2022.09.11','YYYY.MM.DD'));
commit;

-- E cá está o erro! Esse aluno já não é do curso de Informática!
















