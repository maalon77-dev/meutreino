<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

$messages = [];

if ($conn->connect_error) {
    $messages[] = "❌ Erro de conexão: " . $conn->connect_error;
} else {
    $messages[] = "✅ Conexão com banco estabelecida com sucesso!";
    
    // Verificar se a coluna nivel existe
    $result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
    
    if ($result->num_rows == 0) {
        // Adicionar a coluna nivel
        $sql = "ALTER TABLE usuarios ADD COLUMN nivel ENUM('ADMIN', 'PROFISSIONAL', 'USUARIO') DEFAULT 'USUARIO' AFTER password";
        
        if ($conn->query($sql)) {
            $messages[] = "✅ Coluna 'nivel' adicionada com sucesso!";
            
            // Atualizar usuários existentes para USUARIO por padrão
            $conn->query("UPDATE usuarios SET nivel = 'USUARIO' WHERE nivel IS NULL");
            $messages[] = "✅ Usuários existentes atualizados para nível 'USUARIO'";
        } else {
            $messages[] = "❌ Erro ao adicionar coluna nivel: " . $conn->error;
        }
    } else {
        $messages[] = "ℹ️ Coluna 'nivel' já existe na tabela usuarios";
    }
    
    // Verificar se a coluna criado_por existe
    $result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'criado_por'");
    
    if ($result->num_rows == 0) {
        // Adicionar a coluna criado_por
        $sql = "ALTER TABLE usuarios ADD COLUMN criado_por INT NULL AFTER nivel, ADD FOREIGN KEY (criado_por) REFERENCES usuarios(id) ON DELETE SET NULL";
        
        if ($conn->query($sql)) {
            $messages[] = "✅ Coluna 'criado_por' adicionada com sucesso!";
            $messages[] = "✅ Chave estrangeira criada para vincular usuários";
        } else {
            $messages[] = "❌ Erro ao adicionar coluna criado_por: " . $conn->error;
        }
    } else {
        $messages[] = "ℹ️ Coluna 'criado_por' já existe na tabela usuarios";
    }
    
    // Criar um usuário admin padrão se não existir
    $admin_email = 'admin@airfit.com';
    $result = $conn->query("SELECT id FROM usuarios WHERE email = '$admin_email'");
    
    if ($result->num_rows == 0) {
        $admin_sql = "INSERT INTO usuarios (nome, email, username, password, nivel, ativo, data_cadastro) VALUES ('Administrador', '$admin_email', 'admin', 'admin123', 'ADMIN', 1, NOW())";
        
        if ($conn->query($admin_sql)) {
            $messages[] = "✅ Usuário admin criado com sucesso!";
            $messages[] = "📧 Email: admin@airfit.com";
            $messages[] = "🔑 Senha: admin123";
        } else {
            $messages[] = "❌ Erro ao criar usuário admin: " . $conn->error;
        }
    } else {
        $messages[] = "ℹ️ Usuário admin já existe";
    }
    
    // Criar um usuário profissional de exemplo
    $prof_email = 'profissional@airfit.com';
    $result = $conn->query("SELECT id FROM usuarios WHERE email = '$prof_email'");
    
    if ($result->num_rows == 0) {
        $prof_sql = "INSERT INTO usuarios (nome, email, username, password, nivel, ativo, data_cadastro) VALUES ('Profissional Exemplo', '$prof_email', 'profissional', 'prof123', 'PROFISSIONAL', 1, NOW())";
        
        if ($conn->query($prof_sql)) {
            $messages[] = "✅ Usuário profissional criado com sucesso!";
            $messages[] = "📧 Email: profissional@airfit.com";
            $messages[] = "🔑 Senha: prof123";
        } else {
            $messages[] = "❌ Erro ao criar usuário profissional: " . $conn->error;
        }
    } else {
        $messages[] = "ℹ️ Usuário profissional já existe";
    }
    
    // Verificar se existem usuários
    $result = $conn->query("SELECT COUNT(*) as total FROM usuarios");
    $total_usuarios = $result->fetch_assoc()['total'];
    $messages[] = "📊 Total de usuários no sistema: $total_usuarios";
}

$conn->close();
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Setup - AirFit Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .setup-card {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
            max-width: 600px;
            width: 100%;
        }
        .setup-header {
            background: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }
        .setup-body {
            padding: 40px 30px;
        }
        .message {
            padding: 10px 15px;
            margin: 10px 0;
            border-radius: 8px;
            font-weight: 500;
        }
        .message.success {
            background-color: #d1fae5;
            color: #065f46;
            border-left: 4px solid #10b981;
        }
        .message.info {
            background-color: #dbeafe;
            color: #1e40af;
            border-left: 4px solid #3b82f6;
        }
        .message.error {
            background-color: #fee2e2;
            color: #991b1b;
            border-left: 4px solid #ef4444;
        }
        .btn-primary {
            background: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%);
            border: none;
            border-radius: 10px;
            padding: 12px 24px;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="setup-card">
        <div class="setup-header">
            <div class="mb-3">
                <i class="fas fa-cogs fa-3x"></i>
            </div>
            <h2>Setup do Painel Administrativo</h2>
            <p class="mb-0">Configuração automática do sistema</p>
        </div>
        <div class="setup-body">
            <h4 class="mb-4">
                <i class="fas fa-list-check me-2"></i>Resultado da Configuração
            </h4>
            
            <?php foreach ($messages as $message): ?>
                <div class="message <?php echo strpos($message, '✅') !== false ? 'success' : (strpos($message, '❌') !== false ? 'error' : 'info'); ?>">
                    <?php echo htmlspecialchars($message); ?>
                </div>
            <?php endforeach; ?>
            
            <hr class="my-4">
            
            <div class="alert alert-info">
                <h5><i class="fas fa-info-circle me-2"></i>Próximos Passos</h5>
                <ol class="mb-0">
                    <li>Clique no botão abaixo para acessar o painel</li>
                    <li>Faça login com as credenciais fornecidas</li>
                    <li>Altere a senha do admin por segurança</li>
                    <li>Comece a gerenciar seus usuários</li>
                </ol>
            </div>
            
            <div class="d-grid gap-2">
                <a href="index.php" class="btn btn-primary">
                    <i class="fas fa-sign-in-alt me-2"></i>Acessar Painel Administrativo
                </a>
                <a href="../" class="btn btn-outline-secondary">
                    <i class="fas fa-arrow-left me-2"></i>Voltar ao Aplicativo
                </a>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html> 