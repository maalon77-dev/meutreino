# Painel Administrativo AirFit

Este é o painel administrativo completo para gerenciar o aplicativo AirFit.

## 🚀 Instalação

1. **Execute o script de configuração do banco:**
   ```bash
   php add_nivel_column.php
   ```

2. **Acesse o painel:**
   ```
   https://airfit.online/admin/
   ```

## 👤 Login Padrão

Após executar o script de configuração, você pode fazer login com:

### Admin
- **Email:** admin@airfit.com
- **Senha:** admin123

### Profissional
- **Email:** profissional@airfit.com
- **Senha:** prof123

## 🔐 Níveis de Acesso

O sistema possui 3 níveis de acesso:

### ADMIN
- Acesso total ao sistema
- Pode gerenciar todos os usuários
- Pode alterar níveis de outros usuários
- Pode excluir usuários

### PROFISSIONAL
- Acesso ao painel administrativo
- Pode visualizar dados dos usuários
- **Pode criar novos usuários** (apenas nível USUARIO)
- Pode gerenciar treinos e exercícios
- **NÃO** pode alterar níveis de usuários para ADMIN
- **NÃO** pode criar outros PROFISSIONAIs

### USUARIO
- Acesso apenas ao aplicativo móvel
- Não tem acesso ao painel administrativo

## 📋 Funcionalidades

### Dashboard
- Visão geral das estatísticas
- Gráfico de usuários por nível
- Contadores de treinos, exercícios e metas

### Gerenciamento de Usuários
- Listar todos os usuários
- Filtrar por nome, email ou nível
- **Criar novos usuários** (ADMIN e PROFISSIONAL)
- Editar informações do usuário
- Alterar nível de acesso
- Ativar/desativar usuários
- Excluir usuários
- **Vínculo de criação** - mostra quem criou cada usuário

### Segurança
- Sessões seguras
- Validação de níveis de acesso
- Proteção contra auto-exclusão
- Prepared statements para prevenir SQL injection

## 🎨 Interface

- Design moderno e responsivo
- Bootstrap 5
- Font Awesome icons
- Gradientes e animações
- Modais para edição
- Alertas de feedback

## 🔧 Estrutura de Arquivos

```
admin/
├── index.php                    # Página de login
├── dashboard.php                # Dashboard principal
├── usuarios.php                 # Gerenciamento de usuários
├── logout.php                   # Logout
├── setup.php                    # Setup automático completo
├── add_criado_por_column.php    # Script para adicionar vínculo
├── test_connection.php          # Teste de conexão
└── README.md                    # Esta documentação
```

## 🛠️ Como Usar

1. **Primeiro acesso:**
   - Execute `add_nivel_column.php` para configurar o banco
   - Faça login com as credenciais padrão
   - Altere a senha do admin por segurança

2. **Gerenciar usuários:**
   - Acesse "Usuários" no menu lateral
   - Use os filtros para encontrar usuários
   - Clique no ícone de editar para modificar
   - Altere o nível conforme necessário

3. **Segurança:**
   - Sempre use senhas fortes
   - Não compartilhe credenciais de admin
   - Monitore os acessos regularmente

## 🔒 Recomendações de Segurança

1. **Altere a senha padrão do admin**
2. **Use HTTPS em produção**
3. **Configure backup regular do banco**
4. **Monitore logs de acesso**
5. **Mantenha o sistema atualizado**

## 📞 Suporte

Para dúvidas ou problemas, entre em contato com a equipe de desenvolvimento.

---

**Desenvolvido para AirFit** 🏋️‍♂️ 