<?php
// Teste simples para verificar a API de busca global

echo "=== TESTE 1: Busca por categoria e grupo ===\n";
$categoria = 'musculacao';
$grupo = 'biceps';

$url = "https://airfit.online/api/buscar_exercicios_global.php?categoria=$categoria&grupo=$grupo";

echo "Testando URL: $url\n\n";

$response = file_get_contents($url);
$data = json_decode($response, true);

echo "Status: " . (isset($data['erro']) ? 'ERRO' : 'SUCESSO') . "\n";
echo "Total de exercícios: " . ($data['total_exercicios'] ?? 'N/A') . "\n";
echo "Categoria: " . ($data['categoria'] ?? 'N/A') . "\n";
echo "Grupo: " . ($data['grupo'] ?? 'N/A') . "\n";

if (isset($data['exercicios'])) {
    echo "\nPrimeiros 3 exercícios:\n";
    for ($i = 0; $i < min(3, count($data['exercicios'])); $i++) {
        $ex = $data['exercicios'][$i];
        echo "- " . $ex['nome_do_exercicio'] . "\n";
    }
}

if (isset($data['erro'])) {
    echo "\nERRO: " . $data['erro'] . "\n";
}

echo "\n\n=== TESTE 2: Busca global por termo ===\n";
$termo = 'flexão';

$url2 = "https://airfit.online/api/buscar_exercicios_global.php?termo=$termo";

echo "Testando URL: $url2\n\n";

$response2 = file_get_contents($url2);
$data2 = json_decode($response2, true);

echo "Status: " . (isset($data2['erro']) ? 'ERRO' : 'SUCESSO') . "\n";
echo "Total de exercícios: " . ($data2['total_exercicios'] ?? 'N/A') . "\n";
echo "Termo de busca: " . ($data2['termo_busca'] ?? 'N/A') . "\n";

if (isset($data2['exercicios'])) {
    echo "\nPrimeiros 3 exercícios:\n";
    for ($i = 0; $i < min(3, count($data2['exercicios'])); $i++) {
        $ex = $data2['exercicios'][$i];
        echo "- " . $ex['nome_do_exercicio'] . " (Categoria: " . $ex['categoria'] . ", Grupo: " . $ex['grupo'] . ")\n";
    }
}

if (isset($data2['erro'])) {
    echo "\nERRO: " . $data2['erro'] . "\n";
}

echo "\n\n=== TESTE 3: Busca combinada (termo + categoria) ===\n";
$termo3 = 'braço';
$categoria3 = 'musculacao';

$url3 = "https://airfit.online/api/buscar_exercicios_global.php?termo=$termo3&categoria=$categoria3";

echo "Testando URL: $url3\n\n";

$response3 = file_get_contents($url3);
$data3 = json_decode($response3, true);

echo "Status: " . (isset($data3['erro']) ? 'ERRO' : 'SUCESSO') . "\n";
echo "Total de exercícios: " . ($data3['total_exercicios'] ?? 'N/A') . "\n";
echo "Termo de busca: " . ($data3['termo_busca'] ?? 'N/A') . "\n";
echo "Categoria: " . ($data3['categoria'] ?? 'N/A') . "\n";

if (isset($data3['exercicios'])) {
    echo "\nPrimeiros 3 exercícios:\n";
    for ($i = 0; $i < min(3, count($data3['exercicios'])); $i++) {
        $ex = $data3['exercicios'][$i];
        echo "- " . $ex['nome_do_exercicio'] . " (Grupo: " . $ex['grupo'] . ")\n";
    }
}

if (isset($data3['erro'])) {
    echo "\nERRO: " . $data3['erro'] . "\n";
}
?> 