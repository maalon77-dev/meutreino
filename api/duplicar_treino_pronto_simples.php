<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => true, 'message' => 'Método não permitido']);
    exit;
}

// Configurações do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$dbname = 'academia3322';
$username = 'academia3322';
$password = 'vida1503A@';

try {
    // Obter dados do POST
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Dados inválidos');
    }
    
    $usuarioId = $input['usuario_id'] ?? null;
    $treinoOriginalId = $input['treino_original_id'] ?? null;
    $nomeTreino = $input['nome_treino'] ?? null;
    
    if (!$usuarioId || !$treinoOriginalId || !$nomeTreino) {
        throw new Exception('Dados obrigatórios não fornecidos');
    }
    
    // Conexão com o banco
    $mysqli = new mysqli($host, $username, $password, $dbname);
    
    if ($mysqli->connect_error) {
        throw new Exception("Erro de conexão: " . $mysqli->connect_error);
    }
    
    $mysqli->set_charset("utf8mb4");
    
    // Iniciar transação
    $mysqli->autocommit(FALSE);
    
    try {
        // 1. Criar novo treino para o usuário
        $sql_criar_treino = "INSERT INTO treinos (usuario_id, nome_treino, publico, ordem) VALUES (?, ?, '0', (SELECT COALESCE(MAX(ordem), 0) + 1 FROM treinos t2 WHERE t2.usuario_id = ?))";
        $stmt_criar_treino = $mysqli->prepare($sql_criar_treino);
        $stmt_criar_treino->bind_param("isi", $usuarioId, $nomeTreino, $usuarioId);
        
        if (!$stmt_criar_treino->execute()) {
            throw new Exception("Erro ao criar treino: " . $stmt_criar_treino->error);
        }
        
        $novoTreinoId = $mysqli->insert_id;
        $stmt_criar_treino->close();
        
        // 2. Buscar exercícios do treino original
        $sql_buscar_exercicios = "SELECT * FROM exercicios WHERE id_treino = ? ORDER BY ordem ASC, id ASC";
        $stmt_buscar_exercicios = $mysqli->prepare($sql_buscar_exercicios);
        $stmt_buscar_exercicios->bind_param("i", $treinoOriginalId);
        $stmt_buscar_exercicios->execute();
        $result_exercicios = $stmt_buscar_exercicios->get_result();
        
        // 3. Duplicar exercícios
        $sql_duplicar_exercicio = "INSERT INTO exercicios (id_treino, nome_exercicio, ordem, series, repeticoes) VALUES (?, ?, ?, ?, ?)";
        $stmt_duplicar_exercicio = $mysqli->prepare($sql_duplicar_exercicio);
        
        while ($exercicio = $result_exercicios->fetch_assoc()) {
            $stmt_duplicar_exercicio->bind_param(
                "isiii",
                $novoTreinoId,
                $exercicio['nome_exercicio'],
                $exercicio['ordem'],
                $exercicio['series'],
                $exercicio['repeticoes']
            );
            
            if (!$stmt_duplicar_exercicio->execute()) {
                throw new Exception("Erro ao duplicar exercício: " . $stmt_duplicar_exercicio->error);
            }
        }
        
        $stmt_buscar_exercicios->close();
        $stmt_duplicar_exercicio->close();
        
        // Commit da transação
        $mysqli->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Treino duplicado com sucesso',
            'novo_treino_id' => $novoTreinoId
        ], JSON_UNESCAPED_UNICODE);
        
    } catch (Exception $e) {
        // Rollback em caso de erro
        $mysqli->rollback();
        throw $e;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($mysqli)) {
        $mysqli->autocommit(TRUE);
        $mysqli->close();
    }
}
?> 