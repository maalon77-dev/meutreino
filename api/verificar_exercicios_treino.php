<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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
    // Conexão com o banco
    $mysqli = new mysqli($host, $username, $password, $dbname);
    
    if ($mysqli->connect_error) {
        throw new Exception("Erro de conexão: " . $mysqli->connect_error);
    }
    
    $mysqli->set_charset("utf8mb4");
    
    // Verificar treinos públicos
    $sql_treinos = "SELECT id, nome_treino, publico FROM treinos WHERE publico = '1'";
    $result_treinos = $mysqli->query($sql_treinos);
    
    $treinos = [];
    while ($treino = $result_treinos->fetch_assoc()) {
        // Verificar exercícios deste treino
        $sql_exercicios = "SELECT COUNT(*) as total FROM exercicios WHERE id_treino = ?";
        $stmt = $mysqli->prepare($sql_exercicios);
        $stmt->bind_param("i", $treino['id']);
        $stmt->execute();
        $result_count = $stmt->get_result();
        $count = $result_count->fetch_assoc()['total'];
        $stmt->close();
        
        // Buscar alguns exercícios de exemplo
        $sql_exemplo = "SELECT id, nome_exercicio, ordem, series, repeticoes FROM exercicios WHERE id_treino = ? LIMIT 3";
        $stmt = $mysqli->prepare($sql_exemplo);
        $stmt->bind_param("i", $treino['id']);
        $stmt->execute();
        $result_exemplo = $stmt->get_result();
        
        $exercicios_exemplo = [];
        while ($exercicio = $result_exemplo->fetch_assoc()) {
            $exercicios_exemplo[] = $exercicio;
        }
        $stmt->close();
        
        $treinos[] = [
            'id' => $treino['id'],
            'nome_treino' => $treino['nome_treino'],
            'total_exercicios' => $count,
            'exercicios_exemplo' => $exercicios_exemplo
        ];
    }
    
    echo json_encode([
        'success' => true,
        'treinos' => $treinos
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($mysqli)) {
        $mysqli->close();
    }
}
?> 