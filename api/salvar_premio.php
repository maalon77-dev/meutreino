<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Configurações do banco de dados
$servername = "academia3322.mysql.dbaas.com.br";
$username = "academia3322";
$password = "vida1503A@";
$dbname = "academia3322";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $e->getMessage()]);
    exit;
}

// Verificar se é uma requisição POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        echo json_encode(['erro' => 'Dados inválidos']);
        exit;
    }
    
    $usuario_id = $input['usuario_id'] ?? null;
    $nome_animal = $input['nome_animal'] ?? null;
    $emoji_animal = $input['emoji_animal'] ?? null;
    $peso_animal = $input['peso_animal'] ?? null;
    $peso_total_levantado = $input['peso_total_levantado'] ?? null;
    $data_conquista = $input['data_conquista'] ?? null;
    $nome_treino = $input['nome_treino'] ?? null;
    
    if (!$usuario_id || !$nome_animal || !$peso_animal || !$peso_total_levantado) {
        echo json_encode(['erro' => 'Dados obrigatórios não fornecidos']);
        exit;
    }
    
    try {
        // Verificar se a tabela existe, se não, criar
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS premios_conquistados (
                id INT AUTO_INCREMENT PRIMARY KEY,
                usuario_id INT NOT NULL,
                nome_animal VARCHAR(100) NOT NULL,
                emoji_animal VARCHAR(10) NOT NULL,
                peso_animal DECIMAL(10,2) NOT NULL,
                peso_total_levantado DECIMAL(10,2) NOT NULL,
                data_conquista DATETIME NOT NULL,
                nome_treino VARCHAR(100) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_usuario_id (usuario_id),
                INDEX idx_data_conquista (data_conquista)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
        
        // Inserir o prêmio
        $stmt = $pdo->prepare("
            INSERT INTO premios_conquistados 
            (usuario_id, nome_animal, emoji_animal, peso_animal, peso_total_levantado, data_conquista, nome_treino) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $usuario_id,
            $nome_animal,
            $emoji_animal,
            $peso_animal,
            $peso_total_levantado,
            $data_conquista ?: date('Y-m-d H:i:s'),
            $nome_treino
        ]);
        
        $id = $pdo->lastInsertId();
        
        echo json_encode([
            'sucesso' => true,
            'message' => 'Prêmio salvo com sucesso',
            'id' => $id,
            'premio' => [
                'id' => $id,
                'usuario_id' => $usuario_id,
                'nome_animal' => $nome_animal,
                'emoji_animal' => $emoji_animal,
                'peso_animal' => $peso_animal,
                'peso_total_levantado' => $peso_total_levantado,
                'data_conquista' => $data_conquista ?: date('Y-m-d H:i:s'),
                'nome_treino' => $nome_treino
            ]
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao salvar prêmio: ' . $e->getMessage()]);
    }
    
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Buscar prêmios de um usuário
    $usuario_id = $_GET['usuario_id'] ?? null;
    
    if (!$usuario_id) {
        echo json_encode(['erro' => 'ID do usuário não fornecido']);
        exit;
    }
    
    try {
        // Verificar se a tabela existe
        $stmt = $pdo->query("SHOW TABLES LIKE 'premios_conquistados'");
        if ($stmt->rowCount() == 0) {
            echo json_encode(['premios' => []]);
            exit;
        }
        
        $stmt = $pdo->prepare("
            SELECT * FROM premios_conquistados 
            WHERE usuario_id = ? 
            ORDER BY data_conquista DESC
        ");
        
        $stmt->execute([$usuario_id]);
        $premios = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'sucesso' => true,
            'premios' => $premios,
            'total' => count($premios)
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao buscar prêmios: ' . $e->getMessage()]);
    }
    
} else {
    echo json_encode(['erro' => 'Método não permitido']);
}
?> 