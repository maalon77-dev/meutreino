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

// Verificar se a tabela metas existe, se não, criar
try {
    $sql = "CREATE TABLE IF NOT EXISTS metas (
        id VARCHAR(36) PRIMARY KEY,
        usuario_id INT NOT NULL,
        nome VARCHAR(255) NOT NULL,
        tipo ENUM('peso', 'distancia', 'repeticoes', 'frequencia', 'carga', 'medidas') NOT NULL,
        valor_inicial DECIMAL(10,2) NOT NULL,
        valor_desejado DECIMAL(10,2) NOT NULL,
        valor_atual DECIMAL(10,2) NOT NULL DEFAULT 0,
        prazo DATE NULL,
        data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
        concluida BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
    )";
    $pdo->exec($sql);
    
    // Criar tabela de progresso das metas
    $sql = "CREATE TABLE IF NOT EXISTS progresso_metas (
        id INT AUTO_INCREMENT PRIMARY KEY,
        meta_id VARCHAR(36) NOT NULL,
        valor DECIMAL(10,2) NOT NULL,
        observacao TEXT NULL,
        data_progresso DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meta_id) REFERENCES metas(id) ON DELETE CASCADE
    )";
    $pdo->exec($sql);
    
} catch(PDOException $e) {
    echo json_encode(['erro' => 'Erro ao criar tabelas: ' . $e->getMessage()]);
    exit;
}

$acao = $_GET['acao'] ?? '';

switch($acao) {
    case 'criar_meta':
        criarMeta($pdo);
        break;
    case 'listar_metas':
        listarMetas($pdo);
        break;
    case 'atualizar_progresso':
        atualizarProgresso($pdo);
        break;
    case 'excluir_meta':
        excluirMeta($pdo);
        break;
    case 'marcar_concluida':
        marcarConcluida($pdo);
        break;
    default:
        echo json_encode(['erro' => 'Ação não especificada']);
}

function criarMeta($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['usuario_id']) || !isset($data['nome']) || !isset($data['tipo']) || 
        !isset($data['valor_inicial']) || !isset($data['valor_desejado'])) {
        echo json_encode(['erro' => 'Dados incompletos']);
        return;
    }
    
    try {
        $sql = "INSERT INTO metas (id, usuario_id, nome, tipo, valor_inicial, valor_desejado, valor_atual, prazo) 
                VALUES (:id, :usuario_id, :nome, :tipo, :valor_inicial, :valor_desejado, :valor_inicial, :prazo)";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':id' => $data['id'],
            ':usuario_id' => $data['usuario_id'],
            ':nome' => $data['nome'],
            ':tipo' => $data['tipo'],
            ':valor_inicial' => $data['valor_inicial'],
            ':valor_desejado' => $data['valor_desejado'],
            ':prazo' => $data['prazo'] ?? null
        ]);
        
        echo json_encode(['sucesso' => true, 'message' => 'Meta criada com sucesso']);
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao criar meta: ' . $e->getMessage()]);
    }
}

function listarMetas($pdo) {
    $usuario_id = $_GET['usuario_id'] ?? null;
    
    if (!$usuario_id) {
        echo json_encode(['erro' => 'ID do usuário não fornecido']);
        return;
    }
    
    try {
        $sql = "SELECT m.*, 
                       (SELECT COUNT(*) FROM progresso_metas WHERE meta_id = m.id) as total_progressos
                FROM metas m 
                WHERE m.usuario_id = :usuario_id 
                ORDER BY m.data_criacao DESC";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':usuario_id' => $usuario_id]);
        $metas = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Buscar progressos para cada meta
        foreach ($metas as &$meta) {
            $sql_progresso = "SELECT * FROM progresso_metas 
                             WHERE meta_id = :meta_id 
                             ORDER BY data_progresso DESC";
            $stmt_progresso = $pdo->prepare($sql_progresso);
            $stmt_progresso->execute([':meta_id' => $meta['id']]);
            $meta['progressos'] = $stmt_progresso->fetchAll(PDO::FETCH_ASSOC);
        }
        
        echo json_encode(['sucesso' => true, 'metas' => $metas]);
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao listar metas: ' . $e->getMessage()]);
    }
}

function atualizarProgresso($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['meta_id']) || !isset($data['valor'])) {
        echo json_encode(['erro' => 'Dados incompletos']);
        return;
    }
    
    try {
        $pdo->beginTransaction();
        
        // Inserir novo progresso
        $sql_progresso = "INSERT INTO progresso_metas (meta_id, valor, observacao) 
                         VALUES (:meta_id, :valor, :observacao)";
        $stmt = $pdo->prepare($sql_progresso);
        $stmt->execute([
            ':meta_id' => $data['meta_id'],
            ':valor' => $data['valor'],
            ':observacao' => $data['observacao'] ?? null
        ]);
        
        // Atualizar valor atual da meta
        $sql_meta = "UPDATE metas SET valor_atual = :valor WHERE id = :meta_id";
        $stmt = $pdo->prepare($sql_meta);
        $stmt->execute([
            ':valor' => $data['valor'],
            ':meta_id' => $data['meta_id']
        ]);
        
        $pdo->commit();
        echo json_encode(['sucesso' => true, 'message' => 'Progresso atualizado com sucesso']);
    } catch(PDOException $e) {
        $pdo->rollback();
        echo json_encode(['erro' => 'Erro ao atualizar progresso: ' . $e->getMessage()]);
    }
}

function excluirMeta($pdo) {
    $meta_id = $_GET['meta_id'] ?? null;
    
    if (!$meta_id) {
        echo json_encode(['erro' => 'ID da meta não fornecido']);
        return;
    }
    
    try {
        $sql = "DELETE FROM metas WHERE id = :meta_id";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':meta_id' => $meta_id]);
        
        echo json_encode(['sucesso' => true, 'message' => 'Meta excluída com sucesso']);
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao excluir meta: ' . $e->getMessage()]);
    }
}

function marcarConcluida($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['meta_id'])) {
        echo json_encode(['erro' => 'ID da meta não fornecido']);
        return;
    }
    
    try {
        $sql = "UPDATE metas SET concluida = :concluida WHERE id = :meta_id";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':concluida' => $data['concluida'] ?? true,
            ':meta_id' => $data['meta_id']
        ]);
        
        echo json_encode(['sucesso' => true, 'message' => 'Status da meta atualizado']);
    } catch(PDOException $e) {
        echo json_encode(['erro' => 'Erro ao atualizar meta: ' . $e->getMessage()]);
    }
}
?> 