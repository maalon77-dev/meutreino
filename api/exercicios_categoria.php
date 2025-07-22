<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuração de erro
error_reporting(E_ALL);
ini_set('display_errors', 0);

// Pegar categoria e grupo
$categoria = $_GET['categoria'] ?? '';
$grupo = $_GET['grupo'] ?? '';

// Validar categoria
if (empty($categoria)) {
    http_response_code(400);
    echo json_encode(['erro' => 'Categoria é obrigatória']);
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
    $mysqli->set_charset('utf8mb4');
    
    // Preparar consulta
    if (!empty($grupo)) {
        $stmt = $mysqli->prepare("SELECT * FROM exercicios_admin WHERE categoria = ? AND grupo = ? ORDER BY nome_do_exercicio");
        if (!$stmt) throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
        $stmt->bind_param('ss', $categoria, $grupo);
    } else {
        $stmt = $mysqli->prepare("SELECT * FROM exercicios_admin WHERE categoria = ? ORDER BY nome_do_exercicio");
        if (!$stmt) throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
        $stmt->bind_param('s', $categoria);
    }
    
    // Executar consulta
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