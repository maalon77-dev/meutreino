<?php
// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

echo "<h2>🔧 Adicionando Colunas Faltantes</h2>";

// Verificar e adicionar coluna ativo
$result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'ativo'");
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE usuarios ADD COLUMN ativo TINYINT(1) DEFAULT 1 AFTER password";
    if ($conn->query($sql)) {
        echo "✅ Coluna 'ativo' adicionada com sucesso!<br>";
    } else {
        echo "❌ Erro ao adicionar coluna ativo: " . $conn->error . "<br>";
    }
} else {
    echo "ℹ️ Coluna 'ativo' já existe<br>";
}

// Verificar e adicionar coluna data_cadastro
$result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'data_cadastro'");
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE usuarios ADD COLUMN data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER ativo";
    if ($conn->query($sql)) {
        echo "✅ Coluna 'data_cadastro' adicionada com sucesso!<br>";
    } else {
        echo "❌ Erro ao adicionar coluna data_cadastro: " . $conn->error . "<br>";
    }
} else {
    echo "ℹ️ Coluna 'data_cadastro' já existe<br>";
}

// Verificar e adicionar coluna nivel
$result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE usuarios ADD COLUMN nivel ENUM('ADMIN', 'PROFISSIONAL', 'USUARIO') DEFAULT 'USUARIO' AFTER password";
    if ($conn->query($sql)) {
        echo "✅ Coluna 'nivel' adicionada com sucesso!<br>";
        
        // Atualizar usuários existentes para USUARIO por padrão
        $conn->query("UPDATE usuarios SET nivel = 'USUARIO' WHERE nivel IS NULL");
        echo "✅ Usuários existentes atualizados para nível 'USUARIO'<br>";
    } else {
        echo "❌ Erro ao adicionar coluna nivel: " . $conn->error . "<br>";
    }
} else {
    echo "ℹ️ Coluna 'nivel' já existe<br>";
}

// Verificar e adicionar coluna criado_por
$result = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'criado_por'");
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE usuarios ADD COLUMN criado_por INT NULL AFTER nivel, ADD FOREIGN KEY (criado_por) REFERENCES usuarios(id) ON DELETE SET NULL";
    if ($conn->query($sql)) {
        echo "✅ Coluna 'criado_por' adicionada com sucesso!<br>";
        echo "✅ Chave estrangeira criada para vincular usuários<br>";
    } else {
        echo "❌ Erro ao adicionar coluna criado_por: " . $conn->error . "<br>";
    }
} else {
    echo "ℹ️ Coluna 'criado_por' já existe<br>";
}

// Criar usuário admin padrão se não existir
$admin_email = 'admin@airfit.com';
$result = $conn->query("SELECT id FROM usuarios WHERE email = '$admin_email'");

if ($result->num_rows == 0) {
    $admin_sql = "INSERT INTO usuarios (nome, email, username, password, nivel, ativo, data_cadastro) VALUES ('Administrador', '$admin_email', 'admin', 'admin123', 'ADMIN', 1, NOW())";
    
    if ($conn->query($admin_sql)) {
        echo "✅ Usuário admin criado com sucesso!<br>";
        echo "📧 Email: admin@airfit.com<br>";
        echo "🔑 Senha: admin123<br>";
    } else {
        echo "❌ Erro ao criar usuário admin: " . $conn->error . "<br>";
    }
} else {
    echo "ℹ️ Usuário admin já existe<br>";
}

// Criar usuário profissional de exemplo
$prof_email = 'profissional@airfit.com';
$result = $conn->query("SELECT id FROM usuarios WHERE email = '$prof_email'");

if ($result->num_rows == 0) {
    $prof_sql = "INSERT INTO usuarios (nome, email, username, password, nivel, ativo, data_cadastro) VALUES ('Profissional Exemplo', '$prof_email', 'profissional', 'prof123', 'PROFISSIONAL', 1, NOW())";
    
    if ($conn->query($prof_sql)) {
        echo "✅ Usuário profissional criado com sucesso!<br>";
        echo "📧 Email: profissional@airfit.com<br>";
        echo "🔑 Senha: prof123<br>";
    } else {
        echo "❌ Erro ao criar usuário profissional: " . $conn->error . "<br>";
    }
} else {
    echo "ℹ️ Usuário profissional já existe<br>";
}

$conn->close();
echo "<br>🎉 Configuração concluída!<br>";
echo "<a href='usuarios.php' class='btn btn-primary'>Ir para Gerenciar Usuários</a>";
?> 