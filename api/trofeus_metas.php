<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Configuração do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$dbname = 'academia3322';
$username = 'academia3322';
$password = 'vida1503A@';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $e->getMessage()]);
    exit;
}

// Verificar se a tabela trofeus_metas existe, se não, criar
try {
    $sql = "CREATE TABLE IF NOT EXISTS trofeus_metas (
        id INT AUTO_INCREMENT PRIMARY KEY,
        usuario_id INT NOT NULL,
        meta_id VARCHAR(36) NOT NULL,
        nome_meta VARCHAR(255) NOT NULL,
        trofeu_id VARCHAR(50) NOT NULL,
        nome_trofeu VARCHAR(255) NOT NULL,
        emoji_trofeu VARCHAR(10) NOT NULL,
        descricao_trofeu TEXT NOT NULL,
        categoria_trofeu VARCHAR(50) NOT NULL,
        raridade_trofeu INT NOT NULL,
        mensagem_motivacional TEXT NOT NULL,
        data_conquista DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
    )";
    $pdo->exec($sql);
    
} catch(PDOException $e) {
    echo json_encode(['erro' => 'Erro ao criar tabela: ' . $e->getMessage()]);
    exit;
}

$acao = $_GET['acao'] ?? '';

switch($acao) {
    case 'conceder_trofeu':
        concederTrofeu($pdo);
        break;
    case 'listar_trofeus':
        listarTrofeus($pdo);
        break;
    default:
        echo json_encode(['erro' => 'Ação não especificada']);
}

function concederTrofeu($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['usuario_id']) || !isset($data['meta_id']) || !isset($data['nome_meta']) || 
        !isset($data['trofeu_id']) || !isset($data['nome_trofeu'])) {
        echo json_encode(['erro' => 'Dados incompletos']);
        return;
    }
    
    try {
        // Verificar se já existe um troféu para esta meta
        $sql_check = "SELECT id FROM trofeus_metas WHERE meta_id = :meta_id AND usuario_id = :usuario_id";
        $stmt_check = $pdo->prepare($sql_check);
        $stmt_check->execute([
            ':meta_id' => $data['meta_id'],
            ':usuario_id' => $data['usuario_id']
        ]);
        
        if ($stmt_check->fetch()) {
            echo json_encode(['erro' => 'Troféu já concedido para esta meta']);
            return;
        }
        
        // Inserir novo troféu
        $sql = "INSERT INTO trofeus_metas (
                    usuario_id, meta_id, nome_meta, trofeu_id, nome_trofeu, 
                    emoji_trofeu, descricao_trofeu, categoria_trofeu, 
                    raridade_trofeu, mensagem_motivacional
                ) VALUES (
                    :usuario_id, :meta_id, :nome_meta, :trofeu_id, :nome_trofeu,
                    :emoji_trofeu, :descricao_trofeu, :categoria_trofeu,
                    :raridade_trofeu, :mensagem_motivacional
                )";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':usuario_id' => $data['usuario_id'],
            ':meta_id' => $data['meta_id'],
            ':nome_meta' => $data['nome_meta'],
            ':trofeu_id' => $data['trofeu_id'],
            ':nome_trofeu' => $data['nome_trofeu'],
            ':emoji_trofeu' => $data['emoji_trofeu'],
            ':descricao_trofeu' => $data['descricao_trofeu'],
            ':categoria_trofeu' => $data['categoria_trofeu'],
            ':raridade_trofeu' => $data['raridade_trofeu'],
            ':mensagem_motivacional' => $data['mensagem_motivacional']
        ]);
        
        echo json_encode([
            'sucesso' => true, 
            'message' => 'Troféu concedido com sucesso!',
            'trofeu' => [
                'nome' => $data['nome_trofeu'],
                'emoji' => $data['emoji_trofeu'],
                'raridade' => $data['raridade_trofeu'],
                'mensagem' => $data['mensagem_motivacional']
            ]
        ]);
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao conceder troféu: ' . $e->getMessage()]);
    }
}

function listarTrofeus($pdo) {
    $usuario_id = $_GET['usuario_id'] ?? null;
    
    if (!$usuario_id) {
        echo json_encode(['erro' => 'ID do usuário não fornecido']);
        return;
    }
    
    try {
        $sql = "SELECT * FROM trofeus_metas 
                WHERE usuario_id = :usuario_id 
                ORDER BY data_conquista DESC";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':usuario_id' => $usuario_id]);
        $trofeus = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(['sucesso' => true, 'trofeus' => $trofeus]);
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao listar troféus: ' . $e->getMessage()]);
    }
}
?> 