import 'package:flutter/material.dart';
import '../../core/models/supplier.dart';
import '../../core/repositories/supplier_repository.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _supplierRepo = SupplierRepository();
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _ciController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _ciController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nuevoProveedor = Supplier(
        id: null, // La DB asignará el ID
        nombre: _nombreController.text.trim(),
        ciIdentidad: _ciController.text.trim(),
        telefono: _telefonoController.text.trim(),
      );

      // Guardar en base de datos
      await _supplierRepo.createSupplier(nuevoProveedor);

      if (mounted) {
        // ✅ CRÍTICO: Regresar a la página anterior y enviar el objeto creado
        // PurchasePage recibirá este objeto y recargará la lista.
        Navigator.pop(context, nuevoProveedor);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Proveedor guardado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Proveedor'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Proveedor *',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ciController,
                decoration: InputDecoration(
                  labelText: 'CI / Identidad',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _guardarProveedor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR PROVEEDOR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
