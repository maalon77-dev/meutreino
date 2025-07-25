<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

try {
    $conn = new mysqli($host, $user, $pass, $db);
    $conn->set_charset("utf8mb4");
    
    if ($conn->connect_error) {
        die("Erro de conexão: " . $conn->connect_error);
    }
    
    echo "✅ Conexão com banco estabelecida com sucesso!<br><br>";
    
    // Verificar estrutura da tabela usuarios
    echo "<h3>Estrutura da tabela 'usuarios':</h3>";
    $result = $conn->query("DESCRIBE usuarios");
    
    if ($result) {
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr><th>Campo</th><th>Tipo</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
        
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . $row['Field'] . "</td>";
            echo "<td>" . $row['Type'] . "</td>";
            echo "<td>" . $row['Null'] . "</td>";
            echo "<td>" . $row['Key'] . "</td>";
            echo "<td>" . $row['Default'] . "</td>";
            echo "<td>" . $row['Extra'] . "</td>";
            echo "</tr>";
        }
        echo "</table><br>";
    } else {
        echo "❌ Erro ao verificar estrutura da tabela: " . $conn->error . "<br>";
    }
    
    // Verificar se existem usuários
    echo "<h3>Usuários cadastrados:</h3>";
    $result = $conn->query("SELECT id, nome, email, nivel FROM usuarios LIMIT 5");
    
    if ($result) {
        if ($result->num_rows > 0) {
            echo "<table border='1' style='border-collapse: collapse;'>";
            echo "<tr><th>ID</th><th>Nome</th><th>Email</th><th>Nível</th></tr>";
            
            while ($row = $result->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row['id'] . "</td>";
                echo "<td>" . $row['nome'] . "</td>";
                echo "<td>" . $row['email'] . "</td>";
                echo "<td>" . ($row['nivel'] ?? 'NULL') . "</td>";
                echo "</tr>";
            }
            echo "</table><br>";
        } else {
            echo "❌ Nenhum usuário encontrado na tabela<br>";
        }
    } else {
        echo "❌ Erro ao buscar usuários: " . $conn->error . "<br>";
    }
    
    // Testar consulta de login
    echo "<h3>Teste de consulta de login:</h3>";
    $test_email = 'admin@airfit.com';
    $test_password = 'admin123';
    
    $stmt = $conn->prepare("SELECT id, nome, nivel FROM usuarios WHERE email = ? AND senha = ? AND nivel IN ('ADMIN', 'PROFISSIONAL')");
    
    if ($stmt) {
        $stmt->bind_param('ss', $test_email, $test_password);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();
            echo "✅ Login testado com sucesso!<br>";
            echo "ID: " . $user['id'] . "<br>";
            echo "Nome: " . $user['nome'] . "<br>";
            echo "Nível: " . $user['nivel'] . "<br>";
        } else {
            echo "❌ Usuário não encontrado ou nível incorreto<br>";
        }
    } else {
        echo "❌ Erro no prepare: " . $conn->error . "<br>";
    }
    
    $conn->close();
    
} catch (Exception $e) {
    echo "❌ Erro: " . $e->getMessage();
}
?> 