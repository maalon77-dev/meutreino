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
    
    // Buscar exercícios do treino 211 (ou outro treino que você queira testar)
    $treino_id = 211; // Altere para o ID do treino que você quer testar
    
    $sql_buscar = "SELECT * FROM exercicios WHERE id_treino = ? ORDER BY ordem ASC, id ASC";
    $stmt = $mysqli->prepare($sql_buscar);
    $stmt->bind_param("i", $treino_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $exercicios = [];
    while ($exercicio = $result->fetch_assoc()) {
        $exercicios[] = [
            'id' => $exercicio['id'],
            'nome_do_exercicio' => $exercicio['nome_do_exercicio'],
            'foto_gif' => $exercicio['foto_gif'],
            'link_video' => $exercicio['link_video'],
            'descricao' => $exercicio['descricao'],
            'categoria' => $exercicio['categoria'],
            'musculos' => $exercicio['musculos'],
            'numero_series' => $exercicio['numero_series'],
            'tempo_descanso' => $exercicio['tempo_descanso'],
            'ordem' => $exercicio['ordem'],
            'foto_principal_fem' => $exercicio['foto_principal_fem'],
            'foto_principal_masc' => $exercicio['foto_principal_masc'],
            'tempo_exercicio' => $exercicio['tempo_exercicio'],
            'distancia' => $exercicio['distancia'],
            'peso' => $exercicio['peso'],
            'numero_repeticoes' => $exercicio['numero_repeticoes'],
            'editado' => $exercicio['editado']
        ];
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'treino_id' => $treino_id,
        'total_exercicios' => count($exercicios),
        'exercicios' => $exercicios
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