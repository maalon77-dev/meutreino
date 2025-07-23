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

$alteracoes = [];

// Verificar e adicionar coluna duracao_anterior
$sql = "SHOW COLUMNS FROM historico_evolucao LIKE 'duracao_anterior'";
$result = $conn->query($sql);
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE historico_evolucao ADD COLUMN duracao_anterior DECIMAL(10,2) DEFAULT 0.00";
    if ($conn->query($sql) === TRUE) {
        $alteracoes[] = 'Coluna duracao_anterior adicionada';
    } else {
        echo json_encode(['erro' => 'Erro ao adicionar duracao_anterior: ' . $conn->error]);
        exit;
    }
}

// Verificar e adicionar coluna duracao_nova
$sql = "SHOW COLUMNS FROM historico_evolucao LIKE 'duracao_nova'";
$result = $conn->query($sql);
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE historico_evolucao ADD COLUMN duracao_nova DECIMAL(10,2) DEFAULT 0.00";
    if ($conn->query($sql) === TRUE) {
        $alteracoes[] = 'Coluna duracao_nova adicionada';
    } else {
        echo json_encode(['erro' => 'Erro ao adicionar duracao_nova: ' . $conn->error]);
        exit;
    }
}

// Verificar e adicionar coluna distancia_anterior
$sql = "SHOW COLUMNS FROM historico_evolucao LIKE 'distancia_anterior'";
$result = $conn->query($sql);
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE historico_evolucao ADD COLUMN distancia_anterior DECIMAL(10,2) DEFAULT 0.00";
    if ($conn->query($sql) === TRUE) {
        $alteracoes[] = 'Coluna distancia_anterior adicionada';
    } else {
        echo json_encode(['erro' => 'Erro ao adicionar distancia_anterior: ' . $conn->error]);
        exit;
    }
}

// Verificar e adicionar coluna distancia_nova
$sql = "SHOW COLUMNS FROM historico_evolucao LIKE 'distancia_nova'";
$result = $conn->query($sql);
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE historico_evolucao ADD COLUMN distancia_nova DECIMAL(10,2) DEFAULT 0.00";
    if ($conn->query($sql) === TRUE) {
        $alteracoes[] = 'Coluna distancia_nova adicionada';
    } else {
        echo json_encode(['erro' => 'Erro ao adicionar distancia_nova: ' . $conn->error]);
        exit;
    }
}

if (empty($alteracoes)) {
    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Todas as colunas já existem na tabela historico_evolucao'
    ]);
} else {
    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Colunas adicionadas com sucesso!',
        'alteracoes' => $alteracoes
    ]);
}

$conn->close();
?> 