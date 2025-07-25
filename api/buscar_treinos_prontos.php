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
    
    // Buscar treinos públicos
    $sql = "SELECT t.*, COUNT(e.id) as total_exercicios
            FROM treinos t
            LEFT JOIN exercicios e ON t.id = e.id_treino
            WHERE t.publico = '1'
            GROUP BY t.id
            ORDER BY t.nome_treino ASC";
    
    $result = $mysqli->query($sql);
    
    if (!$result) {
        throw new Exception("Erro na consulta: " . $mysqli->error);
    }
    
    $treinos = [];
    
    while ($row = $result->fetch_assoc()) {
        // Buscar exercícios deste treino
        $sql_exercicios = "SELECT * FROM exercicios WHERE id_treino = ? ORDER BY ordem ASC, id ASC";
        
        $stmt_exercicios = $mysqli->prepare($sql_exercicios);
        $stmt_exercicios->bind_param("i", $row['id']);
        $stmt_exercicios->execute();
        $result_exercicios = $stmt_exercicios->get_result();
        
        $exercicios = [];
        while ($exercicio = $result_exercicios->fetch_assoc()) {
            $exercicios[] = [
                'id' => $exercicio['id'],
                'nome_exercicio' => $exercicio['nome_do_exercicio'],
                'descricao' => $exercicio['descricao'] ?? '',
                'grupo' => $exercicio['categoria'] ?? '',
                'ordem' => $exercicio['ordem'],
                'series' => $exercicio['numero_series'],
                'repeticoes' => $exercicio['numero_repeticoes'],
                'tempo' => $exercicio['tempo_exercicio'] ?? '',
                'peso' => $exercicio['peso'],
                'distancia' => $exercicio['distancia'],
            ];
        }
        
        $stmt_exercicios->close();
        
        $treinos[] = [
            'id' => $row['id'],
            'nome_treino' => $row['nome_treino'],
            'descricao' => $row['descricao'] ?? '',
            'publico' => $row['publico'],
            'total_exercicios' => $row['total_exercicios'],
            'exercicios' => $exercicios,
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