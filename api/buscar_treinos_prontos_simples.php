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
    
    // Buscar treinos públicos (publico = '1')
    $sql = "SELECT t.id, t.nome_treino, t.descricao, t.publico, t.ordem
            FROM treinos t
            WHERE t.publico = '1'
            ORDER BY t.nome_treino ASC";
    
    $result = $mysqli->query($sql);
    
    if (!$result) {
        throw new Exception("Erro na consulta: " . $mysqli->error);
    }
    
    $treinos = [];
    
    while ($row = $result->fetch_assoc()) {
        // Buscar exercícios deste treino
        $sql_exercicios = "SELECT e.id, e.nome_exercicio, e.descricao, e.ordem, e.series, e.repeticoes, e.tempo, e.peso, e.distancia
                          FROM exercicios e
                          WHERE e.id_treino = ?
                          ORDER BY e.ordem ASC, e.id ASC";
        
        $stmt_exercicios = $mysqli->prepare($sql_exercicios);
        if (!$stmt_exercicios) {
            throw new Exception("Erro ao preparar consulta de exercícios: " . $mysqli->error);
        }
        
        $stmt_exercicios->bind_param("i", $row['id']);
        $stmt_exercicios->execute();
        $result_exercicios = $stmt_exercicios->get_result();
        
        $exercicios = [];
        while ($exercicio = $result_exercicios->fetch_assoc()) {
            $exercicios[] = [
                'id' => $exercicio['id'],
                'nome_exercicio' => $exercicio['nome_exercicio'],
                'descricao' => $exercicio['descricao'] ?? '',
                'grupo' => '',
                'ordem' => $exercicio['ordem'] ?? 0,
                'series' => $exercicio['series'] ?? 0,
                'repeticoes' => $exercicio['repeticoes'] ?? 0,
                'tempo' => $exercicio['tempo'] ?? '',
                'peso' => $exercicio['peso'] ?? '',
                'distancia' => $exercicio['distancia'] ?? '',
            ];
        }
        
        $stmt_exercicios->close();
        
        $treinos[] = [
            'id' => $row['id'],
            'nome_treino' => $row['nome_treino'],
            'descricao' => $row['descricao'] ?? '',
            'publico' => $row['publico'],
            'total_exercicios' => count($exercicios),
            'exercicios' => $exercicios,
        ];
    }
    
    echo json_encode($treinos, JSON_UNESCAPED_UNICODE);
    
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