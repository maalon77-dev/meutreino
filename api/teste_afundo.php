<?php
// Teste específico para verificar exercícios com "afundo"
echo "=== TESTE ESPECÍFICO PARA 'AFUNDO' ===\n";

try {
    // Conectar ao banco
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    
    $mysqli->set_charset('utf8mb4');
    
    // Teste 1: Buscar por "afundo" exato
    echo "\n1. Buscando por 'afundo' exato:\n";
    $query1 = "SELECT * FROM exercicios_admin WHERE nome_do_exercicio LIKE '%afundo%'";
    $result1 = $mysqli->query($query1);
    
    if ($result1) {
        echo "Encontrados: " . $result1->num_rows . " exercícios\n";
        while ($row = $result1->fetch_assoc()) {
            echo "- " . $row['nome_do_exercicio'] . " (Categoria: " . $row['categoria'] . ", Grupo: " . $row['grupo'] . ")\n";
        }
    }
    
    // Teste 2: Buscar por "afund" (parcial)
    echo "\n2. Buscando por 'afund' (parcial):\n";
    $query2 = "SELECT * FROM exercicios_admin WHERE nome_do_exercicio LIKE '%afund%'";
    $result2 = $mysqli->query($query2);
    
    if ($result2) {
        echo "Encontrados: " . $result2->num_rows . " exercícios\n";
        while ($row = $result2->fetch_assoc()) {
            echo "- " . $row['nome_do_exercicio'] . " (Categoria: " . $row['categoria'] . ", Grupo: " . $row['grupo'] . ")\n";
        }
    }
    
    // Teste 3: Verificar total de exercícios na tabela
    echo "\n3. Total de exercícios na tabela exercicios_admin:\n";
    $query3 = "SELECT COUNT(*) as total FROM exercicios_admin";
    $result3 = $mysqli->query($query3);
    
    if ($result3) {
        $row = $result3->fetch_assoc();
        echo "Total: " . $row['total'] . " exercícios\n";
    }
    
    // Teste 4: Verificar algumas categorias disponíveis
    echo "\n4. Categorias disponíveis:\n";
    $query4 = "SELECT DISTINCT categoria FROM exercicios_admin ORDER BY categoria";
    $result4 = $mysqli->query($query4);
    
    if ($result4) {
        while ($row = $result4->fetch_assoc()) {
            echo "- " . $row['categoria'] . "\n";
        }
    }
    
    // Teste 5: Verificar alguns grupos disponíveis
    echo "\n5. Grupos disponíveis:\n";
    $query5 = "SELECT DISTINCT grupo FROM exercicios_admin ORDER BY grupo LIMIT 10";
    $result5 = $mysqli->query($query5);
    
    if ($result5) {
        while ($row = $result5->fetch_assoc()) {
            echo "- " . $row['grupo'] . "\n";
        }
    }
    
    // Teste 6: Buscar exercícios que contenham "perna" ou "quadríceps"
    echo "\n6. Buscando exercícios com 'perna' ou 'quadríceps':\n";
    $query6 = "SELECT * FROM exercicios_admin WHERE nome_do_exercicio LIKE '%perna%' OR nome_do_exercicio LIKE '%quadríceps%' OR nome_do_exercicio LIKE '%quadriceps%' LIMIT 5";
    $result6 = $mysqli->query($query6);
    
    if ($result6) {
        echo "Encontrados: " . $result6->num_rows . " exercícios\n";
        while ($row = $result6->fetch_assoc()) {
            echo "- " . $row['nome_do_exercicio'] . " (Categoria: " . $row['categoria'] . ", Grupo: " . $row['grupo'] . ")\n";
        }
    }
    
    $mysqli->close();
    
} catch (Exception $e) {
    echo "ERRO: " . $e->getMessage() . "\n";
}
?> 