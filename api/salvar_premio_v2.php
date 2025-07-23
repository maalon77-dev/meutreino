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
    $raw_input = file_get_contents('php://input');
    error_log("=== SALVAR PREMIO ===");
    error_log("Raw input: $raw_input");
    
    $input = json_decode($raw_input, true);
    
    if (!$input) {
        error_log("Erro: Dados inválidos - JSON decode falhou");
        echo json_encode(['erro' => 'Dados inválidos']);
        exit;
    }
    
    error_log("Input decodificado: " . print_r($input, true));
    
    $usuario_id = $input['usuario_id'] ?? null;
    $nome_animal = $input['nome_animal'] ?? null;
    $emoji_animal = $input['emoji_animal'] ?? null;
    $peso_animal = $input['peso_animal'] ?? null;
    $peso_total_levantado = $input['peso_total_levantado'] ?? null;
    $data_conquista = $input['data_conquista'] ?? null;
    $nome_treino = $input['nome_treino'] ?? null;
    
    error_log("Dados extraídos:");
    error_log("usuario_id: $usuario_id");
    error_log("nome_animal: $nome_animal");
    error_log("emoji_animal: $emoji_animal");
    error_log("peso_animal: $peso_animal");
    error_log("peso_total_levantado: $peso_total_levantado");
    error_log("data_conquista: $data_conquista");
    error_log("nome_treino: $nome_treino");
    
    // Campo para tipo de conquista (simplificado)
    $tipo_conquista = $input['tipo_conquista'] ?? 'treino'; // 'treino' ou 'meta'
    
    // Validação simplificada
    if (!$usuario_id || !$nome_animal) {
        echo json_encode(['erro' => 'Dados obrigatórios não fornecidos (usuario_id e nome_animal são obrigatórios)']);
        exit;
    }
    // Para treinos, peso_animal e peso_total_levantado podem ser 0 (caso da Águia)
    if ($peso_animal === null) $peso_animal = 0.0;
    if ($peso_total_levantado === null) $peso_total_levantado = 0.0;
    
    try {
        // Verificar se a tabela existe, se não, criar com estrutura simples
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS premios_conquistados (
                id INT AUTO_INCREMENT PRIMARY KEY,
                usuario_id INT NOT NULL,
                nome_animal VARCHAR(100) NOT NULL,
                emoji_animal VARCHAR(10) NOT NULL,
                peso_animal DECIMAL(10,2) NULL,
                peso_total_levantado DECIMAL(10,2) NULL,
                data_conquista DATETIME NOT NULL,
                nome_treino VARCHAR(100) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ");
        
        // Inserir o prêmio (apenas campos que existem na tabela atual)
        $query = "INSERT INTO premios_conquistados 
            (usuario_id, nome_animal, emoji_animal, peso_animal, peso_total_levantado, data_conquista, nome_treino) 
            VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        error_log("Query: $query");
        
        $stmt = $pdo->prepare($query);
        
        $params = [
            $usuario_id,
            $nome_animal,
            $emoji_animal,
            $peso_animal,
            $peso_total_levantado,
            $data_conquista ?: date('Y-m-d H:i:s'),
            $nome_treino
        ];
        
        error_log("Parâmetros: " . print_r($params, true));
        
        $stmt->execute($params);
        
        $id = $pdo->lastInsertId();
        
        error_log("Prêmio salvo com sucesso. ID: $id");
        
        echo json_encode([
            'sucesso' => true,
            'message' => 'Prêmio salvo com sucesso',
            'id' => $id
        ]);
        
    } catch(PDOException $e) {
        error_log("Erro PDO ao salvar prêmio: " . $e->getMessage());
        echo json_encode(['erro' => 'Erro ao salvar prêmio: ' . $e->getMessage()]);
    } catch(Exception $e) {
        error_log("Erro geral ao salvar prêmio: " . $e->getMessage());
        echo json_encode(['erro' => 'Erro geral ao salvar prêmio: ' . $e->getMessage()]);
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