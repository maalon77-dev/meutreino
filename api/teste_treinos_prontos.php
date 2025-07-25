<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    // Configurações do banco de dados
    $host = 'academia3322.mysql.dbaas.com.br';
    $dbname = 'academia3322';
    $username = 'academia3322';
    $password = 'vida1503A@';

    // Conexão com o banco
    $mysqli = new mysqli($host, $username, $password, $dbname);
    
    if ($mysqli->connect_error) {
        throw new Exception("Erro de conexão: " . $mysqli->connect_error);
    }
    
    $mysqli->set_charset("utf8mb4");
    
    // Teste simples - contar treinos públicos
    $sql = "SELECT COUNT(*) as total FROM treinos WHERE publico = '1'";
    $result = $mysqli->query($sql);
    
    if (!$result) {
        throw new Exception("Erro na consulta: " . $mysqli->error);
    }
    
    $row = $result->fetch_assoc();
    $total_publicos = $row['total'];
    
    // Buscar alguns treinos públicos
    $sql_treinos = "SELECT id, nome_treino, descricao FROM treinos WHERE publico = '1' LIMIT 5";
    $result_treinos = $mysqli->query($sql_treinos);
    
    $treinos = [];
    while ($treino = $result_treinos->fetch_assoc()) {
        $treinos[] = [
            'id' => $treino['id'],
            'nome_treino' => $treino['nome_treino'],
            'descricao' => $treino['descricao'] ?? '',
            'total_exercicios' => 0,
            'exercicios' => []
        ];
    }
    
    echo json_encode([
        'success' => true,
        'total_publicos' => $total_publicos,
        'treinos' => $treinos
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'message' => $e->getMessage(),
        'treinos' => []
    ], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($mysqli)) {
        $mysqli->close();
    }
}
?> 