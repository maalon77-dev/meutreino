<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Configurações do banco
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
    echo json_encode(['erro' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}
    
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            echo json_encode(['sucesso' => false, 'erro' => 'Dados inválidos']);
            exit;
        }
        
        $usuario_id = $data['usuario_id'] ?? null;
        $exercicio_id = $data['exercicio_id'] ?? null;
        $nome_exercicio = $data['nome_exercicio'] ?? '';
        $categoria = $data['categoria'] ?? '';
        $peso_anterior = $data['peso_anterior'] ?? 0;
        $peso_novo = $data['peso_novo'] ?? 0;
        $repeticoes_anteriores = $data['repeticoes_anteriores'] ?? 0;
        $repeticoes_novas = $data['repeticoes_novas'] ?? 0;
        $series_anteriores = $data['series_anteriores'] ?? 0;
        $series_novas = $data['series_novas'] ?? 0;
        $duracao_anterior = $data['duracao_anterior'] ?? 0;
        $duracao_nova = $data['duracao_nova'] ?? 0;
        $distancia_anterior = $data['distancia_anterior'] ?? 0;
        $distancia_nova = $data['distancia_nova'] ?? 0;
        $observacoes = $data['observacoes'] ?? '';
        
        if (!$usuario_id || !$exercicio_id) {
            echo json_encode(['sucesso' => false, 'erro' => 'ID do usuário e ID do exercício são obrigatórios']);
            exit;
        }
        
        // Verificar se houve mudança (qualquer alteração)
        $houve_mudanca = false;
        if ($peso_novo != $peso_anterior || 
            $repeticoes_novas != $repeticoes_anteriores || 
            $series_novas != $series_anteriores ||
            $duracao_nova != $duracao_anterior ||
            $distancia_nova != $distancia_anterior) {
            $houve_mudanca = true;
        }
        
        if ($houve_mudanca) {
            $sql = "INSERT INTO historico_evolucao 
                    (usuario_id, exercicio_id, nome_exercicio, categoria, peso_anterior, peso_novo, 
                     repeticoes_anteriores, repeticoes_novas, series_anteriores, series_novas, 
                     duracao_anterior, duracao_nova, distancia_anterior, distancia_nova, observacoes) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                echo json_encode(['sucesso' => false, 'erro' => 'Erro no prepare: ' . $conn->error]);
                exit;
            }
            
            $stmt->bind_param('iissddiiissddds', 
                $usuario_id,
                $exercicio_id,
                $nome_exercicio,
                $categoria,
                $peso_anterior,
                $peso_novo,
                $repeticoes_anteriores,
                $repeticoes_novas,
                $series_anteriores,
                $series_novas,
                $duracao_anterior,
                $duracao_nova,
                $distancia_anterior,
                $distancia_nova,
                $observacoes
            );
            
            if ($stmt->execute()) {
                echo json_encode([
                    'sucesso' => true,
                    'mensagem' => 'Histórico salvo com sucesso!',
                    'id_evolucao' => $conn->insert_id
                ]);
            } else {
                echo json_encode([
                    'sucesso' => false,
                    'erro' => 'Erro ao salvar histórico: ' . $stmt->error
                ]);
            }
        } else {
            echo json_encode([
                'sucesso' => false,
                'mensagem' => 'Nenhuma mudança detectada para salvar'
            ]);
        }
        
    } elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Buscar histórico de evolução de um exercício
        $usuario_id = $_GET['usuario_id'] ?? null;
        $exercicio_id = $_GET['exercicio_id'] ?? null;
        
        if (!$usuario_id || !$exercicio_id) {
            echo json_encode(['sucesso' => false, 'erro' => 'ID do usuário e ID do exercício são obrigatórios']);
            exit;
        }
        
        $sql = "SELECT * FROM historico_evolucao 
                WHERE usuario_id = ? AND exercicio_id = ? 
                ORDER BY data_evolucao DESC 
                LIMIT 50";
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            echo json_encode(['sucesso' => false, 'erro' => 'Erro no prepare: ' . $conn->error]);
            exit;
        }
        
        $stmt->bind_param('ii', $usuario_id, $exercicio_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $historico = [];
        while ($row = $result->fetch_assoc()) {
            $historico[] = $row;
        }
        
        echo json_encode([
            'sucesso' => true,
            'historico' => $historico
        ]);
        
    } else {
        echo json_encode(['sucesso' => false, 'erro' => 'Método não permitido']);
    }
?> 