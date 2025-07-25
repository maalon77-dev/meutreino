<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Configurações do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$dbname = 'academia3322';
$username = 'academia3322';
$password = 'vida1503A@';

try {
    // Conexão com o banco
    $mysqli = new mysqli($host, $username, $password, $dbname);
    
    if ($mysqli->connect_error) {
        throw new Exception("Erro de conexão: " . $mysqli->connect_error);
    }
    
    $mysqli->set_charset("utf8mb4");
    
    // 1. Buscar um exercício do treino 211
    $sql_buscar = "SELECT * FROM exercicios WHERE id_treino = 211 LIMIT 1";
    $result_buscar = $mysqli->query($sql_buscar);
    $exercicio_original = $result_buscar->fetch_assoc();
    
    if (!$exercicio_original) {
        throw new Exception("Nenhum exercício encontrado no treino 211");
    }
    
    // 2. Criar um treino de teste
    $sql_criar_treino = "INSERT INTO treinos (usuario_id, nome_treino, publico, ordem) VALUES (1, 'TESTE FOTO GIF', '0', 999)";
    $mysqli->query($sql_criar_treino);
    $treino_teste_id = $mysqli->insert_id;
    
    // 3. Testar duplicação com todos os campos
    $sql_duplicar = "INSERT INTO exercicios (
        id_treino, 
        user_id, 
        nome_do_exercicio, 
        foto_gif, 
        numero_repeticoes, 
        peso, 
        numero_series, 
        tempo_descanso, 
        ordem, 
        editado,
        distancia,
        link_video,
        descricao,
        categoria,
        musculos,
        tempo_exercicio,
        foto_principal_fem,
        foto_principal_masc
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    $stmt = $mysqli->prepare($sql_duplicar);
    $stmt->bind_param(
        "iissssssiidsssssss",
        $treino_teste_id,
        1, // user_id
        $exercicio_original['nome_do_exercicio'] ?? '',
        $exercicio_original['foto_gif'] ?? '',
        $exercicio_original['numero_repeticoes'] ?? '10',
        $exercicio_original['peso'] ?? '0',
        $exercicio_original['numero_series'] ?? '3',
        $exercicio_original['tempo_descanso'] ?? '60',
        $exercicio_original['ordem'] ?? 1,
        0, // editado
        $exercicio_original['distancia'] ?? 0.00,
        $exercicio_original['link_video'] ?? '',
        $exercicio_original['descricao'] ?? '',
        $exercicio_original['categoria'] ?? '',
        $exercicio_original['musculos'] ?? '',
        $exercicio_original['tempo_exercicio'] ?? '',
        $exercicio_original['foto_principal_fem'] ?? '',
        $exercicio_original['foto_principal_masc'] ?? ''
    );
    
    $stmt->execute();
    $exercicio_duplicado_id = $mysqli->insert_id;
    $stmt->close();
    
    // 4. Verificar o exercício duplicado
    $sql_verificar = "SELECT * FROM exercicios WHERE id = ?";
    $stmt_verificar = $mysqli->prepare($sql_verificar);
    $stmt_verificar->bind_param("i", $exercicio_duplicado_id);
    $stmt_verificar->execute();
    $result_verificar = $stmt_verificar->get_result();
    $exercicio_duplicado = $result_verificar->fetch_assoc();
    $stmt_verificar->close();
    
    // 5. Limpar dados de teste
    $mysqli->query("DELETE FROM exercicios WHERE id = $exercicio_duplicado_id");
    $mysqli->query("DELETE FROM treinos WHERE id = $treino_teste_id");
    
    echo json_encode([
        'success' => true,
        'exercicio_original' => [
            'id' => $exercicio_original['id'],
            'nome_do_exercicio' => $exercicio_original['nome_do_exercicio'],
            'foto_gif' => $exercicio_original['foto_gif'],
            'link_video' => $exercicio_original['link_video'],
            'descricao' => $exercicio_original['descricao']
        ],
        'exercicio_duplicado' => [
            'id' => $exercicio_duplicado['id'],
            'nome_do_exercicio' => $exercicio_duplicado['nome_do_exercicio'],
            'foto_gif' => $exercicio_duplicado['foto_gif'],
            'link_video' => $exercicio_duplicado['link_video'],
            'descricao' => $exercicio_duplicado['descricao']
        ],
        'campos_iguais' => [
            'nome_do_exercicio' => $exercicio_original['nome_do_exercicio'] === $exercicio_duplicado['nome_do_exercicio'],
            'foto_gif' => $exercicio_original['foto_gif'] === $exercicio_duplicado['foto_gif'],
            'link_video' => $exercicio_original['link_video'] === $exercicio_duplicado['link_video'],
            'descricao' => $exercicio_original['descricao'] === $exercicio_duplicado['descricao']
        ]
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($mysqli)) {
        $mysqli->close();
    }
}
?> 