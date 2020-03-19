/*########################
# OBS: Query Performance Insight � o nome de um recurso dispon�vel no Banco de Dados SQL do Azure que
permite que voc� revise o efeito de consultas nos recursos do banco de dados, identifique
*/

/*########################
# OBS: OBS2

Nota Criando um banco de dados SQL no portal do Azure
Para trabalhar com as ferramentas de monitoramento no Banco de Dados SQL, voc� deve ter um Azure
conta e descri��o. Voc� deve ent�o criar um banco de dados SQL e associ�-lo
com um servidor novo ou existente. Por �ltimo, voc� deve definir as configura��es do firewall para
habilite seu endere�o IP para acessar o banco de dados.

Se voc� n�o possui uma conta no momento, pode configurar uma avalia��o gratuita em
https://azure.microsoft.com/pt-pt/free/. Em seguida, conecte-se ao portal do Azure em
https://portal.azure.com. Em seguida, para criar um novo banco de dados de amostra, clique em SQL
Bancos de dados no painel de navega��o no lado esquerdo da tela e, em seguida, clique em
Adicione para abrir o blade do banco de dados SQL. Aqui voc� fornece um nome para o seu
banco de dados, selecione uma assinatura, selecione Criar novo no grupo de recursos
se��o e forne�a um nome para o grupo de recursos. Na fonte selecionada
lista suspensa, selecione Amostra e, em seguida, na lista suspensa Selecionar Amostra,
selecione AdventureWorksLT [V12]. Clique em Servidor, clique em Criar um Novo Servidor,
fornecer um nome de servidor, um login de administrador do servidor, senha e senha
confirma��o e localiza��o. Certifique-se de manter a sele��o padr�o de Sim para
Criar V12 Server (Lastest Update) como o Query Performance Insight s� funciona
com o banco de dados SQL V12. Clique em Selecionar para criar o servidor. No SQL
L�mina do banco de dados, clique em Camada de pre�os, selecione a camada B�sica e clique no bot�o
Selecione o bot�o. Para o banco de dados de amostra, voc� pode usar o n�vel de servi�o mais baixo
n�vel para minimizar os encargos associados a este servi�o. Quando voc� n�o
precisa trabalhar com o banco de dados, n�o se esque�a de exclu�-lo no portal do Azure para
evite incorrer em cobran�as cont�nuas. No blade do Banco de Dados SQL, clique em Criar para
finalize a cria��o do banco de dados de amostra. Quando o banco de dados est� pronto,
aparece na lista de bancos de dados SQL. Talvez seja necess�rio clicar em Atualizar v�rios
vezes para v�-lo aparecer.



*/


/*########################
# OBS: 3)
Quando o Banco de Dados SQL estiver dispon�vel, clique no conjunto de dados para abrir seu blade e
em seguida, clique no nome do servidor para abrir o blade do servidor. Clique em Mostrar Firewall
Configura��es, clique em Adicionar IP do Cliente e, em seguida, clique em Salvar para ativar sua conex�o com
o Banco de Dados SQL. Voc� pode adicionar manualmente os IPs do cliente para abrir o firewall
permitir que outros usu�rios acessem o banco de dados tamb�m.
*/