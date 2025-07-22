<?php
// Headers obrigatórios
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuração de erro
error_reporting(0);
ini_set('display_errors', 0);

// Pegar parâmetros
$id_treino = intval($_GET['id_treino'] ?? 0);
$user_id = intval($_GET['user_id'] ?? 0);

// Log para debug
error_log("API get_exercicios.php - id_treino: $id_treino, user_id: $user_id");

// Validar IDs
if ($id_treino <= 0) {
    error_log("Erro: ID do treino é obrigatório - recebido: $id_treino");
    http_response_code(400);
    echo json_encode(['erro' => 'ID do treino é obrigatório', 'id_treino_recebido' => $id_treino]);
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
    
    // Preparar consulta baseada na presença do user_id
    if ($user_id > 0) {
        $stmt = $mysqli->prepare("SELECT * FROM exercicios WHERE id_treino = ? AND user_id = ? ORDER BY COALESCE(ordem, id)");
        if (!$stmt) {
            throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
        }
        $stmt->bind_param('ii', $id_treino, $user_id);
    } else {
        $stmt = $mysqli->prepare("SELECT * FROM exercicios WHERE id_treino = ? ORDER BY COALESCE(ordem, id)");
        if (!$stmt) {
            throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
        }
        $stmt->bind_param('i', $id_treino);
    }
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