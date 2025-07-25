<?php
// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

echo "<h2>🔍 Teste da Tabela Usuarios</h2>";

// Testar conexão
if ($conn->connect_error) {
    die("❌ Erro de conexão: " . $conn->connect_error);
}
echo "✅ Conexão estabelecida com sucesso!<br><br>";

// Verificar estrutura da tabela
echo "<h3>📋 Estrutura da Tabela:</h3>";
$result = $conn->query("DESCRIBE usuarios");
if ($result) {
    echo "<table border='1' style='border-collapse: collapse;'>";
    echo "<tr><th>Campo</th><th>Tipo</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['Field'] . "</td>";
        echo "<td>" . $row['Type'] . "</td>";
        echo "<td>" . $row['Null'] . "</td>";
        echo "<td>" . $row['Key'] . "</td>";
        echo "<td>" . $row['Default'] . "</td>";
        echo "<td>" . $row['Extra'] . "</td>";
        echo "</tr>";
    }
    echo "</table><br>";
} else {
    echo "❌ Erro ao verificar estrutura: " . $conn->error . "<br><br>";
}

// Verificar se as colunas específicas existem
echo "<h3>🔍 Verificação de Colunas:</h3>";
$colunas = ['nivel', 'criado_por', 'ativo', 'data_cadastro'];
foreach ($colunas as $coluna) {
    $result = $conn->query("SHOW COLUMNS FROM usuarios LIKE '$coluna'");
    if ($result && $result->num_rows > 0) {
        echo "✅ Coluna '$coluna' existe<br>";
    } else {
        echo "❌ Coluna '$coluna' NÃO existe<br>";
    }
}
echo "<br>";

// Testar consulta básica
echo "<h3>📊 Teste de Consulta:</h3>";
$sql = "SELECT id, nome, email FROM usuarios LIMIT 5";
$result = $conn->query($sql);
if ($result) {
    echo "✅ Consulta básica funcionou!<br>";
    echo "Encontrados " . $result->num_rows . " usuários<br><br>";
} else {
    echo "❌ Erro na consulta básica: " . $conn->error . "<br><br>";
}

// Testar consulta com JOIN
echo "<h3>🔗 Teste de JOIN:</h3>";
$sql = "SELECT u.id, u.nome, u.email, u.nivel, c.nome as criador_nome 
        FROM usuarios u 
        LEFT JOIN usuarios c ON u.criado_por = c.id 
        LIMIT 3";
$result = $conn->query($sql);
if ($result) {
    echo "✅ Consulta com JOIN funcionou!<br>";
    echo "Encontrados " . $result->num_rows . " registros<br><br>";
} else {
    echo "❌ Erro na consulta com JOIN: " . $conn->error . "<br><br>";
}

// Mostrar alguns usuários
echo "<h3>👥 Usuários Cadastrados:</h3>";
$sql = "SELECT id, nome, email, nivel, ativo FROM usuarios ORDER BY id LIMIT 10";
$result = $conn->query($sql);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Nome</th><th>Email</th><th>Nível</th><th>Ativo</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . htmlspecialchars($row['nome']) . "</td>";
        echo "<td>" . htmlspecialchars($row['email']) . "</td>";
        echo "<td>" . ($row['nivel'] ?? 'N/A') . "</td>";
        echo "<td>" . ($row['ativo'] ? 'Sim' : 'Não') . "</td>";
        echo "</tr>";
    }
    echo "</table><br>";
} else {
    echo "❌ Nenhum usuário encontrado ou erro na consulta<br><br>";
}

$conn->close();
echo "<br>🎉 Teste concluído!";
?> 