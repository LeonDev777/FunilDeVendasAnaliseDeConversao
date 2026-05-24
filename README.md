# Analise de CRM e Funil de Vendas com SQL 

Esse projeto foi feito pra praticar os meus conhecimentos de SQL simulando o banco de dados de um sistema de CRM. Como estou estudando faz 8 meses, decidi criar um funil de vendas para analisar as taxas de conversão de leads e performance.

### O que o projeto responde:
1. O volume de leads em cada etapa e a taxa de conversão geral.
2. O tempo médio em dias que um lead leva de "Contato" até fechar venda.
3. Ranking dos melhores vendedores por valor faturado.
4. Os principais motivos que fazem a empresa perder negócios.

### Como rodar
Fiz os scripts usando a sintaxe do SQLite.
1. Crie as tabelas rodando o arquivo `create_tables.sql`.
2. Insira os registros de testes usando o `seed_data.sql`.
3. Execute os arquivos de queries separados para ver os relatórios de negócio.

### O que aprendi fazendo
* Consegui entender melhor como fazer auto-join (JOIN da tabela com ela mesma) no script de tempo de conversão para comparar datas da mesma tabela.
* Entendi a importância de limpar dados, já que digitei uma data errada no seed de teste e ela quebrava os relatórios mensais.
* Usei a função WITH pela primeira vez para criar uma tabela temporária (CTE) e facilitar a leitura da query do funil.
