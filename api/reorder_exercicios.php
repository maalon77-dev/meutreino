<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['exercicios']) || !is_array($input['exercicios'])) {
        http_response_code(400);
        echo json_encode(['erro' => 'Lista de exercícios inválida']);
        exit;
    }

    try {
        // Usar as mesmas configurações do banco remoto
        $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
        
        // Verificar conexão
        if ($mysqli->connect_error) {
            throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
        }
        
        // Definir charset
        $mysqli->set_charset('utf8mb4');
        
        // Iniciar transação
        $mysqli->autocommit(FALSE);
        
        // Preparar statement
        $stmt = $mysqli->prepare("UPDATE exercicios SET ordem = ? WHERE id = ?");
        if (!$stmt) {
            throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
        }
        
        foreach ($input['exercicios'] as $index => $exercicio) {
            $ordem = $index + 1;
            $stmt->bind_param('ii', $ordem, $exercicio['id']);
            
            if (!$stmt->execute()) {
                throw new Exception('Erro ao executar consulta: ' . $stmt->error);
            }
        }
        
        // Confirmar transação
        $mysqli->commit();
        
        // Fechar conexões
        $stmt->close();
        $mysqli->close();
        
        echo json_encode(['sucesso' => true]);
        
    } catch (Exception $e) {
        // Reverter transação em caso de erro
        if (isset($mysqli)) {
            $mysqli->rollback();
            $mysqli->close();
        }
        
        error_log("Erro ao reordenar exercícios: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['erro' => 'Erro interno do servidor: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['erro' => 'Método não permitido']);
}
?> 