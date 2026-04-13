#!/bin/bash

echo "=============================================="
echo "VERIFICACIÓN FINAL - SISTEMA COMPLETO NOVA-ADEN"
echo "=============================================="

echo -e "\n[1] Verificando Base de Datos..."
if grep -q "version: 6" lib/core/database/database_helper.dart; then
    echo "✅ DB versión 6 OK"
else
    echo "❌ ERROR: BD no tiene versión 6"
fi

echo -e "\n[2] Verificando SaleRepository Methods..."
if grep -q "registrarPagoFiado" lib/core/repositories/sale_repository.dart; then
    echo "✅ Método fiados OK"
else
    echo "❌ ERROR: No existe registrarPagoFiado"
fi

if grep -q "getFlujoDeCaja" lib/core/repositories/sale_repository.dart; then
    echo "✅ Método flujo caja OK"
else
    echo "❌ ERROR: No existe getFlujoDeCaja"
fi

if grep -q "getDeudasPendientes" lib/core/repositories/sale_repository.dart; then
    echo "✅ Método deudas pendientes OK"
else
    echo "❌ ERROR: No existe getDeudasPendientes"
fi

echo -e "\n[3] Verificando Conexiones POS..."
if grep -q "SaleRepository" lib/presentation/pages/pos_page.dart; then
    echo "✅ POS conecta con Repository"
else
    echo "❌ ERROR: POS no usa SaleRepository"
fi

if grep -q "createSale" lib/presentation/pages/pos_page.dart; then
    echo "✅ POS llama createSale"
else
    echo "❌ ERROR: POS no llama createSale"
fi

echo -e "\n[4] Verificando Tablas en Schema..."
for TABLE in "ventas" "detalle_ventas" "mermas" "config"; do
    if grep -q "$TABLE" lib/core/database/database_helper.dart; then
        echo "✅ Tabla $TABLE definida"
    else
        echo "❌ ERROR: Tabla $TABLE no existe"
    fi
done

echo -e "\n[5] Verificando Main.dart Imports..."
if grep -q "flutter/services.dart" lib/main.dart; then
    echo "✅ Services importado (SystemChrome OK)"
else
    echo "❌ ERROR: Falta flutter/services.dart"
fi

if ! grep -q "errorBuilder" lib/main.dart; then
    echo "✅ errorBuilder eliminado"
else
    echo "❌ ERROR: errorBuilder aún existe"
fi

echo -e "\n[6] Verificando PDF Generator..."
if grep -q "import '../models/sale.dart'" lib/core/utils/pdf_generator.dart; then
    echo "✅ PDF usa SaleLine correcto"
else
    echo "❌ ERROR: PDF no importa correctamente"
fi

if ! grep -q "class SaleLine" lib/core/utils/pdf_generator.dart; then
    echo "✅ No duplicado SaleLine en PDF"
else
    echo "❌ ERROR: Hay duplicación SaleLine en PDF"
fi

echo -e "\n=============================================="
echo "VERIFICACIÓN COMPLETADA - REVISAR RESULTADOS ARRIBA"
echo "=============================================="
