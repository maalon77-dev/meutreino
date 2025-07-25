<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Configurações do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

// Conectar ao banco
$conn = new mysqli($host, $user, $pass, $db);

// Configurar charset para UTF-8
$conn->set_charset("utf8mb4");

// Verificar conexão
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        echo json_encode(['success' => false, 'message' => 'Dados inválidos']);
        exit;
    }
    
    $exercicios = $input['exercicios'] ?? [];
    
    if (empty($exercicios)) {
        echo json_encode(['success' => false, 'message' => 'Lista de exercícios não fornecida']);
        exit;
    }
    
    try {
        // Iniciar transação
        $conn->autocommit(FALSE);
        
        // Preparar statement para atualizar a ordem dos exercícios
        $stmt = $conn->prepare("UPDATE exercicios SET ordem = ? WHERE id = ?");
        
        if (!$stmt) {
            throw new Exception('Erro ao preparar consulta: ' . $conn->error);
        }
        
        foreach ($exercicios as $index => $exercicio) {
            $id = $exercicio['id'] ?? null;
            $ordem = $index + 1; // Ordem começa em 1
            
            if ($id) {
                $stmt->bind_param('ii', $ordem, $id);
                if (!$stmt->execute()) {
                    throw new Exception('Erro ao executar consulta: ' . $stmt->error);
                }
            }
        }
        
        // Confirmar transação
        $conn->commit();
        
        // Fechar statement
        $stmt->close();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Ordem dos exercícios atualizada com sucesso',
            'exercicios_atualizados' => count($exercicios)
        ]);
        
    } catch (Exception $e) {
        // Reverter transação em caso de erro
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => 'Erro ao atualizar ordem: ' . $e->getMessage()]);
    } finally {
        // Fechar conexão
        $conn->close();
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Método não permitido']);
}
?> 