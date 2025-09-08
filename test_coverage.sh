#!/bin/bash

# Script para executar testes com cobertura
# Uso: ./test_coverage.sh

echo "🧪 Executando testes com cobertura..."

# Limpar cobertura anterior
echo "🧹 Limpando cobertura anterior..."
rm -rf coverage/

# Executar testes com cobertura
echo "▶️  Executando testes..."
flutter test --coverage

# Verificar se os testes passaram
if [ $? -eq 0 ]; then
    echo "✅ Testes executados com sucesso!"
    
    # Verificar cobertura
    echo "📊 Verificando cobertura de código..."
    
    # Instalar lcov se não estiver instalado (macOS)
    if ! command -v lcov &> /dev/null; then
        echo "📦 Instalando lcov..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install lcov
        else
            echo "❌ lcov não encontrado. Instale manualmente."
            exit 1
        fi
    fi
    
    # Gerar relatório HTML
    echo "📄 Gerando relatório HTML..."
    genhtml coverage/lcov.info -o coverage/html --no-function-coverage
    
    # Calcular cobertura total
    echo "📈 Calculando cobertura total..."
    COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//')
    
    echo "📊 Cobertura total: ${COVERAGE}%"
    
    # Verificar se atingiu 80%
    if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
        echo "🎉 Meta de 80% de cobertura atingida!"
    else
        echo "⚠️  Meta de 80% não atingida. Cobertura atual: ${COVERAGE}%"
    fi
    
    echo "📁 Relatório HTML disponível em: coverage/html/index.html"
    echo "📄 Relatório LCOV disponível em: coverage/lcov.info"
    
else
    echo "❌ Testes falharam!"
    exit 1
fi

