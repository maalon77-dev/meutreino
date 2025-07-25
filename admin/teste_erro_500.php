<?php
// Ativar exibição de erros
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>🔍 Teste de Erro 500</h1>";

// Simular session
session_start();
$_SESSION['admin_logged_in'] = true;
$_SESSION['admin_id'] = 1;
$_SESSION['admin_nome'] = 'Teste';
$_SESSION['admin_nivel'] = 'ADMIN';

echo "<h2>1️⃣ Teste de Session:</h2>";
echo "Session admin_logged_in: " . ($_SESSION['admin_logged_in'] ? 'true' : 'false') . "<br>";
echo "Session admin_id: " . $_SESSION['admin_id'] . "<br>";
echo "Session admin_nome: " . $_SESSION['admin_nome'] . "<br>";
echo "Session admin_nivel: " . $_SESSION['admin_nivel'] . "<br><br>";

// Teste de conexão
echo "<h2>2️⃣ Teste de Conexão:</h2>";
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

try {
    $conn = new mysqli($host, $user, $pass, $db);
    $conn->set_charset("utf8mb4");
    
    if ($conn->connect_error) {
        throw new Exception("Erro de conexão: " . $conn->connect_error);
    }
    echo "✅ Conexão OK<br><br>";
} catch (Exception $e) {
    echo "❌ Erro de conexão: " . $e->getMessage() . "<br><br>";
    exit;
}

// Teste de variáveis
echo "<h2>3️⃣ Teste de Variáveis:</h2>";
$message = '';
$message_type = '';
$search = $_GET['search'] ?? '';
$nivel_filter = $_GET['nivel'] ?? '';

echo "Search: '$search'<br>";
echo "Nivel filter: '$nivel_filter'<br>";
echo "Message: '$message'<br>";
echo "Message type: '$message_type'<br><br>";

// Teste de construção de WHERE
echo "<h2>4️⃣ Teste de WHERE:</h2>";
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

echo "Where conditions: " . print_r($where_conditions, true) . "<br>";
echo "Params: " . print_r($params, true) . "<br>";
echo "Types: '$types'<br>";
echo "Where clause: '$where_clause'<br><br>";

// Teste de verificação de colunas
echo "<h2>5️⃣ Teste de Verificação de Colunas:</h2>";
$check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
$check_criado_por = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'criado_por'");

echo "Coluna nivel existe: " . ($check_nivel->num_rows > 0 ? 'SIM' : 'NÃO') . "<br>";
echo "Coluna criado_por existe: " . ($check_criado_por->num_rows > 0 ? 'SIM' : 'NÃO') . "<br><br>";

// Teste de construção da SQL
echo "<h2>6️⃣ Teste de Construção SQL:</h2>";
if ($check_nivel->num_rows > 0 && $check_criado_por->num_rows > 0) {
    echo "📋 Ambas as colunas existem<br>";
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

echo "SQL: " . htmlspecialchars($sql) . "<br><br>";

// Teste de preparação da statement
echo "<h2>7️⃣ Teste de Preparação:</h2>";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo "❌ Erro ao preparar statement: " . $conn->error . "<br><br>";
    exit;
}
echo "✅ Statement preparado OK<br>";

// Teste de bind de parâmetros
echo "<h2>8️⃣ Teste de Bind:</h2>";
if (!empty($params)) {
    $bind_result = $stmt->bind_param($types, ...$params);
    if (!$bind_result) {
        echo "❌ Erro ao fazer bind dos parâmetros<br><br>";
        exit;
    }
    echo "✅ Parâmetros vinculados OK<br>";
} else {
    echo "ℹ️ Nenhum parâmetro para vincular<br>";
}
echo "<br>";

// Teste de execução
echo "<h2>9️⃣ Teste de Execução:</h2>";
$execute_result = $stmt->execute();
if (!$execute_result) {
    echo "❌ Erro ao executar query: " . $stmt->error . "<br><br>";
    exit;
}
echo "✅ Query executada OK<br>";

// Teste de obtenção do resultado
echo "<h2>🔟 Teste de Resultado:</h2>";
$result = $stmt->get_result();
if (!$result) {
    echo "❌ Erro ao obter resultado: " . $stmt->error . "<br><br>";
    exit;
}
echo "✅ Resultado obtido OK<br>";

// Teste de conversão para array
echo "<h2>1️⃣1️⃣ Teste de Conversão:</h2>";
$usuarios = $result->fetch_all(MYSQLI_ASSOC);
echo "✅ Dados convertidos para array OK<br>";
echo "Total de usuários: " . count($usuarios) . "<br><br>";

// Mostrar alguns dados
echo "<h2>1️⃣2️⃣ Dados Obtidos:</h2>";
if (count($usuarios) > 0) {
    echo "Primeiro usuário:<br>";
    $primeiro = $usuarios[0];
    foreach ($primeiro as $key => $value) {
        echo "  $key: " . ($value ?? 'NULL') . "<br>";
    }
} else {
    echo "Nenhum usuário encontrado<br>";
}

$conn->close();
echo "<br>🎉 TODOS OS TESTES PASSARAM!<br>";
echo "Se chegou até aqui, o problema não está na lógica PHP.<br>";
echo "Pode ser um problema de configuração do servidor ou sintaxe HTML.<br>";
?> 