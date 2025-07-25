<?php
// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

// Verificar se a coluna nivel existe
$result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");

if ($result->num_rows == 0) {
    // Adicionar a coluna nivel
    $sql = "ALTER TABLE usuarios ADD COLUMN nivel ENUM('ADMIN', 'PROFISSIONAL', 'USUARIO') DEFAULT 'USUARIO' AFTER senha";
    
    if ($conn->query($sql)) {
        echo "✅ Coluna 'nivel' adicionada com sucesso!\n";
        
        // Atualizar usuários existentes para USUARIO por padrão
        $conn->query("UPDATE usuarios SET nivel = 'USUARIO' WHERE nivel IS NULL");
        echo "✅ Usuários existentes atualizados para nível 'USUARIO'\n";
        
        // Criar um usuário admin padrão se não existir
        $admin_email = 'admin@airfit.com';
        $result = $conn->query("SELECT id FROM usuarios WHERE email = '$admin_email'");
        
        if ($result->num_rows == 0) {
            $admin_sql = "INSERT INTO usuarios (nome, email, senha, nivel, ativo, data_cadastro) VALUES ('Administrador', '$admin_email', 'admin123', 'ADMIN', 1, NOW())";
            
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
        
    } else {
        echo "❌ Erro ao adicionar coluna: " . $conn->error . "\n";
    }
} else {
    echo "ℹ️ Coluna 'nivel' já existe na tabela usuarios\n";
}

$conn->close();
echo "\n🎉 Script concluído!\n";
?> 