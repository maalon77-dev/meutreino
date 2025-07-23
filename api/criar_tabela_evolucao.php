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

// SQL para criar a tabela
$sql = "CREATE TABLE IF NOT EXISTS historico_evolucao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    exercicio_id INT NOT NULL,
    nome_exercicio VARCHAR(255) NOT NULL,
    peso_anterior DECIMAL(10,2) DEFAULT 0.00,
    peso_novo DECIMAL(10,2) NOT NULL,
    repeticoes_anteriores INT DEFAULT 0,
    repeticoes_novas INT NOT NULL,
    series_anteriores INT DEFAULT 0,
    series_novas INT NOT NULL,
    data_evolucao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    INDEX idx_usuario_exercicio (usuario_id, exercicio_id),
    INDEX idx_data_evolucao (data_evolucao)
)";

if ($conn->query($sql) === TRUE) {
    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Tabela historico_evolucao criada com sucesso!'
    ]);
} else {
    echo json_encode([
        'sucesso' => false,
        'erro' => 'Erro ao criar tabela: ' . $conn->error
    ]);
}

$conn->close();
?> 