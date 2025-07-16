<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
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
    
    // Criar tabela se não existir
    $createTableSQL = "CREATE TABLE IF NOT EXISTS historico_treinos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        usuario_id INT NOT NULL,
        nome_treino VARCHAR(255) NOT NULL,
        tempo_total INT NOT NULL,
        km_percorridos DECIMAL(10,2) DEFAULT 0.00,
        data_treino DATETIME DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    $pdo->exec($createTableSQL);
    
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["erro" => "Erro de conexão: " . $e->getMessage()]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $usuario_id = $_POST['usuario_id'] ?? null;
    $nome_treino = $_POST['nome_treino'] ?? null;
    $tempo_total = $_POST['tempo_total'] ?? null;
    $km_percorridos = $_POST['km_percorridos'] ?? 0;
    $data_treino = $_POST['data_treino'] ?? date('Y-m-d H:i:s');
    
    if (!$usuario_id || !$nome_treino || !$tempo_total) {
        http_response_code(400);
        echo json_encode(["erro" => "Dados obrigatórios faltando: usuario_id, nome_treino, tempo_total"]);
        exit;
    }
    
    try {
        $stmt = $pdo->prepare("INSERT INTO historico_treinos (usuario_id, nome_treino, tempo_total, km_percorridos, data_treino) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$usuario_id, $nome_treino, $tempo_total, $km_percorridos, $data_treino]);
        
        echo json_encode(["sucesso" => true, "message" => "Treino salvo com sucesso", "id" => $pdo->lastInsertId()]);
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(["erro" => "Erro ao salvar treino: " . $e->getMessage()]);
    }
} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $usuario_id = $_GET['usuario_id'] ?? null;
    
    if (!$usuario_id) {
        http_response_code(400);
        echo json_encode(["erro" => "usuario_id é obrigatório"]);
        exit;
    }
    
    try {
        $stmt = $pdo->prepare("SELECT * FROM historico_treinos WHERE usuario_id = ? ORDER BY data_treino DESC");
        $stmt->execute([$usuario_id]);
        $historico = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode($historico);
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(["erro" => "Erro ao buscar histórico: " . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(["erro" => "Método não permitido"]);
}
?> 