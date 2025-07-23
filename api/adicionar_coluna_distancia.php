<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

// Conectar ao banco
$conn = new mysqli($host, $user, $pass, $db);

// Configurar charset para UTF-8
$conn->set_charset("utf8mb4");

// Verificar conexão
if ($conn->connect_error) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}

// Verificar se a coluna já existe
$sql = "SHOW COLUMNS FROM exercicios LIKE 'distancia'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Coluna distancia já existe na tabela exercicios'
    ]);
} else {
    // Adicionar a coluna
    $sql = "ALTER TABLE exercicios ADD COLUMN distancia DECIMAL(10,2) DEFAULT 0.00";
    
    if ($conn->query($sql) === TRUE) {
        echo json_encode([
            'sucesso' => true,
            'mensagem' => 'Coluna distancia adicionada com sucesso!'
        ]);
    } else {
        echo json_encode([
            'sucesso' => false,
            'erro' => 'Erro ao adicionar coluna: ' . $conn->error
        ]);
    }
}

$conn->close();
?> 