<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

try {
    // Conectar ao banco
    $conn = new mysqli($host, $user, $pass, $db);
    
    // Configurar charset para UTF-8
    $conn->set_charset("utf8mb4");
    
    // Verificar conexão
    if ($conn->connect_error) {
        throw new Exception('Erro de conexão: ' . $conn->connect_error);
    }
    
    // Buscar todos os registros com problemas de codificação
    $sql = "SELECT id, categoria FROM exercicios WHERE categoria LIKE '%Ã§Ã£o%' OR categoria LIKE '%Ã£o%'";
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception('Erro na consulta: ' . $conn->error);
    }
    
    $corrigidos = 0;
    $erros = [];
    
    while ($row = $result->fetch_assoc()) {
        $id = $row['id'];
        $categoria_antiga = $row['categoria'];
        
        // Corrigir caracteres especiais
        $categoria_nova = str_replace(
            ['Ã§Ã£o', 'Ã£o', 'Ã§', 'Ã£', 'Ã¡', 'Ã­', 'Ã³', 'Ãº', 'Ã©'],
            ['ção', 'ão', 'ç', 'ã', 'á', 'í', 'ó', 'ú', 'é'],
            $categoria_antiga
        );
        
        // Se houve mudança, atualizar o banco
        if ($categoria_nova !== $categoria_antiga) {
            $stmt = $conn->prepare("UPDATE exercicios SET categoria = ? WHERE id = ?");
            if ($stmt) {
                $stmt->bind_param('si', $categoria_nova, $id);
                if ($stmt->execute()) {
                    $corrigidos++;
                } else {
                    $erros[] = "Erro ao atualizar ID $id: " . $stmt->error;
                }
                $stmt->close();
            } else {
                $erros[] = "Erro ao preparar update para ID $id: " . $conn->error;
            }
        }
    }
    
    $conn->close();
    
    echo json_encode([
        'sucesso' => true,
        'corrigidos' => $corrigidos,
        'erros' => $erros,
        'mensagem' => "Correção concluída. $corrigidos registros corrigidos."
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'sucesso' => false,
        'erro' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?> 