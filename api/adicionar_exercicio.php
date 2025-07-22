<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuração de erro
error_reporting(0);
ini_set('display_errors', 0);

try {
    // Conectar ao banco
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    
    // Verificar conexão
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    
    // Definir charset
    $mysqli->set_charset('utf8mb4');
    
    // Pegar dados do POST
    $id_treino = intval($_POST['id_treino'] ?? 0);
    $user_id = intval($_POST['user_id'] ?? 0);
    $nome_exercicio = $_POST['nome_exercicio'] ?? '';
    $foto_exercicio = $_POST['foto_exercicio'] ?? '';
    $numero_repeticoes = $_POST['numero_repeticoes'] ?? '10';
    $peso = $_POST['peso'] ?? '0';
    $numero_series = $_POST['numero_series'] ?? '3';
    $tempo_descanso = $_POST['tempo_descanso'] ?? '60';
    $ordem = intval($_POST['ordem'] ?? 1);
    
    // Debug removido para evitar problemas
    
    // Validar dados obrigatórios
    if ($id_treino <= 0) {
        throw new Exception('ID do treino é obrigatório');
    }
    
    if ($user_id <= 0) {
        throw new Exception('ID do usuário é obrigatório');
    }
    
    if (empty($nome_exercicio)) {
        throw new Exception('Nome do exercício é obrigatório');
    }
    
    // Preparar consulta (adicionando campo 'editado' como 0 = não editado)
    $stmt = $mysqli->prepare("INSERT INTO exercicios (id_treino, user_id, nome_do_exercicio, foto_gif, numero_repeticoes, peso, numero_series, tempo_descanso, ordem, editado) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)");
    if (!$stmt) {
        throw new Exception('Erro ao preparar consulta: ' . $mysqli->error);
    }
    
    // Executar consulta
    $stmt->bind_param('iissssssi', $id_treino, $user_id, $nome_exercicio, $foto_exercicio, $numero_repeticoes, $peso, $numero_series, $tempo_descanso, $ordem);
    if (!$stmt->execute()) {
        throw new Exception('Erro ao executar consulta: ' . $stmt->error);
    }
    
    // Obter ID do exercício inserido
    $id_exercicio = $mysqli->insert_id;
    
    // Fechar conexões
    $stmt->close();
    $mysqli->close();
    
    // Retornar sucesso
    echo json_encode([
        'sucesso' => true,
        'id' => $id_exercicio,
        'mensagem' => 'Exercício adicionado com sucesso'
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'sucesso' => false,
        'erro' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?> 