<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

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
    
    // Primeiro, verificar se a coluna publico existe
    $sql_check = "SHOW COLUMNS FROM treinos LIKE 'publico'";
    $result_check = $mysqli->query($sql_check);
    
    if ($result_check->num_rows == 0) {
        // Se a coluna não existe, criar ela
        $sql_add_column = "ALTER TABLE treinos ADD COLUMN publico ENUM('0', '1') DEFAULT '0' AFTER nome_treino";
        if (!$mysqli->query($sql_add_column)) {
            throw new Exception("Erro ao criar coluna publico: " . $mysqli->error);
        }
        
        // Atualizar treinos existentes
        $sql_update = "UPDATE treinos SET publico = '0' WHERE publico IS NULL";
        $mysqli->query($sql_update);
    }
    
    // Buscar treinos públicos
    $sql = "SELECT t.*, COUNT(e.id) as total_exercicios
            FROM treinos t
            LEFT JOIN exercicios e ON t.id = e.id_treino
            WHERE t.publico = '1'
            GROUP BY t.id
            ORDER BY t.nome_treino ASC";
    
    $result = $mysqli->query($sql);
    
    if (!$result) {
        throw new Exception("Erro na consulta: " . $mysqli->error);
    }
    
    $treinos = [];
    
    while ($row = $result->fetch_assoc()) {
        // Buscar exercícios deste treino
        $sql_exercicios = "SELECT e.*, g.nome as nome_grupo
                          FROM exercicios e
                          LEFT JOIN grupos g ON e.id_grupo = g.id
                          WHERE e.id_treino = ?
                          ORDER BY e.ordem ASC, e.id ASC";
        
        $stmt_exercicios = $mysqli->prepare($sql_exercicios);
        if (!$stmt_exercicios) {
            throw new Exception("Erro ao preparar consulta de exercícios: " . $mysqli->error);
        }
        
        $stmt_exercicios->bind_param("i", $row['id']);
        $stmt_exercicios->execute();
        $result_exercicios = $stmt_exercicios->get_result();
        
        $exercicios = [];
        while ($exercicio = $result_exercicios->fetch_assoc()) {
            $exercicios[] = [
                'id' => $exercicio['id'],
                'nome_exercicio' => $exercicio['nome_exercicio'],
                'descricao' => $exercicio['descricao'] ?? '',
                'grupo' => $exercicio['nome_grupo'] ?? '',
                'ordem' => $exercicio['ordem'] ?? 0,
                'series' => $exercicio['series'] ?? 0,
                'repeticoes' => $exercicio['repeticoes'] ?? 0,
                'tempo' => $exercicio['tempo'] ?? '',
                'peso' => $exercicio['peso'] ?? '',
                'distancia' => $exercicio['distancia'] ?? '',
            ];
        }
        
        $stmt_exercicios->close();
        
        $treinos[] = [
            'id' => $row['id'],
            'nome_treino' => $row['nome_treino'],
            'descricao' => $row['descricao'] ?? '',
            'publico' => $row['publico'],
            'total_exercicios' => (int)$row['total_exercicios'],
            'exercicios' => $exercicios,
        ];
    }
    
    // Se não há treinos públicos, criar alguns de exemplo
    if (empty($treinos)) {
        // Inserir treinos de exemplo
        $treinos_exemplo = [
            [
                'nome' => 'Treino Iniciante - Corpo Completo',
                'descricao' => 'Treino ideal para quem está começando na academia',
                'exercicios' => [
                    ['nome' => 'Agachamento Livre', 'series' => 3, 'repeticoes' => 12],
                    ['nome' => 'Flexão de Braço', 'series' => 3, 'repeticoes' => 10],
                    ['nome' => 'Remada Curvada', 'series' => 3, 'repeticoes' => 12],
                    ['nome' => 'Elevação Lateral', 'series' => 3, 'repeticoes' => 12],
                    ['nome' => 'Prancha', 'series' => 3, 'repeticoes' => 30],
                ]
            ],
            [
                'nome' => 'Treino Intermediário - Push/Pull',
                'descricao' => 'Treino focado em empurrar e puxar',
                'exercicios' => [
                    ['nome' => 'Supino Reto', 'series' => 4, 'repeticoes' => 10],
                    ['nome' => 'Desenvolvimento com Halteres', 'series' => 4, 'repeticoes' => 10],
                    ['nome' => 'Tríceps na Polia', 'series' => 3, 'repeticoes' => 12],
                    ['nome' => 'Puxada na Frente', 'series' => 4, 'repeticoes' => 10],
                    ['nome' => 'Rosca Direta', 'series' => 3, 'repeticoes' => 12],
                    ['nome' => 'Abdominal Crunch', 'series' => 3, 'repeticoes' => 15],
                ]
            ]
        ];
        
        $mysqli->autocommit(FALSE);
        
        try {
            foreach ($treinos_exemplo as $treino) {
                // Inserir treino
                $sql_treino = "INSERT INTO treinos (usuario_id, nome_treino, descricao, publico, ordem) VALUES (1, ?, ?, '1', 0)";
                $stmt = $mysqli->prepare($sql_treino);
                $stmt->bind_param("ss", $treino['nome'], $treino['descricao']);
                $stmt->execute();
                $treino_id = $mysqli->insert_id;
                $stmt->close();
                
                // Inserir exercícios
                foreach ($treino['exercicios'] as $index => $exercicio) {
                    $sql_exercicio = "INSERT INTO exercicios (id_treino, nome_exercicio, ordem, series, repeticoes) VALUES (?, ?, ?, ?, ?)";
                    $stmt = $mysqli->prepare($sql_exercicio);
                    $ordem = $index + 1;
                    $stmt->bind_param("isiii", $treino_id, $exercicio['nome'], $ordem, $exercicio['series'], $exercicio['repeticoes']);
                    $stmt->execute();
                    $stmt->close();
                }
                
                // Adicionar à lista de retorno
                $treinos[] = [
                    'id' => $treino_id,
                    'nome_treino' => $treino['nome'],
                    'descricao' => $treino['descricao'],
                    'publico' => '1',
                    'total_exercicios' => count($treino['exercicios']),
                    'exercicios' => array_map(function($ex) {
                        return [
                            'id' => 0,
                            'nome_exercicio' => $ex['nome'],
                            'descricao' => '',
                            'grupo' => '',
                            'ordem' => 0,
                            'series' => $ex['series'],
                            'repeticoes' => $ex['repeticoes'],
                            'tempo' => '',
                            'peso' => '',
                            'distancia' => '',
                        ];
                    }, $treino['exercicios']),
                ];
            }
            
            $mysqli->commit();
        } catch (Exception $e) {
            $mysqli->rollback();
            throw $e;
        } finally {
            $mysqli->autocommit(TRUE);
        }
    }
    
    echo json_encode($treinos, JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'message' => $e->getMessage(),
        'treinos' => []
    ], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($mysqli)) {
        $mysqli->close();
    }
}
?> 