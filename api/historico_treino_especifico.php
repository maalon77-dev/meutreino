<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

$servername = "academia3322.mysql.dbaas.com.br";
$username = "academia3322";
$password = "vida1503A@";
$dbname = "academia3322";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["erro" => "Erro de conexão: " . $e->getMessage()]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $usuario_id = $_GET['usuario_id'] ?? null;
    $treino_id = $_GET['treino_id'] ?? null;
    
    if (!$usuario_id || !$treino_id) {
        http_response_code(400);
        echo json_encode(["erro" => "usuario_id e treino_id são obrigatórios"]);
        exit;
    }
    
    try {
        // Buscar histórico do treino específico
        $stmt = $pdo->prepare("
            SELECT * FROM historico_treinos 
            WHERE usuario_id = ? AND nome_treino = (SELECT nome_treino FROM treinos WHERE id = ?)
            ORDER BY data_treino DESC
        ");
        $stmt->execute([$usuario_id, $treino_id]);
        $historico = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Calcular estatísticas
        $total_vezes = count($historico);
        $ultima_vez = null;
        $primeira_vez = null;
        
        if ($total_vezes > 0) {
            $ultima_vez = $historico[0]['data_treino']; // Primeiro da lista ordenada por DESC
            $primeira_vez = $historico[$total_vezes - 1]['data_treino']; // Último da lista
        }
        
        $resultado = [
            'total_vezes' => $total_vezes,
            'ultima_vez' => $ultima_vez,
            'primeira_vez' => $primeira_vez,
            'historico' => $historico
        ];
        
        echo json_encode($resultado);
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(["erro" => "Erro ao buscar histórico: " . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(["erro" => "Método não permitido"]);
}
?> 