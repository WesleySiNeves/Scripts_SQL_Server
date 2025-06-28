/*########################
# OBS: Query Performance Insight é o nome de um recurso disponível no Banco de Dados SQL do Azure que
permite que você revise o efeito de consultas nos recursos do banco de dados, identifique
*/

/*########################
# OBS: OBS2

Nota Criando um banco de dados SQL no portal do Azure
Para trabalhar com as ferramentas de monitoramento no Banco de Dados SQL, você deve ter um Azure
conta e descrição. Você deve então criar um banco de dados SQL e associá-lo
com um servidor novo ou existente. Por último, você deve definir as configurações do firewall para
habilite seu endereço IP para acessar o banco de dados.

Se você não possui uma conta no momento, pode configurar uma avaliação gratuita em
https://azure.microsoft.com/pt-pt/free/. Em seguida, conecte-se ao portal do Azure em
https://portal.azure.com. Em seguida, para criar um novo banco de dados de amostra, clique em SQL
Bancos de dados no painel de navegação no lado esquerdo da tela e, em seguida, clique em
Adicione para abrir o blade do banco de dados SQL. Aqui você fornece um nome para o seu
banco de dados, selecione uma assinatura, selecione Criar novo no grupo de recursos
seção e forneça um nome para o grupo de recursos. Na fonte selecionada
lista suspensa, selecione Amostra e, em seguida, na lista suspensa Selecionar Amostra,
selecione AdventureWorksLT [V12]. Clique em Servidor, clique em Criar um Novo Servidor,
fornecer um nome de servidor, um login de administrador do servidor, senha e senha
confirmação e localização. Certifique-se de manter a seleção padrão de Sim para
Criar V12 Server (Lastest Update) como o Query Performance Insight só funciona
com o banco de dados SQL V12. Clique em Selecionar para criar o servidor. No SQL
Lâmina do banco de dados, clique em Camada de preços, selecione a camada Básica e clique no botão
Selecione o botão. Para o banco de dados de amostra, você pode usar o nível de serviço mais baixo
nível para minimizar os encargos associados a este serviço. Quando você não
precisa trabalhar com o banco de dados, não se esqueça de excluí-lo no portal do Azure para
evite incorrer em cobranças contínuas. No blade do Banco de Dados SQL, clique em Criar para
finalize a criação do banco de dados de amostra. Quando o banco de dados está pronto,
aparece na lista de bancos de dados SQL. Talvez seja necessário clicar em Atualizar vários
vezes para vê-lo aparecer.



*/


/*########################
# OBS: 3)
Quando o Banco de Dados SQL estiver disponível, clique no conjunto de dados para abrir seu blade e
em seguida, clique no nome do servidor para abrir o blade do servidor. Clique em Mostrar Firewall
Configurações, clique em Adicionar IP do Cliente e, em seguida, clique em Salvar para ativar sua conexão com
o Banco de Dados SQL. Você pode adicionar manualmente os IPs do cliente para abrir o firewall
permitir que outros usuários acessem o banco de dados também.
*/