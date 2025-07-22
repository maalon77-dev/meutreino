<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuração de erro
error_reporting(E_ALL);
ini_set('display_errors', 0);

$categoria = $_GET['categoria'] ?? '';
if (empty($categoria)) {
    http_response_code(400);
    echo json_encode(['erro' => 'Categoria é obrigatória']);
    exit;
}

try {
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    $mysqli->set_charset('utf8mb4');
    $stmt = $mysqli->prepare("SELECT DISTINCT grupo FROM exercicios_admin WHERE categoria = ? AND grupo IS NOT NULL AND grupo != '' ORDER BY grupo");
    if (!$stmt) {
        throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
    }
    $stmt->bind_param('s', $categoria);
    if (!$stmt->execute()) {
        throw new Exception('Erro ao executar consulta: ' . $stmt->error);
    }
    $result = $stmt->get_result();
    $grupos = [];
    while ($row = $result->fetch_assoc()) {
        $grupos[] = $row['grupo'];
    }
    $stmt->close();
    $mysqli->close();
    echo json_encode($grupos, JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}
?> 