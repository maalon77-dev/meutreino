<?php
header('Content-Type: application/json; charset=utf-8');

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
    
    // Iniciar transação
    $mysqli->autocommit(FALSE);
    
    try {
        // Treinos prontos de exemplo
        $treinos_prontos = [
            [
                'nome' => 'Treino Iniciante - Corpo Completo',
                'descricao' => 'Treino ideal para quem está começando na academia',
                'exercicios' => [
                    ['nome' => 'Agachamento Livre', 'series' => 3, 'repeticoes' => 12, 'grupo' => 'Pernas'],
                    ['nome' => 'Flexão de Braço', 'series' => 3, 'repeticoes' => 10, 'grupo' => 'Peito'],
                    ['nome' => 'Remada Curvada', 'series' => 3, 'repeticoes' => 12, 'grupo' => 'Costas'],
                    ['nome' => 'Elevação Lateral', 'series' => 3, 'repeticoes' => 12, 'grupo' => 'Ombros'],
                    ['nome' => 'Prancha', 'series' => 3, 'repeticoes' => 30, 'grupo' => 'Abdômen'],
                ]
            ],
            [
                'nome' => 'Treino Intermediário - Push/Pull',
                'descricao' => 'Treino focado em empurrar e puxar',
                'exercicios' => [
                    ['nome' => 'Supino Reto', 'series' => 4, 'repeticoes' => 10, 'grupo' => 'Peito'],
                    ['nome' => 'Desenvolvimento com Halteres', 'series' => 4, 'repeticoes' => 10, 'grupo' => 'Ombros'],
                    ['nome' => 'Tríceps na Polia', 'series' => 3, 'repeticoes' => 12, 'grupo' => 'Tríceps'],
                    ['nome' => 'Puxada na Frente', 'series' => 4, 'repeticoes' => 10, 'grupo' => 'Costas'],
                    ['nome' => 'Rosca Direta', 'series' => 3, 'repeticoes' => 12, 'grupo' => 'Bíceps'],
                    ['nome' => 'Abdominal Crunch', 'series' => 3, 'repeticoes' => 15, 'grupo' => 'Abdômen'],
                ]
            ],
            [
                'nome' => 'Treino Avançado - Hipertrofia',
                'descricao' => 'Treino focado em ganho de massa muscular',
                'exercicios' => [
                    ['nome' => 'Leg Press', 'series' => 4, 'repeticoes' => 12, 'grupo' => 'Pernas'],
                    ['nome' => 'Agachamento com Barra', 'series' => 4, 'repeticoes' => 8, 'grupo' => 'Pernas'],
                    ['nome' => 'Extensão de Pernas', 'series' => 3, 'repeticoes' => 15, 'grupo' => 'Pernas'],
                    ['nome' => 'Flexão de Pernas', 'series' => 3, 'repeticoes' => 15, 'grupo' => 'Pernas'],
                    ['nome' => 'Elevação de Panturrilha', 'series' => 4, 'repeticoes' => 20, 'grupo' => 'Pernas'],
                ]
            ],
            [
                'nome' => 'Treino Cardio - Queima de Gordura',
                'descricao' => 'Treino focado em queima de gordura e condicionamento',
                'exercicios' => [
                    ['nome' => 'Burpee', 'series' => 3, 'repeticoes' => 10, 'grupo' => 'Cardio'],
                    ['nome' => 'Mountain Climber', 'series' => 3, 'repeticoes' => 20, 'grupo' => 'Cardio'],
                    ['nome' => 'Jumping Jack', 'series' => 3, 'repeticoes' => 30, 'grupo' => 'Cardio'],
                    ['nome' => 'Polichinelo', 'series' => 3, 'repeticoes' => 25, 'grupo' => 'Cardio'],
                    ['nome' => 'Corrida no Local', 'series' => 3, 'repeticoes' => 60, 'grupo' => 'Cardio'],
                ]
            ]
        ];
        
        foreach ($treinos_prontos as $treino) {
            // Inserir treino
            $sql_treino = "INSERT INTO treinos (usuario_id, nome_treino, descricao, publico, ordem) VALUES (1, ?, ?, '1', 0)";
            $stmt_treino = $mysqli->prepare($sql_treino);
            $stmt_treino->bind_param("ss", $treino['nome'], $treino['descricao']);
            
            if (!$stmt_treino->execute()) {
                throw new Exception("Erro ao inserir treino: " . $stmt_treino->error);
            }
            
            $treino_id = $mysqli->insert_id;
            $stmt_treino->close();
            
            // Inserir exercícios
            foreach ($treino['exercicios'] as $index => $exercicio) {
                // Buscar grupo muscular
                $sql_grupo = "SELECT id FROM grupos WHERE nome LIKE ? LIMIT 1";
                $stmt_grupo = $mysqli->prepare($sql_grupo);
                $grupo_nome = "%" . $exercicio['grupo'] . "%";
                $stmt_grupo->bind_param("s", $grupo_nome);
                $stmt_grupo->execute();
                $result_grupo = $stmt_grupo->get_result();
                $grupo_id = 1; // Default
                if ($row = $result_grupo->fetch_assoc()) {
                    $grupo_id = $row['id'];
                }
                $stmt_grupo->close();
                
                // Inserir exercício
                $sql_exercicio = "INSERT INTO exercicios (id_treino, nome_exercicio, id_grupo, ordem, series, repeticoes) VALUES (?, ?, ?, ?, ?, ?)";
                $stmt_exercicio = $mysqli->prepare($sql_exercicio);
                $ordem = $index + 1;
                $stmt_exercicio->bind_param("isiiii", $treino_id, $exercicio['nome'], $grupo_id, $ordem, $exercicio['series'], $exercicio['repeticoes']);
                
                if (!$stmt_exercicio->execute()) {
                    throw new Exception("Erro ao inserir exercício: " . $stmt_exercicio->error);
                }
                
                $stmt_exercicio->close();
            }
        }
        
        // Commit da transação
        $mysqli->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Treinos prontos inseridos com sucesso'
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