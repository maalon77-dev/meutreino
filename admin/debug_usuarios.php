<?php
// Ativar exibição de erros
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>🔍 Debug Detalhado - Usuarios.php</h2>";

try {
    // Teste 1: Conexão com banco
    echo "<h3>1️⃣ Teste de Conexão:</h3>";
    $host = 'academia3322.mysql.dbaas.com.br';
    $user = 'academia3322';
    $pass = 'vida1503A@';
    $db = 'academia3322';

    $conn = new mysqli($host, $user, $pass, $db);
    $conn->set_charset("utf8mb4");

    if ($conn->connect_error) {
        throw new Exception("Erro de conexão: " . $conn->connect_error);
    }
    echo "✅ Conexão OK<br><br>";

    // Teste 2: Verificar se a tabela existe
    echo "<h3>2️⃣ Verificar Tabela:</h3>";
    $result = $conn->query("SHOW TABLES LIKE 'usuarios'");
    if ($result->num_rows == 0) {
        throw new Exception("Tabela 'usuarios' não existe!");
    }
    echo "✅ Tabela 'usuarios' existe<br><br>";

    // Teste 3: Verificar estrutura da tabela
    echo "<h3>3️⃣ Estrutura da Tabela:</h3>";
    $result = $conn->query("DESCRIBE usuarios");
    if (!$result) {
        throw new Exception("Erro ao descrever tabela: " . $conn->error);
    }
    
    $colunas = [];
    while ($row = $result->fetch_assoc()) {
        $colunas[] = $row['Field'];
        echo "📋 " . $row['Field'] . " (" . $row['Type'] . ")<br>";
    }
    echo "<br>";

    // Teste 4: Verificar colunas específicas
    echo "<h3>4️⃣ Verificação de Colunas Específicas:</h3>";
    $colunas_necessarias = ['id', 'nome', 'email', 'password', 'username'];
    $colunas_opcionais = ['nivel', 'criado_por', 'ativo', 'data_cadastro'];
    
    foreach ($colunas_necessarias as $coluna) {
        if (in_array($coluna, $colunas)) {
            echo "✅ $coluna - EXISTE<br>";
        } else {
            echo "❌ $coluna - NÃO EXISTE<br>";
        }
    }
    
    echo "<br>Colunas opcionais:<br>";
    foreach ($colunas_opcionais as $coluna) {
        if (in_array($coluna, $colunas)) {
            echo "✅ $coluna - EXISTE<br>";
        } else {
            echo "⚠️ $coluna - NÃO EXISTE (opcional)<br>";
        }
    }
    echo "<br>";

    // Teste 5: Consulta básica
    echo "<h3>5️⃣ Teste de Consulta Básica:</h3>";
    $sql = "SELECT id, nome, email FROM usuarios LIMIT 1";
    $result = $conn->query($sql);
    if (!$result) {
        throw new Exception("Erro na consulta básica: " . $conn->error);
    }
    echo "✅ Consulta básica OK<br>";
    echo "Registros encontrados: " . $result->num_rows . "<br><br>";

    // Teste 6: Simular a lógica da página usuarios.php
    echo "<h3>6️⃣ Simulação da Lógica usuarios.php:</h3>";
    
    // Simular filtros
    $search = '';
    $nivel_filter = '';
    $where_conditions = [];
    $params = [];
    $types = '';

    if ($search) {
        $where_conditions[] = "(nome LIKE ? OR email LIKE ?)";
        $search_param = "%$search%";
        $params[] = $search_param;
        $params[] = $search_param;
        $types .= 'ss';
    }

    if ($nivel_filter) {
        // Verificar se a coluna nivel existe antes de filtrar
        $check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
        if ($check_nivel->num_rows > 0) {
            $where_conditions[] = "nivel = ?";
            $params[] = $nivel_filter;
            $types .= 's';
        }
    }

    $where_clause = '';
    if (!empty($where_conditions)) {
        $where_clause = 'WHERE ' . implode(' AND ', $where_conditions);
    }

    echo "Where clause: " . ($where_clause ?: 'Nenhuma condição') . "<br>";
    echo "Parâmetros: " . count($params) . "<br>";
    echo "Tipos: '$types'<br><br>";

    // Teste 7: Construir SQL baseado nas colunas existentes
    echo "<h3>7️⃣ Construção da Query SQL:</h3>";
    
    $check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
    $check_criado_por = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'criado_por'");

    if ($check_nivel->num_rows > 0 && $check_criado_por->num_rows > 0) {
        echo "📋 Ambas as colunas (nivel e criado_por) existem<br>";
        $sql = "SELECT u.id, u.nome, u.email, u.nivel, u.ativo, u.data_cadastro, u.criado_por, c.nome as criador_nome 
                FROM usuarios u 
                LEFT JOIN usuarios c ON u.criado_por = c.id 
                $where_clause 
                ORDER BY u.nome";
    } elseif ($check_nivel->num_rows > 0) {
        echo "📋 Apenas coluna nivel existe<br>";
        $sql = "SELECT id, nome, email, nivel, ativo, data_cadastro, NULL as criado_por, NULL as criador_nome 
                FROM usuarios 
                $where_clause 
                ORDER BY nome";
    } else {
        echo "📋 Nenhuma coluna opcional existe<br>";
        $sql = "SELECT id, nome, email, 'USUARIO' as nivel, ativo, data_cadastro, NULL as criado_por, NULL as criador_nome 
                FROM usuarios 
                $where_clause 
                ORDER BY nome";
    }

    echo "SQL gerado: " . htmlspecialchars($sql) . "<br><br>";

    // Teste 8: Executar a query
    echo "<h3>8️⃣ Execução da Query:</h3>";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Erro ao preparar statement: " . $conn->error);
    }
    echo "✅ Statement preparado OK<br>";

    if (!empty($params)) {
        $bind_result = $stmt->bind_param($types, ...$params);
        if (!$bind_result) {
            throw new Exception("Erro ao fazer bind dos parâmetros");
        }
        echo "✅ Parâmetros vinculados OK<br>";
    }

    $execute_result = $stmt->execute();
    if (!$execute_result) {
        throw new Exception("Erro ao executar query: " . $stmt->error);
    }
    echo "✅ Query executada OK<br>";

    $result = $stmt->get_result();
    if (!$result) {
        throw new Exception("Erro ao obter resultado: " . $stmt->error);
    }
    echo "✅ Resultado obtido OK<br>";

    $usuarios = $result->fetch_all(MYSQLI_ASSOC);
    echo "✅ Dados convertidos para array OK<br>";
    echo "Total de usuários: " . count($usuarios) . "<br><br>";

    // Teste 9: Verificar dados
    echo "<h3>9️⃣ Verificação dos Dados:</h3>";
    if (count($usuarios) > 0) {
        echo "Primeiro usuário:<br>";
        $primeiro = $usuarios[0];
        foreach ($primeiro as $key => $value) {
            echo "  $key: " . ($value ?? 'NULL') . "<br>";
        }
    } else {
        echo "Nenhum usuário encontrado<br>";
    }

    echo "<br>🎉 TODOS OS TESTES PASSARAM!<br>";
    echo "A página usuarios.php deve funcionar corretamente.<br>";

} catch (Exception $e) {
    echo "<br>❌ ERRO ENCONTRADO:<br>";
    echo "<strong>" . $e->getMessage() . "</strong><br>";
    echo "<br>📋 Stack trace:<br>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?> 