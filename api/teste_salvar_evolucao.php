<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

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
    
    // Dados de teste
    $dadosTeste = [
        'usuario_id' => 1,
        'exercicio_id' => 1,
        'nome_exercicio' => 'Flexão de Braço',
        'peso_anterior' => 0,
        'peso_novo' => 5,
        'repeticoes_anteriores' => 10,
        'repeticoes_novas' => 12,
        'series_anteriores' => 3,
        'series_novas' => 3,
        'observacoes' => ''
    ];
    
    // Verificar se há evolução
    $houve_evolucao = false;
    if ($dadosTeste['peso_novo'] > $dadosTeste['peso_anterior'] || 
        $dadosTeste['repeticoes_novas'] > $dadosTeste['repeticoes_anteriores'] || 
        $dadosTeste['series_novas'] > $dadosTeste['series_anteriores']) {
        $houve_evolucao = true;
    }
    
    if ($houve_evolucao) {
        $sql = "INSERT INTO historico_evolucao 
                (usuario_id, exercicio_id, nome_exercicio, peso_anterior, peso_novo, 
                 repeticoes_anteriores, repeticoes_novas, series_anteriores, series_novas, observacoes) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            echo json_encode(['sucesso' => false, 'erro' => 'Erro no prepare: ' . $conn->error]);
            exit;
        }
        
        $stmt->bind_param('iisddiiiss', 
            $dadosTeste['usuario_id'],
            $dadosTeste['exercicio_id'],
            $dadosTeste['nome_exercicio'],
            $dadosTeste['peso_anterior'],
            $dadosTeste['peso_novo'],
            $dadosTeste['repeticoes_anteriores'],
            $dadosTeste['repeticoes_novas'],
            $dadosTeste['series_anteriores'],
            $dadosTeste['series_novas'],
            $dadosTeste['observacoes']
        );
        
        if ($stmt->execute()) {
            echo json_encode([
                'sucesso' => true,
                'mensagem' => 'Evolução de teste salva com sucesso!',
                'id_evolucao' => $conn->insert_id,
                'dados_testados' => $dadosTeste
            ]);
        } else {
            echo json_encode([
                'sucesso' => false,
                'erro' => 'Erro ao salvar evolução: ' . $stmt->error,
                'dados_testados' => $dadosTeste
            ]);
        }
    } else {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Nenhuma evolução detectada para salvar',
            'dados_testados' => $dadosTeste
        ]);
    }
?> 