<?php
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
    echo "Erro de conexão: " . $conn->connect_error;
    exit;
}

// SQL para adicionar a coluna categoria
$sql = "ALTER TABLE historico_evolucao ADD COLUMN categoria VARCHAR(50) DEFAULT NULL AFTER nome_exercicio";

if ($conn->query($sql) === TRUE) {
    echo "Coluna 'categoria' adicionada com sucesso na tabela historico_evolucao!\n";
} else {
    echo "Erro ao adicionar coluna: " . $conn->error . "\n";
}

$conn->close();
?> 