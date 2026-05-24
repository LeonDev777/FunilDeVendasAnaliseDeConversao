-- Criando as tabelas do CRM para analise de funil
CREATE TABLE vendedores (
    id_vendedor INT PRIMARY KEY,
    nome_vendedor VARCHAR(100),
    regiao VARCHAR(50)
);
CREATE TABLE leads (
    id_lead VARCHAR(50) PRIMARY KEY,
    nome_contato VARCHAR(100),
    empresa VARCHAR(100),
    origem_lead VARCHAR(50), -- de onde veio: inbound, outbound, etc
    data_cadastro DATE
);
create table historico_funil (
    id_historico INT PRIMARY KEY,
    id_lead VARCHAR(50),
    id_vendedor INT,
    etapa_funil VARCHAR(50), -- Contato, Qualificado, Proposta, Fechado Ganho, Fechado Perdido
    data_mudanca DATETIME,
    valor_proposta DECIMAL(10,2),
    motivo_perda VARCHAR(100),
    FOREIGN KEY (id_lead) REFERENCES leads(id_lead),
    FOREIGN KEY (id_vendedor) REFERENCES vendedores(id_vendedor)
);

-- Populando dados do CRM para testar as metricas de conversao
INSERT INTO vendedores VALUES (1, 'Carlos Silva', 'Sudeste');
INSERT INTO vendedores VALUES (2, 'Mariana Dias', 'Sul');
INSERT INTO vendedores VALUES (3, 'Roberto', 'Nordeste'); -- cadastrado sem sobrenome
INSERT INTO leads VALUES ('l1', 'João Pereira', 'Tech Simples', 'Inbound', '2026-01-10');
INSERT INTO leads VALUES ('l2', 'Ana Souza', 'Global Comercio', 'Outbound', '2026-01-12');
INSERT INTO leads VALUES ('l3', 'Marcos Lima', 'Studio Design', 'Indicação', '2026-01-15');
INSERT INTO leads VALUES ('l4', 'Patricia', 'Supermercado ABC', 'Inbound', '2026-01-20');
INSERT INTO leads VALUES ('l5', 'Ricardo Santos', 'Fábrica Total', 'Outbound', '2026-02-01');
INSERT INTO leads VALUES ('l6', 'Juliana M.', 'Restaurante Central', 'Google', '2026-02-05');
-- data errada que acabou indo pro futuro por erro de digitação
INSERT INTO leads VALUES ('l7', 'Lucas Silva', 'Auto Pecas Nova', 'Inbound', '2028-03-10');
INSERT INTO historico_funil VALUES (101, 'l1', 1, 'Contato', '2026-01-10 14:00:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (102, 'l1', 1, 'Qualificado', '2026-01-12 10:30:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (103, 'l1', 1, 'Proposta', '2026-01-15 16:00:00', 5000.00, NULL);
INSERT INTO historico_funil VALUES (104, 'l1', 1, 'Fechado Ganho', '2026-01-20 11:00:00', 5000.00, NULL);
INSERT INTO historico_funil VALUES (105, 'l2', 2, 'Contato', '2026-01-12 09:15:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (106, 'l2', 2, 'Qualificado', '2026-01-14 15:20:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (107, 'l2', 2, 'Fechado Perdido', '2026-01-18 14:00:00', 0.00, 'Preço alto');
INSERT INTO historico_funil VALUES (108, 'l3', 1, 'Contato', '2026-01-15 11:00:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (109, 'l3', 1, 'Proposta', '2026-01-22 09:00:00', 12500.00, NULL);
INSERT INTO historico_funil VALUES (110, 'l3', 1, 'Fechado Ganho', '2026-01-29 17:30:00', 12000.00, NULL); -- fecharam com desconto
INSERT INTO historico_funil VALUES (111, 'l4', 3, 'Contato', '2026-01-20 15:45:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (112, 'l4', 3, 'Fechado Perdido', '2026-01-21 10:00:00', 0.00, 'Sem escopo / Sumiu');
INSERT INTO historico_funil VALUES (113, 'l5', 2, 'Contato', '2026-02-01 13:00:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (114, 'l5', 2, 'Qualificado', '2026-02-03 11:00:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (115, 'l5', 2, 'Proposta', '2026-02-10 14:00:00', 3200.00, NULL);
INSERT INTO historico_funil VALUES (116, 'l6', 3, 'Contato', '2026-02-05 10:20:00', 0.00, NULL);
INSERT INTO historico_funil VALUES (117, 'l6', 3, 'Fechado Perdido', '2026-02-12 16:00:00', 4000.00, 'Preço alto');
INSERT INTO historico_funil VALUES (118, 'l7', 1, 'Contato', '2028-03-10 09:00:00', 0.00, NULL);

-- 1. Total de leads por etapa e taxa de conversao geral para ganho
WITH contagem_etapas AS (
  select 
    etapa_funil,
    count(distinct id_lead) as total_leads
  from historico_funil
  where data_mudanca < '2027-01-01' -- tirando o lead com data errada do futuro
  group by etapa_funil
)
SELECT 
  etapa_funil,
  total_leads,
  -- peguei o total de leads direto da tabela principal pra calcular a porcentagem do total
  round((total_leads * 100.0) / (select count(*) from leads where data_cadastro < '2027-01-01'), 2) as pct_do_total
FROM contagem_etapas
ORDER BY total_leads DESC;

-- 2. Tempo medio em dias que o lead demora para fechar negocio como Ganho
select 
    a.id_lead,
    min(a.data_mudanca) as data_entrada,
    max(b.data_mudanca) as data_fechamento,
    -- corrigido: era julianday do SQLite, nao funciona no SQL Server
    DATEDIFF(day, min(a.data_mudanca), max(b.data_mudanca)) as dias_para_fechar
from historico_funil a
join historico_funil b on a.id_lead = b.id_lead
where a.etapa_funil = 'Contato' 
  and b.etapa_funil = 'Fechado Ganho'
group by a.id_lead;
-- TODO: melhorar isso depois para calcular a média geral da coluna de dias usando uma subquery maior

-- 3. Total vendido por vendedor e ticket medio das propostas ganhas
SELECT 
    v.nome_vendedor,
    v.regiao,
    COUNT(DISTINCT h.id_lead) as contratos_fechados,
    SUM(h.valor_proposta) as valor_total_vendido,
    SUM(h.valor_proposta) / COUNT(DISTINCT h.id_lead) AS ticket_medio
FROM vendedores v
JOIN historico_funil h ON v.id_vendedor = h.id_vendedor
WHERE h.etapa_funil = 'Fechado Ganho'
GROUP BY v.id_vendedor, v.nome_vendedor, v.regiao
order by valor_total_vendido desc;

-- 4. Quais os principais motivos de perda de leads e o valor perdido estimado?
select 
  motivo_perda,
  count(*) as quantidade_leads,
  sum(valor_proposta) as valor_total_perdido
from historico_funil
where etapa_funil = 'Fechado Perdido'
group by motivo_perda
having motivo_perda is not null -- tira os nulos se tiver algum erro
order by quantidade_leads desc;
