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
        // 1. Verificar se o treino original existe e é público
        $sql_verificar = "SELECT id, nome_treino FROM treinos WHERE id = ? AND publico = '1'";
        $stmt_verificar = $mysqli->prepare($sql_verificar);
        $stmt_verificar->bind_param("i", $treinoOriginalId);
        $stmt_verificar->execute();
        $result_verificar = $stmt_verificar->get_result();
        
        if ($result_verificar->num_rows == 0) {
            throw new Exception("Treino não encontrado ou não é público");
        }
        
        $treino_original = $result_verificar->fetch_assoc();
        $stmt_verificar->close();
        
        // 2. Buscar a próxima ordem para o usuário
        $sql_ordem = "SELECT COALESCE(MAX(ordem), 0) + 1 as proxima_ordem FROM treinos WHERE usuario_id = ?";
        $stmt_ordem = $mysqli->prepare($sql_ordem);
        $stmt_ordem->bind_param("i", $usuarioId);
        $stmt_ordem->execute();
        $result_ordem = $stmt_ordem->get_result();
        $ordem = $result_ordem->fetch_assoc()['proxima_ordem'];
        $stmt_ordem->close();
        
        // 3. Criar novo treino para o usuário
        $sql_criar_treino = "INSERT INTO treinos (usuario_id, nome_treino, publico, ordem) VALUES (?, ?, '0', ?)";
        $stmt_criar_treino = $mysqli->prepare($sql_criar_treino);
        $stmt_criar_treino->bind_param("isi", $usuarioId, $nomeTreino, $ordem);
        
        if (!$stmt_criar_treino->execute()) {
            throw new Exception("Erro ao criar treino: " . $stmt_criar_treino->error);
        }
        
        $novoTreinoId = $mysqli->insert_id;
        $stmt_criar_treino->close();
        
        // 4. Buscar exercícios do treino original
        $sql_buscar_exercicios = "SELECT * FROM exercicios WHERE id_treino = ? ORDER BY ordem ASC, id ASC";
        $stmt_buscar_exercicios = $mysqli->prepare($sql_buscar_exercicios);
        $stmt_buscar_exercicios->bind_param("i", $treinoOriginalId);
        $stmt_buscar_exercicios->execute();
        $result_exercicios = $stmt_buscar_exercicios->get_result();
        
        $exercicios_duplicados = 0;
        
        // 5. Duplicar exercícios
        while ($exercicio = $result_exercicios->fetch_assoc()) {
            $sql_duplicar_exercicio = "INSERT INTO exercicios (
                id_treino, nome_exercicio, descricao, id_grupo, ordem, 
                series, repeticoes, tempo, peso, distancia, 
                observacoes, video_url, imagem_url, categoria
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            $stmt_duplicar_exercicio = $mysqli->prepare($sql_duplicar_exercicio);
            $stmt_duplicar_exercicio->bind_param(
                "issiiissssssss",
                $novoTreinoId,
                $exercicio['nome_exercicio'],
                $exercicio['descricao'],
                $exercicio['id_grupo'],
                $exercicio['ordem'],
                $exercicio['series'],
                $exercicio['repeticoes'],
                $exercicio['tempo'],
                $exercicio['peso'],
                $exercicio['distancia'],
                $exercicio['observacoes'],
                $exercicio['video_url'],
                $exercicio['imagem_url'],
                $exercicio['categoria']
            );
            
            if (!$stmt_duplicar_exercicio->execute()) {
                throw new Exception("Erro ao duplicar exercício: " . $stmt_duplicar_exercicio->error);
            }
            
            $exercicios_duplicados++;
            $stmt_duplicar_exercicio->close();
        }
        
        $stmt_buscar_exercicios->close();
        
        // Commit da transação
        $mysqli->commit();
        
        echo json_encode([
            'success' => true,
            'message' => "Treino duplicado com sucesso! $exercicios_duplicados exercícios copiados.",
            'novo_treino_id' => $novoTreinoId,
            'exercicios_duplicados' => $exercicios_duplicados
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