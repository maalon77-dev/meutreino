<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Configurações do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$dbname = 'academia3322';
$username = 'academia3322';
$password = 'vida1503A@';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo json_encode(['status' => 'success', 'message' => 'Conexão com banco estabelecida']);
} catch(PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => 'Erro de conexão: ' . $e->getMessage()]);
    exit;
}

// Verificar se a tabela existe
try {
    $stmt = $pdo->query("SHOW TABLES LIKE 'premios_conquistados'");
    if ($stmt->rowCount() == 0) {
        echo json_encode(['status' => 'info', 'message' => 'Tabela premios_conquistados não existe']);
    } else {
        echo json_encode(['status' => 'success', 'message' => 'Tabela premios_conquistados existe']);
        
        // Contar registros
        $stmt = $pdo->query("SELECT COUNT(*) as total FROM premios_conquistados");
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode(['status' => 'info', 'message' => 'Total de prêmios: ' . $result['total']]);
    }
} catch(PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => 'Erro ao verificar tabela: ' . $e->getMessage()]);
}
?> 