<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Setup - Treinos Prontos</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .step {
            margin-bottom: 30px;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 8px;
        }
        .success { border-color: #4CAF50; background-color: #f1f8e9; }
        .error { border-color: #f44336; background-color: #ffebee; }
        .info { border-color: #2196F3; background-color: #e3f2fd; }
        .btn {
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 5px;
        }
        .btn:hover { background-color: #45a049; }
        .btn-danger { background-color: #f44336; }
        .btn-danger:hover { background-color: #da190b; }
        pre {
            background-color: #f8f8f8;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .status {
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .status.success { background-color: #d4edda; color: #155724; }
        .status.error { background-color: #f8d7da; color: #721c24; }
        .status.info { background-color: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 Setup - Funcionalidade de Treinos Prontos</h1>
        
        <?php
        // Configurações do banco de dados
        $host = 'academia3322.mysql.dbaas.com.br';
        $dbname = 'academia3322';
        $username = 'academia3322';
        $password = 'vida1503A@';
        
        $mysqli = null;
        $errors = [];
        $success = [];
        
        function executeStep($title, $callback) {
            global $mysqli, $errors, $success;
            
            echo "<div class='step info'>";
            echo "<h3>📋 $title</h3>";
            
            try {
                $result = $callback();
                if ($result === true) {
                    echo "<div class='status success'>✅ $title concluído com sucesso!</div>";
                    $success[] = $title;
                } else {
                    echo "<div class='status success'>✅ $result</div>";
                    $success[] = $title;
                }
            } catch (Exception $e) {
                echo "<div class='status error'>❌ Erro: " . $e->getMessage() . "</div>";
                $errors[] = $title . ": " . $e->getMessage();
            }
            
            echo "</div>";
        }
        
        // Conectar ao banco
        try {
            $mysqli = new mysqli($host, $username, $password, $dbname);
            if ($mysqli->connect_error) {
                throw new Exception("Erro de conexão: " . $mysqli->connect_error);
            }
            $mysqli->set_charset("utf8mb4");
            echo "<div class='status success'>✅ Conexão com banco estabelecida</div>";
        } catch (Exception $e) {
            echo "<div class='status error'>❌ Erro de conexão: " . $e->getMessage() . "</div>";
            exit;
        }
        
        // Passo 1: Verificar se a coluna publico existe
        executeStep("Verificar estrutura da tabela", function() use ($mysqli) {
            $sql = "SHOW COLUMNS FROM treinos LIKE 'publico'";
            $result = $mysqli->query($sql);
            
            if ($result->num_rows > 0) {
                return "Coluna 'publico' já existe na tabela treinos";
            } else {
                return "Coluna 'publico' não encontrada - será criada no próximo passo";
            }
        });
        
        // Passo 2: Adicionar coluna publico
        executeStep("Adicionar coluna 'publico'", function() use ($mysqli) {
            $sql = "SHOW COLUMNS FROM treinos LIKE 'publico'";
            $result = $mysqli->query($sql);
            
            if ($result->num_rows > 0) {
                return "Coluna 'publico' já existe - pulando criação";
            }
            
            $sql_add = "ALTER TABLE treinos ADD COLUMN publico ENUM('0', '1') DEFAULT '0' AFTER nome_treino";
            if (!$mysqli->query($sql_add)) {
                throw new Exception($mysqli->error);
            }
            
            return "Coluna 'publico' criada com sucesso";
        });
        
        // Passo 3: Criar índice
        executeStep("Criar índice para otimização", function() use ($mysqli) {
            $sql = "SHOW INDEX FROM treinos WHERE Key_name = 'idx_treinos_publico'";
            $result = $mysqli->query($sql);
            
            if ($result->num_rows > 0) {
                return "Índice 'idx_treinos_publico' já existe";
            }
            
            $sql_index = "CREATE INDEX idx_treinos_publico ON treinos(publico)";
            if (!$mysqli->query($sql_index)) {
                throw new Exception($mysqli->error);
            }
            
            return "Índice criado com sucesso";
        });
        
        // Passo 4: Atualizar treinos existentes
        executeStep("Atualizar treinos existentes", function() use ($mysqli) {
            $sql = "UPDATE treinos SET publico = '0' WHERE publico IS NULL";
            if (!$mysqli->query($sql)) {
                throw new Exception($mysqli->error);
            }
            
            $affected = $mysqli->affected_rows;
            return "Atualizados $affected treinos para privados (publico = '0')";
        });
        
        // Passo 5: Inserir treinos prontos de exemplo
        executeStep("Inserir treinos prontos de exemplo", function() use ($mysqli) {
            // Verificar se já existem treinos públicos
            $sql_check = "SELECT COUNT(*) as count FROM treinos WHERE publico = '1'";
            $result = $mysqli->query($sql_check);
            $row = $result->fetch_assoc();
            
            if ($row['count'] > 0) {
                return "Já existem " . $row['count'] . " treinos públicos - pulando inserção";
            }
            
            // Treinos de exemplo
            $treinos = [
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
                foreach ($treinos as $treino) {
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
                }
                
                $mysqli->commit();
                return "Inseridos " . count($treinos) . " treinos prontos com exercícios";
                
            } catch (Exception $e) {
                $mysqli->rollback();
                throw $e;
            } finally {
                $mysqli->autocommit(TRUE);
            }
        });
        
        // Passo 6: Verificar estrutura final
        executeStep("Verificar estrutura final", function() use ($mysqli) {
            $sql = "DESCRIBE treinos";
            $result = $mysqli->query($sql);
            
            echo "<h4>Estrutura da tabela treinos:</h4>";
            echo "<pre>";
            while ($row = $result->fetch_assoc()) {
                echo $row['Field'] . " (" . $row['Type'] . ")\n";
            }
            echo "</pre>";
            
            return "Estrutura verificada com sucesso";
        });
        
        // Passo 7: Verificar dados
        executeStep("Verificar dados", function() use ($mysqli) {
            $sql = "SELECT COUNT(*) as total FROM treinos";
            $result = $mysqli->query($sql);
            $total = $result->fetch_assoc()['total'];
            
            $sql_publicos = "SELECT COUNT(*) as publicos FROM treinos WHERE publico = '1'";
            $result = $mysqli->query($sql_publicos);
            $publicos = $result->fetch_assoc()['publicos'];
            
            $sql_privados = "SELECT COUNT(*) as privados FROM treinos WHERE publico = '0'";
            $result = $mysqli->query($sql_privados);
            $privados = $result->fetch_assoc()['privados'];
            
            echo "<h4>Resumo dos dados:</h4>";
            echo "<pre>";
            echo "Total de treinos: $total\n";
            echo "Treinos públicos: $publicos\n";
            echo "Treinos privados: $privados\n";
            echo "</pre>";
            
            return "Dados verificados com sucesso";
        });
        
        // Fechar conexão
        if ($mysqli) {
            $mysqli->close();
        }
        
        // Resumo final
        echo "<div class='step " . (empty($errors) ? 'success' : 'error') . "'>";
        echo "<h3>📊 Resumo Final</h3>";
        
        if (empty($errors)) {
            echo "<div class='status success'>🎉 Setup concluído com sucesso!</div>";
            echo "<p>Todos os passos foram executados sem erros.</p>";
        } else {
            echo "<div class='status error'>⚠️ Setup concluído com erros</div>";
            echo "<p>Alguns passos falharam. Verifique os erros acima.</p>";
        }
        
        echo "<h4>Próximos passos:</h4>";
        echo "<ol>";
        echo "<li>Teste a funcionalidade no app Flutter</li>";
        echo "<li>Verifique se os treinos prontos aparecem na nova página</li>";
        echo "<li>Teste a funcionalidade de adicionar treinos aos seus treinos</li>";
        echo "</ol>";
        
        echo "</div>";
        ?>
        
        <div class="step info">
            <h3>🔗 Links Úteis</h3>
            <a href="buscar_treinos_prontos.php" class="btn" target="_blank">Testar API - Buscar Treinos Prontos</a>
            <a href="adicionar_coluna_publico.php" class="btn" target="_blank">Executar Setup Manual</a>
            <a href="inserir_treinos_prontos.php" class="btn" target="_blank">Inserir Mais Treinos</a>
        </div>
    </div>
</body>
</html> 