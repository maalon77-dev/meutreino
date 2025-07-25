<?php
// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

echo "🔧 Configurando sistema de vínculo de usuários...\n\n";

// Verificar se a coluna nivel existe
$result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
if ($result->num_rows == 0) {
    // Adicionar a coluna nivel
    $sql = "ALTER TABLE usuarios ADD COLUMN nivel ENUM('ADMIN', 'PROFISSIONAL', 'USUARIO') DEFAULT 'USUARIO' AFTER password";
    
    if ($conn->query($sql)) {
        echo "✅ Coluna 'nivel' adicionada com sucesso!\n";
        
        // Atualizar usuários existentes para USUARIO por padrão
        $conn->query("UPDATE usuarios SET nivel = 'USUARIO' WHERE nivel IS NULL");
        echo "✅ Usuários existentes atualizados para nível 'USUARIO'\n";
    } else {
        echo "❌ Erro ao adicionar coluna nivel: " . $conn->error . "\n";
    }
} else {
    echo "ℹ️ Coluna 'nivel' já existe\n";
}

// Verificar se a coluna criado_por existe
$result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'criado_por'");
if ($result->num_rows == 0) {
    // Adicionar a coluna criado_por
    $sql = "ALTER TABLE usuarios ADD COLUMN criado_por INT NULL AFTER nivel, ADD FOREIGN KEY (criado_por) REFERENCES usuarios(id) ON DELETE SET NULL";
    
    if ($conn->query($sql)) {
        echo "✅ Coluna 'criado_por' adicionada com sucesso!\n";
        echo "✅ Chave estrangeira criada para vincular usuários\n";
    } else {
        echo "❌ Erro ao adicionar coluna criado_por: " . $conn->error . "\n";
    }
} else {
    echo "ℹ️ Coluna 'criado_por' já existe\n";
}

// Criar um usuário admin padrão se não existir
$admin_email = 'admin@airfit.com';
$result = $conn->query("SELECT id FROM usuarios WHERE email = '$admin_email'");

if ($result->num_rows == 0) {
    $admin_sql = "INSERT INTO usuarios (nome, email, username, password, nivel, ativo, data_cadastro) VALUES ('Administrador', '$admin_email', 'admin', 'admin123', 'ADMIN', 1, NOW())";
    
    if ($conn->query($admin_sql)) {
        echo "✅ Usuário admin criado:\n";
        echo "   Email: admin@airfit.com\n";
        echo "   Senha: admin123\n";
    } else {
        echo "❌ Erro ao criar usuário admin: " . $conn->error . "\n";
    }
} else {
    echo "ℹ️ Usuário admin já existe\n";
}

// Criar um usuário profissional de exemplo
$prof_email = 'profissional@airfit.com';
$result = $conn->query("SELECT id FROM usuarios WHERE email = '$prof_email'");

if ($result->num_rows == 0) {
    $prof_sql = "INSERT INTO usuarios (nome, email, username, password, nivel, ativo, data_cadastro) VALUES ('Profissional Exemplo', '$prof_email', 'profissional', 'prof123', 'PROFISSIONAL', 1, NOW())";
    
    if ($conn->query($prof_sql)) {
        echo "✅ Usuário profissional criado:\n";
        echo "   Email: profissional@airfit.com\n";
        echo "   Senha: prof123\n";
    } else {
        echo "❌ Erro ao criar usuário profissional: " . $conn->error . "\n";
    }
} else {
    echo "ℹ️ Usuário profissional já existe\n";
}

$conn->close();
echo "\n🎉 Configuração concluída!\n";
?> 