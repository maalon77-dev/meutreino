<?php
// Headers obrigatórios
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuração de erro
error_reporting(E_ALL);
ini_set('display_errors', 0);

// Pegar ID do treino
$id_treino = intval($_GET['id_treino'] ?? 0);

// Validar ID
if ($id_treino <= 0) {
    http_response_code(400);
    echo json_encode(['erro' => 'ID do treino é obrigatório']);
    exit;
}

try {
    // Conectar ao banco
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    
    // Verificar conexão
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    
    // Definir charset
    $mysqli->set_charset('utf8');
    
    // Preparar consulta
    $stmt = $mysqli->prepare("SELECT * FROM exercicios WHERE id_treino = ? ORDER BY id");
    if (!$stmt) {
        throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
    }
    
    // Executar consulta
    $stmt->bind_param('i', $id_treino);
    if (!$stmt->execute()) {
        throw new Exception('Erro ao executar consulta: ' . $stmt->error);
    }
    
    // Obter resultados
    $result = $stmt->get_result();
    $exercicios = [];
    
    while ($row = $result->fetch_assoc()) {
        $exercicios[] = $row;
    }
    
    // Fechar conexões
    $stmt->close();
    $mysqli->close();
    
    // Retornar JSON
    echo json_encode($exercicios, JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}
?> 