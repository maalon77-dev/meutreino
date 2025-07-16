<?php
$servername = "academia3322.mysql.dbaas.com.br";
$username = "academia3322";
$password = "vida1503A@";
$dbname = "academia3322";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Ler o arquivo SQL
    $sql = file_get_contents('create_historico_treinos_table.sql');
    
    // Executar o SQL
    $pdo->exec($sql);
    
    echo "Tabela 'historico_treinos' criada com sucesso!";
    
} catch(PDOException $e) {
    echo "Erro: " . $e->getMessage();
}
?> 